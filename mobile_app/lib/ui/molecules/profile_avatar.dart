import 'package:flutter/material.dart';

import '../../core/state/user_profile_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';

/// Neumorphic avatar whose initials derive from the saved profile name,
/// rebuilding automatically when [UserProfileController] notifies.
///
/// Extracted from `profile_page.dart` (M48 decomposition).
class ProfileAvatar extends StatelessWidget {
  /// Creates a profile avatar bound to [controller].
  const ProfileAvatar({super.key, required this.controller});

  /// Owns the saved profile name.
  final UserProfileController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final name = controller.profile?.name ?? '';
        return NeumorphicContainer(
          borderRadius: 56,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary500,
            child: Text(
              initialsOf(name),
              style: const TextStyle(
                color: AppColors.textHigh,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Derives up-to-two uppercase initials from [name] (`?` when empty).
  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1).toUpperCase();
    if (parts.length == 1) return first;
    return first + parts.last.substring(0, 1).toUpperCase();
  }
}
