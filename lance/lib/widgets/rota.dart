import 'package:material_ui/material_ui.dart';

/// Rota com transicao animada (fade + leve deslize + escala) usada em todo o app.
Route<T> rotaAnimada<T>(Widget tela) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => tela,
    transitionsBuilder: (_, anim, _, child) {
      final curva = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curva,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curva),
          child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(curva), child: child),
        ),
      );
    },
  );
}
