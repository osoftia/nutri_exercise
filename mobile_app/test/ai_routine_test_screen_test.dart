import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_routine_repository.dart';
import 'package:nutri_mobile_app/core/services/ai_interceptor.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/ai_routine_test_screen.dart';

class _FakeConnectivity extends ConnectivityPlatform {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return const [ConnectivityResult.wifi];
  }
}

void main() {
  setUp(() {
    ConnectivityPlatform.instance = _FakeConnectivity();
  });

  testWidgets('AiRoutineTestScreen generates and renders a routine', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final theme = AppTheme.dark.copyWith(
      splashFactory: NoSplash.splashFactory,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: AiRoutineTestScreen(
          routineRepository: MockRoutineRepository(),
          aiService: AiService(),
        ),
      ),
    );

    expect(find.text('Generate Routine with AI'), findsOneWidget);
    expect(find.text('3 days a week, focus on back and biceps'), findsOneWidget);

    await tester.tap(find.text('Generate Routine with AI'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('Generated Routine'), findsOneWidget);
    expect(
      find.textContaining(
        'Mock AI routine for: 3 days a week, focus on back and biceps',
      ),
      findsOneWidget,
    );
  });
}
