import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/ui/molecules/luna_avatar_switcher.dart';

void main() {
  testWidgets('switches between blueprint and Luna render variants', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LunaAvatarSwitcher(
            blueprint: SizedBox.expand(key: Key('blueprint_body')),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('blueprint_body')), findsOneWidget);
    expect(find.byKey(const Key('luna_avatar_variant_selector')), findsNothing);

    await tester.tap(find.byKey(const Key('luna_avatar_style_toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('blueprint_body')), findsNothing);
    expect(
        find.byKey(const Key('luna_avatar_variant_selector')), findsOneWidget);
    expect(find.byKey(const Key('luna_avatar_asset_pending')), findsOneWidget);

    await tester.tap(find.byKey(const Key('luna_avatar_variant_selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female avatar').last);
    await tester.pumpAndSettle();

    expect(find.text('Female Luna render'), findsOneWidget);
  });
}
