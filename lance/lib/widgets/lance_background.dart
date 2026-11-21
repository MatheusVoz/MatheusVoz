import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Fundo padrao: cor lisa e clara, sem efeitos.
class LanceBackground extends StatelessWidget {
  final Widget child;

  /// Mantido por compatibilidade (o fundo nao tem mais animacao).
  final bool animado;
  const LanceBackground({super.key, required this.child, this.animado = true});

  @override
  Widget build(BuildContext context) => ColoredBox(color: AppColors.fundo, child: child);
}
