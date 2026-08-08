import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineException implements Exception {
  const OfflineException([this.message = 'No internet connection']);

  final String message;

  @override
  String toString() => message;
}

/// Intercepts AI queries and guards them against missing connectivity.
class AiService {
  AiService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Throws [OfflineException] when the device has no active connection.
  Future<void> ensureOnline() async {
    final results = await _connectivity.checkConnectivity();
    final online = results.any((result) => result != ConnectivityResult.none);
    if (!online) {
      throw const OfflineException();
    }
  }
}
