import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/futebol_posicoes.dart';
import '../models/game_mode.dart';
import '../models/posicao.dart';
import '../models/theme_category.dart';
import '../services/feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/campo_futebol.dart';
import '../widgets/confetti.dart';
import '../widgets/escalar_sheet.dart';
import '../widgets/foto_item.dart';
import '../widgets/glow_button.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/option_selector.dart';
import '../widgets/pressable.dart';

enum _Fase { config, jogo, fim }

/// Jogo da maleta: cada jogador monta um time de 5. Na sua vez, a pessoa abre
/// uma das maletas, ve quem saiu e escala numa posicao do seu campinho
/// (Futebol) ou no seu time (outros temas). Pode tambem passar a vez.
/// No Futebol sempre aparecem goleiros suficientes (2 por jogador, no minimo).
class MaletaScreen extends StatefulWidget {
  final ThemeCategory tema;
  const MaletaScreen({super.key, required this.tema});

  static const maletasPorRodada = 5;
  static const tamanhoTime = 5;

  @override
  State<MaletaScreen> createState() => _MaletaScreenState();
}

class _MaletaScreenState extends State<MaletaScreen> with TickerProviderStateMixin {
  _Fase _fase = _Fase.config;
  int _jogadores = 2;

  /// Time de cada jogador: vaga (0..4) -> item. No Futebol, a vaga e a Posicao.
  late List<Map<int, String>> _times;

  /// Itens que ainda vao sair (ordem sorteada).
  List<String> _baralho = [];

  /// Maletas da rodada (null = ja aberta).
  List<String?> _maletas = [];
  final Set<String> _usados = {};
  int _vez = 0;
  int? _vencedor;

  /// Maleta que esta tremendo (abrindo).
  int? _abrindo;

  /// Aviso animado "Vez de ..." entre as jogadas.
  late final AnimationController _aviso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  bool get _futebol => widget.tema.id == Posicao.temaFutebol;
  String _nome(int i) => 'Jogador ${i + 1}';
  Color _cor(int i) => AppColors.coresJogadores[i % AppColors.coresJogadores.length];

  @override
  void dispose() {
    _aviso.dispose();
    super.dispose();
  }

  void _comecar() {
    setState(() {
      _times = List.generate(_jogadores, (_) => <int, String>{});
      _usados.clear();
      _vez = 0;
      _vencedor = null;
      // Itens de sobra para quem passar a vez; no Futebol, 2 goleiros por jogador.
      _baralho = montarBaralho(
        widget.tema,
        _jogadores * MaletaScreen.tamanhoTime * 2,
        goleirosMin: _jogadores * 2,
      );
      _novaRodadaDeMaletas();
      _fase = _Fase.jogo;
    });
    _mostrarAviso();
  }

  void _mostrarAviso() => _aviso.forward(from: 0);

  /// Alguem ainda precisa de goleiro?
  bool get _faltaGoleiro => _futebol && _times.any((t) => !t.containsKey(Posicao.goleiro.index));

  /// Prepara 5 maletas novas. Se alguem ainda nao tem goleiro, garante um entre elas.
  void _novaRodadaDeMaletas() {
    if (_baralho.length < MaletaScreen.maletasPorRodada) {
      _baralho.addAll(
        montarBaralho(
          widget.tema,
          30,
          goleirosMin: _faltaGoleiro ? 3 : 0,
          excluir: {..._usados, ..._baralho},
        ),
      );
    }
    final rodada = _baralho.take(MaletaScreen.maletasPorRodada).toList();
    _baralho.removeRange(0, rodada.length);
    if (_faltaGoleiro && !rodada.any((i) => funcaoDe(i) == Funcao.goleiro)) {
      final k = _baralho.indexWhere((i) => funcaoDe(i) == Funcao.goleiro);
      if (k >= 0) {
        final troca = math.Random().nextInt(rodada.length);
        final goleiro = _baralho.removeAt(k);
        _baralho.add(rodada[troca]);
        rodada[troca] = goleiro;
      }
    }
    _maletas = List<String?>.of(rodada);
  }

