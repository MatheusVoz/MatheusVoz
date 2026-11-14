import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../services/feedback_service.dart';
import '../state/settings_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_card.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_switch.dart';
import '../widgets/lance_top_bar.dart';

/// Configuracoes: som e vibracao.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    return Scaffold(
      body: LanceBackground(
        child: SafeArea(
          child: Column(
            children: [
              const LanceTopBar(titulo: 'Configurações'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _Opcao(
                      icone: s.som ? LanceIconType.som : LanceIconType.somMudo,
                      titulo: 'Som',
                      descricao: 'Martelo, moedas e fanfarra',
                      valor: s.som,
                      onChanged: (v) {
                        s.som = v;
                        if (v) FeedbackService.instancia.tocar(Som.moeda);
                      },
                    ),
                    _Opcao(
                      icone: LanceIconType.vibracao,
                      titulo: 'Vibração',
                      descricao: 'Vibrar ao bater o martelo',
                      valor: s.vibracao,
                      onChanged: (v) {
                        s.vibracao = v;
                        if (v) FeedbackService.instancia.vibrarForte();
                      },
                    ),
                    const SizedBox(height: 18),
                    LanceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sobre', style: AppText.titulo(17)),
                          const SizedBox(height: 6),
                          Text(
                            'LANCE! versão 1.0 — funciona 100% offline, sem login e sem anúncios. '
                            'A partida em andamento é salva automaticamente.\n\n'
                            'Fontes Bungee e Fredoka sob a SIL Open Font License. '
                            'Ícones e sons criados especialmente para o app.',
                            style: AppText.texto(14, cor: AppColors.lilas.withValues(alpha: 0.8)),
                          ),
                        ],
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

class _Opcao extends StatelessWidget {
  final LanceIconType icone;
  final String titulo, descricao;
  final bool valor;
  final ValueChanged<bool> onChanged;
  const _Opcao({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LanceCard(
        corBorda: valor ? AppColors.roxo : null,
        brilho: valor,
        child: Row(
          children: [
            LanceIcon(icone, tamanho: 42, preenchimento: valor ? AppColors.roxo : AppColors.desativado),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: AppText.texto(18, cor: AppColors.branco, peso: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(descricao, style: AppText.texto(14)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            LanceSwitch(valor: valor, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
