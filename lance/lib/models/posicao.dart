/// Posicoes do campinho de futebol (5 jogadores, como no jogo da maleta).
/// [x] e [y] sao a posicao da bolinha no campo (0 a 1; y=0 e o ataque, la em cima).
enum Posicao {
  atacante('ATA', 'Atacante', 0.5, 0.13),
  meiaEsquerda('ME', 'Meia esquerda', 0.2, 0.37),
  meiaDireita('MD', 'Meia direita', 0.8, 0.37),
  volante('VOL', 'Volante', 0.5, 0.6),
  goleiro('GOL', 'Goleiro', 0.5, 0.86);

  final String sigla;
  final String nome;
  final double x;
  final double y;
  const Posicao(this.sigla, this.nome, this.x, this.y);

  /// Tema que usa o campinho.
  static const temaFutebol = 'futebol';
}

/// Funcao do jogador de futebol (de onde ele joga de verdade).
enum Funcao {
  goleiro('Goleiro', [Posicao.goleiro]),
  defensor('Defensor', [Posicao.volante]),
  meia('Meia', [Posicao.meiaEsquerda, Posicao.meiaDireita]),
  atacante('Atacante', [Posicao.atacante]);

  final String nome;

  /// Posicoes do campinho que combinam com a funcao.
  final List<Posicao> posicoes;
  const Funcao(this.nome, this.posicoes);
}
