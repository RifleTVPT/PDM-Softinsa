import 'package:flutter/foundation.dart';
import 'conectividade_servico.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  bool _isOnline = true;
  int? _idUtilizador;

  bool get isOnline => _isOnline;
  int? get idUtilizador => _idUtilizador;

  AppState() {
    _initConnectivity();
    _loadUserSession();
  }

  void _initConnectivity() {
    ConectividadeServico().temInternet().then((hasNet) {
      _isOnline = hasNet;
      notifyListeners();
    });

    ConectividadeServico().onConnectivityChanged.listen((hasNet) {
      if (_isOnline != hasNet) {
        _isOnline = hasNet;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    _idUtilizador = prefs.getInt('idUtilizador');
    notifyListeners();
  }

  void updateSession(int id) {
    _idUtilizador = id;
    notifyListeners();
  }

  void clearSession() {
    _idUtilizador = null;
    notifyListeners();
  }
}
