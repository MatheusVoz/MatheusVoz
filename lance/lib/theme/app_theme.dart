import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Tema global do aplicativo.
class AppTheme {
  AppTheme._();

  static ThemeData get tema {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: AppText.fonteTexto,
      scaffoldBackgroundColor: AppColors.fundo,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.roxo,
        secondary: AppColors.neon,
        surface: AppColors.superficie,
        onPrimary: AppColors.branco,
        onSurface: AppColors.lilas,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
    return base.copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.neon,
        selectionColor: Color(0x66FFD23F),
        selectionHandleColor: AppColors.neon,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.superficieClara,
        contentTextStyle: AppText.texto(15, cor: AppColors.branco),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
