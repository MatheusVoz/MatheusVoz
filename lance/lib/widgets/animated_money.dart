import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Valor em reais que anima (conta) quando muda, ficando lilas e pulsando ao diminuir.
class AnimatedMoney extends StatefulWidget {
  final int valor;
  final double tamanho;
  final Color cor;
  final String prefixo;

  const AnimatedMoney({
    super.key,
    required this.valor,
    this.tamanho = 22,
    this.cor = AppColors.branco,
    this.prefixo = 'R\$',
  });

  @override
  State<AnimatedMoney> createState() => _AnimatedMoneyState();
}

class _AnimatedMoneyState extends State<AnimatedMoney> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late int _de = widget.valor;
  late int _para = widget.valor;

  @override
  void didUpdateWidget(AnimatedMoney old) {
    super.didUpdateWidget(old);
    if (old.valor != widget.valor) {
      _de = _valorAtual;
      _para = widget.valor;
      _ctrl.forward(from: 0);
    }
  }

  int get _valorAtual {
    final t = Curves.easeOutCubic.transform(_ctrl.value);
    return (_de + (_para - _de) * t).round();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final animando = _ctrl.isAnimating;
        final diminuindo = _para < _de;
        final pulso = animando ? 1 + 0.18 * (1 - _ctrl.value) : 1.0;
        return Transform.scale(
          scale: pulso,
          child: Text(
            '${widget.prefixo}$_valorAtual',
            maxLines: 1,
            style: AppText.numero(
              widget.tamanho,
              cor: animando && diminuindo ? AppColors.neon : widget.cor,
            ).copyWith(shadows: animando ? AppText.brilho : null),
          ),
        );
      },
    );
  }
}
