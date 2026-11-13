import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'lance_icon.dart';

/// Card central com o item em leilao. Entra com deslize lateral + bounce
/// sempre que o item muda.
class ItemCard extends StatelessWidget {
  final String item;
  final int indice;
  final LanceIconType icone;
  final String tema;

  const ItemCard({
    super.key,
    required this.item,
    required this.indice,
    required this.icone,
    required this.tema,
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
      layoutBuilder: (atual, anteriores) =>
          Stack(alignment: Alignment.center, children: [...anteriores, ?atual]),
      child: _Conteudo(key: ValueKey(indice), item: item, icone: icone, tema: tema),
    );
  }
}

class _Conteudo extends StatelessWidget {
  final String item;
  final LanceIconType icone;
  final String tema;
  const _Conteudo({super.key, required this.item, required this.icone, required this.tema});

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
        final alturaIcone = (c.maxHeight * 0.32).clamp(36.0, 88.0);
        return Container(
          width: double.infinity,
          height: c.maxHeight,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1450), Color(0xFF150A28), Color(0xFF1E0E3A)],
            ),
            border: Border.all(color: AppColors.neon, width: 2.5),
            boxShadow: [
              BoxShadow(color: AppColors.neon.withValues(alpha: 0.55), blurRadius: 28, spreadRadius: 1),
              BoxShadow(color: AppColors.roxo.withValues(alpha: 0.35), blurRadius: 60, spreadRadius: 4),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LanceIcon(icone, tamanho: alturaIcone),
              SizedBox(height: c.maxHeight > 180 ? 10 : 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: c.maxWidth - 36),
                    child: Text(
                      item.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      style: AppText.titulo(_fonte(c.maxWidth)).copyWith(shadows: AppText.brilho),
                    ),
                  ),
                ),
              ),
              if (c.maxHeight > 150) ...[
                const SizedBox(height: 6),
                Text(
                  tema.toUpperCase(),
                  style: AppText.texto(
                    13,
                    cor: AppColors.lilas.withValues(alpha: 0.8),
                  ).copyWith(letterSpacing: 2.4),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
