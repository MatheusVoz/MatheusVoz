import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../services/feedback_service.dart';
import '../state/game_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/glow_button.dart';
import '../widgets/item_card.dart';
import '../widgets/keypad_sheet.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_dialog.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/player_chip.dart';
import '../widgets/pressable.dart';
import '../widgets/rota.dart';
import 'review_screen.dart';

/// Tela principal do leilao.
class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> with TickerProviderStateMixin {
  /// Jogador escolhido como vencedor do lance atual.
  int? _selecionado;

  /// Valor do lance que esta sendo registrado.
  int _valor = 1;

  /// Animacao do martelo ("VENDIDO!").
  late final AnimationController _martelo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  /// Animacao de "LEILAO ENCERRADO".
  late final AnimationController _fim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  /// Dados exibidos na animacao de venda.
  String _vendaJogador = '';
  int _vendaValor = 0;
  Color _vendaCor = AppColors.roxo;
  bool _vendendo = false;

  @override
  void initState() {
    super.initState();
    // Se a partida foi retomada ja encerrada, mostra o aviso de fim.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<GameController>().leilaoEncerrado) _fim.forward();
    });
  }

  @override
  void dispose() {
    _martelo.dispose();
    _fim.dispose();
    super.dispose();
  }

  GameController get _game => context.read<GameController>();

  // -------------------------------------------------------------
  // Acoes
  // -------------------------------------------------------------

  void _tocarJogador(Player p) {
    if (_vendendo) return;
    final g = _game;
    if (!g.podeArrematar(p)) {
      avisar(context, '${p.nome}: ${g.motivoBloqueio(p) ?? 'não pode arrematar'}.');
      return;
    }
    setState(() {
      if (_selecionado == p.id) {
        _selecionado = null;
      } else {
        _selecionado = p.id;
        _valor = _valor.clamp(1, g.lanceMaximo(p));
      }
    });
  }

  void _ajustar(int delta) {
    if (_selecionado == null) return;
    final max = _game.lanceMaximo(_game.jogador(_selecionado!));
    final novo = (_valor + delta).clamp(1, math.max(1, max)).toInt();
    if (novo == _valor) {
      if (delta > 0) avisar(context, 'Lance máximo para este jogador: R\$$max.');
      return;
    }
    setState(() => _valor = novo);
  }

  Future<void> _digitarValor() async {
    if (_selecionado == null) return;
    final p = _game.jogador(_selecionado!);
    final v = await mostrarTecladoLance(
      context,
      valorInicial: _valor,
      maximo: _game.lanceMaximo(p),
      jogador: p.nome,
    );
    if (v != null && mounted) setState(() => _valor = v);
  }

  Future<void> _vender() async {
    if (_selecionado == null || _vendendo) return;
    final g = _game;
    final p = g.jogador(_selecionado!);
    // Valida antes de animar.
    if (_valor > g.lanceMaximo(p) || _valor < 1) {
      avisar(context, 'Lance inválido. Máximo de ${p.nome}: R\$${g.lanceMaximo(p)}.');
      return;
    }
    setState(() {
      _vendendo = true;
      _vendaJogador = p.nome;
      _vendaValor = _valor;
      _vendaCor = p.cor;
    });
    _martelo.forward(from: 0);
    // O martelo bate em ~35% da animacao: som + vibracao nesse instante.
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    FeedbackService.instancia.tocar(Som.martelo);
    FeedbackService.instancia.vibrarForte();
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    final r = g.vender(p.id, _valor);
    if (!r.ok) {
      avisar(context, r.erro!);
    } else {
      FeedbackService.instancia.tocar(Som.moeda);
    }
    setState(() {
      _selecionado = null;
      _valor = 1;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _vendendo = false);
    if (g.leilaoEncerrado) _mostrarFim();
  }

  void _pular() {
    if (_vendendo) return;
    _game.pular();
    setState(() {
      _selecionado = null;
      _valor = 1;
    });
    if (_game.leilaoEncerrado) _mostrarFim();
  }

  void _desfazer() {
    if (_vendendo) return;
    final a = _game.desfazer();
    if (a == null) return;
    _fim.reset();
    setState(() {
      _selecionado = null;
      _valor = 1;
    });
    final item = _game.itemAtual ?? '';
    if (a.venda) {
      avisar(context, 'Venda desfeita: "$item" voltou ao leilão.');
    } else {
      avisar(context, '"$item" voltou ao leilão.');
    }
  }

  void _mostrarFim() {
    FeedbackService.instancia.vibrarForte();
    _fim.forward(from: 0);
  }

  void _verListas() {
    _game.irParaRevisao();
    Navigator.of(context).pushReplacement(rotaAnimada(const ReviewScreen()));
  }

  Future<void> _sair() async {
    final ok = await confirmar(
      context,
      titulo: 'Pausar leilão?',
      mensagem: 'A partida fica salva. Você pode continuar depois pelo menu.',
      sim: 'Ir ao menu',
      icone: LanceIconType.cronometro,
    );
    if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _mostrarListas() {
    final g = _game;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ListasParciais(game: g),
    );
  }

  // -------------------------------------------------------------
  // Interface
  // -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    if (!g.temPartida) return const Scaffold(body: LanceBackground(child: SizedBox()));
    final config = g.config!;
    // Se o selecionado ficou invalido (ex.: regra mudou), limpa a selecao.
    if (_selecionado != null && !g.podeArrematar(g.jogador(_selecionado!))) _selecionado = null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _sair();
      },
      child: Scaffold(
        body: LanceBackground(
          child: Stack(
            children: [
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final h = c.maxHeight;
                    final linhas = (g.jogadores.length / 2).ceil();
                    // Altura dos cards de jogador adaptada a tela.
                    final alturaChip = ((h * 0.27) / linhas - 8).clamp(56.0, 84.0);
                    final compacto = h < 640;
                    return Column(
                      children: [
                        _topo(g, compacto),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                            child: g.itemAtual == null
                                ? const SizedBox()
                                : ItemCard(
                                    item: g.itemAtual!,
                                    indice: g.indiceAtual,
                                    icone: g.tema.icone,
                                    tema: config.temaNome,
                                    temaId: config.temaId,
                                  ),
                          ),
                        ),
                        _gradeJogadores(g, alturaChip),
                        _painelLance(g, compacto),
                        _acoes(g, compacto),
                      ],
                    );
                  },
                ),
              ),
              _overlayMartelo(),
              _overlayFim(g),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topo(GameController g, bool compacto) {
    final atual = math.min(g.indiceAtual + 1, g.totalItens);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          BotaoIcone(icone: LanceIconType.voltar, onTap: _sair, rotulo: 'Pausar', tamanho: 44),
          Expanded(
            child: Column(
              children: [
                Text(
                  'ITEM $atual DE ${g.totalItens}',
                  style: AppText.numero(compacto ? 15 : 17).copyWith(shadows: AppText.brilho),
                ),
              ],
            ),
          ),
          BotaoIcone(icone: LanceIconType.lista, onTap: _mostrarListas, rotulo: 'Ver listas', tamanho: 44),
        ],
      ),
    );
  }

  Widget _gradeJogadores(GameController g, double alturaChip) {
    final js = g.jogadores;
    final linhas = <Widget>[];
    for (var i = 0; i < js.length; i += 2) {
      linhas.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              for (var k = i; k < i + 2; k++) ...[
                if (k > i) const SizedBox(width: 8),
                Expanded(
                  child: k < js.length
                      ? PlayerChip(
                          key: ValueKey('chip_${js[k].id}'),
                          jogador: js[k],
                          selecionado: _selecionado == js[k].id,
                          ativo: g.podeArrematar(js[k]),
                          motivoBloqueio: g.motivoBloqueio(js[k]),
                          altura: alturaChip,
                          onTap: () => _tocarJogador(js[k]),
                        )
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: linhas),
    );
  }

  Widget _painelLance(GameController g, bool compacto) {
    final sel = _selecionado == null ? null : g.jogador(_selecionado!);
    final altura = compacto ? 74.0 : 86.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(a), child: c),
        ),
        child: sel == null
            ? Container(
                key: const ValueKey('dica'),
                height: altura,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.roxo.withValues(alpha: 0.35), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LanceIcon(LanceIconType.jogador, tamanho: 26),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Toque no jogador que venceu o lance',
                        textAlign: TextAlign.center,
                        style: AppText.texto(compacto ? 14 : 16, cor: AppColors.lilas),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                key: const ValueKey('painel'),
                height: altura,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel.cor, width: 2),
                  boxShadow: [BoxShadow(color: sel.cor.withValues(alpha: 0.4), blurRadius: 16)],
                ),
                child: Row(
                  children: [
                    _botaoAjuste('-1', () => _ajustar(-1), compacto),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Digitar valor',
                        child: Pressable(
                          onTap: _digitarValor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'R\$$_valor',
                                  style: AppText.numero(compacto ? 28 : 34).copyWith(shadows: AppText.brilho),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const LanceIcon(LanceIconType.teclado, tamanho: 18),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'máx R\$${g.lanceMaximo(sel)}',
                                      maxLines: 1,
                                      style: AppText.texto(13.5, cor: AppColors.lilas),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _botaoAjuste('+1', () => _ajustar(1), compacto),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _botaoAjuste(String rotulo, VoidCallback onTap, bool compacto) {
    final t = compacto ? 46.0 : 52.0;
    return Semantics(
      button: true,
      label: rotulo,
      child: Pressable(
        onTap: onTap,
        escala: 0.88,
        child: Container(
          width: t,
          height: t,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.superficieClara,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.roxo, width: 2),
          ),
          child: Text(rotulo, style: AppText.numero(compacto ? 15 : 17)),
        ),
      ),
    );
  }

  Widget _acoes(GameController g, bool compacto) {
    final alturaBotao = compacto ? 58.0 : 66.0;
    final ultima = g.ultimaAcao;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          _acaoPequena(
            icone: LanceIconType.pular,
            rotulo: 'Pular',
            descricao: 'Ninguém quis / Pular item',
            altura: alturaBotao,
            onTap: _vendendo ? null : _pular,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GlowButton(
              texto: 'VENDIDO!',
              icone: LanceIconType.martelo,
              altura: alturaBotao,
              tamanhoTexto: compacto ? 21 : 24,
              onTap: _selecionado == null || _vendendo ? null : _vender,
            ),
          ),
          const SizedBox(width: 10),
          _acaoPequena(
            icone: LanceIconType.desfazer,
            rotulo: 'Desfazer',
            descricao: ultima == null
                ? 'Desfazer'
                : (ultima.venda ? 'Desfazer última venda' : 'Desfazer último pulo'),
            altura: alturaBotao,
            onTap: g.podeDesfazer && !_vendendo ? _desfazer : null,
          ),
        ],
      ),
    );
  }

  Widget _acaoPequena({
    required LanceIconType icone,
    required String rotulo,
    required String descricao,
    required double altura,
    required VoidCallback? onTap,
  }) {
    final ativo = onTap != null;
    return Semantics(
      button: true,
      enabled: ativo,
      label: descricao,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: ativo ? 1 : 0.35,
          child: Container(
            width: altura * 1.15,
            height: altura,
            decoration: BoxDecoration(
              color: AppColors.superficieClara,
              borderRadius: BorderRadius.circular(altura / 2.4),
              border: Border.all(color: AppColors.roxo, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LanceIcon(icone, tamanho: altura * 0.42),
                const SizedBox(height: 2),
                Text(
                  rotulo,
                  style: AppText.texto(11.5, cor: AppColors.lilas, peso: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Martelo batendo + "VENDIDO!" com o nome e o valor.
  Widget _overlayMartelo() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _martelo,
        builder: (context, _) {
          final t = _martelo.value;
          if (t == 0 || t == 1) return const SizedBox.shrink();
          final opacidade = t < 0.1 ? t / 0.1 : (t > 0.85 ? (1 - t) / 0.15 : 1.0);
          // Martelo: levanta (0-0.2), desce rapido (0.2-0.3), quica (0.3-0.45).
          double ang;
          if (t < 0.2) {
            ang = -0.9 * Curves.easeOut.transform(t / 0.2);
          } else if (t < 0.28) {
            ang = -0.9 + 1.1 * Curves.easeIn.transform((t - 0.2) / 0.08);
          } else if (t < 0.45) {
            ang = 0.2 * (1 - Curves.elasticOut.transform((t - 0.28) / 0.17));
          } else {
            ang = 0;
          }
          final impacto = t > 0.28 ? Curves.easeOut.transform(((t - 0.28) / 0.3).clamp(0.0, 1.0)) : 0.0;
          final texto = t > 0.3 ? Curves.elasticOut.transform(((t - 0.3) / 0.35).clamp(0.0, 1.0)) : 0.0;
          // Tremida da tela no impacto.
          final tremor = (t > 0.28 && t < 0.4) ? math.sin(t * 160) * 6 * (0.4 - t) / 0.12 : 0.0;
          return Opacity(
            opacity: opacidade.clamp(0.0, 1.0),
            child: Container(
              color: AppColors.fundo.withValues(alpha: 0.9),
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(tremor, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (impacto > 0 && impacto < 1)
                            Container(
                              width: 80 + 180 * impacto,
                              height: 80 + 180 * impacto,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _vendaCor.withValues(alpha: (1 - impacto) * 0.9),
                                  width: 6,
                                ),
                              ),
                            ),
                          Transform.rotate(
                            angle: ang,
                            alignment: const Alignment(0.7, 0.75),
                            child: const LanceIcon(LanceIconType.martelo, tamanho: 170),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: texto,
                      child: Column(
                        children: [
                          Text(
                            'VENDIDO!',
                            style: AppText.titulo(52).copyWith(
                              shadows: [
                                Shadow(color: _vendaCor, blurRadius: 24),
                                const Shadow(color: AppColors.roxo, blurRadius: 48),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              '$_vendaJogador  •  R\$$_vendaValor',
                              textAlign: TextAlign.center,
                              style: AppText.texto(24, cor: AppColors.branco, peso: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Transicao "LEILAO ENCERRADO".
  Widget _overlayFim(GameController g) {
    return AnimatedBuilder(
      animation: _fim,
      builder: (context, _) {
        final t = _fim.value;
        if (t == 0) return const SizedBox.shrink();
        final fundo = (t / 0.3).clamp(0.0, 1.0);
        final titulo = Curves.elasticOut.transform(((t - 0.15) / 0.6).clamp(0.0, 1.0));
        final botoes = Curves.easeOut.transform(((t - 0.6) / 0.4).clamp(0.0, 1.0));
        return Container(
          color: AppColors.fundo.withValues(alpha: 0.96 * fundo),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: titulo,
                    child: Column(
                      children: [
                        const LanceIcon(LanceIconType.martelo, tamanho: 110),
                        const SizedBox(height: 18),
                        Text('LEILÃO', style: AppText.titulo(50).copyWith(shadows: AppText.brilho)),
                        Text(
                          'ENCERRADO',
                          style: AppText.titulo(40, cor: AppColors.neon).copyWith(shadows: AppText.brilho),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          g.textoMotivoFim,
                          textAlign: TextAlign.center,
                          style: AppText.texto(18, cor: AppColors.lilas),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Opacity(
                    opacity: botoes,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - botoes)),
                      child: Column(
                        children: [
                          GlowButton(
                            texto: 'Ver as listas',
                            icone: LanceIconType.lista,
                            altura: 64,
                            onTap: botoes > 0.5 ? _verListas : null,
                          ),
                          const SizedBox(height: 12),
                          GlowButton(
                            texto: 'Desfazer última ação',
                            icone: LanceIconType.desfazer,
                            estilo: EstiloBotao.secundario,
                            altura: 54,
                            tamanhoTexto: 17,
                            onTap: botoes > 0.5 && g.podeDesfazer ? _desfazer : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Folha inferior com as listas parciais de cada jogador durante o leilao.
class _ListasParciais extends StatelessWidget {
  final GameController game;
  const _ListasParciais({required this.game});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.roxo, width: 2),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.lilas.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('Listas até agora', textAlign: TextAlign.center, style: AppText.titulo(22)),
            const SizedBox(height: 14),
            for (final p in game.jogadores)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.superficieClara,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.cor, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.texto(18, cor: AppColors.branco, peso: FontWeight.w700),
                          ),
                        ),
                        Text('R\$${p.saldo}', style: AppText.numero(18)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (p.compras.isEmpty)
                      Text(
                        'Nenhum item ainda',
                        style: AppText.texto(14, cor: AppColors.lilas.withValues(alpha: 0.6)),
                      )
                    else
                      for (final c in p.compras)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              Expanded(child: Text(c.item, style: AppText.texto(15))),
                              Text('R\$${c.preco}', style: AppText.texto(15, cor: AppColors.branco)),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
