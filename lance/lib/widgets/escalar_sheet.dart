import 'package:material_ui/material_ui.dart';

import '../models/player.dart';
import '../models/posicao.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'campo_futebol.dart';
import 'foto_item.dart';
import 'glow_button.dart';
import 'lance_icon.dart';

/// Escalacao atual de um jogador (posicao -> nome do jogador de futebol).
Map<Posicao, String> escalacaoDe(List<Purchase> compras) => {
  for (final c in compras)
    if (c.posicao != null) Posicao.values[c.posicao!]: c.item,
};

/// Pergunta em que posicao do campo o item vai entrar.
/// Retorna a posicao escolhida ou null (reserva).
Future<Posicao?> escolherPosicao(
  BuildContext context, {
  required String dono,
  required Color cor,
  required String item,
  required Map<Posicao, String> escalacao,
  required List<Posicao> livres,
  bool permitirReserva = true,
}) async {
  if (livres.isEmpty) return null;
  return showModalBottomSheet<Posicao?>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: cor, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: FotoItem(
                    temaId: Posicao.temaFutebol,
                    item: item,
                    icone: LanceIconType.jogador,
                    raio: 27,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.titulo(18)),
                      Text('Onde $dono vai escalar?', style: AppText.texto(14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.5),
              child: AspectRatio(
                aspectRatio: 1,
                child: CampoFutebol(
                  escalacao: escalacao,
                  selecionaveis: livres.toSet(),
                  cor: cor,
                  onEscolher: (p) => Navigator.of(ctx).pop(p),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('Toque numa bolinha amarela', style: AppText.texto(13)),
            if (permitirReserva) ...[
              const SizedBox(height: 8),
              GlowButton(
                texto: 'Deixar no banco (reserva)',
                estilo: EstiloBotao.secundario,
                altura: 44,
                tamanhoTexto: 15,
                onTap: () => Navigator.of(ctx).pop(null),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
