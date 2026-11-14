import 'dart:math';

import '../data/futebol_posicoes.dart';
import '../widgets/lance_icon.dart';
import 'posicao.dart';
import 'theme_category.dart';

/// Modos de jogo disponiveis.
enum ModoJogo {
  leilao('Leilão', 'Dispute itens com dinheiro fictício', LanceIconType.martelo),
  impostor('Impostor', 'Todos sabem o item, menos um', LanceIconType.mascara),
  maleta('Maleta', 'Abra 5 maletas com itens surpresa', LanceIconType.maleta);

  final String nome;
  final String descricao;
  final LanceIconType icone;
  const ModoJogo(this.nome, this.descricao, this.icone);
}

/// Uma rodada do modo Impostor.
/// Todos veem o mesmo item secreto, exceto o impostor, que ve "IMPOSTOR".
class RodadaImpostor {
  /// Item secreto (ex.: "Ronaldinho").
  final String palavra;

  /// Numero de jogadores.
  final int jogadores;

  /// Indice (0..jogadores-1) de quem e o impostor.
  final int impostor;

  const RodadaImpostor({required this.palavra, required this.jogadores, required this.impostor});

  /// Minimo e maximo de jogadores no modo Impostor.
  static const minimo = 3;
  static const maximo = 10;

  /// Sorteia o item e o impostor.
  factory RodadaImpostor.sortear(ThemeCategory tema, int jogadores, {Random? random}) {
    final r = random ?? Random();
    return RodadaImpostor(
      palavra: tema.itens[r.nextInt(tema.itens.length)],
      jogadores: jogadores,
      impostor: r.nextInt(jogadores),
    );
  }

  /// O que o jogador [indice] ve ao pegar o celular.
  String revelacaoPara(int indice) => indice == impostor ? 'IMPOSTOR' : palavra;

  bool ehImpostor(int indice) => indice == impostor;

  /// O impostor ganha se o grupo votou em outra pessoa.
  bool impostorGanhou(int votado) => votado != impostor;
}

/// Sorteia os itens das maletas (sem repetir).
List<String> sortearMaletas(ThemeCategory tema, {int quantidade = 5, Random? random}) {
  final itens = tema.itens.toSet().toList()..shuffle(random ?? Random());
  return itens.take(quantidade).toList();
}

/// Monta a ordem (sorteada) dos itens de uma partida.
/// No tema Futebol garante pelo menos [goleirosMin] goleiros no meio dos itens,
/// para ninguem ter que colocar um atacante no gol.
List<String> montarBaralho(
  ThemeCategory tema,
  int quantidade, {
  int goleirosMin = 0,
  Set<String> excluir = const {},
  Random? random,
}) {
  final r = random ?? Random();
  final todos = tema.itens.toSet().difference(excluir).toList()..shuffle(r);
  if (tema.id != Posicao.temaFutebol || goleirosMin <= 0) {
    return todos.take(quantidade).toList();
  }
  final goleiros = todos.where((i) => funcaoDe(i) == Funcao.goleiro).toList();
  final outros = todos.where((i) => funcaoDe(i) != Funcao.goleiro).toList();
  final nGol = min(min(goleirosMin, goleiros.length), quantidade);
  final baralho = [
    ...goleiros.take(nGol),
    ...[...outros, ...goleiros.skip(nGol)].take(quantidade - nGol),
  ]..shuffle(r);
  return baralho;
}
