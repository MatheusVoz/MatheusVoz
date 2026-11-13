import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'pressable.dart';

/// Interruptor liga/desliga proprio, roxo neon.
class LanceSwitch extends StatelessWidget {
  final bool valor;
  final ValueChanged<bool> onChanged;
  const LanceSwitch({super.key, required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: valor,
      child: Pressable(
        onTap: () => onChanged(!valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          width: 64,
          height: 36,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: valor ? AppColors.gradienteBotao : null,
            color: valor ? null : AppColors.desativado.withValues(alpha: 0.5),
            border: Border.all(color: valor ? const Color(0xFFE2C6FF) : AppColors.desativado, width: 2),
            boxShadow: valor
                ? [BoxShadow(color: AppColors.neon.withValues(alpha: 0.5), blurRadius: 14)]
                : null,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutBack,
            alignment: valor ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: valor ? AppColors.branco : AppColors.lilas.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