  List<Posicao> _livres(int jogador) => [
    for (final p in Posicao.values)
      if (!_times[jogador].containsKey(p.index)) p,
  ];

  bool _completo(int jogador) => _times[jogador].length >= MaletaScreen.tamanhoTime;

  Future<void> _abrir(int i) async {
    final item = _maletas[i];
    if (item == null || _abrindo != null) return;
    // A maleta treme antes de abrir.
    setState(() => _abrindo = i);
    FeedbackService.instancia.vibrarLeve();
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    FeedbackService.instancia.tocar(Som.moeda);

    int? vaga;
    var passou = false;
    if (_futebol) {
      final escolha = await escolherPosicao(
        context,
        dono: _nome(_vez),
        cor: _cor(_vez),
        item: item,
        escalacao: {for (final e in _times[_vez].entries) Posicao.values[e.key]: e.value},
        livres: _livres(_vez),
        textoAlternativa: 'Não quero, passar a vez',
      );
      vaga = escolha.posicao?.index;
      passou = escolha.alternativa;
    } else {
      final ok = await _revelar(item);
      if (ok == true) {
        vaga = List.generate(
          MaletaScreen.tamanhoTime,
          (k) => k,
        ).firstWhere((k) => !_times[_vez].containsKey(k));
      } else {
        passou = true;
      }
    }
    if (!mounted) return;
    setState(() {
      _abrindo = null;
      if (vaga == null && !passou) return;
      if (vaga != null) _times[_vez][vaga] = item;
      _usados.add(item);
      _maletas[i] = null;
      if (_maletas.every((m) => m == null)) _novaRodadaDeMaletas();
      _proximaVez();
    });
    if (_fase == _Fase.jogo) _mostrarAviso();
  }

  void _proximaVez() {
    if (List.generate(_jogadores, (k) => k).every(_completo)) {
      _fase = _Fase.fim;
      return;
    }
    do {
      _vez = (_vez + 1) % _jogadores;
    } while (_completo(_vez));
    // Se ninguem mais precisa de goleiro, nada muda; se precisa e nao ha nas
    // maletas restantes, a proxima rodada garante um.
  }

