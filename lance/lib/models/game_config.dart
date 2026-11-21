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

  /// Quantos itens vao a leilao.
  final int quantidadeItens;

  const GameConfig({
    required this.temaId,
    required this.temaNome,
    required this.itensPersonalizados,
    required this.jogadores,
    required this.dinheiroInicial,
    required this.quantidadeItens,
  });

  /// Opcoes oferecidas na tela de configuracao.
  static const opcoesJogadores = [2, 3, 4, 5, 6];
  static const opcoesDinheiro = [20, 30, 50];

  /// Nao ha limite de itens por jogador: cada um arremata quantos conseguir pagar.
  /// Minimo de itens no leilao: 2 por jogador.
  static int minimoItens(int jogadores) => jogadores * 2;

  /// Valor padrao sugerido de itens no leilao (4 por jogador + 4 extras).
  static int padraoItens(int jogadores, int disponiveis) {
    final p = jogadores * 4 + 4;
    return p > disponiveis ? disponiveis : p;
  }

  Map<String, dynamic> toJson() => {
    'temaId': temaId,
    'temaNome': temaNome,
    'itensPersonalizados': itensPersonalizados,
    'jogadores': jogadores.map((j) => j.toJson()).toList(),
    'dinheiroInicial': dinheiroInicial,
    'quantidadeItens': quantidadeItens,
  };

  factory GameConfig.fromJson(Map<String, dynamic> j) => GameConfig(
    temaId: j['temaId'] as String,
    temaNome: j['temaNome'] as String,
    itensPersonalizados: List<String>.from(j['itensPersonalizados'] as List),
    jogadores: (j['jogadores'] as List).map((e) => PlayerSetup.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    dinheiroInicial: j['dinheiroInicial'] as int,
    quantidadeItens: j['quantidadeItens'] as int,
  );
}
