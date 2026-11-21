import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Nota do jogador (0-99) num selo pequeno. Lendas (95+) em amarelo.
class NotaBadge extends StatelessWidget {
  final int nota;
  final double tamanho;
  const NotaBadge({super.key, required this.nota, this.tamanho = 13});

  @override
  Widget build(BuildContext context) {
    final lenda = nota >= 95;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: tamanho * 0.5, vertical: tamanho * 0.12),
      decoration: BoxDecoration(
        color: lenda ? AppColors.neon : AppColors.roxoEscuro,
        borderRadius: BorderRadius.circular(tamanho * 0.45),
      ),
      child: Text('$nota', style: AppText.numero(tamanho, cor: lenda ? AppColors.roxoEscuro : AppColors.brancoPuro)),
    );
  }
}
