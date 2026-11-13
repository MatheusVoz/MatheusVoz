import 'player.dart';

/// Configuracao escolhida antes de comecar o leilao.
class GameConfig {
  /// Id do tema escolhido.
  final String temaId;

  /// Nome do tema (guardado para exibicao e para o tema personalizado).
  final String temaNome;

  /// Itens do tema personalizado (vazio para temas prontos).
  final List<String> itensPersonalizados;

  /// Jogadores (nome + cor).
  final List<PlayerSetup> jogadores;

  /// Dinheiro inicial de cada jogador.
  final int dinheiroInicial;

  /// Quantos itens cada jogador pode arrematar.
  final int tamanhoLista;

  /// Quantos itens vao a leilao.
  final int quantidadeItens;

  const GameConfig({
    required this.temaId,
    required this.temaNome,
    required this.itensPersonalizados,
    required this.jogadores,
    required this.dinheiroInicial,
    required this.tamanhoLista,
    required this.quantidadeItens,
  });

  /// Opcoes oferecidas na tela de configuracao.
  static const opcoesJogadores = [2, 4, 6];
  static const opcoesDinheiro = [20, 30, 50];
  static const opcoesLista = [3, 4, 5, 6];

  /// Itens extras somados ao minimo no valor padrao.
  static const extrasPadrao = 4;

  /// Minimo de itens: cada jogador precisa conseguir completar a lista.
  static int minimoItens(int jogadores, int lista) => jogadores * lista;

  /// Valor padrao sugerido de itens no leilao.
  static int padraoItens(int jogadores, int lista, int disponiveis) {
    final p = minimoItens(jogadores, lista) + extrasPadrao;
    return p > disponiveis ? disponiveis : p;
  }

  Map<String, dynamic> toJson() => {
    'temaId': temaId,
    'temaNome': temaNome,
    'itensPersonalizados': itensPersonalizados,
    'jogadores': jogadores.map((j) => j.toJson()).toList(),
    'dinheiroInicial': dinheiroInicial,
    'tamanhoLista': tamanhoLista,
    'quantidadeItens': quantidadeItens,
  };

  factory GameConfig.fromJson(Map<String, dynamic> j) => GameConfig(
    temaId: j['temaId'] as String,
    temaNome: j['temaNome'] as String,
    itensPersonalizados: List<String>.from(j['itensPersonalizados'] as List),
    jogadores: (j['jogadores'] as List)
        .map((e) => PlayerSetup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    dinheiroInicial: j['dinheiroInicial'] as int,
    tamanhoLista: j['tamanhoLista'] as int,
    quantidadeItens: j['quantidadeItens'] as int,
  );
}
