import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Painel escuro com borda roxa usado para agrupar conteudo.
class LanceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? corBorda;
  final bool brilho;

  const LanceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.corBorda,
    this.brilho = false,
  });

  @override
  Widget build(BuildContext context) {
    final borda = corBorda ?? AppColors.roxo.withValues(alpha: 0.45);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D1330), Color(0xFF120C1C)],
        ),
        border: Border.all(color: borda, width: 1.5),
        boxShadow: brilho ? [BoxShadow(color: borda.withValues(alpha: 0.5), blurRadius: 20)] : null,
      ),
      child: child,
    );
  }
}

/// Titulo de secao (lilas, caixa alta).
class SectionTitle extends StatelessWidget {
  final String texto;
  final Widget? trailing;
  const SectionTitle(this.texto, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.neon,
              borderRadius: BorderRadius.circular(3),
              boxShadow: const [BoxShadow(color: AppColors.neon, blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto.toUpperCase(),
              style: AppText.texto(
                15,
                cor: AppColors.lilas,
                peso: FontWeight.w700,
              ).copyWith(letterSpacing: 1.6),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
