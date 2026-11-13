import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias do usuario: som, vibracao e regra do R$1 por vaga.
class SettingsController extends ChangeNotifier {
  static const _kSom = 'cfg_som';
  static const _kVibracao = 'cfg_vibracao';
  static const _kRegra = 'cfg_regra_reserva';

  bool _som = true;
  bool _vibracao = true;
  bool _regraReserva = true;

  bool get som => _som;
  bool get vibracao => _vibracao;

  /// Regra opcional: o jogador precisa guardar R$1 para cada vaga que falta.
  bool get regraReserva => _regraReserva;

  /// Carrega as preferencias salvas.
  Future<void> carregar() async {
    final p = await SharedPreferences.getInstance();
    _som = p.getBool(_kSom) ?? true;
    _vibracao = p.getBool(_kVibracao) ?? true;
    _regraReserva = p.getBool(_kRegra) ?? true;
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

  set regraReserva(bool v) {
    _regraReserva = v;
    _salvar(_kRegra, v);
    notifyListeners();
  }
}
