import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

/// Network status detector using connectivity_plus
class NetworkDetector {
  NetworkDetector._();

  static final NetworkDetector _instance = NetworkDetector._();
  static NetworkDetector get instance => _instance;

  final Connectivity _connectivity = Connectivity();
  
  StreamController<bool>? _connectionStreamController;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Stream of connection status
  Stream<bool> get connectionStream {
    _connectionStreamController ??= StreamController<bool>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _connectionStreamController!.stream;
  }

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final isConnected = await _checkConnectivity(results);
        _connectionStreamController?.add(isConnected);
        
        AppLogger.info(
          'Network status changed: ${isConnected ? "Connected" : "Disconnected"}',
          tag: 'Network',
        );
      },
    );

    // Check initial status
    checkConnection().then((isConnected) {
      _connectionStreamController?.add(isConnected);
    });
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Check current connection status
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return await _checkConnectivity(results);
    } on Object catch (e) {
      AppLogger.error('Error checking connection', error: e);
      return false;
    }
  }

  Future<bool> _checkConnectivity(List<ConnectivityResult> results) async {
    // If no results or contains none, no connection
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return false;
    }

    // Has mobile or wifi connection
    if (results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi)) {
      return true;
    }

    // Other connection types (ethernet, bluetooth, vpn, etc.)
    return results.isNotEmpty;
  }

  /// Dispose resources
  void dispose() {
    _stopListening();
    _connectionStreamController?.close();
    _connectionStreamController = null;
  }
}
