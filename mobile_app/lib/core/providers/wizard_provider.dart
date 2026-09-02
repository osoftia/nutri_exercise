import 'package:flutter/foundation.dart';

import '../data/routine_repository.dart';
import '../models/wizard_models.dart';

enum WizardStatus { editing, generating, generated, error }

class RoutineWizardProvider extends ChangeNotifier {
  RoutineWizardProvider(this._repository);

  final RoutineRepository _repository;

  int _currentStep = 0;
  static const int totalSteps = 4;

  int? _age;
  FitnessGoal? _goal;
  FitnessLevel? _fitnessLevel;
  int? _availableDays;

  WizardStatus _status = WizardStatus.editing;
  String? _generatedText;
  String? _error;

  int get currentStep => _currentStep;
  int? get age => _age;
  FitnessGoal? get goal => _goal;
  FitnessLevel? get fitnessLevel => _fitnessLevel;
  int? get availableDays => _availableDays;
  WizardStatus get status => _status;
  String? get generatedText => _generatedText;
  String? get error => _error;

  double get progress => _currentStep / totalSteps;

  bool get isCurrentStepValid => switch (_currentStep) {
    0 => _age != null && _age! >= 14 && _age! <= 80,
    1 => _goal != null,
    2 => _fitnessLevel != null,
    3 => _availableDays != null && _availableDays! >= 2 && _availableDays! <= 6,
    _ => false,
  };

  bool get canGoForward => isCurrentStepValid && _currentStep < totalSteps;
  bool get canGoBack => _currentStep > 0;
  bool get isOnConfirmStep => _currentStep == totalSteps;

  WizardData? get wizardData {
    if (_age == null ||
        _goal == null ||
        _fitnessLevel == null ||
        _availableDays == null) {
      return null;
    }
    return WizardData(
      age: _age!,
      goal: _goal!,
      fitnessLevel: _fitnessLevel!,
      availableDays: _availableDays!,
    );
  }

  String? get preferencesPreview => wizardData?.toPreferencesString();

  void setAge(int value) {
    _age = value;
    notifyListeners();
  }

  void setGoal(FitnessGoal value) {
    _goal = value;
    notifyListeners();
  }

  void setFitnessLevel(FitnessLevel value) {
    _fitnessLevel = value;
    notifyListeners();
  }

  void setAvailableDays(int value) {
    _availableDays = value;
    notifyListeners();
  }

  void nextStep() {
    if (!isCurrentStepValid) return;
    if (_currentStep < totalSteps) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step < _currentStep) {
      _currentStep = step;
      notifyListeners();
    }
  }

  Future<void> generateRoutine() async {
    final data = wizardData;
    if (data == null) return;

    _status = WizardStatus.generating;
    _error = null;
    notifyListeners();

    try {
      final preferences = data.toPreferencesString();
      _generatedText = await _repository.generateRoutine(preferences);
      _status = WizardStatus.generated;
    } catch (e) {
      _error = e.toString();
      _status = WizardStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    _age = null;
    _goal = null;
    _fitnessLevel = null;
    _availableDays = null;
    _status = WizardStatus.editing;
    _generatedText = null;
    _error = null;
    notifyListeners();
  }
}
