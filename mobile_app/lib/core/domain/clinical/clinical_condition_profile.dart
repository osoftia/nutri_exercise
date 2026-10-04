import 'dart:convert';

import 'clinical_condition.dart';

/// A user's selected conditions, severity levels, and optional demo scenario.
class ClinicalConditionProfile {
  const ClinicalConditionProfile({
    this.conditions = const {},
    this.mockCase = ClinicalMockCase.none,
  });

  final Map<ClinicalCondition, ClinicalSeverity> conditions;
  final ClinicalMockCase mockCase;

  bool get isEmpty => conditions.isEmpty;

  ClinicalSeverity? severityFor(ClinicalCondition condition) =>
      conditions[condition];

  ClinicalConditionProfile copyWith({
    Map<ClinicalCondition, ClinicalSeverity>? conditions,
    ClinicalMockCase? mockCase,
  }) =>
      ClinicalConditionProfile(
        conditions: conditions ?? this.conditions,
        mockCase: mockCase ?? this.mockCase,
      );

  Map<String, Object?> toJson() => {
        'conditions': {
          for (final entry in conditions.entries)
            entry.key.name: entry.value.name,
        },
        'mockCase': mockCase.name,
      };

  String encode() => jsonEncode(toJson());

  static ClinicalConditionProfile decode(String raw) {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return const ClinicalConditionProfile();
    final storedConditions = json['conditions'];
    final conditions = <ClinicalCondition, ClinicalSeverity>{};
    if (storedConditions is Map) {
      for (final entry in storedConditions.entries) {
        final condition = ClinicalCondition.values.where(
          (value) => value.name == entry.key,
        );
        final severity = ClinicalSeverity.values.where(
          (value) => value.name == entry.value,
        );
        if (condition.isNotEmpty && severity.isNotEmpty) {
          conditions[condition.first] = severity.first;
        }
      }
    }
    final mockCaseName = json['mockCase'];
    final mockCase = ClinicalMockCase.values.where(
      (value) => value.name == mockCaseName,
    );
    return ClinicalConditionProfile(
      conditions: conditions,
      mockCase: mockCase.isEmpty ? ClinicalMockCase.none : mockCase.first,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! ClinicalConditionProfile ||
        other.mockCase != mockCase ||
        other.conditions.length != conditions.length) {
      return false;
    }
    return conditions.entries.every(
      (entry) => other.conditions[entry.key] == entry.value,
    );
  }

  @override
  int get hashCode => Object.hash(
        mockCase,
        Object.hashAll(
          conditions.entries
              .map((entry) => Object.hash(entry.key, entry.value)),
        ),
      );
}
