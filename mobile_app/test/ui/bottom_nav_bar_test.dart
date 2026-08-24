import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_container.dart';
import 'package:nutri_mobile_app/ui/organisms/bottom_nav_bar.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrap({int currentIndex = 0, ValueChanged<int>? onSelect}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        bottomNavigationBar: BottomNavBar(
          currentIndex: currentIndex,
          onDestinationSelected: onSelect,
        ),
      ),
    );
  }

  testWidgets('shows exactly the four main tabs', (tester) async {
    await tester.pumpWidget(wrap());

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.destinations, hasLength(4));

    final labels = navBar.destinations
        .map((d) => (d as NavigationDestination).label)
        .toList();
    expect(labels, contains('Routines'));
    expect(labels, contains('Nutrition'));
    expect(labels, contains('Schedule'));
    expect(labels, contains('Profile'));
    expect(labels, isNot(contains('Dashboard')));
  });

  testWidgets('renders the nav bar inside a neumorphic container', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());

    expect(find.byType(NeumorphicContainer), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NeumorphicContainer),
        matching: find.byType(NavigationBar),
      ),
      findsOneWidget,
    );
  });

  testWidgets('reports the selected index via callback', (tester) async {
    int? selected;
    await tester.pumpWidget(wrap(onSelect: (i) => selected = i));

    await tester.tap(find.text('Profile'));
    await tester.pump();

    expect(selected, 3);
  });
}