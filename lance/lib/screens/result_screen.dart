import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../services/feedback_service.dart';
import '../state/game_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/confetti.dart';
import '../widgets/glow_button.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/pressable.dart';
import '../widgets/rota.dart';
import 'auction_screen.dart';
import 'review_screen.dart';
import 'theme_select_screen.dart';

/// Resultado: podio animado com confete em cima e, embaixo, a lista em que o
/// juiz da pontos. O podio se atualiza ao vivo (mais pontos = mais alto).
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const _alturaLinha = 54.0;

  /// Muda a chave para disparar uma nova chuva de confete.
  int _confetes = 0;
  int? _lider;

  @override
  void initState() {
    super.initState();
    // Fanfarra e confete assim que a tela abre.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      FeedbackService.instancia.tocar(Som.fanfarra);
      FeedbackService.instancia.vibrarForte();
      setState(() => _confetes++);
    });
  }

  void _pontuar(GameController g, Player p, int delta) {
    g.darPonto(p.id, delta);
    final topo = g.classificacao.first;
    // Novo lider com pontos: mais confete.
    if (g.pontos(topo.id) > 0 && topo.id != _lider) {
      _lider = topo.id;
      FeedbackService.instancia.tocar(Som.moeda);
      setState(() => _confetes++);
    }
  }

  void _voltarRevisao(GameController g) {
    g.irParaRevisao();
    Navigator.of(context).pushReplacement(rotaAnimada(const ReviewScreen()));
  }

  void _denovo() {
    context.read<GameController>().jogarNovamente();
    Navigator.of(context).pushAndRemoveUntil(rotaAnimada(const AuctionScreen()), (r) => r.isFirst);
  }

  Future<void> _novo() async {
    final nav = Navigator.of(context);
    await context.read<GameController>().encerrarPartida();
    nav.pushAndRemoveUntil(rotaAnimada(const ThemeSelectScreen()), (r) => r.isFirst);
  }

  Future<void> _menu() async {
    final nav = Navigator.of(context);
    await context.read<GameController>().encerrarPartida();
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    if (!g.temPartida || g.fase != FasePartida.juiz) {
      return const Scaffold(body: LanceBackground(child: SizedBox()));
    }
    final lista = g.classificacao;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltarRevisao(g);
      },
      child: Scaffold(
        body: LanceBackground(
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    LanceTopBar(titulo: 'Pódio', onVoltar: () => _voltarRevisao(g)),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _Podio(classificacao: lista, pontos: g.pontos),
                            const SizedBox(height: 14),
                            Text(
                              '1 ponto por item. Juiz: use + e − para ajustar',
                              style: AppText.texto(13, cor: AppColors.lilas.withValues(alpha: 0.75)),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: lista.length * _alturaLinha,
                              child: Stack(
                                children: [
                                  // Cada linha desliza ate a nova posicao quando a ordem muda.
                                  for (final p in g.jogadores)
                                    AnimatedPositioned(
                                      key: ValueKey('linha_${p.id}'),
                                      duration: const Duration(milliseconds: 420),
                                      curve: Curves.easeOutBack,
                                      left: 0,
                                      right: 0,
                                      top: lista.indexOf(p) * _alturaLinha,
                                      height: _alturaLinha - 8,
                                      child: _Linha(
                                        jogador: p,
                                        posicao: lista.indexOf(p) + 1,
                                        pontos: g.pontos(p.id),
                                        onMais: () => _pontuar(g, p, 1),
                                        onMenos: () => _pontuar(g, p, -1),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: GlowButton(
                              texto: 'Jogar de novo',
                              icone: LanceIconType.play,
                              altura: 48,
                              tamanhoTexto: 16,
                              onTap: _denovo,
                            ),
                          ),
                          const SizedBox(width: 8),
                          BotaoIcone(icone: LanceIconType.martelo, rotulo: 'Novo leilão', onTap: _novo),
                          const SizedBox(width: 8),
                          BotaoIcone(icone: LanceIconType.voltar, rotulo: 'Menu', onTap: _menu),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_confetes > 0) Positioned.fill(child: ConfettiRain(key: ValueKey(_confetes))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Podio com 2o - 1o - 3o. Os blocos crescem ao abrir a tela e os jogadores
/// trocam de lugar com animacao quando a pontuacao muda.
class _Podio extends StatelessWidget {
  final List<Player> classificacao;
  final int Function(int id) pontos;
  const _Podio({required this.classificacao, required this.pontos});

  @override
  Widget build(BuildContext context) {
    final n = classificacao.length;
    final ordem = <int>[if (n > 1) 1, 0, if (n > 2) 2];
    const alturas = {0: 120.0, 1: 86.0, 2: 62.0};
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => SizedBox(
        height: 250,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final pos in ordem)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _Coluna(
                    posicao: pos,
                    jogador: classificacao[pos],
                    pontos: pontos(classificacao[pos].id),
                    alturaBloco: alturas[pos]! * Curves.easeOutBack.transform(t),
                    entrada: t,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Coluna extends StatelessWidget {
  final int posicao;
  final Player jogador;
  final int pontos;
  final double alturaBloco;
  final double entrada;

  const _Coluna({
    required this.posicao,
    required this.jogador,
    required this.pontos,
    required this.alturaBloco,
    required this.entrada,
  });

  @override
  Widget build(BuildContext context) {
    final campeao = posicao == 0;
    final p = jogador;
    final coroa = campeao ? Curves.elasticOut.transform(((entrada - 0.5) / 0.5).clamp(0.0, 1.0)) : 0.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (campeao)
          Transform.scale(
            scale: coroa,
            child: const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: LanceIcon(LanceIconType.coroa, tamanho: 44),
            ),
          ),
        // Nome e pontos trocam com animacao quando outro jogador assume a posicao.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (c, a) => ScaleTransition(
            scale: a,
            child: FadeTransition(opacity: a, child: c),
          ),
          child: Column(
            key: ValueKey('${p.id}_$pontos'),
            children: [
              Container(
                width: campeao ? 14 : 11,
                height: campeao ? 14 : 11,
                decoration: BoxDecoration(shape: BoxShape.circle, color: p.cor),
              ),
              const SizedBox(height: 4),
              Text(
                p.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.texto(campeao ? 16 : 14, cor: AppColors.branco, peso: FontWeight.w700),
              ),
              Text(
                pontos == 1 ? '1 ponto' : '$pontos pontos',
                style: AppText.texto(12, cor: AppColors.lilas.withValues(alpha: 0.75)),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
        Container(
          height: alturaBloco.clamp(0.0, 200.0),
          width: double.infinity,
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            gradient: campeao
                ? AppColors.gradienteBotao
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.superficieClara, AppColors.superficie],
                  ),
            boxShadow: campeao ? [BoxShadow(color: AppColors.neon.withValues(alpha: 0.45), blurRadius: 22)] : null,
          ),
          child: alturaBloco > 40
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${posicao + 1}º',
                    style: AppText.numero(
                      campeao ? 30 : 24,
                      cor: campeao ? AppColors.textoSobreAmarelo : AppColors.branco,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

/// Linha minimalista: posicao, cor, nome e controle de pontos.
class _Linha extends StatelessWidget {
  final Player jogador;
  final int posicao;
  final int pontos;
  final VoidCallback onMais;
  final VoidCallback onMenos;

  const _Linha({
    required this.jogador,
    required this.posicao,
    required this.pontos,
    required this.onMais,
    required this.onMenos,
  });

  @override
  Widget build(BuildContext context) {
    final p = jogador;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.superficie.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$posicaoº', style: AppText.numero(14, cor: AppColors.lilas.withValues(alpha: 0.8))),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.cor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              p.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.texto(15, cor: AppColors.branco, peso: FontWeight.w700),
            ),
          ),
          _BotaoPonto(mais: false, onTap: pontos > 0 ? onMenos : null, chave: 'menos_${p.id}'),
          SizedBox(
            width: 36,
            child: Center(
              child: Text('$pontos', key: ValueKey('pontos_${p.id}'), style: AppText.numero(17)),
            ),
          ),
          _BotaoPonto(mais: true, onTap: onMais, chave: 'mais_${p.id}'),
        ],
      ),
    );
  }
}

class _BotaoPonto extends StatelessWidget {
  final bool mais;
  final VoidCallback? onTap;
  final String chave;
  const _BotaoPonto({required this.mais, required this.onTap, required this.chave});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey(chave),
      button: true,
      label: mais ? 'Dar ponto' : 'Tirar ponto',
      child: Pressable(
        onTap: onTap,
        escala: 0.85,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: onTap == null ? 0.3 : 1,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: mais ? AppColors.neon : AppColors.superficieClara),
            child: LanceIcon(
              mais ? LanceIconType.mais : LanceIconType.menos,
              tamanho: 16,
              preenchimento: mais ? AppColors.roxoEscuro : AppColors.branco,
              contorno: mais ? AppColors.roxoEscuro : AppColors.branco,
            ),
          ),
        ),
      ),
    );
  }
}
