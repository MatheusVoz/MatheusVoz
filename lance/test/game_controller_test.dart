import 'dart:math';

import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:lance/data/themes_data.dart';
import 'package:lance/models/game_config.dart';
import 'package:lance/models/player.dart';
import 'package:lance/state/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameConfig _config(int jogadores, int dinheiro, {int? itens}) => GameConfig(
  temaId: 'bebidas',
  temaNome: 'Bebidas',
  itensPersonalizados: const [],
  jogadores: [for (var i = 0; i < jogadores; i++) PlayerSetup(nome: 'J${i + 1}', corIndice: i)],
  dinheiroInicial: dinheiro,
  quantidadeItens: itens ?? GameConfig.padraoItens(jogadores, 50),
);

GameController _novo(GameConfig c, {int seed = 1}) {
  final g = GameController()..persistir = false;
  g.iniciar(c, temaPorId(c.temaId)!, random: Random(seed));
  return g;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('todos os temas prontos tem pelo menos 40 itens unicos e sem emojis', () {
    final emoji = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
    expect(temasProntos.length, 8);
    for (final t in temasProntos) {
      expect(t.itens.toSet().length, greaterThanOrEqualTo(40), reason: t.nome);
      expect(t.itens.toSet().length, t.itens.length, reason: 'itens repetidos em ${t.nome}');
      for (final i in t.itens) {
        expect(emoji.hasMatch(i), isFalse, reason: i);
      }
    }
  });

  test('futebol tem apenas jogadores (sem times)', () {
    final futebol = temaPorId('futebol')!.itens;
    for (final time in ['Flamengo', 'Corinthians', 'Palmeiras', 'Real Madrid', 'Barcelona', 'Liverpool']) {
      expect(futebol, isNot(contains(time)));
    }
  });

  test('inicio: itens sorteados, sem repeticao, quantidade correta', () {
    final g = _novo(_config(4, 30));
    expect(g.totalItens, 20);
    expect(g.itens.toSet().length, 20);
    expect(g.jogadores.every((j) => j.saldo == 30), isTrue);
  });

  test('pode dar lance com todo o dinheiro, mesmo no primeiro item', () {
    final g = _novo(_config(2, 20));
    final p = g.jogadores.first;
    expect(g.lanceMaximo(p), 20);
    expect(g.vender(0, 20).ok, isTrue);
    expect(g.jogador(0).saldo, 0);
  });

  test('exemplo do Iniesta: os dois com R\$3, um da R\$3 e leva', () {
    final g = _novo(_config(2, 20));
    g.vender(0, 17);
    g.vender(1, 17);
    expect(g.jogador(0).saldo, 3);
    expect(g.jogador(1).saldo, 3);
    expect(g.vender(1, 3).ok, isTrue);
    expect(g.jogador(1).saldo, 0);
  });

  test('validacoes de venda: minimo R\$1 e nunca acima do saldo', () {
    final g = _novo(_config(2, 20));
    expect(g.vender(0, 0).ok, isFalse);
    expect(g.vender(0, 21).ok, isFalse);
    expect(g.vender(0, 5).ok, isTrue);
    expect(g.vender(0, 16).ok, isFalse); // so tem 15
    expect(g.vender(0, 15).ok, isTrue);
  });

  test('sem limite de itens por jogador', () {
    final g = _novo(_config(2, 50, itens: 20));
    for (var i = 0; i < 12; i++) {
      expect(g.vender(0, 1).ok, isTrue);
    }
    expect(g.jogador(0).compras.length, 12);
    expect(g.podeArrematar(g.jogador(0)), isTrue);
  });

  test('jogador sem dinheiro fica desativado; fim quando todos ficam sem', () {
    final g = _novo(_config(2, 20));
    expect(g.vender(0, 20).ok, isTrue);
    expect(g.podeArrematar(g.jogador(0)), isFalse);
    expect(g.motivoBloqueio(g.jogador(0)), 'Sem dinheiro');
    expect(g.leilaoEncerrado, isFalse);
    expect(g.vender(1, 20).ok, isTrue);
    expect(g.motivoFim, MotivoFim.semDinheiro);
  });

  test('fim quando acabam os itens', () {
    final g = _novo(_config(2, 20, itens: 6));
    for (var i = 0; i < 6; i++) {
      g.pular();
    }
    expect(g.motivoFim, MotivoFim.semItens);
    expect(g.itemAtual, isNull);
  });

  test('desfazer venda e pulo restaura estado', () {
    final g = _novo(_config(2, 30));
    final item0 = g.itemAtual;
    g.vender(1, 7);
    g.pular();
    expect(g.indiceAtual, 2);
    g.desfazer();
    expect(g.indiceAtual, 1);
    final a = g.desfazer()!;
    expect(a.venda, isTrue);
    expect(g.indiceAtual, 0);
    expect(g.itemAtual, item0);
    expect(g.jogador(1).saldo, 30);
    expect(g.jogador(1).compras, isEmpty);
    expect(g.podeDesfazer, isFalse);
  });

  test('persistencia: salvar e restaurar a partida', () {
    final g = _novo(_config(4, 50));
    g.vender(2, 10);
    g.pular();
    final h = GameController()..persistir = false;
    h.carregarJson(g.toJson());
    expect(h.indiceAtual, 2);
    expect(h.jogador(2).saldo, 40);
    expect(h.jogador(2).compras.single.preco, 10);
    h.desfazer();
    h.desfazer();
    expect(h.jogador(2).saldo, 50);
  });

  test('partida salva por versao antiga (com tamanhoLista) ainda abre', () {
    final g = _novo(_config(2, 20));
    final json = g.toJson();
    (json['config'] as Map<String, dynamic>)['tamanhoLista'] = 4;
    final h = GameController()..persistir = false;
    h.carregarJson(json);
    expect(h.jogadores.length, 2);
  });

  // Simula partidas completas para todas as combinacoes pedidas.
  for (final jogadores in GameConfig.opcoesJogadores) {
    for (final dinheiro in GameConfig.opcoesDinheiro) {
      test('simulacao: $jogadores jogadores, R\$$dinheiro', () {
        for (var seed = 0; seed < 40; seed++) {
          final rnd = Random(seed);
          final g = _novo(_config(jogadores, dinheiro), seed: seed);
          var passos = 0;
          while (!g.leilaoEncerrado) {
            passos++;
            expect(passos, lessThan(500));
            final aptos = g.jogadores.where(g.podeArrematar).toList();
            expect(aptos, isNotEmpty);
            final acao = rnd.nextInt(10);
            if (acao == 0) {
              g.pular();
            } else if (acao == 1 && g.podeDesfazer) {
              g.desfazer();
            } else {
              final p = aptos[rnd.nextInt(aptos.length)];
              // As vezes vai com tudo, as vezes um valor qualquer.
              final valor = rnd.nextInt(4) == 0 ? p.saldo : 1 + rnd.nextInt(p.saldo);
              expect(g.vender(p.id, valor).ok, isTrue);
            }
            for (final p in g.jogadores) {
              expect(p.saldo, greaterThanOrEqualTo(0));
              expect(p.saldo + p.totalGasto, dinheiro);
            }
          }
          expect(g.motivoFim, isNotNull);
        }
      });
    }
  }

  test('jogar novamente mantem configuracao e zera estado', () {
    final g = _novo(_config(6, 20));
    g.vender(0, 5);
    g.jogarNovamente(random: Random(9));
    expect(g.jogadores.length, 6);
    expect(g.jogadores.every((p) => p.saldo == 20 && p.compras.isEmpty), isTrue);
    expect(g.indiceAtual, 0);
    expect(g.podeDesfazer, isFalse);
  });

  test('ranking do juiz por pontos', () {
    final g = _novo(_config(4, 30));
    g.irParaJuiz();
    expect(g.fase, FasePartida.juiz);
    expect(g.ranking, [0, 1, 2, 3]);
    g.darPonto(2, 1);
    g.darPonto(2, 1);
    g.darPonto(3, 1);
    expect(g.ranking, [2, 3, 0, 1]);
    g.darPonto(3, 2);
    expect(g.ranking.first, 3);
    g.darPonto(1, -1);
    expect(g.pontos(1), 0);
    final h = GameController()..persistir = false;
    h.carregarJson(g.toJson());
    expect(h.pontos(3), 3);
    expect(h.ranking.first, 3);
    g.jogarNovamente();
    expect(g.pontos(3), 0);
  });

  test('player json', () {
    final p = Player(id: 1, nome: 'A', cor: const Color(0xFF8B2CF5), saldo: 3);
    expect(Player.fromJson(p.toJson()).cor, p.cor);
  });
}
