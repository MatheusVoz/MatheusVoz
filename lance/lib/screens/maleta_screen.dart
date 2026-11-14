import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

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
/// uma das 5 maletas, ve quem saiu e escala na posicao que quiser do seu
/// campinho (tema Futebol) ou na sua lista (outros temas). Quando todos os
/// times estao completos, o grupo decide quem montou o melhor time.
class MaletaScreen extends StatefulWidget {
  final ThemeCategory tema;
  const MaletaScreen({super.key, required this.tema});

  static const maletasPorRodada = 5;
  static const tamanhoTime = 5;

  @override
  State<MaletaScreen> createState() => _MaletaScreenState();
}

class _MaletaScreenState extends State<MaletaScreen> {
  _Fase _fase = _Fase.config;
  int _jogadores = 2;

  /// Time de cada jogador: vaga (0..4) -> item. No futebol, a vaga e a Posicao.
  late List<Map<int, String>> _times;

  /// Maletas da rodada (null = ja aberta).
  List<String?> _maletas = [];
  final Set<String> _usados = {};
  int _vez = 0;
  int? _vencedor;
  bool _abrindo = false;

  bool get _futebol => widget.tema.id == Posicao.temaFutebol;
  String _nome(int i) => 'Jogador ${i + 1}';
  Color _cor(int i) => AppColors.coresJogadores[i % AppColors.coresJogadores.length];

  void _comecar() {
    setState(() {
      _times = List.generate(_jogadores, (_) => <int, String>{});
      _usados.clear();
      _vez = 0;
      _vencedor = null;
      _novaRodadaDeMaletas();
      _fase = _Fase.jogo;
    });
  }

  /// Sorteia 5 maletas novas com itens que ainda nao sairam.
  void _novaRodadaDeMaletas() {
    final restantes = widget.tema.itens.toSet().difference(_usados).toList()..shuffle();
    final pool = restantes.length >= MaletaScreen.maletasPorRodada
        ? restantes
        : (widget.tema.itens.toSet().toList()..shuffle());
    _maletas = pool.take(MaletaScreen.maletasPorRodada).cast<String?>().toList();
  }

  List<Posicao> _livres(int jogador) => [
    for (final p in Posicao.values)
      if (!_times[jogador].containsKey(p.index)) p,
  ];

  bool _completo(int jogador) => _times[jogador].length >= MaletaScreen.tamanhoTime;

  Future<void> _abrir(int i) async {
    final item = _maletas[i];
    if (item == null || _abrindo) return;
    setState(() => _abrindo = true);
    FeedbackService.instancia.tocar(Som.moeda);
    FeedbackService.instancia.vibrarLeve();

    int? vaga;
    if (_futebol) {
      final pos = await escolherPosicao(
        context,
        dono: _nome(_vez),
        cor: _cor(_vez),
        item: item,
        escalacao: {for (final e in _times[_vez].entries) Posicao.values[e.key]: e.value},
        livres: _livres(_vez),
        permitirReserva: false,
      );
      vaga = pos?.index;
    } else {
      final ok = await _revelar(item);
      if (ok == true) {
        vaga = List.generate(
          MaletaScreen.tamanhoTime,
          (k) => k,
        ).firstWhere((k) => !_times[_vez].containsKey(k));
      }
    }
    if (!mounted) return;
    setState(() {
      _abrindo = false;
      if (vaga == null) return;
      _times[_vez][vaga] = item;
      _usados.add(item);
      _maletas[i] = null;
      if (_maletas.every((m) => m == null)) _novaRodadaDeMaletas();
      _proximaVez();
    });
  }

  void _proximaVez() {
    if (List.generate(_jogadores, (k) => k).every(_completo)) {
      _fase = _Fase.fim;
      return;
    }
    do {
      _vez = (_vez + 1) % _jogadores;
    } while (_completo(_vez));
  }

  /// Revela o item (temas sem campinho) e confirma a entrada no time.
  Future<bool?> _revelar(String item) {
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
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
                width: math.min(200, MediaQuery.sizeOf(ctx).height * 0.3),
                height: math.min(200, MediaQuery.sizeOf(ctx).height * 0.3),
                child: FotoItem(temaId: widget.tema.id, item: item, icone: widget.tema.icone),
              ),
              const SizedBox(height: 10),
              Text(item, textAlign: TextAlign.center, style: AppText.titulo(24)),
              const SizedBox(height: 14),
              GlowButton(
                texto: 'Colocar no time de ${_nome(_vez)}',
                icone: LanceIconType.check,
                onTap: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
        ),
      ),
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
            if (_vencedor != null) const Positioned.fill(child: ConfettiRain()),
          ],
        ),
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
          '${_futebol ? 'escale o jogador numa posição do seu campo' : 'coloque o item no seu time'}.',
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

  /// Times de todos os jogadores (campinhos ou listas).
  Widget _times_({bool destacarVez = true, bool compacto = false}) {
    final porLinha = _jogadores <= 2 ? 2 : 2;
    return LayoutBuilder(
      builder: (context, c) {
        final largura = (c.maxWidth - 12 * (porLinha - 1)) / porLinha;
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (var j = 0; j < _jogadores; j++)
              SizedBox(
                width: compacto && _jogadores > 2 ? largura * 0.8 : largura,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: !destacarVez || j == _vez ? 1 : 0.55,
                  child: _futebol ? _campoDe(j) : _listaDe(j),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _campoDe(int j) => CampoFutebol(
    titulo: _nome(j),
    cor: _cor(j),
    escalacao: {for (final e in _times[j].entries) Posicao.values[e.key]: e.value},
    mostrarNomes: _jogadores <= 2,
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

  Widget _jogo() {
    final restantes = [
      for (var i = 0; i < _maletas.length; i++)
        if (_maletas[i] != null) i,
    ];
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _times_(compacto: true),
          ),
        ),
        // De quem e a vez.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(_vez),
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: _cor(_vez), borderRadius: BorderRadius.circular(14)),
            child: Text(
              'Vez de ${_nome(_vez)}: escolha uma maleta',
              textAlign: TextAlign.center,
              style: AppText.texto(15, cor: AppColors.brancoPuro, peso: FontWeight.w700),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: LayoutBuilder(
            builder: (context, c) {
              final lado = math.min((c.maxWidth - 3 * 10) / 3, 112.0);
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final i in restantes)
                    SizedBox(
                      width: lado,
                      height: lado * 0.86,
                      child: _Maleta(numero: i + 1, onTap: () => _abrir(i)),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _fim() {
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
                  const LanceIcon(LanceIconType.coroa, tamanho: 50),
                  Text(_nome(_vencedor!), style: AppText.titulo(30, cor: _cor(_vencedor!))),
                ],
                const SizedBox(height: 12),
                _times_(destacarVez: false),
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
  }
}

/// Maleta fechada com o numero.
class _Maleta extends StatelessWidget {
  final int numero;
  final VoidCallback onTap;
  const _Maleta({required this.numero, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir maleta $numero',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
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
                      border: Border.all(color: AppColors.roxo, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.roxo.withValues(alpha: 0.25),
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
    );
  }
}
