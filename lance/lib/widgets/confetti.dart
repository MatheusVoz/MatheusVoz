import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Chuva de confete roxo desenhada com CustomPainter (sem pacotes).
class ConfettiRain extends StatefulWidget {
  final int quantidade;
  final Duration duracao;
  const ConfettiRain({super.key, this.quantidade = 140, this.duracao = const Duration(seconds: 6)});

  @override
  State<ConfettiRain> createState() => _ConfettiRainState();
}

class _Particula {
  final double x, atraso, velocidade, giro, largura, altura, balanco, fase;
  final Color cor;
  final bool redondo;
  _Particula(math.Random r)
    : x = r.nextDouble(),
      atraso = r.nextDouble() * 0.45,
      velocidade = 0.55 + r.nextDouble() * 0.6,
      giro = (r.nextDouble() - 0.5) * 16,
      largura = 6 + r.nextDouble() * 7,
      altura = 9 + r.nextDouble() * 9,
      balanco = 10 + r.nextDouble() * 26,
      fase = r.nextDouble() * math.pi * 2,
      redondo = r.nextDouble() < 0.25,
      cor = const [
        AppColors.roxo,
        AppColors.neon,
        AppColors.lilas,
        Color(0xFFD946EF),
        Color(0xFF6D5BFF),
        Colors.white,
      ][r.nextInt(6)];
}

class _ConfettiRainState extends State<ConfettiRain> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: widget.duracao)
    ..forward();
  late final List<_Particula> _ps = List.generate(widget.quantidade, (_) => _Particula(math.Random()));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_ps, _ctrl.value)),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particula> ps;
  final double t;
  _ConfettiPainter(this.ps, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in ps) {
      final local = ((t - p.atraso) / (1 - p.atraso)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final y = -30 + (size.height + 60) * local * p.velocidade * 1.4;
      if (y > size.height + 20) continue;
      final x = p.x * size.width + math.sin(local * 10 + p.fase) * p.balanco;
      final opacidade = local > 0.85 ? (1 - local) / 0.15 : 1.0;
      final paint = Paint()..color = p.cor.withValues(alpha: opacidade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * p.giro);
      if (p.redondo) {
        canvas.drawCircle(Offset.zero, p.largura / 2, paint);
      } else {
        // Efeito 3D: a largura "vira" com o tempo.
        final w = p.largura * math.cos(local * p.giro * 1.3).abs().clamp(0.2, 1.0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: p.altura),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
