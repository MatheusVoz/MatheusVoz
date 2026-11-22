import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Tema global do aplicativo.
class AppTheme {
  AppTheme._();

  static ThemeData get tema {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: AppText.fonteTexto,
      scaffoldBackgroundColor: AppColors.fundo,
      colorScheme: const ColorScheme.light(
        primary: AppColors.roxo,
        secondary: AppColors.neon,
        surface: AppColors.superficie,
        onPrimary: AppColors.brancoPuro,
        onSurface: AppColors.lilas,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
    return base.copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.roxo,
        selectionColor: Color(0x557B2FF7),
        selectionHandleColor: AppColors.roxo,
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
