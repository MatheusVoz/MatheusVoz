import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'lance_icon.dart';

/// Logo do LANCE!: selo roxo (o mesmo do icone do celular) com o martelo
/// amarelo batendo, e o nome com a exclamacao em amarelo.
class LanceLogo extends StatefulWidget {
  final double tamanho;
  const LanceLogo({super.key, this.tamanho = 1});

  @override
  State<LanceLogo> createState() => _LanceLogoState();
}

class _LanceLogoState extends State<LanceLogo> with TickerProviderStateMixin {
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat();

  @override
  void dispose() {
    _entrada.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.tamanho;
    return AnimatedBuilder(
      animation: Listenable.merge([_entrada, _loop]),
      builder: (context, _) {
        final e = Curves.elasticOut.transform(_entrada.value.clamp(0.0, 1.0));
        // Martelo levanta (0-18%), desce rapido (18-25%) e quica (25-40%).
        final l = _loop.value;
        double angulo;
        if (l < 0.18) {
          angulo = -0.5 * Curves.easeOut.transform(l / 0.18);
        } else if (l < 0.25) {
          angulo = -0.5 + 0.62 * Curves.easeIn.transform((l - 0.18) / 0.07);
        } else if (l < 0.40) {
          angulo = 0.12 * (1 - Curves.easeOut.transform((l - 0.25) / 0.15));
        } else {
          angulo = 0;
        }
        final impacto = (l > 0.24 && l < 0.5) ? 1 - (l - 0.24) / 0.26 : 0.0;
        final selo = 132 * s;

        return Opacity(
          opacity: _entrada.value.clamp(0.0, 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.5 + 0.5 * e,
                child: Container(
                  width: selo,
                  height: selo,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradienteRoxo,
                    borderRadius: BorderRadius.circular(selo * 0.24),
                    boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: Stack(
                    children: [
                      // Linhas de impacto quando o martelo bate.
                      if (impacto > 0) Positioned.fill(child: CustomPaint(painter: _Impacto(impacto))),
                      Center(
                        child: Transform.rotate(
                          angle: angulo,
                          alignment: const Alignment(0.65, 0.75),
                          child: LanceIcon(LanceIconType.martelo, tamanho: selo * 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16 * s),
              _Marca(tamanho: 58 * s, entrada: e),
            ],
          ),
        );
      },
    );
  }
}

/// Nome "LANCE" em roxo escuro com a exclamacao amarela inclinada.
class _Marca extends StatelessWidget {
  final double tamanho;
  final double entrada;
  const _Marca({required this.tamanho, required this.entrada});

  @override
  Widget build(BuildContext context) {
    final contorno = AppText.titulo(tamanho).copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tamanho * 0.1
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.roxoEscuro,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('LANCE', style: AppText.titulo(tamanho, cor: AppColors.roxoEscuro)),
        Transform.rotate(
          angle: 0.18 * entrada,
          child: Stack(
            children: [
              Text('!', style: contorno),
              Text('!', style: AppText.titulo(tamanho, cor: AppColors.neon)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Impacto extends CustomPainter {
  final double t;
  _Impacto(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFFFE680).withValues(alpha: t)
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;
    final c = Offset(size.width * 0.78, size.height * 0.68);
    for (final ang in const [-30.0, -60.0, 0.0]) {
      final a = ang * math.pi / 180;
      final d = Offset(math.cos(a), math.sin(a));
      final r1 = size.width * (0.12 + 0.04 * (1 - t));
      final r2 = r1 + size.width * 0.08;
      canvas.drawLine(c + d * r1, c + d * r2, p);
    }
  }

  @override
  bool shouldRepaint(_Impacto old) => old.t != t;
}
