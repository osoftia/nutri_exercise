import 'package:flutter/material.dart';

import '../../core/models/user_profile.dart';
import '../../core/state/user_profile_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

/// Profile tab: neumorphic form to view and edit personal details,
/// backed by [UserProfileController] for immediate state reflection.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.controller});

  final UserProfileController controller;

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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const AppHeading('Profile', size: AppHeadingSize.h2),
        const SizedBox(height: AppSpacing.xl),
        Center(child: _Avatar(controller: widget.controller)),
        const SizedBox(height: AppSpacing.xl),
        NeumorphicContainer(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNameField(),
                const SizedBox(height: AppSpacing.lg),
                _buildAgeField(),
                const SizedBox(height: AppSpacing.lg),
                _buildWeightField(),
                const SizedBox(height: AppSpacing.lg),
                _buildHeightField(),
                const SizedBox(height: AppSpacing.lg),
                _buildGoalField(),
                const SizedBox(height: AppSpacing.xl),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      key: const Key('profile_name_field'),
      controller: _nameController,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(labelText: 'Name'),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Name is required';
        }
        return null;
      },
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      key: const Key('profile_age_field'),
      controller: _ageController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(labelText: 'Age'),
      validator: (value) => _positiveNumberValidator(value, 'Age'),
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      key: const Key('profile_weight_field'),
      controller: _weightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Weight',
        suffixText: 'kg',
      ),
      validator: (value) => _positiveNumberValidator(value, 'Weight'),
    );
  }

  Widget _buildHeightField() {
    return TextFormField(
      key: const Key('profile_height_field'),
      controller: _heightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Height',
        suffixText: 'cm',
      ),
      validator: (value) => _positiveNumberValidator(value, 'Height'),
    );
  }

  Widget _buildGoalField() {
    return DropdownButtonFormField<FitnessGoal>(
      key: const Key('profile_goal_field'),
      initialValue: _goal,
      decoration: const InputDecoration(labelText: 'Fitness Goal'),
      items: FitnessGoal.values
          .map(
            (goal) => DropdownMenuItem(
              value: goal,
              child: AppText(goal.label),
            ),
          )
          .toList(),
      onChanged: (goal) {
        if (goal != null) setState(() => _goal = goal);
      },
    );
  }

  Widget _buildSaveButton() {
    return NeumorphicContainer(
      inset: true,
      borderRadius: AppRadius.md,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 48,
        child: TextButton(
          key: const Key('profile_save_button'),
          onPressed: _save,
          child: const AppText('Save Profile'),
        ),
      ),
    );
  }

  String? _positiveNumberValidator(String? value, String label) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$label is required';
    final number = double.tryParse(trimmed);
    if (number == null) return 'Enter a valid number';
    if (number < 1) return '$label must be at least 1';
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