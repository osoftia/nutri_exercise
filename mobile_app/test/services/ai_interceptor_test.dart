import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/services/ai_interceptor.dart';

class _FakeConnectivity extends ConnectivityPlatform {
  _FakeConnectivity(this._results);

  final List<ConnectivityResult> _results;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;
}

void main() {
  group('OfflineException', () {
    test('defaults to a generic message', () {
      const ex = OfflineException();
      expect(ex.message, 'No internet connection');
      expect(ex.toString(), 'No internet connection');
    });

    test('accepts a custom message', () {
      const ex = OfflineException('Airplane mode');
      expect(ex.toString(), 'Airplane mode');
    });
  });

  group('AiService.ensureOnline', () {
    test('resolves when a connection is available', () async {
      ConnectivityPlatform.instance = _FakeConnectivity([
        ConnectivityResult.wifi,
      ]);
      final service = AiService();

      await expectLater(service.ensureOnline(), completes);
    });

    test('throws OfflineException when no connection is available', () async {
      ConnectivityPlatform.instance = _FakeConnectivity([
        ConnectivityResult.none,
      ]);
      final service = AiService();

      await expectLater(
        service.ensureOnline(),
        throwsA(isA<OfflineException>()),
      );
    });
  });
}
