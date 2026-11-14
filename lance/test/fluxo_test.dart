import 'package:flutter_test/flutter_test.dart';
import 'package:lance/main.dart';
import 'package:lance/services/feedback_service.dart';
import 'package:lance/state/game_controller.dart';
import 'package:lance/state/settings_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<void> jogarPartida(
  WidgetTester t, {
  required int jogadores,
  required int dinheiro,
  required String tela,
  bool capturas = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  FeedbackService.habilitado = false;
  final tamanho = telas[tela]!;
  t.view.physicalSize = tamanho * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);

  final settings = SettingsController();
  await settings.carregar();
  final game = GameController();
  await t.pumpWidget(LanceApp(settings: settings, game: game));
  await esperar(t, 2200);
  if (capturas) await capturar(t, '01_menu_$tela');

  await tocar(t, find.text('Novo Jogo'));
  await esperar(t, 900);
  await tocar(t, find.bySemanticsLabel('Modo Leilão'));
  await esperar(t, 1400);
  if (capturas) await capturar(t, '02_temas_$tela');

  await tocar(t, find.text('BEBIDAS'));
  await esperar(t, 900);
  await tocar(t, find.byKey(ValueKey('jogadores-$jogadores')));
  await tocar(t, find.byKey(ValueKey('dinheiro-$dinheiro')));
  await esperar(t, 900);
  if (jogadores >= 4) {
    // Da um nome ao primeiro jogador para testar o campo.
    await t.enterText(find.byType(TextField).first, 'Ana Beatriz');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await esperar(t, 300);
  }
  if (capturas) await capturar(t, '03_config_$tela');
  await tocar(t, find.text('Começar Leilão'));
  await esperar(t, 1200);

  expect(game.temPartida, isTrue);
  expect(game.jogadores.length, jogadores);
  expect(game.jogadores.every((p) => p.saldo == dinheiro), isTrue);
  if (capturas) await capturar(t, '04_leilao_$tela');

  var vendas = 0;
  var rodada = 0;
  while (!game.leilaoEncerrado) {
    rodada++;
    expect(rodada, lessThan(80), reason: 'leilao nao terminou');
    // A cada 7 itens, pula um.
    if (rodada % 7 == 0) {
      await tocar(t, find.bySemanticsLabel('Ninguém quis / Pular item'));
      await esperar(t, 700);
      continue;
    }
    final apto = game.jogadores.firstWhere(game.podeArrematar);
    await tocar(t, find.byKey(ValueKey('chip_${apto.id}')));
    await esperar(t, 300);
    // Sobe o lance algumas vezes (respeitando o maximo).
    final cliques = rodada % 3;
    for (var i = 0; i < cliques; i++) {
      await tocar(t, find.text('+1'));
    }
    if (capturas && vendas == 1) await capturar(t, '05_lance_$tela');
    final saldoAntes = game.jogador(apto.id).saldo;
    await tocar(t, find.text('VENDIDO!'));
    await esperar(t, 500);
    if (capturas && vendas == 1) await capturar(t, '06_vendido_$tela');
    await esperar(t, 1300);
    vendas++;
    expect(game.jogador(apto.id).saldo, lessThan(saldoAntes));
    // Testa o desfazer uma vez.
    if (vendas == 3) {
      await tocar(t, find.bySemanticsLabel('Desfazer última venda'));
      await esperar(t, 800);
      expect(game.jogador(apto.id).saldo, saldoAntes);
    }
  }
  await esperar(t, 1600);
  expect(find.text('ENCERRADO'), findsOneWidget);
  if (capturas) await capturar(t, '07_encerrado_$tela');

  await tocar(t, find.text('Ver as listas'));
  await esperar(t, 1000);
  expect(game.fase, FasePartida.revisao);
  if (capturas) await capturar(t, '08_revisao_$tela');

  await tocar(t, find.text('Chamar o Juiz'));
  await esperar(t, 1000);
  expect(find.text('Pódio'), findsOneWidget);
  expect(game.fase, FasePartida.juiz);
  // O juiz da 2 pontos ao ultimo jogador: ele sobe para o topo da tabela.
  final ultimo = game.jogadores.last;
  await tocar(t, find.byKey(ValueKey('mais_${ultimo.id}')));
  await esperar(t, 300);
  await tocar(t, find.byKey(ValueKey('mais_${ultimo.id}')));
  await esperar(t, 900);
  expect(game.pontos(ultimo.id), 2);
  expect(game.ranking.first, ultimo.id);
  // E 1 ponto ao primeiro, que fica em segundo.
  await tocar(t, find.byKey(ValueKey('mais_${game.jogadores.first.id}')));
  await esperar(t, 900);
  expect(game.ranking[1], game.jogadores.first.id);
  if (capturas) await capturar(t, '09_podio_$tela');

  // Jogar de novo com as mesmas configuracoes.
  await tocar(t, find.text('Jogar de novo'));
  await esperar(t, 1200);
  expect(game.fase, FasePartida.leilao);
  expect(game.jogadores.length, jogadores);
  expect(game.jogadores.every((p) => p.saldo == dinheiro && p.compras.isEmpty), isTrue);
  // Encerra a arvore para nao deixar timers pendentes.
  await t.pumpWidget(const SizedBox());
  await esperar(t, 7000);
}

void main() {
  setUpAll(carregarFontes);

  for (final tela in telas.keys) {
    for (final j in [2, 4, 6]) {
      for (final d in [20, 30, 50]) {
        testWidgets('fluxo completo: $j jogadores, R\$$d, tela $tela', (t) async {
          await jogarPartida(t, jogadores: j, dinheiro: d, tela: tela);
        });
      }
    }
  }

  testWidgets('capturas de tela', (t) async {
    await jogarPartida(t, jogadores: 6, dinheiro: 30, tela: 'media', capturas: gerarCapturas);
  }, skip: !gerarCapturas);
}
