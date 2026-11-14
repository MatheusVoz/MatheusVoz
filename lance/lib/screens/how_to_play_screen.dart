import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';

/// Como Jogar: regras em passos ilustrados.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _passos = <(LanceIconType, String, String)>[
    (
      LanceIconType.bola,
      'Escolha o tema',
      'Futebol, Comidas, Bebidas, Carros... ou crie um tema com os seus próprios itens.',
    ),
    (
      LanceIconType.jogadores,
      'Monte a mesa',
      'De 2 a 6 jogadores. Cada um recebe o mesmo dinheiro fictício e um número de vagas na lista.',
    ),
    (
      LanceIconType.martelo,
      'Um item por vez',
      'O item da vez aparece no centro. Todos dão lances em voz alta, começando em R\$1.',
    ),
    (
      LanceIconType.jogador,
      'O leiloeiro registra',
      'Quem der o maior lance vence: toque no jogador, ajuste o valor e bata o martelo em VENDIDO!',
    ),
    (
      LanceIconType.moeda,
      'Cuidado com o saldo',
      'Ninguém pode dar lance acima do que tem. Com a regra do R\$1 por vaga, guarde R\$1 para cada vaga que falta.',
    ),
    (LanceIconType.pular, 'Ninguém quis?', 'Pule o item. Errou? Use Desfazer para voltar a última venda.'),
    (
      LanceIconType.lista,
      'Fim do leilão',
      'Acaba quando todas as listas fecham, o dinheiro acaba ou os itens terminam.',
    ),
    (
      LanceIconType.trofeu,
      'O juiz decide',
      'Uma pessoa de fora analisa as listas e ordena do 1º ao último. O campeão ganha a coroa!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LanceBackground(
        child: SafeArea(
          child: Column(
            children: [
              const LanceTopBar(titulo: 'Como Jogar'),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _passos.length,
                  itemBuilder: (_, i) {
                    final (icone, titulo, texto) = _passos[i];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + i * 90),
                      curve: Curves.easeOutBack,
                      builder: (_, v, c) => Opacity(
                        opacity: v.clamp(0.0, 1.0),
                        child: Transform.translate(offset: Offset(50 * (1 - v), 0), child: c),
                      ),
                      child: _Passo(numero: i + 1, icone: icone, titulo: titulo, texto: texto),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  final int numero;
  final LanceIconType icone;
  final String titulo, texto;
  const _Passo({required this.numero, required this.icone, required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [Color(0xFF4A1F9A), Color(0xFF34107A)]),
        border: Border.all(color: AppColors.roxo.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.superficie,
                  border: Border.all(color: AppColors.neon, width: 2),
                  boxShadow: [BoxShadow(color: AppColors.neon.withValues(alpha: 0.4), blurRadius: 14)],
                ),
                child: LanceIcon(icone, tamanho: 40),
              ),
              Positioned(
                left: -4,
                top: -4,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.gradienteBotao),
                  child: Text('$numero', style: AppText.numero(12, cor: AppColors.textoSobreAmarelo)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppText.titulo(17)),
                const SizedBox(height: 4),
                Text(texto, style: AppText.texto(15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
