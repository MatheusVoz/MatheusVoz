import 'package:material_ui/material_ui.dart';

/// Paleta oficial do LANCE! (tema claro): fundo claro, roxo e amarelo de destaque.
class AppColors {
  AppColors._();

  /// Fundo claro (branco levemente lilas).
  static const fundo = Color(0xFFF7F3FF);

  /// Roxo escuro: textos fortes e texto sobre amarelo.
  static const roxoEscuro = Color(0xFF24104F);

  /// Roxo principal (bordas, detalhes, destaques).
  static const roxo = Color(0xFF7B2FF7);

  /// Amarelo de destaque (botoes principais, selecao, coroa).
  /// O nome "neon" foi mantido para nao quebrar o codigo existente.
  static const neon = Color(0xFFFFC81F);

  /// Amarelo, nome explicito.
  static const amarelo = neon;

  /// Texto secundario (roxo acinzentado).
  static const lilas = Color(0xFF6E5C93);

  /// Texto principal. (O nome "branco" vem da versao escura; no tema claro
  /// e o roxo bem escuro usado em titulos e textos importantes.)
  static const branco = roxoEscuro;

  /// Branco de verdade, para textos sobre fundos roxos.
  static const brancoPuro = Color(0xFFFFFFFF);

  /// Superficie dos cards (branco).
  static const superficie = Color(0xFFFFFFFF);

  /// Superficie levemente lilas (campos, botoes secundarios).
  static const superficieClara = Color(0xFFEFE7FF);

  /// Elementos desativados.
  static const desativado = Color(0xFFB9AFCF);

  /// Alertas.
  static const alerta = Color(0xFFE5395B);

  /// Texto sobre fundo amarelo.
  static const textoSobreAmarelo = roxoEscuro;

  /// Cores atribuidas automaticamente aos jogadores (bem distintas no fundo claro).
  static const coresJogadores = <Color>[
    Color(0xFF7B2FF7), // Roxo
    Color(0xFFF5A300), // Amarelo-ouro
    Color(0xFFE5397F), // Rosa
    Color(0xFF1FA0E0), // Azul
    Color(0xFF20B26B), // Verde
    Color(0xFFFF6B2C), // Laranja
    Color(0xFF9C6BFF), // Lavanda
    Color(0xFF2D3A8C), // Anil
  ];

  /// Gradiente padrao do fundo das telas.
  static const gradienteFundo = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [fundo, fundo],
  );

  /// Gradiente dos botoes principais (amarelo).
  static const gradienteBotao = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neon, neon],
  );

  /// Gradiente roxo (card do item, destaques).
  static const gradienteRoxo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [roxo, roxo],
  );
}
