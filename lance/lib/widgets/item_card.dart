import 'package:material_ui/material_ui.dart';

import '../data/futebol_posicoes.dart';
import '../models/posicao.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'foto_item.dart';
import 'lance_icon.dart';
import 'nota_badge.dart';

/// Card central com o item em leilao. Entra com deslize lateral + bounce
/// sempre que o item muda.
class ItemCard extends StatelessWidget {
  final String item;
  final int indice;
  final LanceIconType icone;
  final String tema;
  final String temaId;

  const ItemCard({
    super.key,
    required this.item,
    required this.indice,
    required this.icone,
    required this.tema,
    required this.temaId,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      reverseDuration: const Duration(milliseconds: 260),
      switchInCurve: Curves.linear,
      transitionBuilder: (child, anim) {
        final entrando = child.key == ValueKey(indice);
        if (!entrando) {
          // Saindo: desliza para a esquerda e some.
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(-0.6, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeIn)),
              child: child,
            ),
          );
        }
        final slide = Tween(begin: const Offset(1.1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: anim,
            curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
          ),
        );
        final bounce = Tween(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(
            parent: anim,
            curve: const Interval(0.25, 1, curve: Curves.elasticOut),
          ),
        );
        return SlideTransition(
          position: slide,
          child: ScaleTransition(scale: bounce, child: child),
        );
      },
      layoutBuilder: (atual, anteriores) => Stack(alignment: Alignment.center, children: [...anteriores, ?atual]),
      child: _Conteudo(key: ValueKey(indice), item: item, icone: icone, tema: tema, temaId: temaId),
    );
  }
}

class _Conteudo extends StatelessWidget {
  final String item;
  final LanceIconType icone;
  final String tema;
  final String temaId;
  const _Conteudo({super.key, required this.item, required this.icone, required this.tema, required this.temaId});

  /// Escolhe o tamanho da fonte pelo comprimento do nome.
  double _fonte(double largura) {
    final n = item.length;
    final base = largura < 330 ? 0.88 : 1.0;
    if (n <= 8) return 38 * base;
    if (n <= 13) return 32 * base;
    if (n <= 20) return 27 * base;
    return 23 * base;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Container(
          width: double.infinity,
          height: c.maxHeight,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: AppColors.superficie,
            border: Border.all(color: AppColors.superficieClara, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.roxoEscuro.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Foto do item (ou icone do tema, se nao houver foto livre).
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FotoItem(temaId: temaId, item: item, icone: icone),
                    ),
                    // No Futebol, a nota do jogador fica no canto da foto.
                    if (temaId == Posicao.temaFutebol && notaDe(item) > 0)
                      Positioned(top: 8, left: 8, child: NotaBadge(nota: notaDe(item), tamanho: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: (c.maxHeight * 0.16).clamp(28.0, 52.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: c.maxWidth - 24),
                    child: Text(
                      item.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: AppText.titulo(_fonte(c.maxWidth)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
