import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'lance_icon.dart';

/// Logo animado: martelo que bate + texto LANCE! com brilho pulsante.
class LanceLogo extends StatefulWidget {
  final double tamanho;
  const LanceLogo({super.key, this.tamanho = 1});

  @override
  State<LanceLogo> createState() => _LanceLogoState();
}

class _LanceLogoState extends State<LanceLogo> with TickerProviderStateMixin {
  // Entrada (uma vez) e loop (martelo batendo + brilho).
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

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
        final e = _entrada.value;
        final escalaEntrada = Curves.elasticOut.transform(e.clamp(0.0, 1.0));
        // Martelo: levanta e bate no inicio de cada ciclo.
        final l = _loop.value;
        double angulo;
        if (l < 0.18) {
          angulo = -0.55 * Curves.easeOut.transform(l / 0.18);
        } else if (l < 0.26) {
          angulo = -0.55 + 0.75 * Curves.easeIn.transform((l - 0.18) / 0.08);
        } else if (l < 0.40) {
          angulo = 0.2 * (1 - Curves.easeOut.transform((l - 0.26) / 0.14));
        } else {
          angulo = 0;
        }
        final impacto = (l > 0.25 && l < 0.45) ? (1 - (l - 0.25) / 0.2) : 0.0;
        final brilho = 18 + 14 * math.sin(l * 2 * math.pi).abs() + 20 * impacto;

        return Transform.scale(
          scale: 0.4 + 0.6 * escalaEntrada,
          child: Opacity(
            opacity: e.clamp(0.0, 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 150 * s,
                  height: 130 * s,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Aura neon atras do martelo.
                      Container(
                        width: 110 * s,
                        height: 110 * s,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.roxo.withValues(alpha: 0.55),
                              blurRadius: brilho * s * 2,
                              spreadRadius: 4 * s,
                            ),
                          ],
                        ),
                      ),
                      // Ondas de impacto.
                      if (impacto > 0)
                        Container(
                          width: (90 + 60 * (1 - impacto)) * s,
                          height: (90 + 60 * (1 - impacto)) * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.neon.withValues(alpha: impacto * 0.8),
                              width: 3 * s,
                            ),
                          ),
                        ),
                      Transform.rotate(
                        angle: angulo,
                        alignment: const Alignment(0.6, 0.7),
                        child: LanceIcon(LanceIconType.martelo, tamanho: 120 * s),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6 * s),
                Text(
                  'LANCE!',
                  style: AppText.titulo(64 * s).copyWith(
                    shadows: [
                      Shadow(color: AppColors.neon, blurRadius: brilho),
                      Shadow(color: AppColors.roxo, blurRadius: brilho * 2),
                    ],
                  ),
                ),
                Text(
                  'O LEILÃO DA GALERA',
                  style: AppText.texto(
                    15 * s,
                    cor: AppColors.lilas,
                  ).copyWith(letterSpacing: 4 * s, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
