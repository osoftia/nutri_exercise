import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_voice_input_service.dart';
import 'package:nutri_mobile_app/core/services/voice_input_service.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/wizard_voice_input_field.dart';

void main() {
  Widget wrap(VoiceInputService service) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Center(child: WizardVoiceInputField(service: service)),
    ),
  );

  group(
    'Scenario 1: Requesting microphone permission on first use',
    () {
      testWidgets(
        'tapping the mic requests permission and enters the listening state',
        (tester) async {
          final service = MockVoiceInputService();
          await tester.pumpWidget(wrap(service));

          expect(find.byKey(const Key('mic_button')), findsOneWidget);

          await tester.tap(find.byKey(const Key('mic_button')));
          await tester.pump();

          expect(service.initializeCalls, 1);
          expect(service.isListening, isTrue);
          expect(find.byKey(const Key('mic_pulsing')), findsOneWidget);
          expect(find.byKey(const Key('listening_label')), findsOneWidget);
          expect(
            tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
            'Listening...',
          );
        },
      );
    },
  );

  group(
    'Scenario 2: Tapping the microphone icon starts listening and updates the UI',
    () {
      testWidgets(
        'shows pulsing glow, Listening text and read-only field, and caches permission',
        (tester) async {
          final service = MockVoiceInputService(transcript: 'Increase my weekly training volume');
          await tester.pumpWidget(wrap(service));

          await tester.tap(find.byKey(const Key('mic_button')));
          await tester.pump();

          expect(find.byKey(const Key('mic_pulsing')), findsOneWidget);
          expect(find.byKey(const Key('listening_label')), findsOneWidget);
          expect(
            tester.widget<TextField>(find.byType(TextField)).readOnly,
            isTrue,
          );

          await tester.tap(find.byKey(const Key('mic_button')));
          await tester.pump();

          expect(service.isListening, isFalse);
          expect(find.byKey(const Key('mic_pulsing')), findsNothing);
          expect(
            tester.widget<TextField>(find.byType(TextField)).readOnly,
            isFalse,
          );

          await tester.tap(find.byKey(const Key('mic_button')));
          await tester.pump();

          expect(service.initializeCalls, 1, reason: 'permission must be cached, no re-prompt');
          expect(find.byKey(const Key('mic_pulsing')), findsOneWidget);
        },
      );
    },
  );

  group(
    'Scenario 3: Converting speech to text and populating the input field',
    () {
      testWidgets(
        'populates the field with the recognized text and returns to idle',
        (tester) async {
          final service = MockVoiceInputService(transcript: 'Increase my weekly training volume');
          await tester.pumpWidget(wrap(service));

          await tester.tap(find.byKey(const Key('mic_button')));
          await tester.pump();

          expect(
            tester.widget<TextField>(find.byType(TextField)).controller?.text,
            'Increase my weekly training volume',
          );

          await tester.tap(find.byKey(const Key('mic_button')));
          await tester.pump();

          expect(service.isListening, isFalse);
          expect(find.byKey(const Key('mic_pulsing')), findsNothing);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller?.text,
            'Increase my weekly training volume',
          );
        },
      );
    },
  );

  group(
    'Scenario 4: Handling microphone permission denial',
    () {
      testWidgets(
        'shows an error, keeps the icon idle and the field editable',
        (tester) async {
          final service = MockVoiceInputService(denyPermission: true);
          await tester.pumpWidget(wrap(service));

          await tester.tap(find.byKey(const Key('mic_button')));
          await tester.pump();

          expect(
            find.text('Microphone permission is required to use voice input'),
            findsOneWidget,
          );
          expect(find.byKey(const Key('mic_pulsing')), findsNothing);
          expect(find.byKey(const Key('listening_label')), findsNothing);
          expect(
            tester.widget<TextField>(find.byType(TextField)).readOnly,
            isFalse,
          );
          expect(
            tester.widget<IconButton>(find.byKey(const Key('mic_button'))).icon,
            isA<Icon>().having((i) => i.icon, 'icon', Icons.mic_none),
          );
        },
      );
    },
  );

  group(
    'Scenario 5: Handling unrecognized speech',
    () {
      testWidgets(
        'shows a retry message and keeps the previous value',
        (tester) async {
          final service = MockVoiceInputService(unrecognized: true);
          await tester.pumpWidget(wrap(service));

          await tester.enterText(find.byType(TextField), 'Previous goal');
          await tester.pump();

          await tester.tap(find.byKey(const Key('mic_button')));
          await tester.pump();
          await tester.tap(find.byKey(const Key('mic_button')));
          await tester.pump();

          expect(
            find.text('Sorry, I did not understand that. Please try again.'),
            findsOneWidget,
          );
          expect(find.byKey(const Key('mic_pulsing')), findsNothing);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller?.text,
            'Previous goal',
          );
        },
      );
    },
  );

  group(
    'Scenario 6: Handling speech recognition errors',
    () {
      testWidgets(
        'shows a failure message and keeps the previous value',
        (tester) async {
          final service = MockVoiceInputService(throwOnListen: true);
          await tester.pumpWidget(wrap(service));

          await tester.enterText(find.byType(TextField), 'Previous goal');
          await tester.pump();

          await tester.tap(find.byKey(const Key('mic_button')));
          await tester.pump();
          await tester.tap(find.byKey(const Key('mic_button')));
          await tester.pump();

          expect(find.text('Voice input failed. Please try again.'), findsOneWidget);
          expect(find.byKey(const Key('mic_pulsing')), findsNothing);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller?.text,
            'Previous goal',
          );
        },
      );
    },
  );
}