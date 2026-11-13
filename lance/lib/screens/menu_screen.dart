import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/game_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/glow_button.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_dialog.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_logo.dart';
import '../widgets/rota.dart';
import 'auction_screen.dart';
import 'how_to_play_screen.dart';
import 'judge_screen.dart';
import 'podium_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';
import 'theme_select_screen.dart';

/// Tela inicial: splash com logo animado e menu principal.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  // Os botoes aparecem depois que o logo termina de entrar.
  late final AnimationController _botoes = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _botoes.forward();
    });
  }

  @override
  void dispose() {
    _botoes.dispose();
    super.dispose();
  }

  Widget _entrada(int ordem, Widget child) {
    final inicio = (ordem * 0.14).clamp(0.0, 0.7);
    final anim = CurvedAnimation(
      parent: _botoes,
      curve: Interval(inicio, (inicio + 0.45).clamp(0, 1), curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 40 * (1 - anim.value)), child: c),
      ),
      child: child,
    );
  }

  Future<void> _novoLeilao() async {
    final game = context.read<GameController>();
    if (game.temPartida && game.fase != FasePartida.podio) {
      final ok = await confirmar(
        context,
        titulo: 'Leilão em andamento',
        mensagem: 'Existe uma partida salva. Começar um novo leilão vai apagá-la.',
        sim: 'Novo leilão',
      );
      if (!ok || !mounted) return;
      await game.encerrarPartida();
    }
    if (!mounted) return;
    Navigator.of(context).push(rotaAnimada(const ThemeSelectScreen()));
  }

  void _continuar() {
    final game = context.read<GameController>();
    final Widget tela = switch (game.fase) {
      FasePartida.leilao => const AuctionScreen(),
      FasePartida.revisao => const ReviewScreen(),
      FasePartida.juiz => const JudgeScreen(),
      FasePartida.podio => const PodiumScreen(),
    };
    Navigator.of(context).push(rotaAnimada(tela));
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final temSalva = game.temPartida && game.fase != FasePartida.podio;
    return Scaffold(
      body: LanceBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final escalaLogo = (c.maxHeight / 760).clamp(0.7, 1.15);
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(height: 24 * escalaLogo),
                        LanceLogo(tamanho: escalaLogo),
                        SizedBox(height: 30 * escalaLogo),
                        Column(
                          children: [
                            if (temSalva) ...[
                              _entrada(
                                0,
                                GlowButton(
                                  texto: 'Continuar Leilão',
                                  icone: LanceIconType.play,
                                  altura: 66,
                                  tamanhoTexto: 21,
                                  onTap: _continuar,
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            _entrada(
                              1,
                              GlowButton(
                                texto: 'Novo Leilão',
                                icone: LanceIconType.martelo,
                                altura: 66,
                                tamanhoTexto: 22,
                                estilo: temSalva ? EstiloBotao.secundario : EstiloBotao.principal,
                                onTap: _novoLeilao,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _entrada(
                              2,
                              GlowButton(
                                texto: 'Como Jogar',
                                icone: LanceIconType.livro,
                                estilo: EstiloBotao.secundario,
                                onTap: () => Navigator.of(context).push(rotaAnimada(const HowToPlayScreen())),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _entrada(
                              3,
                              GlowButton(
                                texto: 'Configurações',
                                icone: LanceIconType.engrenagem,
                                estilo: EstiloBotao.secundario,
                                onTap: () => Navigator.of(context).push(rotaAnimada(const SettingsScreen())),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _entrada(
                          4,
                          Text(
                            '100% offline  •  sem anúncios',
                            style: AppText.texto(13, cor: AppColors.lilas.withValues(alpha: 0.55)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
