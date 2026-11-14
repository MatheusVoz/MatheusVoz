import 'package:material_ui/material_ui.dart';

import '../data/themes_data.dart';
import '../models/theme_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/pressable.dart';
import '../widgets/rota.dart';
import 'custom_theme_screen.dart';
import 'setup_screen.dart';

/// Escolha do tema: grade de cards grandes com icone proprio.
class ThemeSelectScreen extends StatelessWidget {
  const ThemeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LanceBackground(
        child: SafeArea(
          child: Column(
            children: [
              const LanceTopBar(titulo: 'Escolha o tema'),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.25,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _Entrada(
                            ordem: i,
                            child: _CardTema(
                              tema: temasProntos[i],
                              onTap: () =>
                                  Navigator.of(context).push(rotaAnimada(SetupScreen(tema: temasProntos[i]))),
                            ),
                          ),
                          childCount: temasProntos.length,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      sliver: SliverToBoxAdapter(
                        child: _Entrada(
                          ordem: temasProntos.length,
                          child: _CardPersonalizado(
                            onTap: () => Navigator.of(context).push(rotaAnimada(const CustomThemeScreen())),
                          ),
                        ),
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

/// Animacao de entrada escalonada dos cards.
class _Entrada extends StatelessWidget {
  final int ordem;
  final Widget child;
  const _Entrada({required this.ordem, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + ordem * 70),
      curve: Curves.easeOutBack,
      builder: (_, v, c) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.7 + 0.3 * v, child: c),
      ),
      child: child,
    );
  }
}

class _CardTema extends StatelessWidget {
  final ThemeCategory tema;
  final VoidCallback onTap;
  const _CardTema({required this.tema, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tema ${tema.nome}',
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5523B0), Color(0xFF34107A)],
            ),
            border: Border.all(color: AppColors.roxo.withValues(alpha: 0.85), width: 2),
            boxShadow: [BoxShadow(color: AppColors.roxo.withValues(alpha: 0.35), blurRadius: 16)],
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LanceIcon(tema.icone, tamanho: (c.maxHeight * 0.46).clamp(40.0, 84.0)),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tema.nome.toUpperCase(), style: AppText.titulo(15)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CardPersonalizado extends StatelessWidget {
  final VoidCallback onTap;
  const _CardPersonalizado({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tema personalizado',
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: AppColors.gradienteBotao,
            border: Border.all(color: AppColors.branco, width: 2),
            boxShadow: [BoxShadow(color: AppColors.neon.withValues(alpha: 0.5), blurRadius: 22)],
          ),
          child: Row(
            children: [
              const LanceIcon(
                LanceIconType.lapis,
                tamanho: 52,
                preenchimento: AppColors.branco,
                contorno: AppColors.roxoEscuro,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'TEMA PERSONALIZADO',
                        style: AppText.titulo(16, cor: AppColors.textoSobreAmarelo),
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
