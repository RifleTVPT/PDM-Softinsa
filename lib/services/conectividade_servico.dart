import 'package:connectivity_plus/connectivity_plus.dart';

class ConectividadeServico {
  static final ConectividadeServico _instance =
      ConectividadeServico._internal();
  final Connectivity _connectivity = Connectivity();

  factory ConectividadeServico() {
    return _instance;
  }

  ConectividadeServico._internal();

  /// Retorna true se houver qualquer tipo de ligação à Internet (Wi-Fi, Dados Móveis, Ethernet)
  Future<bool> temInternet() async {
    final ConnectivityResult connectivityResult =
        await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged
        .map((result) => result != ConnectivityResult.none);
  }
}
