import 'package:flutter/foundation.dart';

import '../constants/muscle_group_map.dart';
import '../data/routine_repository.dart';
import '../models/routine_models.dart';

enum RoutineStatus { idle, loading, loaded, error }

class RoutineProvider extends ChangeNotifier {
  RoutineProvider(this._repository);

  final RoutineRepository _repository;
  List<WorkoutDay> _routine = [];
  WorkoutDay? _selectedDay;
  String? _selectedMuscleRegion;
  RoutineStatus _status = RoutineStatus.idle;
  String? _error;

  List<WorkoutDay> get routine => _routine;
  WorkoutDay? get selectedDay => _selectedDay;
  String? get selectedMuscleRegion => _selectedMuscleRegion;
  RoutineStatus get status => _status;
  String? get error => _error;

  List<Exercise> get selectedDayExercises =>
      _selectedDay?.exercises ?? const [];

  Set<String> get activeMuscleRegions {
    return selectedDayExercises
        .map((e) => muscleGroupToRegion[e.muscleGroup])
        .whereType<String>()
        .toSet();
  }

  Future<void> loadRoutine() async {
    _status = RoutineStatus.loading;
    notifyListeners();
    try {
      _routine = await _repository.getWeeklyRoutine();
      _selectedDay = _routine.isNotEmpty ? _routine.first : null;
      _status = RoutineStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = RoutineStatus.error;
    }
    notifyListeners();
  }

  void selectDay(WorkoutDay day) {
    _selectedDay = day;
    _selectedMuscleRegion = null;
    notifyListeners();
  }

  void selectMuscleRegion(String? region) {
    _selectedMuscleRegion = region;
    notifyListeners();
  }

  List<Exercise> exercisesForRegion(String regionId) {
    return selectedDayExercises
        .where((e) => muscleGroupToRegion[e.muscleGroup] == regionId)
        .toList();
  }
}
