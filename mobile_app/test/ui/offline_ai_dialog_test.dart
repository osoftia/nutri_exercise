import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/ui/molecules/offline_ai_dialog.dart';

void main() {
  testWidgets('renders the offline message and closes', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OfflineAiDialog()));

    expect(find.text('Offline AI'), findsOneWidget);
    expect(
      find.text('To consult the AI, please connect to the internet.'),
      findsOneWidget,
    );
    expect(find.text('Got it'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
  });

  testWidgets('showOfflineAiDialog opens the dialog', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

    showOfflineAiDialog(tester.element(find.byType(SizedBox)));
    await tester.pumpAndSettle();

    expect(find.text('Offline AI'), findsOneWidget);
  });
}
