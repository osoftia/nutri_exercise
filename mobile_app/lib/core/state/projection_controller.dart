import 'package:flutter/foundation.dart';

import '../data/projection_repository.dart';
import '../models/projection_models.dart';

/// ChangeNotifier owning the projection plan and the selected milestone.
/// Exposes the avatar's two morph dimensions (shoulder/waist) directly.
class ProjectionController extends ChangeNotifier {
  ProjectionController({required ProjectionRepository repository})
    : _repository = repository;

  final ProjectionRepository _repository;

  ProjectionPlan? _plan;
  int _selectedMonth = 0;
  bool _isLoading = false;

  ProjectionPlan? get plan => _plan;
  int get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;

  ProjectionMilestone? get selectedMilestone =>
      _plan?.milestoneFor(_selectedMonth);

  /// Shoulder morph factor for the selected milestone (baseline `0.5`).
  double get shoulderFactor => selectedMilestone?.shoulderFactor ?? 0.5;

  /// Waist morph factor for the selected milestone (baseline `0.5`).
  double get waistFactor => selectedMilestone?.waistFactor ?? 0.5;

  /// Loads the plan from the repository and notifies.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _plan = await _repository.loadPlan();
    _isLoading = false;
    notifyListeners();
  }

  /// Selects a milestone month (`0`, `1`, `3` or `6`) and notifies.
  void selectMonth(int month) {
    if (_selectedMonth == month) return;
    _selectedMonth = month;
    notifyListeners();
  }
}
