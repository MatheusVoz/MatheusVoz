import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../state/settings_controller.dart';

/// Efeitos sonoros disponiveis.
enum Som { martelo, moeda, fanfarra, toque }

/// Toca sons curtos e vibra, respeitando as configuracoes do usuario.
class FeedbackService {
  FeedbackService._();
  static final instancia = FeedbackService._();

  /// Pode ser desligado em testes automatizados (sem plugin de audio).
  static bool habilitado = true;

  SettingsController? _settings;
  final Map<Som, AudioPlayer> _players = {};

  void conectar(SettingsController s) => _settings = s;

  String _arquivo(Som s) => switch (s) {
    Som.martelo => 'sounds/martelo.wav',
    Som.moeda => 'sounds/moeda.wav',
    Som.fanfarra => 'sounds/fanfarra.wav',
    Som.toque => 'sounds/toque.wav',
  };

  /// Toca um som (se o som estiver ligado).
  Future<void> tocar(Som s) async {
    if (!habilitado || !(_settings?.som ?? true)) return;
    try {
      final player = _players.putIfAbsent(s, () => AudioPlayer());
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource(_arquivo(s)), volume: 1.0);
    } catch (_) {
      // Falha de audio nunca deve travar o jogo.
    }
  }

  /// Vibracao forte (venda).
  Future<void> vibrarForte() async {
    if (!habilitado || !(_settings?.vibracao ?? true)) return;
    try {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  /// Vibracao leve (toques em botoes).
  Future<void> vibrarLeve() async {
    if (!habilitado || !(_settings?.vibracao ?? true)) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
