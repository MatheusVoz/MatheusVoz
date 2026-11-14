import 'package:material_ui/material_ui.dart';

/// Paleta oficial do LANCE!: roxo, amarelo e branco.
/// Fundo roxo, destaques e botoes principais em amarelo, textos em branco.
class AppColors {
  AppColors._();

  /// Fundo roxo profundo.
  static const fundo = Color(0xFF2A0D5E);

  /// Roxo mais escuro usado nos gradientes do fundo e como texto sobre amarelo.
  static const roxoEscuro = Color(0xFF1C0742);

  /// Roxo principal (cards, botoes secundarios, bordas).
  static const roxo = Color(0xFF7B2FF7);

  /// Amarelo de destaque (brilhos, selecao, botoes principais).
  /// O nome "neon" foi mantido para nao quebrar o codigo existente.
  static const neon = Color(0xFFFFD23F);

  /// Amarelo, nome explicito.
  static const amarelo = neon;

  /// Texto secundario: branco levemente lilas.
  static const lilas = Color(0xFFE9DEFF);

  /// Branco para textos principais.
  static const branco = Color(0xFFFFFFFF);

  /// Superficie dos cards.
  static const superficie = Color(0xFF3B1680);

  /// Superficie um pouco mais clara.
  static const superficieClara = Color(0xFF4A1F9A);

  /// Elementos desativados.
  static const desativado = Color(0xFF6E5A96);

  /// Alertas.
  static const alerta = Color(0xFFFF6B8B);

  /// Texto sobre fundo amarelo.
  static const textoSobreAmarelo = roxoEscuro;

  /// Cores de destaque que os jogadores podem escolher (amarelos, brancos e lilases).
  static const coresJogadores = <Color>[
    Color(0xFFFFD23F), // Amarelo
    Color(0xFFFFFFFF), // Branco
    Color(0xFFC9A7FF), // Lilas
    Color(0xFFFFA62B), // Ouro
    Color(0xFF9F7BFF), // Lavanda
    Color(0xFFFFF09A), // Creme
    Color(0xFFE77BFF), // Rosa-violeta
    Color(0xFF7FE0FF), // Azul-claro
  ];

  static const nomesCores = <String>[
    'Amarelo',
    'Branco',
    'Lilás',
    'Ouro',
    'Lavanda',
    'Creme',
    'Rosa',
    'Azul',
  ];

  /// Gradiente padrao do fundo das telas.
  static const gradienteFundo = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4A1A9E), fundo, fundo, roxoEscuro],
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  /// Gradiente dos botoes principais (amarelo).
  static const gradienteBotao = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE57A), neon, Color(0xFFFFB800)],
  );
}
