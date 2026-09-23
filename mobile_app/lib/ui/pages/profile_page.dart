import 'package:flutter/material.dart';

import '../../core/data/daily_entry_repository.dart';
import '../../core/data/notification_prefs_repository.dart';
import '../../core/domain/i18n/app_strings.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/language_controller.dart';
import '../../core/state/symptom_controller.dart';
import '../../core/state/user_profile_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';
import '../molecules/accordion_section.dart';
import '../molecules/language_switcher.dart';
import '../molecules/settings_panel.dart';
import '../molecules/symptom_tracker.dart';
import '../molecules/tests_panel.dart';

/// Profile tab: neumorphic form to view and edit personal details,
/// backed by [UserProfileController] for immediate state reflection, plus the
/// reactive language switcher when a [LanguageController] is provided.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.controller,
    this.languageController,
    this.symptomController,
    this.notificationPrefsRepository,
    this.notificationService,
    this.dailyEntryRepository,
  });

  final UserProfileController controller;

  /// Optional language controller; enables the language switcher.
  final LanguageController? languageController;

  /// Optional symptom controller; enables the Daily Symptoms accordion.
  final SymptomController? symptomController;

  /// Optional prefs store; enables the System Settings accordion.
  final NotificationPrefsRepository? notificationPrefsRepository;

  /// Optional notification service; enables the Pruebas accordion.
  final NotificationService? notificationService;

  /// Optional calendar store; feeds the reactive meal test notification.
  final DailyEntryRepository? dailyEntryRepository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  FitnessGoal _goal = FitnessGoal.muscleGain;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await widget.controller.load();
    final profile = widget.controller.profile;
    if (profile == null || !mounted) return;
    setState(() {
      _nameController.text = profile.name;
      _ageController.text = profile.age.toString();
      _weightController.text = _formatNumber(profile.weightKg);
      _heightController.text = _formatNumber(profile.heightCm);
      _goal = profile.goal;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final profile = UserProfile(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      weightKg: double.parse(_weightController.text.trim()),
      heightCm: double.parse(_heightController.text.trim()),
      goal: _goal,
    );
    await widget.controller.save(profile);
  }

  static String _formatNumber(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizationScope.stringsOf(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        AppHeading(strings.profileTitle, size: AppHeadingSize.h2),
        const SizedBox(height: AppSpacing.xl),
        Center(child: _Avatar(controller: widget.controller)),
        const SizedBox(height: AppSpacing.xl),
        AccordionSection(
          headerKey: const Key('profile_user_settings_accordion'),
          title: strings.userSettingsTitle,
          icon: Icons.person_outline,
          initiallyExpanded: true,
          child: NeumorphicContainer(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildNameField(strings),
                  const SizedBox(height: AppSpacing.lg),
                  _buildAgeField(strings),
                  const SizedBox(height: AppSpacing.lg),
                  _buildWeightField(strings),
                  const SizedBox(height: AppSpacing.lg),
                  _buildHeightField(strings),
                  const SizedBox(height: AppSpacing.lg),
                  _buildGoalField(strings),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSaveButton(strings),
                ],
              ),
            ),
          ),
        ),
        if (widget.symptomController != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AccordionSection(
            headerKey: const Key('profile_symptoms_accordion'),
            title: strings.symptomTrackerTitle,
            subtitle: strings.symptomTrackerSubtitle,
            icon: Icons.healing,
            child: SymptomTracker(controller: widget.symptomController!),
          ),
        ],
        if (widget.notificationPrefsRepository != null ||
            widget.languageController != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AccordionSection(
            headerKey: const Key('profile_settings_accordion'),
            title: strings.systemSettingsTitle,
            icon: Icons.settings,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.notificationPrefsRepository != null)
                  SettingsPanel(
                    prefsRepository: widget.notificationPrefsRepository,
                  ),
                if (widget.languageController != null) ...[
                  if (widget.notificationPrefsRepository != null)
                    const SizedBox(height: AppSpacing.xl),
                  LanguageSwitcher(controller: widget.languageController!),
                ],
              ],
            ),
          ),
        ],
        if (widget.notificationService != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AccordionSection(
            headerKey: const Key('profile_tests_accordion'),
            title: strings.testsSectionTitle,
            icon: Icons.science_outlined,
            child: TestsPanel(
              notificationService: widget.notificationService!,
              dailyEntryRepository: widget.dailyEntryRepository,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNameField(AppStrings strings) {
    return TextFormField(
      key: const Key('profile_name_field'),
      controller: _nameController,
      textInputAction: TextInputAction.next,
      decoration: AppInputDecoration.rounded(label: strings.nameFieldLabel),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return strings.requiredField(strings.nameFieldLabel);
        }
        return null;
      },
    );
  }

  Widget _buildAgeField(AppStrings strings) {
    return TextFormField(
      key: const Key('profile_age_field'),
      controller: _ageController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      decoration: AppInputDecoration.rounded(label: strings.ageFieldLabel),
      validator: (value) =>
          _positiveNumberValidator(strings, value, strings.ageFieldLabel),
    );
  }

  Widget _buildWeightField(AppStrings strings) {
    return TextFormField(
      key: const Key('profile_weight_field'),
      controller: _weightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: AppInputDecoration.rounded(
        label: strings.weightFieldLabel,
        suffix: 'kg',
      ),
      validator: (value) =>
          _positiveNumberValidator(strings, value, strings.weightFieldLabel),
    );
  }

  Widget _buildHeightField(AppStrings strings) {
    return TextFormField(
      key: const Key('profile_height_field'),
      controller: _heightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      decoration: AppInputDecoration.rounded(
        label: strings.heightFieldLabel,
        suffix: 'cm',
      ),
      validator: (value) =>
          _positiveNumberValidator(strings, value, strings.heightFieldLabel),
    );
  }

  Widget _buildGoalField(AppStrings strings) {
    return DropdownButtonFormField<FitnessGoal>(
      key: const Key('profile_goal_field'),
      // ignore: deprecated_member_use
      value: _goal,
      decoration: AppInputDecoration.rounded(label: strings.fitnessGoalLabel),
      items: FitnessGoal.values
          .map(
            (goal) => DropdownMenuItem(
              value: goal,
              child: AppText(strings.fitnessGoal(goal)),
            ),
          )
          .toList(),
      onChanged: (goal) {
        if (goal != null) setState(() => _goal = goal);
      },
    );
  }

  Widget _buildSaveButton(AppStrings strings) {
    return NeumorphicContainer(
      inset: true,
      borderRadius: AppRadius.md,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 48,
        child: TextButton(
          key: const Key('profile_save_button'),
          onPressed: _save,
          child: AppText(strings.saveProfileButton),
        ),
      ),
    );
  }

  String? _positiveNumberValidator(
    AppStrings strings,
    String? value,
    String label,
  ) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return strings.requiredField(label);
    final number = double.tryParse(trimmed);
    if (number == null) return strings.invalidNumberMessage;
    if (number < 1) return strings.minimumOneMessage(label);
    return null;
  }
}

/// Neumorphic avatar whose initials derive from the saved profile name,
/// rebuilding automatically when [UserProfileController] notifies.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.controller});

  final UserProfileController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final name = controller.profile?.name ?? '';
        final initials = _initials(name);
        return NeumorphicContainer(
          borderRadius: 56,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary500,
            child: Text(
              initials,
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

  static String _initials(String name) {
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