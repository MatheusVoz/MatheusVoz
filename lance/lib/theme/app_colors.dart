import 'package:material_ui/material_ui.dart';

/// Paleta oficial do LANCE!: roxo e preto.
class AppColors {
  AppColors._();

  /// Fundo preto profundo.
  static const fundo = Color(0xFF0A0A0F);

  /// Roxo bem escuro usado nos gradientes do fundo.
  static const roxoEscuro = Color(0xFF1A0B2E);

  /// Roxo principal da marca.
  static const roxo = Color(0xFF8B2CF5);

  /// Roxo neon para destaques e brilhos.
  static const neon = Color(0xFFB266FF);

  /// Lilas claro para textos secundarios.
  static const lilas = Color(0xFFD9B8FF);

  /// Branco, apenas para textos importantes.
  static const branco = Color(0xFFFFFFFF);

  /// Superficie de cards (preto arroxeado).
  static const superficie = Color(0xFF15101F);

  /// Superficie um pouco mais clara.
  static const superficieClara = Color(0xFF221733);

  /// Cinza para elementos desativados.
  static const desativado = Color(0xFF4A4458);

  /// Vermelho-rosado discreto para alertas (sem fugir da paleta).
  static const alerta = Color(0xFFFF5C9E);

  /// Cores de destaque que os jogadores podem escolher (tons de roxo/lilas/violeta).
  static const coresJogadores = <Color>[
    Color(0xFF8B2CF5), // Roxo
    Color(0xFFB266FF), // Neon
    Color(0xFFD9B8FF), // Lilas
    Color(0xFFD946EF), // Magenta
    Color(0xFF6D5BFF), // Indigo
    Color(0xFFF0A6FF), // Orquidea
    Color(0xFFA78BFA), // Lavanda
    Color(0xFF9E00FF), // Violeta eletrico
  ];

  static const nomesCores = <String>[
    'Roxo',
    'Neon',
    'Lilás',
    'Magenta',
    'Índigo',
    'Orquídea',
    'Lavanda',
    'Violeta',
  ];

  /// Gradiente padrao do fundo das telas.
  static const gradienteFundo = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [roxoEscuro, fundo, fundo, Color(0xFF12071F)],
    stops: [0.0, 0.45, 0.75, 1.0],
  );

  /// Gradiente dos botoes principais.
  static const gradienteBotao = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neon, roxo, Color(0xFF6A16C9)],
  );
}
