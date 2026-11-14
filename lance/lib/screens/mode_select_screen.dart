import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/game_mode.dart';
import '../state/game_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_dialog.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/pressable.dart';
import '../widgets/rota.dart';
import 'theme_select_screen.dart';

/// Escolha do modo de jogo: Leilao, Impostor ou Maleta.
class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  Future<void> _escolher(BuildContext context, ModoJogo modo) async {
    final game = context.read<GameController>();
    // Um novo leilao apaga o leilao salvo (os outros modos nao mexem nele).
    if (modo == ModoJogo.leilao && game.temPartida) {
      final ok = await confirmar(
        context,
        titulo: 'Leilão em andamento',
        mensagem: 'Existe um leilão salvo. Começar outro vai apagá-lo.',
        sim: 'Novo leilão',
      );
      if (!ok || !context.mounted) return;
      await game.encerrarPartida();
    }
    if (!context.mounted) return;
    Navigator.of(context).push(rotaAnimada(ThemeSelectScreen(modo: modo)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LanceBackground(
        child: SafeArea(
          child: Column(
            children: [
              const LanceTopBar(titulo: 'Escolha o modo'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    for (var i = 0; i < ModoJogo.values.length; i++)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 380 + i * 90),
                        curve: Curves.easeOutBack,
                        builder: (_, v, c) => Opacity(
                          opacity: v.clamp(0.0, 1.0),
                          child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: c),
                        ),
                        child: _CardModo(
                          modo: ModoJogo.values[i],
                          onTap: () => _escolher(context, ModoJogo.values[i]),
                        ),
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

class _CardModo extends StatelessWidget {
  final ModoJogo modo;
  final VoidCallback onTap;
  const _CardModo({required this.modo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: 'Modo ${modo.nome}',
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.roxo.withValues(alpha: 0.25), width: 1.5),
              boxShadow: [BoxShadow(color: AppColors.roxo.withValues(alpha: 0.10), blurRadius: 16)],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.superficieClara),
                  child: LanceIcon(modo.icone, tamanho: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(modo.nome.toUpperCase(), style: AppText.titulo(18)),
                      const SizedBox(height: 2),
                      Text(modo.descricao, style: AppText.texto(14)),
                    ],
                  ),
                ),
                const LanceIcon(LanceIconType.play, tamanho: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
