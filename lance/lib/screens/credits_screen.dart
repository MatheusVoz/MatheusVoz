import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_top_bar.dart';

/// Creditos das fotos (licencas livres da Wikimedia Commons exigem atribuicao).
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  Future<List<Map<String, dynamic>>> _carregar() async {
    try {
      final texto = await rootBundle.loadString('assets/fotos/creditos.json');
      return List<Map<String, dynamic>>.from(jsonDecode(texto) as List);
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LanceBackground(
        child: SafeArea(
          child: Column(
            children: [
              const LanceTopBar(titulo: 'Créditos das fotos'),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _carregar(),
                  builder: (context, snap) {
                    final lista = snap.data ?? const [];
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: lista.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Fotos da Wikimedia Commons, usadas sob licenças livres '
                              '(Creative Commons ou domínio público). Itens sem foto livre usam ícones.',
                              style: AppText.texto(13),
                            ),
                          );
                        }
                        final c = lista[i - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${c['item']}',
                                style: AppText.texto(14, cor: AppColors.branco, peso: FontWeight.w700),
                              ),
                              Text('${c['autor']}  •  ${c['licenca']}', style: AppText.texto(12)),
                              Text(
                                '${c['fonte']}',
                                style: AppText.texto(11, cor: AppColors.lilas.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        );
                      },
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
