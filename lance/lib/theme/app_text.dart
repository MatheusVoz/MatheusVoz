import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Estilos de texto: Bungee para titulos e numeros, Fredoka para o resto.
class AppText {
  AppText._();

  static const fonteTitulo = 'Bungee';
  static const fonteTexto = 'Fredoka';

  /// Titulo gigante (logo, telas de impacto).
  static TextStyle titulo(double tamanho, {Color cor = AppColors.branco}) =>
      TextStyle(fontFamily: fonteTitulo, fontSize: tamanho, color: cor, height: 1.1, letterSpacing: 0.5);

  /// Numero em destaque (dinheiro, contadores).
  static TextStyle numero(double tamanho, {Color cor = AppColors.branco}) => titulo(tamanho, cor: cor);

  /// Texto padrao.
  static TextStyle texto(double tamanho, {Color cor = AppColors.lilas, FontWeight peso = FontWeight.w600}) =>
      TextStyle(fontFamily: fonteTexto, fontSize: tamanho, color: cor, fontWeight: peso, height: 1.25);

  /// Texto de botao.
  static TextStyle botao(double tamanho, {Color cor = AppColors.branco}) => TextStyle(
    fontFamily: fonteTexto,
    fontSize: tamanho,
    color: cor,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  /// Sombra de brilho neon para textos.
  static const brilho = [
    Shadow(color: AppColors.neon, blurRadius: 18),
    Shadow(color: AppColors.roxo, blurRadius: 36),
  ];
}
