import 'package:flutter/material.dart';

import '../../core/state/nutrition_controller.dart';
import '../../core/state/schedule_controller.dart';
import '../../core/state/user_profile_controller.dart';
import '../organisms/bottom_nav_bar.dart';
import 'nutrition_page.dart';
import 'profile_page.dart';
import 'routines_page.dart';
import 'schedule_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({
    super.key,
    required this.profileController,
    required this.scheduleController,
    required this.nutritionController,
  });

  final UserProfileController profileController;
  final ScheduleController scheduleController;
  final NutritionController nutritionController;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = [
    const RoutinesPage(),
    NutritionPage(controller: widget.nutritionController),
    SchedulePage(controller: widget.scheduleController),
    ProfilePage(controller: widget.profileController),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _tabs[_currentIndex]),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
      ),
    );
  }
}