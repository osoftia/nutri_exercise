import 'package:flutter/material.dart';

import '../../core/state/ai_chat_controller.dart';
import '../../core/state/daily_log_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/notification_navigation_controller.dart';
import '../../core/state/nutrition_controller.dart';
import '../../core/state/projection_controller.dart';
import '../../core/state/schedule_controller.dart';
import '../../core/state/user_profile_controller.dart';
import '../atoms/neumorphic_fab.dart';
import '../molecules/ai_chat_sheet.dart';
import '../molecules/daily_log_sheet.dart';
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
    required this.projectionController,
    required this.aiChatController,
    required this.notificationNav,
    required this.dailyLogController,
  });

  final UserProfileController profileController;
  final ScheduleController scheduleController;
  final NutritionController nutritionController;
  final ProjectionController projectionController;
  final AiChatController aiChatController;
  final NotificationNavigationController notificationNav;
  final DailyLogController dailyLogController;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = [
    RoutinesPage(controller: widget.projectionController),
    NutritionPage(controller: widget.nutritionController),
    SchedulePage(controller: widget.scheduleController),
    ProfilePage(controller: widget.profileController),
  ];

  @override
  void initState() {
    super.initState();
    widget.notificationNav.addListener(_onNotificationAction);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingAction());
  }

  @override
  void dispose() {
    widget.notificationNav.removeListener(_onNotificationAction);
    super.dispose();
  }

  void _onNotificationAction() {
    final action = widget.notificationNav.pending;
    if (action == NotificationAction.openDailyLog) {
      widget.notificationNav.consume();
      showDailyLogSheet(context, widget.dailyLogController);
    }
  }

  void _handlePendingAction() {
    if (widget.notificationNav.pending == NotificationAction.openDailyLog) {
      _onNotificationAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _tabs[_currentIndex]),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            key: const Key('daily_log_fab'),
            onPressed: () =>
                showDailyLogSheet(context, widget.dailyLogController),
            backgroundColor: AppColors.primary500,
            foregroundColor: AppColors.textHigh,
            icon: const Icon(Icons.edit_note),
            label: const Text('Daily Log'),
            tooltip: 'Daily Log',
          ),
          const SizedBox(height: AppSpacing.md),
          NeumorphicFab(
            onPressed: () => showAiChatSheet(context, widget.aiChatController),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
      ),
    );
  }
}
