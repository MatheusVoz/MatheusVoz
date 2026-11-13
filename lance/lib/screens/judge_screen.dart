import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../state/game_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/glow_button.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/pressable.dart';
import '../widgets/rota.dart';
import 'podium_screen.dart';
import 'review_screen.dart';

/// Tela do juiz: ordena os jogadores do 1o ao ultimo lugar.
class JudgeScreen extends StatefulWidget {
  const JudgeScreen({super.key});

  @override
  State<JudgeScreen> createState() => _JudgeScreenState();
}

class _JudgeScreenState extends State<JudgeScreen> {
  late List<int> _ordem;

  @override
  void initState() {
    super.initState();
    final g = context.read<GameController>();
    _ordem = g.ranking.length == g.jogadores.length
        ? List.of(g.ranking)
        : g.jogadores.map((j) => j.id).toList();
  }

  void _mover(int de, int para) {
    setState(() {
      final id = _ordem.removeAt(de);
      _ordem.insert(para, id);
    });
  }

  /// Toque no jogador: escolhe a posicao diretamente.
  Future<void> _escolherPosicao(int indice) async {
    final g = context.read<GameController>();
    final p = g.jogador(_ordem[indice]);
    final pos = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: p.cor, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Posição de ${p.nome}', textAlign: TextAlign.center, style: AppText.titulo(20)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < _ordem.length; i++)
                    Pressable(
                      onTap: () => Navigator.of(ctx).pop(i),
                      child: Container(
                        width: 84,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: i == indice ? AppColors.gradienteBotao : null,
                          color: i == indice ? null : AppColors.superficieClara,
                          border: Border.all(color: AppColors.roxo, width: 2),
                        ),
                        child: Text('${i + 1}º', style: AppText.numero(24)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (pos != null && pos != indice) _mover(indice, pos);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    if (!g.temPartida) return const Scaffold(body: LanceBackground(child: SizedBox()));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          g.irParaRevisao();
          Navigator.of(context).pushReplacement(rotaAnimada(const ReviewScreen()));
        }
      },
      child: Scaffold(
        body: LanceBackground(
          child: SafeArea(
            child: Column(
              children: [
                LanceTopBar(
                  titulo: 'Decisão do Juiz',
                  onVoltar: () {
                    g.irParaRevisao();
                    Navigator.of(context).pushReplacement(rotaAnimada(const ReviewScreen()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: Text(
                    'Arraste para ordenar do 1º ao último lugar, ou toque em um jogador para escolher a posição.',
                    textAlign: TextAlign.center,
                    style: AppText.texto(15, cor: AppColors.lilas),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    buildDefaultDragHandles: false,
                    itemCount: _ordem.length,
                    proxyDecorator: (child, _, anim) => AnimatedBuilder(
                      animation: anim,
                      builder: (_, c) => Transform.scale(scale: 1 + 0.05 * anim.value, child: c),
                      child: child,
                    ),
                    onReorderItem: _mover,
                    itemBuilder: (_, i) {
                      final p = g.jogador(_ordem[i]);
                      return _LinhaRanking(
                        key: ValueKey('rank_${p.id}'),
                        posicao: i,
                        jogador: p,
                        onTap: () => _escolherPosicao(i),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: GlowButton(
                    texto: 'Confirmar Ranking',
                    icone: LanceIconType.check,
                    altura: 64,
                    onTap: () {
                      g.confirmarRanking(_ordem);
                      Navigator.of(context).pushReplacement(rotaAnimada(const PodiumScreen()));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinhaRanking extends StatelessWidget {
  final int posicao;
  final Player jogador;
  final VoidCallback onTap;
  const _LinhaRanking({super.key, required this.posicao, required this.jogador, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = jogador;
    final destaque = posicao == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ReorderableDelayedDragStartListener(
        index: posicao,
        child: Pressable(
          onTap: onTap,
          escala: 0.97,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
            decoration: BoxDecoration(
              color: AppColors.superficieClara,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: destaque ? AppColors.branco : p.cor, width: destaque ? 2.5 : 2),
              boxShadow: [BoxShadow(color: p.cor.withValues(alpha: destaque ? 0.6 : 0.25), blurRadius: 14)],
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Container(
                    key: ValueKey(posicao),
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: destaque ? AppColors.gradienteBotao : null,
                      color: destaque ? null : AppColors.superficie,
                      border: Border.all(color: p.cor, width: 2),
                    ),
                    child: destaque
                        ? const LanceIcon(
                            LanceIconType.coroa,
                            tamanho: 30,
                            preenchimento: Color(0xFF5A12B0),
                            contorno: Color(0xFFF4E8FF),
                          )
                        : Text('${posicao + 1}º', style: AppText.numero(17)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.texto(18, cor: AppColors.branco, peso: FontWeight.w700),
                      ),
                      Text(
                        p.compras.isEmpty ? 'Nenhum item' : p.compras.map((c) => c.item).join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.texto(13, cor: AppColors.lilas),
                      ),
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: posicao,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: LanceIcon(LanceIconType.arrastar, tamanho: 30),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
