import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../services/feedback_service.dart';
import '../state/game_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/confetti.dart';
import '../widgets/glow_button.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/pressable.dart';
import '../widgets/rota.dart';
import 'auction_screen.dart';
import 'review_screen.dart';
import 'theme_select_screen.dart';

/// Resultado: tabela de classificacao. O juiz da pontos para cada jogador
/// e a tabela se reordena sozinha (quem tem mais pontos fica no topo).
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const _alturaLinha = 66.0;

  /// Muda a chave para disparar uma nova chuva de confete.
  int _confetes = 0;
  int? _lider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FeedbackService.instancia.tocar(Som.fanfarra);
      setState(() => _confetes++);
    });
  }

  void _pontuar(GameController g, Player p, int delta) {
    g.darPonto(p.id, delta);
    final topo = g.classificacao.first;
    // Novo lider com pontos: comemora.
    if (g.pontos(topo.id) > 0 && topo.id != _lider) {
      _lider = topo.id;
      FeedbackService.instancia.tocar(Som.moeda);
      setState(() => _confetes++);
    }
  }

  void _voltarRevisao(GameController g) {
    g.irParaRevisao();
    Navigator.of(context).pushReplacement(rotaAnimada(const ReviewScreen()));
  }

  void _denovo() {
    context.read<GameController>().jogarNovamente();
    Navigator.of(context).pushAndRemoveUntil(rotaAnimada(const AuctionScreen()), (r) => r.isFirst);
  }

  Future<void> _novo() async {
    final nav = Navigator.of(context);
    await context.read<GameController>().encerrarPartida();
    nav.pushAndRemoveUntil(rotaAnimada(const ThemeSelectScreen()), (r) => r.isFirst);
  }

  Future<void> _menu() async {
    final nav = Navigator.of(context);
    await context.read<GameController>().encerrarPartida();
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    if (!g.temPartida || g.fase != FasePartida.juiz) {
      return const Scaffold(body: LanceBackground(child: SizedBox()));
    }
    final lista = g.classificacao;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltarRevisao(g);
      },
      child: Scaffold(
        body: LanceBackground(
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    LanceTopBar(titulo: 'Resultado', onVoltar: () => _voltarRevisao(g)),
                    Text('Juiz: dê pontos para cada lista', style: AppText.texto(14)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: SizedBox(
                          height: lista.length * _alturaLinha,
                          child: Stack(
                            children: [
                              // Cada linha desliza ate a sua posicao quando a ordem muda.
                              for (final p in g.jogadores)
                                AnimatedPositioned(
                                  key: ValueKey('linha_${p.id}'),
                                  duration: const Duration(milliseconds: 450),
                                  curve: Curves.easeOutBack,
                                  left: 0,
                                  right: 0,
                                  top: lista.indexOf(p) * _alturaLinha,
                                  height: _alturaLinha - 8,
                                  child: _Linha(
                                    jogador: p,
                                    posicao: 1 + lista.where((o) => g.pontos(o.id) > g.pontos(p.id)).length,
                                    pontos: g.pontos(p.id),
                                    lider: lista.first.id == p.id && g.pontos(p.id) > 0,
                                    onMais: () => _pontuar(g, p, 1),
                                    onMenos: () => _pontuar(g, p, -1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                      child: Column(
                        children: [
                          GlowButton(
                            texto: 'Jogar de novo',
                            icone: LanceIconType.play,
                            altura: 52,
                            tamanhoTexto: 18,
                            onTap: _denovo,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: GlowButton(
                                  texto: 'Novo leilão',
                                  estilo: EstiloBotao.secundario,
                                  altura: 46,
                                  tamanhoTexto: 15,
                                  onTap: _novo,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GlowButton(
                                  texto: 'Menu',
                                  estilo: EstiloBotao.secundario,
                                  altura: 46,
                                  tamanhoTexto: 15,
                                  onTap: _menu,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_confetes > 0)
                Positioned.fill(child: ConfettiRain(key: ValueKey(_confetes), quantidade: 90)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uma linha da tabela: posicao, nome, itens e controle de pontos.
class _Linha extends StatelessWidget {
  final Player jogador;
  final int posicao;
  final int pontos;
  final bool lider;
  final VoidCallback onMais;
  final VoidCallback onMenos;

  const _Linha({
    required this.jogador,
    required this.posicao,
    required this.pontos,
    required this.lider,
    required this.onMais,
    required this.onMenos,
  });

  @override
  Widget build(BuildContext context) {
    final p = jogador;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
      decoration: BoxDecoration(
        color: lider ? const Color(0xFF5B27B8) : AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lider ? AppColors.neon : p.cor.withValues(alpha: 0.6),
          width: lider ? 2.5 : 1.5,
        ),
        boxShadow: lider ? [BoxShadow(color: AppColors.neon.withValues(alpha: 0.5), blurRadius: 16)] : null,
      ),
      child: Row(
        children: [
          // Posicao (coroa para o lider).
          SizedBox(
            width: 40,
            child: Center(
              child: lider
                  ? const LanceIcon(LanceIconType.coroa, tamanho: 32)
                  : Text('$posicaoº', style: AppText.numero(17, cor: AppColors.lilas)),
            ),
          ),
          Container(
            width: 5,
            height: 30,
            decoration: BoxDecoration(color: p.cor, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.texto(16, cor: AppColors.branco, peso: FontWeight.w700),
                ),
                Text(
                  p.compras.isEmpty ? 'Nenhum item' : p.compras.map((c) => c.item).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.texto(12, cor: AppColors.lilas.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          _BotaoPonto(rotulo: '-', onTap: pontos > 0 ? onMenos : null, chave: 'menos_${p.id}'),
          SizedBox(
            width: 42,
            child: Center(
              child: Text(
                '$pontos',
                key: ValueKey('pontos_${p.id}'),
                style: AppText.numero(20, cor: lider ? AppColors.neon : AppColors.branco),
              ),
            ),
          ),
          _BotaoPonto(rotulo: '+', onTap: onMais, chave: 'mais_${p.id}'),
        ],
      ),
    );
  }
}

class _BotaoPonto extends StatelessWidget {
  final String rotulo;
  final VoidCallback? onTap;
  final String chave;
  const _BotaoPonto({required this.rotulo, required this.onTap, required this.chave});

  @override
  Widget build(BuildContext context) {
    final mais = rotulo == '+';
    return Semantics(
      key: ValueKey(chave),
      button: true,
      label: mais ? 'Dar ponto' : 'Tirar ponto',
      child: Pressable(
        onTap: onTap,
        escala: 0.85,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: onTap == null ? 0.35 : 1,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: mais ? AppColors.gradienteBotao : null,
              color: mais ? null : AppColors.superficieClara,
              border: Border.all(color: mais ? AppColors.branco : AppColors.roxo, width: 1.5),
            ),
            child: LanceIcon(
              mais ? LanceIconType.mais : LanceIconType.menos,
              tamanho: 18,
              preenchimento: mais ? AppColors.roxoEscuro : AppColors.branco,
              contorno: mais ? AppColors.roxoEscuro : AppColors.branco,
            ),
          ),
        ),
      ),
    );
  }
}
