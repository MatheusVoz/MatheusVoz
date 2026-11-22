import 'package:material_ui/material_ui.dart';

import '../data/fotos_data.dart';
import '../theme/app_colors.dart';
import 'lance_icon.dart';

/// Caminho da foto embutida de um item (null se o item nao tem foto livre,
/// por exemplo filmes com cartaz protegido ou itens do tema personalizado).
String? fotoDoItem(String temaId, String item) => fotosItens['$temaId|$item'];

/// Foto do item ocupando todo o espaco disponivel, com cantos arredondados.
/// Sem foto, mostra o icone do tema sobre um fundo lilas.
class FotoItem extends StatelessWidget {
  final String temaId;
  final String item;
  final LanceIconType icone;
  final double raio;

  const FotoItem({super.key, required this.temaId, required this.item, required this.icone, this.raio = 22});

  @override
  Widget build(BuildContext context) {
    final foto = fotoDoItem(temaId, item);
    return LayoutBuilder(
      builder: (context, c) {
        final lado = c.biggest.shortestSide.isFinite ? c.biggest.shortestSide : 120.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(raio),
          child: foto == null
              ? Container(
                  color: AppColors.superficieClara,
                  alignment: Alignment.center,
                  child: LanceIcon(icone, tamanho: lado * 0.5),
                )
              : Image.asset(
                  foto,
                  key: ValueKey('foto_$item'),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  gaplessPlayback: true,
                  semanticLabel: 'Foto de $item',
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.superficieClara,
                    alignment: Alignment.center,
                    child: LanceIcon(icone, tamanho: lado * 0.5),
                  ),
                ),
        );
      },
    );
  }
}