  /// Revela o item (temas sem campinho). true = colocar no time; false = passar.
  Future<bool?> _revelar(String item) {
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final lado = math.min(200.0, MediaQuery.sizeOf(ctx).height * 0.28);
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _cor(_vez), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: lado,
                  height: lado,
                  child: FotoItem(temaId: widget.tema.id, item: item, icone: widget.tema.icone),
                ),
                const SizedBox(height: 10),
                Text(item, textAlign: TextAlign.center, style: AppText.titulo(22)),
                const SizedBox(height: 14),
                GlowButton(
                  texto: 'Colocar no time',
                  icone: LanceIconType.check,
                  altura: 48,
                  onTap: () => Navigator.of(ctx).pop(true),
                ),
                const SizedBox(height: 8),
                GlowButton(
                  texto: 'Não quero, passar a vez',
                  icone: LanceIconType.pular,
                  estilo: EstiloBotao.secundario,
                  altura: 44,
                  tamanhoTexto: 15,
                  onTap: () => Navigator.of(ctx).pop(false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LanceBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const LanceTopBar(titulo: 'Jogo da maleta'),
                  Expanded(
                    child: switch (_fase) {
                      _Fase.config => _config(),
                      _Fase.jogo => _jogo(),
                      _Fase.fim => _fim(),
                    },
                  ),
                ],
              ),
            ),
            if (_fase == _Fase.jogo) Positioned.fill(child: _avisoDeVez()),
            if (_vencedor != null) const Positioned.fill(child: ConfettiRain()),
          ],
        ),
      ),
    );
  }

  /// "VEZ DE JOGADOR 2": entra com zoom, fica um instante e some.
  Widget _avisoDeVez() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _aviso,
        builder: (context, _) {
          final t = _aviso.value;
          if (t == 0 || t == 1) return const SizedBox.shrink();
          final entrada = Curves.elasticOut.transform((t / 0.4).clamp(0.0, 1.0));
          final saida = t > 0.75 ? (1 - t) / 0.25 : 1.0;
          return Opacity(
            opacity: saida.clamp(0.0, 1.0),
            child: Container(
              color: AppColors.fundo.withValues(alpha: 0.75),
              alignment: Alignment.center,
              child: Transform.scale(
                scale: 0.4 + 0.6 * entrada,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  decoration: BoxDecoration(
                    color: _cor(_vez),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [BoxShadow(color: _cor(_vez).withValues(alpha: 0.5), blurRadius: 30)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SUA VEZ',
                        style: AppText.texto(16, cor: AppColors.brancoPuro, peso: FontWeight.w700),
                      ),
                      Text(_nome(_vez).toUpperCase(), style: AppText.titulo(30, cor: AppColors.brancoPuro)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _config() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
    child: Column(
      children: [
        const Spacer(),
        const LanceIcon(LanceIconType.maleta, tamanho: 86),
        const SizedBox(height: 10),
        Text('Tema: ${widget.tema.nome}', style: AppText.texto(16)),
        const SizedBox(height: 6),
        Text(
          'Cada um monta um time de ${MaletaScreen.tamanhoTime}. Na sua vez, abra uma maleta e '
          '${_futebol ? 'escale o jogador numa posição do seu campo' : 'coloque o item no seu time'}, '
          'ou passe a vez.',
          textAlign: TextAlign.center,
          style: AppText.texto(14),
        ),
        const SizedBox(height: 24),
        Text('Quantos jogadores?', style: AppText.texto(16, cor: AppColors.branco)),
        const SizedBox(height: 10),
        OptionSelector<int>(
          opcoes: const [2, 3, 4],
          selecionado: _jogadores,
          rotulo: (v) => '$v',
          prefixoChave: 'maleta_jogadores',
          onChanged: (v) => setState(() => _jogadores = v),
        ),
        const Spacer(),
        GlowButton(texto: 'Começar', icone: LanceIconType.play, onTap: _comecar),
      ],
    ),
  );

  /// Times de todos os jogadores, cada um com [lado] de largura.
  Widget _times_(double lado, {bool destacarVez = true}) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (var j = 0; j < _jogadores; j++)
          SizedBox(
            width: lado,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: !destacarVez || j == _vez ? 1 : 0.55,
              child: _futebol ? _campoDe(j, lado) : _listaDe(j),
            ),
          ),
      ],
    );
  }

  Widget _campoDe(int j, double lado) => CampoFutebol(
    titulo: _nome(j),
    cor: _cor(j),
    escalacao: {for (final e in _times[j].entries) Posicao.values[e.key]: e.value},
    mostrarNomes: lado >= 150,
  );

  Widget _listaDe(int j) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _cor(j), width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _nome(j),
          style: AppText.texto(13, cor: AppColors.branco, peso: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var k = 0; k < MaletaScreen.tamanhoTime; k++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _times[j].containsKey(k)
                        ? FotoItem(
                            temaId: widget.tema.id,
                            item: _times[j][k]!,
                            icone: widget.tema.icone,
                            raio: 8,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: AppColors.superficieClara,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );

  /// Tela do jogo: campos e maletas centralizados, ocupando bem a tela
  /// (celular em pe ou tablet).
  Widget _jogo() {
    final restantes = [
      for (var i = 0; i < _maletas.length; i++)
        if (_maletas[i] != null) i,
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final largura = c.maxWidth - 28;
        // Maletas: 5 numa linha em telas largas; 3 por linha no celular.
        final porLinha = largura >= 560 ? 5 : 3;
        final ladoMaleta = math.min(120.0, (largura - (porLinha - 1) * 10) / porLinha);
        final linhasMaletas = (MaletaScreen.maletasPorRodada / porLinha).ceil();
        final alturaMaletas = linhasMaletas * ladoMaleta * 0.86 + (linhasMaletas - 1) * 10;
        // Campos: o maior possivel no espaco que sobra.
        final linhasTimes = _jogadores <= 2 ? 1 : 2;
        final disponivel = c.maxHeight - alturaMaletas - 50 - 56;
        final ladoPorAltura = _futebol ? disponivel / linhasTimes - 26 : double.infinity;
        final ladoTime = math.min(math.min((largura - 12) / 2, ladoPorAltura), 460.0);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _times_(math.max(ladoTime, 120)),
                  const SizedBox(height: 18),
                  // De quem e a vez.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(_vez),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: _cor(_vez), borderRadius: BorderRadius.circular(14)),
                      child: Text(
                        'Vez de ${_nome(_vez)}: escolha uma maleta',
                        textAlign: TextAlign.center,
                        style: AppText.texto(15, cor: AppColors.brancoPuro, peso: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final i in restantes)
                        SizedBox(
                          width: ladoMaleta,
                          height: ladoMaleta * 0.86,
                          child: _Maleta(
                            key: ValueKey('maleta_${_maletas[i]}'),
                            numero: i + 1,
                            tremendo: _abrindo == i,
                            onTap: () => _abrir(i),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fim() {
    return LayoutBuilder(
      builder: (context, c) {
        final ladoTime = math.min((c.maxWidth - 40) / 2, 460.0);
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    Text(_vencedor == null ? 'TIMES COMPLETOS' : 'CAMPEÃO', style: AppText.titulo(24)),
                    if (_vencedor != null) ...[
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.elasticOut,
                        builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                        child: Column(
                          children: [
                            const LanceIcon(LanceIconType.coroa, tamanho: 50),
                            Text(_nome(_vencedor!), style: AppText.titulo(30, cor: _cor(_vencedor!))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _times_(ladoTime, destacarVez: false),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: _vencedor == null
                  ? Column(
                      children: [
                        Text('Quem montou o melhor time?', style: AppText.texto(15, cor: AppColors.branco)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (var j = 0; j < _jogadores; j++) ...[
                              if (j > 0) const SizedBox(width: 8),
                              Expanded(
                                child: Pressable(
                                  key: ValueKey('vencedor_$j'),
                                  onTap: () {
                                    FeedbackService.instancia.tocar(Som.fanfarra);
                                    FeedbackService.instancia.vibrarForte();
                                    setState(() => _vencedor = j);
                                  },
                                  child: Container(
                                    height: 46,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.superficie,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: _cor(j), width: 2),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _nome(j),
                                        style: AppText.texto(
                                          14,
                                          cor: AppColors.branco,
                                          peso: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: GlowButton(
                            texto: 'Jogar de novo',
                            icone: LanceIconType.play,
                            altura: 48,
                            tamanhoTexto: 16,
                            onTap: _comecar,
                          ),
                        ),
                        const SizedBox(width: 8),
                        BotaoIcone(
                          icone: LanceIconType.voltar,
                          rotulo: 'Menu',
                          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Maleta fechada com o numero. Treme quando esta sendo aberta.
class _Maleta extends StatelessWidget {
  final int numero;
  final bool tremendo;
  final VoidCallback onTap;
  const _Maleta({super.key, required this.numero, required this.onTap, this.tremendo = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir maleta $numero',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          // Entrada com pulinho e tremida ao abrir.
          tween: Tween(begin: 0, end: tremendo ? 1 : 0),
          duration: Duration(milliseconds: tremendo ? 500 : 200),
          builder: (context, t, child) => Transform.rotate(
            angle: tremendo ? math.sin(t * math.pi * 8) * 0.12 * (1 - t * 0.5) : 0,
            child: Transform.scale(scale: 1 + 0.12 * t, child: child),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Alca.
                  Positioned(
                    top: 0,
                    left: w * 0.32,
                    right: w * 0.32,
                    height: w * 0.18,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.roxoEscuro, width: w * 0.05),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.1)),
                      ),
                    ),
                  ),
                  // Corpo.
                  Positioned.fill(
                    top: w * 0.13,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFF4F1FA), Color(0xFFD9D3E6)],
                        ),
                        borderRadius: BorderRadius.circular(w * 0.12),
                        border: Border.all(color: tremendo ? AppColors.neon : AppColors.roxo, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: (tremendo ? AppColors.neon : AppColors.roxo).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text('$numero', style: AppText.numero(w * 0.36, cor: AppColors.roxoEscuro)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
