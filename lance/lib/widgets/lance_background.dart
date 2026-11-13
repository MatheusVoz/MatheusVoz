import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Fundo padrao: preto profundo com gradiente e brilhos roxos que flutuam devagar.
class LanceBackground extends StatefulWidget {
  final Widget child;
  final bool animado;
  const LanceBackground({super.key, required this.child, this.animado = true});

  @override
  State<LanceBackground> createState() => _LanceBackgroundState();
}

class _LanceBackgroundState extends State<LanceBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animado) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.fundo, gradient: AppColors.gradienteFundo),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, _) => CustomPaint(painter: _BrilhosPainter(_ctrl.value)),
              ),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class _BrilhosPainter extends CustomPainter {
  final double t;
  _BrilhosPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final a = t * 2 * math.pi;
    void brilho(Offset c, double r, Color cor) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [cor, cor.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    brilho(
      Offset(size.width * (0.15 + 0.08 * math.sin(a)), size.height * 0.12),
      size.width * 0.7,
      const Color(0x332A0F4D),
    );
    brilho(
      Offset(size.width * (0.9 + 0.06 * math.cos(a)), size.height * (0.55 + 0.05 * math.sin(a))),
      size.width * 0.6,
      const Color(0x2A5B1BA8),
    );
    brilho(
      Offset(size.width * 0.3, size.height * (0.98 + 0.03 * math.cos(a))),
      size.width * 0.6,
      const Color(0x221A0B2E),
    );
  }

  @override
  bool shouldRepaint(_BrilhosPainter old) => old.t != t;
}
