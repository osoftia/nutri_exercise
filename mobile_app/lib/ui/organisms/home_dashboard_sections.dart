import 'package:flutter/material.dart';

import '../../core/models/diet_models.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

/// Compact profile summary shown beside the avatar: weight/height with an edit
/// (pencil) icon. Falls back to the 60 kg / 1.70 m defaults when no profile has
/// been saved.
///
/// Extracted from `home_page.dart` (M48 decomposition) so the dashboard page
/// stays focused on composition.
class ProfileInfoCard extends StatelessWidget {
  /// Creates a profile info card.
  const ProfileInfoCard({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  /// The saved profile, or `null` before one exists.
  final UserProfile? profile;

  /// Invoked when the edit (pencil) icon is tapped.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final weight = profile?.weightKg ?? 60;
    final height = profile?.heightCm ?? 170;
    return Container(
      width: 120,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Profile',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                key: const Key('profile_edit_icon'),
                icon: const Icon(Icons.edit, size: 16),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${weight.toStringAsFixed(0)} kg'),
          Text('${height.toStringAsFixed(0)} cm'),
        ],
      ),
    );
  }
}

/// List of daily menus with their meal count and total calories.
class DailyMenuList extends StatelessWidget {
  /// Creates a daily menu list.
  const DailyMenuList({super.key, required this.menus});

  /// The menus to render.
  final List<DailyMenu> menus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final menu in menus)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              title: AppText(menu.date),
              subtitle: AppCaption('${menu.meals.length} meals'),
              trailing: AppText('${menu.totalCalories} kcal'),
            ),
          ),
      ],
    );
  }
}
