import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'screens/menu_screen.dart';
import 'services/feedback_service.dart';
import 'state/game_controller.dart';
import 'state/settings_controller.dart';
import 'theme/app_theme.dart';

/// Ponto de entrada do LANCE!
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Jogo pensado para celular em pe.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1C0742),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final settings = SettingsController();
  await settings.carregar();
  final game = GameController()..regraReserva = settings.regraReserva;
  await game.restaurar();
  FeedbackService.instancia.conectar(settings);

  runApp(LanceApp(settings: settings, game: game));
}

class LanceApp extends StatelessWidget {
  final SettingsController settings;
  final GameController game;
  const LanceApp({super.key, required this.settings, required this.game});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        // A regra do R$1 por vaga acompanha a configuracao em tempo real.
        ChangeNotifierProxyProvider<SettingsController, GameController>(
          create: (_) => game,
          update: (_, s, g) => g!..regraReserva = s.regraReserva,
        ),
      ],
      child: MaterialApp(
        title: 'LANCE!',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.tema,
        home: const MenuScreen(),
      ),
    );
  }
}
