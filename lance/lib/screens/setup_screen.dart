import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/game_config.dart';
import '../models/player.dart';
import '../models/theme_category.dart';
import '../state/game_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/glow_button.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_card.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/option_selector.dart';
import '../widgets/pressable.dart';
import '../widgets/rota.dart';
import 'auction_screen.dart';

/// Configuracao da partida: jogadores, dinheiro, tamanho da lista e itens.
class SetupScreen extends StatefulWidget {
  final ThemeCategory tema;
  const SetupScreen({super.key, required this.tema});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const _maxJogadores = 6;

  int _jogadores = 4;
  int _dinheiro = 30;
  int _lista = 4;
  late int _qtdItens;

  final _nomes = List.generate(_maxJogadores, (_) => TextEditingController());
  final _cores = List.generate(_maxJogadores, (i) => i);

  /// Itens unicos disponiveis no tema.
  late final int _disponiveis = widget.tema.itens.toSet().length;

  @override
  void initState() {
    super.initState();
    // Garante uma combinacao valida para temas personalizados pequenos.
    if (!_jogadoresValido(_jogadores)) {
      _jogadores = GameConfig.opcoesJogadores.lastWhere(_jogadoresValido, orElse: () => 2);
    }
    _ajustarLista();
    _qtdItens = GameConfig.padraoItens(_jogadores, _lista, _disponiveis);
  }

  @override
  void dispose() {
    for (final c in _nomes) {
      c.dispose();
    }
    super.dispose();
  }

  bool _jogadoresValido(int j) => j * GameConfig.opcoesLista.first <= _disponiveis;
  bool _listaValida(int l) => _jogadores * l <= _disponiveis;

  void _ajustarLista() {
    if (!_listaValida(_lista)) {
      _lista = GameConfig.opcoesLista.lastWhere(_listaValida, orElse: () => 3);
    }
  }

  int get _minItens => GameConfig.minimoItens(_jogadores, _lista);

  void _recalcularItens() {
    _qtdItens = GameConfig.padraoItens(_jogadores, _lista, _disponiveis);
  }

  void _escolherCor(int jogador, int cor) {
    setState(() {
      // Se outro jogador ja usa a cor, troca as cores entre eles.
      final outro = _cores.indexOf(cor);
      if (outro >= 0 && outro < _jogadores && outro != jogador) {
        _cores[outro] = _cores[jogador];
      }
      _cores[jogador] = cor;
    });
  }

  void _comecar() {
    final config = GameConfig(
      temaId: widget.tema.id,
      temaNome: widget.tema.nome,
      itensPersonalizados: widget.tema.personalizado ? widget.tema.itens : const [],
      jogadores: [
        for (var i = 0; i < _jogadores; i++)
          PlayerSetup(
            nome: _nomes[i].text.trim().isEmpty ? 'Jogador ${i + 1}' : _nomes[i].text.trim(),
            corIndice: _cores[i],
          ),
      ],
      dinheiroInicial: _dinheiro,
      tamanhoLista: _lista,
      quantidadeItens: _qtdItens.clamp(_minItens, _disponiveis),
    );
    context.read<GameController>().iniciar(config, widget.tema);
    // Remove as telas de configuracao da pilha: voltar do leilao leva ao menu.
    Navigator.of(context).pushAndRemoveUntil(rotaAnimada(const AuctionScreen()), (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LanceBackground(
        child: SafeArea(
          child: Column(
            children: [
              LanceTopBar(titulo: widget.tema.nome),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  children: [
                    const SectionTitle('Número de jogadores'),
                    OptionSelector<int>(
                      opcoes: GameConfig.opcoesJogadores,
                      selecionado: _jogadores,
                      rotulo: (v) => '$v',
                      prefixoChave: 'jogadores',
                      habilitado: _jogadoresValido,
                      altura: 52,
                      onChanged: (v) => setState(() {
                        _jogadores = v;
                        _ajustarLista();
                        _recalcularItens();
                      }),
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle('Jogadores'),
                    for (var i = 0; i < _jogadores; i++) _linhaJogador(i),
                    const SizedBox(height: 10),
                    const SectionTitle('Dinheiro inicial'),
                    OptionSelector<int>(
                      opcoes: GameConfig.opcoesDinheiro,
                      selecionado: _dinheiro,
                      rotulo: (v) => 'R\$$v',
                      prefixoChave: 'dinheiro',
                      onChanged: (v) => setState(() => _dinheiro = v),
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle('Itens por jogador'),
                    OptionSelector<int>(
                      opcoes: GameConfig.opcoesLista,
                      selecionado: _lista,
                      rotulo: (v) => '$v',
                      prefixoChave: 'lista',
                      habilitado: _listaValida,
                      onChanged: (v) => setState(() {
                        _lista = v;
                        _recalcularItens();
                      }),
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle('Itens no leilão'),
                    _seletorItens(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: GlowButton(
                  texto: 'Começar Leilão',
                  icone: LanceIconType.martelo,
                  altura: 56,
                  tamanhoTexto: 19,
                  onTap: _comecar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linhaJogador(int i) {
    final cor = AppColors.coresJogadores[_cores[i]];
    return Padding(
      key: ValueKey('jogador_$i'),
      padding: const EdgeInsets.only(bottom: 10),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 300 + i * 60),
        curve: Curves.easeOutBack,
        builder: (_, v, c) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cor.withValues(alpha: 0.8), width: 2),
            boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.25), blurRadius: 12)],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cor,
                      boxShadow: [BoxShadow(color: cor, blurRadius: 10)],
                    ),
                    child: Text('${i + 1}', style: AppText.numero(18, cor: AppColors.textoSobreAmarelo)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _nomes[i],
                      maxLength: 14,
                      textCapitalization: TextCapitalization.words,
                      style: AppText.texto(17, cor: AppColors.branco),
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        hintText: 'Jogador ${i + 1}',
                        hintStyle: AppText.texto(17, cor: AppColors.lilas.withValues(alpha: 0.45)),
                        filled: true,
                        fillColor: AppColors.superficieClara,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: cor, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Paleta de cores (tons de roxo).
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var c = 0; c < AppColors.coresJogadores.length; c++)
                    Semantics(
                      button: true,
                      selected: _cores[i] == c,
                      label: 'Cor ${AppColors.nomesCores[c]}',
                      child: Pressable(
                        onTap: () => _escolherCor(i, c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.coresJogadores[c],
                            border: Border.all(
                              color: _cores[i] == c ? AppColors.branco : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: _cores[i] == c
                                ? [
                                    BoxShadow(
                                      color: AppColors.coresJogadores[c],
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seletorItens() {
    final podeMenos = _qtdItens > _minItens;
    final podeMais = _qtdItens < _disponiveis;
    return LanceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              BotaoIcone(
                icone: LanceIconType.menos,
                rotulo: 'Menos itens',
                tamanho: 52,
                onTap: podeMenos ? () => setState(() => _qtdItens--) : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('$_qtdItens', style: AppText.numero(38).copyWith(shadows: AppText.brilho)),
                    Text('itens', style: AppText.texto(14)),
                  ],
                ),
              ),
              BotaoIcone(
                icone: LanceIconType.mais,
                rotulo: 'Mais itens',
                tamanho: 52,
                onTap: podeMais ? () => setState(() => _qtdItens++) : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'mín $_minItens  •  máx $_disponiveis',
            textAlign: TextAlign.center,
            style: AppText.texto(13, cor: AppColors.lilas.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
