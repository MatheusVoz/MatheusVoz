import 'package:material_ui/material_ui.dart';

/// Um item arrematado por um jogador.
class Purchase {
  final String item;
  final int preco;

  /// Posicao do item na fila do leilao (para desfazer corretamente).
  final int indiceItem;

  /// Posicao no campinho (indice de Posicao); null = reserva ou tema sem campo.
  int? posicao;

  Purchase({required this.item, required this.preco, required this.indiceItem, this.posicao});

  Map<String, dynamic> toJson() => {'item': item, 'preco': preco, 'indice': indiceItem, 'pos': posicao};

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
    item: j['item'] as String,
    preco: j['preco'] as int,
    indiceItem: j['indice'] as int,
    posicao: j['pos'] as int?,
  );
}

/// Configuracao basica de um jogador (nome e cor), definida antes do leilao.
class PlayerSetup {
  final String nome;
  final int corIndice;

  const PlayerSetup({required this.nome, required this.corIndice});

  Map<String, dynamic> toJson() => {'nome': nome, 'cor': corIndice};

  factory PlayerSetup.fromJson(Map<String, dynamic> j) =>
      PlayerSetup(nome: j['nome'] as String, corIndice: j['cor'] as int);
}

/// Estado de um jogador durante a partida.
class Player {
  final int id;
  final String nome;
  final Color cor;
  int saldo;
  final List<Purchase> compras;

  Player({required this.id, required this.nome, required this.cor, required this.saldo, List<Purchase>? compras})
    : compras = compras ?? [];

  /// Total ja gasto no leilao.
  int get totalGasto => compras.fold(0, (s, c) => s + c.preco);

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'cor': cor.toARGB32(),
    'saldo': saldo,
    'compras': compras.map((c) => c.toJson()).toList(),
  };

  factory Player.fromJson(Map<String, dynamic> j) => Player(
    id: j['id'] as int,
    nome: j['nome'] as String,
    cor: Color(j['cor'] as int),
    saldo: j['saldo'] as int,
    compras: (j['compras'] as List).map((e) => Purchase.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
  );
}
