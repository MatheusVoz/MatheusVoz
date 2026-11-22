import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias do usuario: som e vibracao.
class SettingsController extends ChangeNotifier {
  static const _kSom = 'cfg_som';
  static const _kVibracao = 'cfg_vibracao';

  bool _som = true;
  bool _vibracao = true;

  bool get som => _som;
  bool get vibracao => _vibracao;

  /// Carrega as preferencias salvas.
  Future<void> carregar() async {
    final p = await SharedPreferences.getInstance();
    _som = p.getBool(_kSom) ?? true;
    _vibracao = p.getBool(_kVibracao) ?? true;
    notifyListeners();
  }

  Future<void> _salvar(String chave, bool valor) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(chave, valor);
  }

  set som(bool v) {
    _som = v;
    _salvar(_kSom, v);
    notifyListeners();
  }

  set vibracao(bool v) {
    _vibracao = v;
    _salvar(_kVibracao, v);
    notifyListeners();
  }
}
