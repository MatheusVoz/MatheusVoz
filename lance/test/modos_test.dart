import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lance/data/themes_data.dart';
import 'package:lance/main.dart';
import 'package:lance/models/game_mode.dart';
import 'package:lance/services/feedback_service.dart';
import 'package:lance/state/game_controller.dart';
import 'package:lance/state/settings_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Abre o app e navega ate o tema Futebol do modo escolhido.
Future<void> abrirModo(WidgetTester t, String modo, String tela, {String tema = 'FUTEBOL'}) async {
  SharedPreferences.setMockInitialValues({});
  FeedbackService.habilitado = false;
  t.view.physicalSize = telas[tela]! * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final settings = SettingsController();
  await settings.carregar();
  await t.pumpWidget(LanceApp(settings: settings, game: GameController()));
  await esperar(t, 2200);
  await tocar(t, find.text('Novo Jogo'));
  await esperar(t, 900);
  await tocar(t, find.bySemanticsLabel('Modo $modo'));
  await esperar(t, 1200);
  await tocar(t, find.text(tema));
  await esperar(t, 900);
}

Future<void> fechar(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await esperar(t, 7000);
}

void main() {
  setUpAll(carregarFontes);

  group('regras do Impostor', () {
    test('exatamente um impostor; os outros veem o item', () {
      final tema = temaPorId('futebol')!;
      for (var seed = 0; seed < 50; seed++) {
        final r = RodadaImpostor.sortear(tema, 6, random: Random(seed));
        final revelacoes = [for (var i = 0; i < 6; i++) r.revelacaoPara(i)];
        expect(revelacoes.where((x) => x == 'IMPOSTOR').length, 1);
        expect(revelacoes.where((x) => x == r.palavra).length, 5);
        expect(tema.itens, contains(r.palavra));
      }
    });

    test('impostor perde se for votado e ganha se votarem em outro', () {
      const r = RodadaImpostor(palavra: 'Pelé', jogadores: 4, impostor: 2);
      expect(r.impostorGanhou(2), isFalse);
      expect(r.impostorGanhou(0), isTrue);
    });
  });

  test('maletas: 5 itens diferentes do tema', () {
    final tema = temaPorId('futebol')!;
    for (var seed = 0; seed < 30; seed++) {
      final m = sortearMaletas(tema, random: Random(seed));
      expect(m.length, 5);
      expect(m.toSet().length, 5);
      for (final i in m) {
        expect(tema.itens, contains(i));
      }
    }
  });

  for (final tela in telas.keys) {
    for (final pessoas in [3, 5, 10]) {
      testWidgets('fluxo Impostor: $pessoas pessoas, tela $tela', (t) async {
        await abrirModo(t, 'Impostor', tela);
        // Ajusta a quantidade de pessoas (comeca em 4).
        while (int.parse((t.widget(find.byKey(const ValueKey('qtd_impostor'))) as Text).data!) != pessoas) {
          final atual = int.parse((t.widget(find.byKey(const ValueKey('qtd_impostor'))) as Text).data!);
          await tocar(t, find.bySemanticsLabel(atual < pessoas ? 'Mais jogadores' : 'Menos jogadores'));
          await esperar(t, 100);
        }
        await tocar(t, find.text('Começar'));
        await esperar(t, 600);
        var impostores = 0;
        for (var i = 0; i < pessoas; i++) {
          expect(find.text('JOGADOR ${i + 1}'), findsOneWidget);
          await tocar(t, find.text('Ver minha palavra'));
          await esperar(t, 800);
          if (find.text('IMPOSTOR').evaluate().isNotEmpty) impostores++;
          if (tela == 'media' && pessoas == 5 && gerarCapturas && i == 0) {
            await capturar(t, '11_impostor_palavra_$tela');
          }
          await tocar(t, find.text(i + 1 < pessoas ? 'Esconder e passar' : 'Esconder e votar'));
          await esperar(t, 600);
        }
        expect(impostores, 1);
        expect(find.text('HORA DE VOTAR'), findsOneWidget);
        await tocar(t, find.byKey(const ValueKey('voto_0')));
        await esperar(t, 1500);
        expect(find.text('O IMPOSTOR'), findsOneWidget);
        expect(find.text('GANHOU!').evaluate().length + find.text('PERDEU!').evaluate().length, 1);
        if (tela == 'media' && pessoas == 5 && gerarCapturas) {
          await capturar(t, '12_impostor_resultado_$tela');
        }
        await tocar(t, find.text('Jogar de novo'));
        await esperar(t, 600);
        expect(find.text('JOGADOR 1'), findsOneWidget);
        await fechar(t);
      });
    }

    for (final tema in ['FUTEBOL', 'ANIMAIS']) {
      testWidgets('fluxo Maleta ($tema): tela $tela', (t) async {
        await abrirModo(t, 'Maleta', tela, tema: tema);
        await tocar(t, find.text('Começar'));
        await esperar(t, 600);
        // 2 jogadores x 5 = 10 maletas abertas.
        for (var rodada = 0; rodada < 10; rodada++) {
          await tocar(t, find.bySemanticsLabel(RegExp(r'^Abrir maleta')).first);
          await esperar(t, 800);
          if (tema == 'FUTEBOL') {
            if (tela == 'media' && gerarCapturas && rodada == 3) {
              await capturar(t, '13b_maleta_escalar_$tela');
            }
            await tocar(t, find.bySemanticsLabel(RegExp('^Escalar em ')).first);
          } else {
            await tocar(t, find.textContaining('Colocar no time de'));
          }
          await esperar(t, 700);
          if (tela == 'media' && gerarCapturas && tema == 'FUTEBOL' && rodada == 5) {
            await capturar(t, '13_maleta_$tela');
          }
        }
        expect(find.text('TIMES COMPLETOS'), findsOneWidget);
        await tocar(t, find.byKey(const ValueKey('vencedor_1')));
        await esperar(t, 900);
        expect(find.text('CAMPEÃO'), findsOneWidget);
        if (tela == 'media' && gerarCapturas && tema == 'FUTEBOL') await capturar(t, '14_maleta_fim_$tela');
        await tocar(t, find.text('Jogar de novo'));
        await esperar(t, 600);
        expect(find.bySemanticsLabel('Abrir maleta 1'), findsOneWidget);
        await fechar(t);
      });
    }
  }
}
