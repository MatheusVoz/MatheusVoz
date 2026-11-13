import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'pressable.dart';

/// Linha de botoes seletores grandes (ex.: 2 / 4 / 6 jogadores).
class OptionSelector<T> extends StatelessWidget {
  final List<T> opcoes;
  final T selecionado;
  final String Function(T) rotulo;
  final ValueChanged<T> onChanged;
  final bool Function(T)? habilitado;
  final double altura;

  /// Prefixo das chaves dos botoes (facilita testes automatizados).
  final String prefixoChave;

  const OptionSelector({
    super.key,
    required this.opcoes,
    required this.selecionado,
    required this.rotulo,
    required this.onChanged,
    this.habilitado,
    this.altura = 58,
    this.prefixoChave = 'op',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < opcoes.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _botao(opcoes[i])),
        ],
      ],
    );
  }

  Widget _botao(T op) {
    final sel = op == selecionado;
    final ativo = habilitado?.call(op) ?? true;
    return Semantics(
      key: ValueKey('$prefixoChave-$op'),
      button: true,
      selected: sel,
      label: rotulo(op),
      child: Pressable(
        onTap: ativo ? () => onChanged(op) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: altura,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: sel ? AppColors.gradienteBotao : null,
            color: sel ? null : (ativo ? AppColors.superficieClara : AppColors.superficie),
            border: Border.all(
              color: sel
                  ? const Color(0xFFE2C6FF)
                  : ativo
                  ? AppColors.roxo.withValues(alpha: 0.6)
                  : AppColors.desativado.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: sel
                ? [BoxShadow(color: AppColors.neon.withValues(alpha: 0.55), blurRadius: 18)]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                rotulo(op),
                style: AppText.numero(
                  altura * 0.36,
                  cor: sel
                      ? AppColors.branco
                      : ativo
                      ? AppColors.lilas
                      : AppColors.desativado,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
