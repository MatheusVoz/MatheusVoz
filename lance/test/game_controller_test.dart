import 'dart:math';

import 'package:flutter/painting.dart' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:lance/data/themes_data.dart';
import 'package:lance/models/game_config.dart';
import 'package:lance/models/player.dart';
import 'package:lance/state/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameConfig _config(int jogadores, int dinheiro, int lista, {int? itens}) => GameConfig(
  temaId: 'bebidas',
  temaNome: 'Bebidas',
  itensPersonalizados: const [],
  jogadores: [for (var i = 0; i < jogadores; i++) PlayerSetup(nome: 'J${i + 1}', corIndice: i)],
  dinheiroInicial: dinheiro,
  tamanhoLista: lista,
  quantidadeItens: itens ?? GameConfig.padraoItens(jogadores, lista, 50),
);

GameController _novo(GameConfig c, {bool regra = true, int seed = 1}) {
  final g = GameController()
    ..persistir = false
    ..regraReserva = regra;
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

  test('inicio: itens sorteados, sem repeticao, quantidade correta', () {
    final g = _novo(_config(4, 30, 4));
    expect(g.totalItens, 20);
    expect(g.itens.toSet().length, 20);
    expect(g.jogadores.every((j) => j.saldo == 30), isTrue);
  });

  test('lance maximo respeita regra do R\$1 por vaga', () {
    final g = _novo(_config(2, 20, 4));
    final p = g.jogadores.first;
    expect(g.lanceMaximo(p), 17); // 20 - 3 vagas futuras
    g.regraReserva = false;
    expect(g.lanceMaximo(p), 20);
  });

  test('validacoes de venda', () {
    final g = _novo(_config(2, 20, 3));
    expect(g.vender(0, 0).ok, isFalse); // minimo R$1
    expect(g.vender(0, 21).ok, isFalse); // acima do saldo
    expect(g.vender(0, 19).ok, isFalse); // regra de reserva (max 18)
    expect(g.vender(0, 18).ok, isTrue);
    expect(g.jogador(0).saldo, 2);
    expect(g.lanceMaximo(g.jogador(0)), 1);
    expect(g.vender(0, 2).ok, isFalse);
    expect(g.vender(0, 1).ok, isTrue);
    expect(g.vender(0, 1).ok, isTrue);
    expect(g.vagasRestantes(g.jogador(0)), 0);
    expect(g.podeArrematar(g.jogador(0)), isFalse);
    expect(g.motivoBloqueio(g.jogador(0)), 'Lista completa');
    expect(g.vender(0, 1).ok, isFalse); // lista completa
  });

  test('sem a regra, jogador pode gastar tudo e fica desativado sem dinheiro', () {
    final g = _novo(_config(2, 20, 3), regra: false);
    expect(g.vender(0, 20).ok, isTrue);
    expect(g.podeArrematar(g.jogador(0)), isFalse);
    expect(g.motivoBloqueio(g.jogador(0)), 'Sem dinheiro');
    expect(g.leilaoEncerrado, isFalse);
    expect(g.vender(1, 20).ok, isTrue);
    expect(g.leilaoEncerrado, isTrue);
    expect(g.motivoFim, MotivoFim.semDinheiro);
  });

  test('desfazer venda e pulo restaura estado', () {
    final g = _novo(_config(2, 30, 3));
    final item0 = g.itemAtual;
    g.vender(1, 7);
    g.pular();
    expect(g.indiceAtual, 2);
    g.desfazer(); // desfaz pulo
    expect(g.indiceAtual, 1);
    final a = g.desfazer()!; // desfaz venda
    expect(a.venda, isTrue);
    expect(g.indiceAtual, 0);
    expect(g.itemAtual, item0);
    expect(g.jogador(1).saldo, 30);
    expect(g.jogador(1).compras, isEmpty);
    expect(g.podeDesfazer, isFalse);
  });

  test('fim quando acabam os itens', () {
    final g = _novo(_config(2, 20, 3, itens: 6));
    for (var i = 0; i < 6; i++) {
      g.pular();
    }
    expect(g.motivoFim, MotivoFim.semItens);
    expect(g.itemAtual, isNull);
  });

  test('persistencia: salvar e restaurar a partida', () async {
    final g = _novo(_config(4, 50, 5));
    g.vender(2, 10);
    g.pular();
    final json = g.toJson();
    final h = GameController()..persistir = false;
    h.carregarJson(json);
    expect(h.indiceAtual, 2);
    expect(h.jogador(2).saldo, 40);
    expect(h.jogador(2).compras.single.preco, 10);
    expect(h.podeDesfazer, isTrue);
    h.desfazer();
    h.desfazer();
    expect(h.jogador(2).saldo, 50);
  });

  // Simula partidas completas para todas as combinacoes pedidas.
  for (final jogadores in GameConfig.opcoesJogadores) {
    for (final dinheiro in GameConfig.opcoesDinheiro) {
      for (final lista in GameConfig.opcoesLista) {
        for (final regra in [true, false]) {
          test('simulacao: $jogadores jogadores, R\$$dinheiro, lista $lista, regra $regra', () {
            for (var seed = 0; seed < 25; seed++) {
              final rnd = Random(seed);
              final g = _novo(_config(jogadores, dinheiro, lista), regra: regra, seed: seed);
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
                  final max = g.lanceMaximo(p);
                  final valor = 1 + rnd.nextInt(min(max, 1 + dinheiro ~/ lista));
                  expect(g.vender(p.id, valor).ok, isTrue);
                }
                for (final p in g.jogadores) {
                  expect(p.saldo, greaterThanOrEqualTo(0));
                  expect(p.compras.length, lessThanOrEqualTo(lista));
                  expect(p.saldo + p.totalGasto, dinheiro);
                  if (regra) {
                    // Com a regra, o saldo sempre cobre R$1 por vaga restante.
                    expect(p.saldo, greaterThanOrEqualTo(g.vagasRestantes(p)));
                  }
                }
              }
              expect(g.motivoFim, isNotNull);
            }
          });
        }
      }
    }
  }

  test('com a regra e sem pulos, todas as listas fecham', () {
    for (final j in GameConfig.opcoesJogadores) {
      for (final d in GameConfig.opcoesDinheiro) {
        final g = _novo(_config(j, d, 6));
        while (!g.leilaoEncerrado) {
          final p = g.jogadores.firstWhere(g.podeArrematar);
          g.vender(p.id, g.lanceMaximo(p));
        }
        expect(g.motivoFim, MotivoFim.listasCompletas);
        expect(g.jogadores.every((p) => p.compras.length == 6), isTrue);
      }
    }
  });

  test('jogar novamente mantem configuracao e zera estado', () {
    final g = _novo(_config(6, 20, 3));
    g.vender(0, 5);
    g.jogarNovamente(random: Random(9));
    expect(g.jogadores.length, 6);
    expect(g.jogadores.every((p) => p.saldo == 20 && p.compras.isEmpty), isTrue);
    expect(g.indiceAtual, 0);
    expect(g.podeDesfazer, isFalse);
  });

  test('ranking do juiz', () {
    final g = _novo(_config(4, 30, 3));
    g.irParaJuiz();
    expect(g.ranking, [0, 1, 2, 3]);
    g.confirmarRanking([2, 0, 3, 1]);
    expect(g.fase, FasePartida.podio);
    expect(g.ranking.first, 2);
  });

  // Garante que o tipo Player continua serializavel.
  test('player json', () {
    final p = Player(id: 1, nome: 'A', cor: const Color(0xFF8B2CF5), saldo: 3);
    expect(Player.fromJson(p.toJson()).cor, p.cor);
  });
}
