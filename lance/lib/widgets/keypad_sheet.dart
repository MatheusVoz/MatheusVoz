import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'glow_button.dart';
import 'lance_icon.dart';
import 'pressable.dart';

/// Teclado numerico proprio para digitar o valor do lance.
/// Retorna o valor digitado (ja limitado entre 1 e [maximo]) ou null.
Future<int?> mostrarTecladoLance(
  BuildContext context, {
  required int valorInicial,
  required int maximo,
  required String jogador,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _Teclado(valorInicial: valorInicial, maximo: maximo, jogador: jogador),
  );
}

class _Teclado extends StatefulWidget {
  final int valorInicial, maximo;
  final String jogador;
  const _Teclado({required this.valorInicial, required this.maximo, required this.jogador});

  @override
  State<_Teclado> createState() => _TecladoState();
}

class _TecladoState extends State<_Teclado> {
  String _digitado = '';

  int get _valor => int.tryParse(_digitado) ?? 0;
  bool get _valido => _valor >= 1 && _valor <= widget.maximo;

  void _tecla(String t) {
    setState(() {
      if (t == '<') {
        if (_digitado.isNotEmpty) _digitado = _digitado.substring(0, _digitado.length - 1);
      } else if (_digitado.length < 4) {
        _digitado = (_digitado + t).replaceFirst(RegExp(r'^0+'), '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final excedeu = _valor > widget.maximo;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.roxo, width: 2),
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lance de ${widget.jogador}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.texto(16, cor: AppColors.lilas),
            ),
            const SizedBox(height: 4),
            Text(
              'R\$${_digitado.isEmpty ? widget.valorInicial : _digitado}',
              style: AppText.numero(
                46,
                cor: excedeu
                    ? AppColors.alerta
                    : (_digitado.isEmpty ? AppColors.lilas.withValues(alpha: 0.4) : AppColors.branco),
              ).copyWith(shadows: AppText.brilho),
            ),
            Text(
              excedeu ? 'Acima do máximo (R\$${widget.maximo})' : 'Máximo: R\$${widget.maximo}',
              style: AppText.texto(14, cor: excedeu ? AppColors.alerta : AppColors.lilas),
            ),
            const SizedBox(height: 14),
            for (final linha in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '<'],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: linha[i].isEmpty
                            ? const SizedBox(height: 56)
                            : Pressable(
                                onTap: () => _tecla(linha[i]),
                                child: Container(
                                  height: 56,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.superficieClara,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.roxo.withValues(alpha: 0.6), width: 1.5),
                                  ),
                                  child: linha[i] == '<'
                                      ? Transform.scale(
                                          scaleX: -1,
                                          child: const LanceIcon(LanceIconType.play, tamanho: 26),
                                        )
                                      : Text(linha[i], style: AppText.numero(26)),
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 4),
            GlowButton(
              texto: 'Confirmar valor',
              icone: LanceIconType.check,
              onTap: _valido ? () => Navigator.of(context).pop(_valor) : null,
            ),
          ],
        ),
      ),
    );
  }
}
