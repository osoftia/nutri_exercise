import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// M48 Task 3: enforces a soft ceiling on file size so the atom -> molecule ->
/// organism -> page layering stays small and cohesive. The limit is generous
/// (400 lines) and only applies to the presentation + state layers, where a
/// bloated file signals missing decomposition.
///
/// When this test fails, split the offending file into smaller, highly
/// cohesive widgets/helpers (see the M48 execution log for the pattern).
void main() {
  const int maxLines = 400;

  /// Paths (relative to `lib/`) that are intentionally large: data payloads,
  /// typed dictionaries and the low-level SQLite helper whose methods are a
  /// flat, cohesive query surface. These are documented exceptions.
  const Set<String> exemptPrefixes = {
    'core/mocks/',
    'core/domain/i18n/',
    'core/database/database_helper.dart',
    'core/services/notification_service.dart',
  };

  test('presentation and state files stay under $maxLines lines', () {
    final libDir = Directory('lib');
    final offenders = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relative = entity.path
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'^lib/'), '');
      if (exemptPrefixes.any(relative.startsWith)) continue;

      // Only guard the UI and state layers; domain/data/models may carry more
      // declarative content.
      final isGuarded = relative.startsWith('ui/') ||
          relative.startsWith('core/state/');
      if (!isGuarded) continue;

      final lines = entity.readAsLinesSync().length;
      if (lines > maxLines) {
        offenders.add('$relative ($lines lines)');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These files exceed $maxLines lines and should be decomposed:\n'
          '${offenders.join('\n')}',
    );
  });
}
