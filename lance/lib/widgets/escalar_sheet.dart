import 'package:material_ui/material_ui.dart';

import '../data/futebol_posicoes.dart';
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

/// Resultado da escolha: a posicao escolhida, ou [alternativa] = true se a
/// pessoa tocou no botao alternativo (banco no leilao, passar na maleta).
typedef EscolhaPosicao = ({Posicao? posicao, bool alternativa});

/// Pergunta em que posicao do campo o jogador vai entrar.
Future<EscolhaPosicao> escolherPosicao(
  BuildContext context, {
  required String dono,
  required Color cor,
  required String item,
  required Map<Posicao, String> escalacao,
  required List<Posicao> livres,
  String? textoAlternativa,
}) async {
  if (livres.isEmpty) return (posicao: null, alternativa: true);
  final funcao = funcaoDe(item);
  final r = await showModalBottomSheet<EscolhaPosicao>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (_, v, c) => Transform.scale(scale: v, child: c),
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
                    width: 64,
                    height: 64,
                    child: FotoItem(
                      temaId: Posicao.temaFutebol,
                      item: item,
                      icone: LanceIconType.jogador,
                      raio: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.titulo(19)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: funcao == Funcao.goleiro ? AppColors.neon : AppColors.superficieClara,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            funcao.nome.toUpperCase(),
                            style: AppText.texto(11, cor: AppColors.roxoEscuro, peso: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('Onde $dono vai escalar?', style: AppText.texto(13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.46),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CampoFutebol(
                    escalacao: escalacao,
                    selecionaveis: livres.toSet(),
                    cor: cor,
                    onEscolher: (p) => Navigator.of(ctx).pop((posicao: p, alternativa: false)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Toque numa bolinha amarela', style: AppText.texto(13)),
              if (textoAlternativa != null) ...[
                const SizedBox(height: 8),
                GlowButton(
                  texto: textoAlternativa,
                  icone: LanceIconType.pular,
                  estilo: EstiloBotao.secundario,
                  altura: 44,
                  tamanhoTexto: 15,
                  onTap: () => Navigator.of(ctx).pop((posicao: null, alternativa: true)),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  return r ?? (posicao: null, alternativa: true);
}
