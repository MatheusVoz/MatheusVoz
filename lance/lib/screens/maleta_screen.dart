import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/game_mode.dart';
import '../models/theme_category.dart';
import '../services/feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/foto_item.dart';
import '../widgets/glow_button.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/pressable.dart';

/// Modo Maleta: 5 maletas numeradas, cada uma com um item sorteado do tema.
/// Toque numa maleta para abri-la e ver o que tem dentro.
class MaletaScreen extends StatefulWidget {
  final ThemeCategory tema;
  const MaletaScreen({super.key, required this.tema});

  static const quantidade = 5;

  @override
  State<MaletaScreen> createState() => _MaletaScreenState();
}

class _MaletaScreenState extends State<MaletaScreen> {
  late List<String> _itens = sortearMaletas(widget.tema, quantidade: MaletaScreen.quantidade);
  final Set<int> _abertas = {};

  /// Muda a cada nova rodada para reiniciar as animacoes.
  int _rodada = 0;

  void _abrir(int i) {
    if (_abertas.contains(i)) return;
    setState(() => _abertas.add(i));
    FeedbackService.instancia.tocar(Som.moeda);
    FeedbackService.instancia.vibrarLeve();
  }

  void _novas() {
    setState(() {
      _itens = sortearMaletas(widget.tema, quantidade: MaletaScreen.quantidade);
      _abertas.clear();
      _rodada++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LanceBackground(
        child: SafeArea(
          child: Column(
            children: [
              const LanceTopBar(titulo: 'Maleta'),
              Text('Tema: ${widget.tema.nome}  •  toque para abrir', style: AppText.texto(14)),
              const SizedBox(height: 14),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final largura = (c.maxWidth - 16 * 2 - 12) / 2;
                    final altura = math.min(largura * 0.92, (c.maxHeight - 24) / 3);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          for (var i = 0; i < _itens.length; i++)
                            SizedBox(
                              key: ValueKey('maleta_${_rodada}_$i'),
                              width: largura,
                              height: altura,
                              child: _Maleta(
                                numero: i + 1,
                                item: _itens[i],
                                aberta: _abertas.contains(i),
                                icone: widget.tema.icone,
                                temaId: widget.tema.id,
                                onTap: () => _abrir(i),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: GlowButton(
                        texto: 'Novas maletas',
                        icone: LanceIconType.pular,
                        altura: 48,
                        tamanhoTexto: 16,
                        onTap: _novas,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BotaoIcone(
                      icone: LanceIconType.voltar,
                      rotulo: 'Menu',
                      onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uma maleta: fechada mostra o numero; aberta gira e revela o item.
class _Maleta extends StatelessWidget {
  final int numero;
  final String item;
  final bool aberta;
  final LanceIconType icone;
  final String temaId;
  final VoidCallback onTap;

  const _Maleta({
    required this.temaId,
    required this.numero,
    required this.item,
    required this.aberta,
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: aberta ? 'Maleta $numero: $item' : 'Abrir maleta $numero',
      excludeSemantics: true,
      child: Pressable(
        onTap: aberta ? null : onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: aberta ? 1 : 0),
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOutBack,
          builder: (context, t, _) {
            // Gira no eixo Y: na metade do giro troca a frente pelo verso.
            final angulo = t * math.pi;
            final mostrandoVerso = t > 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angulo),
              child: mostrandoVerso
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _verso(),
                    )
                  : _frente(),
            );
          },
        ),
      ),
    );
  }

  Widget _frente() => Container(
    decoration: BoxDecoration(
      gradient: AppColors.gradienteRoxo,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(color: AppColors.roxo.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 6)),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LanceIcon(LanceIconType.maleta, tamanho: 56),
        const SizedBox(height: 6),
        Text('$numero', style: AppText.numero(30, cor: AppColors.brancoPuro)),
      ],
    ),
  );

  Widget _verso() => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.neon, width: 3),
      boxShadow: [BoxShadow(color: AppColors.neon.withValues(alpha: 0.35), blurRadius: 16)],
    ),
    child: Column(
      children: [
        // Foto do item; o numero da maleta fica num selo no canto.
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: FotoItem(temaId: temaId, item: item, icone: icone, raio: 16),
              ),
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.neon, borderRadius: BorderRadius.circular(10)),
                  child: Text('$numero', style: AppText.numero(13, cor: AppColors.textoSobreAmarelo)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 24,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item,
              key: ValueKey('item_maleta_$numero'),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: AppText.titulo(16),
            ),
          ),
        ),
      ],
    ),
  );
}
