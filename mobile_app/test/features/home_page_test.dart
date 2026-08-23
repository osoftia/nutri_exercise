import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_diet_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_routine_repository.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/home_page.dart';

class _FakeConnectivity extends ConnectivityPlatform {
  _FakeConnectivity(this._results);

  final List<ConnectivityResult> _results;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;
}

class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

void main() {
  setUpAll(() {
    ConnectivityPlatform.instance = _FakeConnectivity([
      ConnectivityResult.wifi,
    ]);
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: HomePage(
          dietRepository: MockDietRepository(),
          routineRepository: MockRoutineRepository(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('tapping a routine schedules a reminder and shows a snackbar', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.text('Monday').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Weekly reminder scheduled for Monday'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
  });
}
