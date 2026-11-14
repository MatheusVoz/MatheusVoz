import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'lance_icon.dart';
import 'pressable.dart';

/// Barra superior propria (sem icones prontos do Material).
class LanceTopBar extends StatelessWidget {
  final String titulo;
  final VoidCallback? onVoltar;
  final Widget? acao;
  final bool mostrarVoltar;

  const LanceTopBar({super.key, required this.titulo, this.onVoltar, this.acao, this.mostrarVoltar = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            if (mostrarVoltar)
              BotaoIcone(
                icone: LanceIconType.voltar,
                onTap: onVoltar ?? () => Navigator.of(context).maybePop(),
                rotulo: 'Voltar',
              )
            else
              const SizedBox(width: 48),
            Expanded(
              child: Text(
                titulo,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.titulo(18).copyWith(shadows: AppText.brilho),
              ),
            ),
            acao ?? const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

/// Botao redondo com icone proprio.
class BotaoIcone extends StatelessWidget {
  final LanceIconType icone;
  final VoidCallback? onTap;
  final String rotulo;
  final double tamanho;

  const BotaoIcone({
    super.key,
    required this.icone,
    required this.onTap,
    required this.rotulo,
    this.tamanho = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: rotulo,
      child: Pressable(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: onTap == null ? 0.35 : 1,
          child: Container(
            width: tamanho,
            height: tamanho,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.superficieClara,
              border: Border.all(color: AppColors.roxo.withValues(alpha: 0.8), width: 2),
              boxShadow: [BoxShadow(color: AppColors.roxo.withValues(alpha: 0.35), blurRadius: 12)],
            ),
            alignment: Alignment.center,
            child: LanceIcon(icone, tamanho: tamanho * 0.5),
          ),
        ),
      ),
    );
  }
}
