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
import '../widgets/rota.dart';
import 'auction_screen.dart';
import 'theme_select_screen.dart';

/// Podio animado com confete roxo e coroa no campeao.
class PodiumScreen extends StatefulWidget {
  const PodiumScreen({super.key});

  @override
  State<PodiumScreen> createState() => _PodiumScreenState();
}

class _PodiumScreenState extends State<PodiumScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();
  int _confetes = 0;

  /// Copia do resultado: a tela continua correta mesmo durante a transicao
  /// para uma nova partida (quando o controlador ja foi reiniciado).
  late final List<Player> _ranking;
  late final String _tema;

  @override
  void initState() {
    super.initState();
    final g = context.read<GameController>();
    _ranking = g.ranking.map(g.jogador).toList();
    _tema = g.config?.temaNome ?? '';
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      FeedbackService.instancia.tocar(Som.fanfarra);
      FeedbackService.instancia.vibrarForte();
      setState(() => _confetes++);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _menu() async {
    await context.read<GameController>().encerrarPartida();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _novo() async {
    final nav = Navigator.of(context);
    await context.read<GameController>().encerrarPartida();
    nav.pushAndRemoveUntil(rotaAnimada(const ThemeSelectScreen()), (r) => r.isFirst);
  }

  void _denovo() {
    context.read<GameController>().jogarNovamente();
    Navigator.of(context).pushAndRemoveUntil(rotaAnimada(const AuctionScreen()), (r) => r.isFirst);
  }

  /// Valor da animacao em um intervalo.
  double _fase(double inicio, double fim, [Curve curva = Curves.easeOutBack]) =>
      curva.transform(((_ctrl.value - inicio) / (fim - inicio)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final ranking = _ranking;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _menu();
      },
      child: Scaffold(
        body: LanceBackground(
          child: Stack(
            children: [
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final alturaPodio = (c.maxHeight * 0.46).clamp(290.0, 400.0);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      child: AnimatedBuilder(
                        animation: _ctrl,
                        builder: (_, _) => Column(
                          children: [
                            Opacity(
                              opacity: _fase(0, 0.2, Curves.easeOut),
                              child: Transform.scale(
                                scale: 0.6 + 0.4 * _fase(0, 0.3),
                                child: Column(
                                  children: [
                                    const LanceIcon(LanceIconType.trofeu, tamanho: 64),
                                    const SizedBox(height: 6),
                                    Text(
                                      'PÓDIO',
                                      style: AppText.titulo(40).copyWith(shadows: AppText.brilho),
                                    ),
                                    Text(
                                      _tema.toUpperCase(),
                                      style: AppText.texto(14).copyWith(letterSpacing: 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(height: alturaPodio, child: _podio(ranking, alturaPodio)),
                            const SizedBox(height: 16),
                            for (var i = 3; i < ranking.length; i++)
                              Opacity(
                                opacity: _fase(0.6 + (i - 3) * 0.06, 0.85 + (i - 3) * 0.05, Curves.easeOut),
                                child: _linhaDemais(i, ranking[i]),
                              ),
                            const SizedBox(height: 18),
                            Opacity(
                              opacity: _fase(0.75, 1, Curves.easeOut),
                              child: Column(
                                children: [
                                  GlowButton(
                                    texto: 'Jogar de novo',
                                    icone: LanceIconType.play,
                                    altura: 62,
                                    onTap: _denovo,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, bottom: 10),
                                    child: Text(
                                      'mesmas configurações, novos itens',
                                      style: AppText.texto(13, cor: AppColors.lilas.withValues(alpha: 0.7)),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GlowButton(
                                          texto: 'Novo leilão',
                                          icone: LanceIconType.martelo,
                                          estilo: EstiloBotao.secundario,
                                          altura: 56,
                                          tamanhoTexto: 17,
                                          onTap: _novo,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: GlowButton(
                                          texto: 'Menu',
                                          icone: LanceIconType.voltar,
                                          estilo: EstiloBotao.secundario,
                                          altura: 56,
                                          tamanhoTexto: 17,
                                          onTap: _menu,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_confetes > 0) Positioned.fill(child: ConfettiRain(key: ValueKey(_confetes))),
            ],
          ),
        ),
      ),
    );
  }

  /// Colunas do podio na ordem visual 2o - 1o - 3o.
  Widget _podio(List<Player> ranking, double altura) {
    final ordemVisual = <int>[if (ranking.length > 1) 1, 0, if (ranking.length > 2) 2];
    // Espaco reservado acima do bloco do campeao (coroa + nome).
    final base = altura - 150;
    final alturas = {0: base, 1: base * 0.72, 2: base * 0.52};
    final atrasos = {2: 0.1, 1: 0.25, 0: 0.4};
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final pos in ordemVisual)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _coluna(pos, ranking[pos], alturas[pos]!, atrasos[pos]!),
            ),
          ),
      ],
    );
  }

  Widget _coluna(int pos, Player p, double alturaBloco, double atraso) {
    final cresce = _fase(atraso, atraso + 0.3, Curves.easeOutCubic);
    final nome = _fase(atraso + 0.2, atraso + 0.45);
    final coroa = pos == 0 ? _fase(0.65, 0.9, Curves.elasticOut) : 0.0;
    final campeao = pos == 0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (campeao)
          Transform.translate(
            offset: Offset(0, -30 * (1 - coroa)),
            child: Opacity(
              opacity: coroa.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: coroa,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: AppColors.neon.withValues(alpha: 0.6), blurRadius: 30)],
                    shape: BoxShape.circle,
                  ),
                  child: const LanceIcon(LanceIconType.coroa, tamanho: 58),
                ),
              ),
            ),
          ),
        Opacity(
          opacity: nome.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.5 + 0.5 * nome,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 4),
              child: Column(
                children: [
                  LanceIcon(LanceIconType.jogador, tamanho: campeao ? 44 : 34, preenchimento: p.cor),
                  const SizedBox(height: 4),
                  Text(
                    p.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppText.texto(campeao ? 18 : 15, cor: AppColors.branco, peso: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          height: alturaBloco * cresce,
          width: double.infinity,
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [p.cor, Color.alphaBlend(Colors.black.withValues(alpha: 0.6), p.cor)],
            ),
            border: Border.all(color: campeao ? AppColors.branco : p.cor.withValues(alpha: 0.9), width: 2),
            boxShadow: [
              BoxShadow(
                color: p.cor.withValues(alpha: campeao ? 0.8 : 0.45),
                blurRadius: campeao ? 30 : 16,
              ),
            ],
          ),
          child: alturaBloco * cresce > 50
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '${pos + 1}º',
                    style: AppText.numero(campeao ? 38 : 30)
                        .copyWith(shadows: const [Shadow(color: Colors.black54, blurRadius: 8)]),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Widget _linhaDemais(int pos, Player p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.superficieClara,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.cor.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Row(
        children: [
          Text('${pos + 1}º', style: AppText.numero(20, cor: AppColors.lilas)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              p.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.texto(17, cor: AppColors.branco, peso: FontWeight.w700),
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.cor),
          ),
        ],
      ),
    );
  }
}
