import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/error_log_repository.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/domain/i18n/localization_scope.dart';
import 'package:nutri_mobile_app/core/models/error_log_entry.dart';
import 'package:nutri_mobile_app/core/services/global_error_handler.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:nutri_mobile_app/ui/molecules/tests_panel.dart';

class _MemoryErrorLogRepository implements ErrorLogRepository {
  _MemoryErrorLogRepository([List<ErrorLogEntry> initial = const []])
      : entries = [...initial];

  final List<ErrorLogEntry> entries;

  @override
  Future<List<ErrorLogEntry>> getAll() async =>
      entries.reversed.toList(growable: false);

  @override
  Future<void> record(ErrorLogEntry entry) async => entries.add(entry);
}

void main() {
  testWidgets('global failure shows a floating Spanish alert and logs details',
      (
    tester,
  ) async {
    final repository = _MemoryErrorLogRepository();
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );
    final handler = GlobalErrorHandler(
      repository: repository,
      showAlert: (message) {
        messengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );

    await handler.capture(
      const SocketException('Connection refused to 127.0.0.1:5039'),
      StackTrace.current,
    );
    await tester.pump();

    expect(
      find.text('En este momento no hay conexión, intente más tarde.'),
      findsOneWidget,
    );
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(repository.entries.single.message, contains('Connection refused'));
    expect(repository.entries.single.stackTrace, isNotEmpty);
  });

  testWidgets('Pruebas error history shows time, code, message and stack', (
    tester,
  ) async {
    final timestamp = DateTime.utc(2026, 10, 6, 14, 22, 31, 456);
    final repository = _MemoryErrorLogRepository([
      ErrorLogEntry(
        id: 7,
        timestamp: timestamp,
        errorCode: '404',
        message: 'HTTP 404 Not Found at /api/clinical/diagnosis',
        stackTrace:
            '#0 AiDiagnosisRepository.generateDiagnosis (test.dart:42:9)',
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: LocalizationScope(
          language: AppLanguage.spanish,
          child: Scaffold(
            body: SingleChildScrollView(
              child: TestsPanel(
                notificationService: NotificationService(),
                errorLogRepository: repository,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings_error_logs_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('error_log_sheet_title')), findsOneWidget);
    expect(find.text('Code: 404'), findsOneWidget);
    expect(find.textContaining('HTTP 404 Not Found'), findsOneWidget);
    expect(
      find.text(timestamp.toLocal().toString().replaceFirst('T', ' ')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('error_log_stack_7')));
    await tester.pumpAndSettle();
    expect(find.textContaining('AiDiagnosisRepository.generateDiagnosis'),
        findsOneWidget);
  });

  testWidgets('error viewer displays a useful empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestsPanel(
            notificationService: NotificationService(),
            errorLogRepository: _MemoryErrorLogRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_error_logs_button')));
    await tester.pumpAndSettle();
    expect(find.text('No errors have been recorded.'), findsOneWidget);
  });
}
