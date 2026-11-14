import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../state/game_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/glow_button.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/pressable.dart';
import '../widgets/rota.dart';
import 'auction_screen.dart';
import 'result_screen.dart';

/// Revisao: a lista de cada jogador em abas (deslize para o lado).
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _pagina = PageController(viewportFraction: 0.9);
  int _atual = 0;

  @override
  void dispose() {
    _pagina.dispose();
    super.dispose();
  }

  void _irPara(int i) {
    _pagina.animateToPage(i, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  void _voltarAoLeilao() {
    final g = context.read<GameController>();
    g.desfazer();
    Navigator.of(context).pushReplacement(rotaAnimada(const AuctionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    if (!g.temPartida) return const Scaffold(body: LanceBackground(child: SizedBox()));
    final js = g.jogadores;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).popUntil((r) => r.isFirst);
      },
      child: Scaffold(
        body: LanceBackground(
          child: SafeArea(
            child: Column(
              children: [
                LanceTopBar(
                  titulo: 'As listas',
                  onVoltar: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  acao: BotaoIcone(
                    icone: LanceIconType.desfazer,
                    rotulo: 'Voltar ao leilão desfazendo a última ação',
                    onTap: g.podeDesfazer ? _voltarAoLeilao : null,
                  ),
                ),
                // Abas com o nome de cada jogador.
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: js.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final sel = i == _atual;
                      return Pressable(
                        onTap: () => _irPara(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: sel ? js[i].cor : AppColors.superficieClara,
                            border: Border.all(color: js[i].cor, width: 2),
                            boxShadow: sel ? [BoxShadow(color: js[i].cor, blurRadius: 14)] : null,
                          ),
                          child: Text(
                            js[i].nome,
                            style: AppText.texto(
                              15,
                              cor: sel ? AppColors.textoSobreAmarelo : AppColors.branco,
                              peso: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _pagina,
                    itemCount: js.length,
                    onPageChanged: (i) => setState(() => _atual = i),
                    itemBuilder: (_, i) => AnimatedBuilder(
                      animation: _pagina,
                      builder: (_, c) {
                        double d = 0;
                        if (_pagina.position.haveDimensions) d = ((_pagina.page ?? 0) - i).abs();
                        return Transform.scale(scale: (1 - d * 0.08).clamp(0.85, 1.0), child: c);
                      },
                      child: _ListaJogador(jogador: js[i]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: GlowButton(
                    texto: 'Chamar o Juiz',
                    icone: LanceIconType.trofeu,
                    altura: 64,
                    onTap: () {
                      g.irParaJuiz();
                      Navigator.of(context).pushReplacement(rotaAnimada(const ResultScreen()));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListaJogador extends StatelessWidget {
  final Player jogador;
  const _ListaJogador({required this.jogador});

  @override
  Widget build(BuildContext context) {
    final p = jogador;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF6F0FF)],
          ),
          border: Border.all(color: p.cor, width: 2.5),
          boxShadow: [BoxShadow(color: p.cor.withValues(alpha: 0.4), blurRadius: 22)],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Row(
                children: [
                  LanceIcon(LanceIconType.jogador, tamanho: 40, preenchimento: p.cor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.titulo(24),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (var i = 0; i < p.compras.length; i++)
                    _linhaItem(i + 1, p.compras[i].item, 'R\$${p.compras[i].preco}', p.cor),
                  if (p.compras.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        'Nenhum item arrematado',
                        textAlign: TextAlign.center,
                        style: AppText.texto(16, cor: AppColors.lilas.withValues(alpha: 0.7)),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.superficieClara,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(child: _resumo('Total gasto', 'R\$${p.totalGasto}')),
                  Container(width: 1.5, height: 40, color: AppColors.roxo.withValues(alpha: 0.5)),
                  Expanded(child: _resumo('Saldo que sobrou', 'R\$${p.saldo}')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumo(String rotulo, String valor) => Column(
    children: [
      Text(rotulo, style: AppText.texto(13, cor: AppColors.lilas)),
      const SizedBox(height: 2),
      Text(valor, style: AppText.numero(24)),
    ],
  );

  Widget _linhaItem(int n, String item, String preco, Color cor) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cor.withValues(alpha: 0.5)),
    ),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
          child: Text('$n', style: AppText.numero(14, cor: AppColors.textoSobreAmarelo)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(item, style: AppText.texto(17, cor: AppColors.branco)),
        ),
        const SizedBox(width: 8),
        Text(preco, style: AppText.numero(18, cor: AppColors.lilas)),
      ],
    ),
  );
}
