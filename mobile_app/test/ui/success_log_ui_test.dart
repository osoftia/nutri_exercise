import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/success_log_repository.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/domain/i18n/localization_scope.dart';
import 'package:nutri_mobile_app/core/models/success_log_entry.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:nutri_mobile_app/ui/molecules/tests_panel.dart';

class _MemorySuccessLogRepository implements SuccessLogRepository {
  _MemorySuccessLogRepository([List<SuccessLogEntry> initial = const []])
      : entries = [...initial];

  final List<SuccessLogEntry> entries;

  @override
  Future<List<SuccessLogEntry>> getAll() async =>
      entries.reversed.toList(growable: false);

  @override
  Future<void> record(SuccessLogEntry entry) async => entries.add(entry);
}

void main() {
  testWidgets(
      'Pruebas success history shows time, status, URL and raw response body',
      (tester) async {
    final timestamp = DateTime.utc(2026, 10, 6, 14, 22, 31, 456);
    final repository = _MemorySuccessLogRepository([
      SuccessLogEntry(
        id: 3,
        timestamp: timestamp,
        statusCode: '200',
        label: 'clinical_diagnosis',
        requestUrl: 'http://10.0.2.2:5039/api/clinical/diagnosis',
        requestBody: '{"conditions":"diabetes:high","userId":1}',
        responseBody:
            '{"diagnosticReport":"Plan","mealSuggestions":[{"name":"Avena"}]}',
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
                successLogRepository: repository,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings_success_logs_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('success_log_sheet_title')), findsOneWidget);
    expect(find.text('Respuestas exitosas'), findsWidgets);
    expect(find.text('Status: 200'), findsOneWidget);
    expect(find.text('Label: clinical_diagnosis'), findsOneWidget);
    expect(
      find.textContaining('http://10.0.2.2:5039/api/clinical/diagnosis'),
      findsOneWidget,
    );
    expect(
      find.text(timestamp.toLocal().toString().replaceFirst('T', ' ')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('success_log_request_body_3')));
    await tester.pumpAndSettle();
    expect(find.textContaining('"userId":1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('success_log_response_body_3')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('"mealSuggestions":[{"name":"Avena"}]'),
      findsOneWidget,
    );
  });

  testWidgets('success viewer displays a useful empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestsPanel(
            notificationService: NotificationService(),
            successLogRepository: _MemorySuccessLogRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_success_logs_button')));
    await tester.pumpAndSettle();
    expect(
      find.text('No successful responses have been recorded.'),
      findsOneWidget,
    );
  });
}
