import 'package:material_ui/material_ui.dart';

import '../models/theme_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/glow_button.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_card.dart';
import '../widgets/lance_dialog.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/pressable.dart';
import '../widgets/rota.dart';
import 'setup_screen.dart';

/// Tema personalizado: o usuario digita os proprios itens.
class CustomThemeScreen extends StatefulWidget {
  const CustomThemeScreen({super.key});

  /// Minimo de itens (2 jogadores x lista de 3).
  static const minimoItens = 6;

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  final _nome = TextEditingController();
  final _item = TextEditingController();
  final _foco = FocusNode();
  final List<String> _itens = [];

  @override
  void dispose() {
    _nome.dispose();
    _item.dispose();
    _foco.dispose();
    super.dispose();
  }

  /// Adiciona o texto digitado. Aceita varios itens separados por virgula ou linha.
  void _adicionar() {
    final partes = _item.text
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (partes.isEmpty) return;
    var repetidos = 0;
    setState(() {
      for (final p in partes) {
        final existe = _itens.any((e) => e.toLowerCase() == p.toLowerCase());
        if (existe) {
          repetidos++;
        } else {
          _itens.insert(0, p);
        }
      }
      _item.clear();
    });
    if (repetidos > 0) avisar(context, 'Itens repetidos foram ignorados.');
    _foco.requestFocus();
  }

  void _continuar() {
    final nome = _nome.text.trim().isEmpty ? 'Personalizado' : _nome.text.trim();
    final tema = ThemeCategory.personalizado(_itens.reversed.toList(), nome: nome);
    Navigator.of(context).push(rotaAnimada(SetupScreen(tema: tema)));
  }

  InputDecoration _decoracao(String dica) => InputDecoration(
    hintText: dica,
    hintStyle: AppText.texto(16, cor: AppColors.lilas.withValues(alpha: 0.4)),
    filled: true,
    fillColor: AppColors.superficieClara,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.roxo.withValues(alpha: 0.6), width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.neon, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final faltam = CustomThemeScreen.minimoItens - _itens.length;
    return Scaffold(
      body: LanceBackground(
        child: SafeArea(
          child: Column(
            children: [
              const LanceTopBar(titulo: 'Tema personalizado'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    const SectionTitle('Nome do tema (opcional)'),
                    TextField(
                      controller: _nome,
                      maxLength: 24,
                      style: AppText.texto(17, cor: AppColors.branco),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _decoracao('Ex.: Músicas, Viagens...').copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 18),
                    SectionTitle('Itens (${_itens.length})'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _item,
                            focusNode: _foco,
                            maxLength: 40,
                            style: AppText.texto(17, cor: AppColors.branco),
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _decoracao('Digite um item').copyWith(counterText: ''),
                            onSubmitted: (_) => _adicionar(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        BotaoIcone(
                          icone: LanceIconType.mais,
                          onTap: _adicionar,
                          rotulo: 'Adicionar item',
                          tamanho: 54,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dica: separe vários itens com vírgula.',
                      style: AppText.texto(13, cor: AppColors.lilas.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 12),
                    if (_itens.isEmpty)
                      LanceCard(
                        child: Column(
                          children: [
                            const LanceIcon(LanceIconType.lista, tamanho: 48),
                            const SizedBox(height: 8),
                            Text(
                              'Nenhum item ainda.\nAdicione pelo menos ${CustomThemeScreen.minimoItens}.',
                              textAlign: TextAlign.center,
                              style: AppText.texto(15),
                            ),
                          ],
                        ),
                      ),
                    for (final it in _itens)
                      Padding(
                        key: ValueKey(it),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutBack,
                          builder: (_, v, c) =>
                              Transform.translate(offset: Offset(40 * (1 - v), 0), child: c),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                            decoration: BoxDecoration(
                              color: AppColors.superficieClara,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.roxo.withValues(alpha: 0.45)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    it,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.texto(16, cor: AppColors.branco),
                                  ),
                                ),
                                Pressable(
                                  onTap: () => setState(() => _itens.remove(it)),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: LanceIcon(LanceIconType.lixeira, tamanho: 26),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: GlowButton(
                  texto: faltam > 0 ? 'Faltam $faltam itens' : 'Continuar',
                  icone: LanceIconType.play,
                  onTap: faltam > 0 ? null : _continuar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
