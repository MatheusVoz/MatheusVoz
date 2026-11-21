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
import '../widgets/foto_item.dart';
import '../widgets/glow_button.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/nota_badge.dart';
import '../widgets/option_selector.dart';
import '../widgets/pressable.dart';

enum _Fase { config, jogo, fim }

/// Jogo da maleta, em rodadas. Em cada rodada aparecem 5 maletas; cada
/// jogador, na sua vez, escolhe uma. As que ninguem escolheu sao descartadas
/// e a proxima rodada comeca.
/// No Futebol as rodadas seguem as posicoes: primeiro 5 goleiros, depois
/// volantes, meias e atacantes. Vence o time com a maior soma de notas.
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

  /// Rodada atual (0..4).
  int _rodada = 0;

  /// Maletas da rodada (null = ja escolhida por alguem).
  List<String?> _maletas = [];

  /// Quem ja escolheu nesta rodada.
  final Set<int> _jaEscolheram = {};
  final Set<String> _usados = {};
  int _vez = 0;

  /// Fim da rodada: as maletas que sobraram aparecem abertas (descartadas).
  bool _mostrandoDescartes = false;

  /// Vencedor (no Futebol sai pela soma das notas; nos outros, a galera escolhe).
  int? _vencedor;

  /// Maleta que esta tremendo (abrindo).
  int? _abrindo;

  /// Aviso animado "Sua vez" entre as jogadas.
  late final AnimationController _aviso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  bool get _futebol => widget.tema.id == Posicao.temaFutebol;
  String _nome(int i) => 'Jogador ${i + 1}';
  Color _cor(int i) => AppColors.coresJogadores[i % AppColors.coresJogadores.length];

  /// Posicao disputada na rodada (so no Futebol).
  Posicao? get _posicaoDaRodada => _futebol ? rodadasMaletaFutebol[_rodada] : null;

  String get _nomeDaRodada {
    final p = _posicaoDaRodada;
    if (p == null) return 'Rodada ${_rodada + 1} de ${MaletaScreen.tamanhoTime}';
    return switch (p) {
      Posicao.goleiro => 'Goleiros',
      Posicao.volante => 'Volantes e zagueiros',
      Posicao.meiaEsquerda || Posicao.meiaDireita => 'Meias',
      Posicao.atacante => 'Atacantes',
    };
  }

  /// Soma das notas do time (Futebol).
  int _forca(int j) => _times[j].values.fold(0, (s, i) => s + notaDe(i));

  @override
  void dispose() {
    _aviso.dispose();
    super.dispose();
  }

  void _comecar() {
    setState(() {
      _times = List.generate(_jogadores, (_) => <int, String>{});
      _usados.clear();
      _vencedor = null;
      _rodada = 0;
      _iniciarRodada();
      _fase = _Fase.jogo;
    });
    _mostrarAviso();
  }

  void _mostrarAviso() => _aviso.forward(from: 0);

  /// Sorteia as 5 maletas da rodada. Quem comeca escolhendo muda a cada rodada.
  void _iniciarRodada() {
    _maletas = List<String?>.of(maletasDaRodada(widget.tema, posicao: _posicaoDaRodada, usados: _usados));
    _jaEscolheram.clear();
    _mostrandoDescartes = false;
    _vez = _rodada % _jogadores;
  }

  Future<void> _abrir(int i) async {
    final item = _maletas[i];
    if (item == null || _abrindo != null || _mostrandoDescartes) return;
    // A maleta treme antes de abrir.
    setState(() => _abrindo = i);
    FeedbackService.instancia.vibrarLeve();
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    FeedbackService.instancia.tocar(Som.moeda);
    await _revelar(item);
    if (!mounted) return;
    setState(() {
      _abrindo = null;
      final vaga = _posicaoDaRodada?.index ?? _rodada;
      _times[_vez][vaga] = item;
      _usados.add(item);
      _maletas[i] = null;
      _jaEscolheram.add(_vez);
      if (_jaEscolheram.length == _jogadores) {
        // Todos escolheram: as outras maletas sao descartadas.
        _mostrandoDescartes = true;
      } else {
        _vez = (_vez + 1) % _jogadores;
      }
    });
    if (!_mostrandoDescartes) _mostrarAviso();
  }

  /// Depois de ver as descartadas: proxima rodada ou resultado.
  void _seguir() {
    setState(() {
      for (final m in _maletas) {
        if (m != null) _usados.add(m);
      }
      if (_rodada + 1 >= MaletaScreen.tamanhoTime) {
        _fase = _Fase.fim;
        if (_futebol) {
          final forcas = List.generate(_jogadores, _forca);
          _vencedor = forcas.indexOf(forcas.reduce(math.max));
          FeedbackService.instancia.tocar(Som.fanfarra);
          FeedbackService.instancia.vibrarForte();
        }
        return;
      }
      _rodada++;
      _iniciarRodada();
    });
    if (_fase == _Fase.jogo) _mostrarAviso();
  }

  /// Mostra o que saiu na maleta.
  Future<void> _revelar(String item) {
    final cor = _cor(_vez);
    final posicao = _posicaoDaRodada;
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final lado = math.min(220.0, MediaQuery.sizeOf(ctx).height * 0.3);
        return SafeArea(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            builder: (_, v, c) => Transform.scale(scale: v, child: c),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.superficie,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cor, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _nome(_vez),
                    style: AppText.texto(14, cor: cor, peso: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: lado,
                    height: lado,
                    child: FotoItem(temaId: widget.tema.id, item: item, icone: widget.tema.icone),
                  ),
                  const SizedBox(height: 10),
                  Text(item, textAlign: TextAlign.center, style: AppText.titulo(22)),
                  if (_futebol) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NotaBadge(nota: notaDe(item), tamanho: 16),
                        const SizedBox(width: 8),
                        Text(funcaoDe(item).nome, style: AppText.texto(15)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  GlowButton(
                    texto: posicao == null ? 'Colocar no time' : 'Escalar: ${posicao.nome}',
                    icone: LanceIconType.check,
                    altura: 48,
                    onTap: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
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
                    boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
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
        const LanceIcon(LanceIconType.maleta, tamanho: 80),
        const SizedBox(height: 10),
        Text(widget.tema.nome, style: AppText.titulo(20)),
        const SizedBox(height: 8),
        Text(
          _futebol
              ? 'São 5 rodadas: goleiros, volantes, meias e atacantes. '
                    'Cada um escolhe uma maleta; as que sobram vão embora. '
                    'No fim, ganha o time com a maior soma de notas.'
              : 'São 5 rodadas de 5 maletas. Cada um escolhe uma; '
                    'as que sobram vão embora. No fim, a galera escolhe o melhor time.',
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
              opacity: !destacarVez || j == _vez || _mostrandoDescartes ? 1 : 0.55,
              child: _futebol ? _campoDe(j, lado) : _listaDe(j),
            ),
          ),
      ],
    );
  }

  Widget _campoDe(int j, double lado) => CampoFutebol(
    titulo: '${_nome(j)}  ·  ${_forca(j)}',
    cor: _cor(j),
    escalacao: {for (final e in _times[j].entries) Posicao.values[e.key]: e.value},
    mostrarNomes: lado >= 150,
  );

  Widget _listaDe(int j) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(14),
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
                        ? FotoItem(temaId: widget.tema.id, item: _times[j][k]!, icone: widget.tema.icone, raio: 8)
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

  /// Tela do jogo: campos em cima, rodada no meio e maletas embaixo,
  /// tudo centralizado (celular em pe ou tablet).
  Widget _jogo() {
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
        final disponivel = c.maxHeight - alturaMaletas - 50 - 80;
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
                  const SizedBox(height: 16),
                  Text(
                    'RODADA ${_rodada + 1}/${MaletaScreen.tamanhoTime}  ·  ${_nomeDaRodada.toUpperCase()}',
                    key: const ValueKey('rodada'),
                    style: AppText.texto(13, cor: AppColors.lilas, peso: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey('$_vez$_mostrandoDescartes'),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _mostrandoDescartes ? AppColors.roxoEscuro : _cor(_vez),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _mostrandoDescartes ? 'Essas foram descartadas' : 'Vez de ${_nome(_vez)}',
                        textAlign: TextAlign.center,
                        style: AppText.texto(15, cor: AppColors.brancoPuro, peso: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < _maletas.length; i++)
                        if (_maletas[i] != null)
                          SizedBox(
                            width: ladoMaleta,
                            height: ladoMaleta * 0.86,
                            child: _mostrandoDescartes
                                ? _Descartada(item: _maletas[i]!, tema: widget.tema, futebol: _futebol)
                                : _Maleta(
                                    key: ValueKey('maleta_${_maletas[i]}'),
                                    numero: i + 1,
                                    tremendo: _abrindo == i,
                                    onTap: () => _abrir(i),
                                  ),
                          ),
                    ],
                  ),
                  if (_mostrandoDescartes) ...[
                    const SizedBox(height: 14),
                    GlowButton(
                      texto: _rodada + 1 >= MaletaScreen.tamanhoTime ? 'Ver resultado' : 'Próxima rodada',
                      icone: LanceIconType.play,
                      altura: 48,
                      onTap: _seguir,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fim() {
    // Ordem final: no Futebol, pela soma das notas.
    final ordem = List.generate(_jogadores, (j) => j);
    if (_futebol) ordem.sort((a, b) => _forca(b).compareTo(_forca(a)));
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
                            const LanceIcon(LanceIconType.coroa, tamanho: 46),
                            Text(_nome(_vencedor!), style: AppText.titulo(28, cor: _cor(_vencedor!))),
                          ],
                        ),
                      ),
                    ],
                    if (_futebol) ...[
                      const SizedBox(height: 10),
                      for (var k = 0; k < ordem.length; k++) _linhaPlacar(k + 1, ordem[k]),
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
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _cor(j), width: 2),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _nome(j),
                                        style: AppText.texto(14, cor: AppColors.branco, peso: FontWeight.w700),
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

  /// Linha do placar final: posicao, jogador e soma das notas.
  Widget _linhaPlacar(int pos, int j) => Container(
    key: ValueKey('placar_$j'),
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    constraints: const BoxConstraints(maxWidth: 420),
    decoration: BoxDecoration(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: pos == 1 ? AppColors.neon : AppColors.superficieClara, width: 2),
    ),
    child: Row(
      children: [
        Text('$posº', style: AppText.numero(16)),
        const SizedBox(width: 12),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _cor(j)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _nome(j),
            style: AppText.texto(15, cor: AppColors.branco, peso: FontWeight.w700),
          ),
        ),
        Text('${_forca(j)}', style: AppText.numero(18)),
        const SizedBox(width: 4),
        Text('pts', style: AppText.texto(12)),
      ],
    ),
  );
}

/// Maleta que ninguem escolheu: aparece aberta e apagada no fim da rodada.
class _Descartada extends StatelessWidget {
  final String item;
  final ThemeCategory tema;
  final bool futebol;
  const _Descartada({required this.item, required this.tema, required this.futebol});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: FotoItem(temaId: tema.id, item: item, icone: tema.icone, raio: 12),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            futebol ? '$item ${notaDe(item)}' : item,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.texto(11, cor: AppColors.branco, peso: FontWeight.w600),
          ),
        ],
      ),
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
                        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
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
