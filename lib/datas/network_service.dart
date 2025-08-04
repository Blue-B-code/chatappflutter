import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final _connectivity = Connectivity();

  static Stream<bool> get onNetworkStatusChange async* {
    await for (final result in _connectivity.onConnectivityChanged) {
      yield result != ConnectivityResult.none;
    }
  }

  static Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
