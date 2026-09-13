import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/state/daily_entry_controller.dart';

class _FakeEntries implements DailyEntryRepository {
  _FakeEntries([Map<String, DailyEntry>? seed]) : _store = {...?seed};

  final Map<String, DailyEntry> _store;
  var failNext = false;

  @override
  Future<DailyEntry?> getByDate(String date) async => _store[date];

  @override
  Future<List<DailyEntry>> getAll() async => _store.values.toList();

  @override
  Future<void> save(DailyEntry entry) async {
    if (failNext) {
      failNext = false;
      throw StateError('save failed');
    }
    _store[entry.date] = entry;
  }

  @override
  Future<void> delete(String date) async {
    if (failNext) {
      failNext = false;
      throw StateError('delete failed');
    }
    _store.remove(date);
  }
}

void main() {
  group('DailyEntryController (M36 Task 3)', () {
    test('loadAll exposes every stored entry', () async {
      final controller = DailyEntryController(
        repository: _FakeEntries({
          '2026-09-10': const DailyEntry(date: '2026-09-10', calories: 500),
          '2026-09-11': const DailyEntry(date: '2026-09-11', calories: 700),
        }),
      );

      await controller.loadAll();

      expect(controller.entries, hasLength(2));
      expect(
        controller.datesWithEntries,
        {'2026-09-10', '2026-09-11'},
      );
    });

    test('save upserts and refreshes the visible list', () async {
      final controller = DailyEntryController(repository: _FakeEntries());
      await controller.loadAll();
      expect(controller.entries, isEmpty);

      final saved = await controller.save(
        const DailyEntry(date: '2026-09-10', calories: 900),
      );

      expect(saved, isTrue);
      expect(controller.entryForDate('2026-09-10')?.calories, 900);
    });

    test('delete removes exactly the requested date', () async {
      final controller = DailyEntryController(
        repository: _FakeEntries({
          '2026-09-10': const DailyEntry(date: '2026-09-10', calories: 500),
          '2026-09-11': const DailyEntry(date: '2026-09-11', calories: 700),
        }),
      );
      await controller.loadAll();

      final deleted = await controller.delete('2026-09-10');

      expect(deleted, isTrue);
      expect(controller.entryForDate('2026-09-10'), isNull);
      // Neighbouring days are untouched.
      expect(controller.entryForDate('2026-09-11')?.calories, 700);
    });

    test('delete of a missing date still succeeds', () async {
      final controller = DailyEntryController(repository: _FakeEntries());
      await controller.loadAll();

      expect(await controller.delete('2026-09-10'), isTrue);
    });

    test('failures return false and surface an error', () async {
      final repo = _FakeEntries();
      final controller = DailyEntryController(repository: repo);
      await controller.loadAll();

      repo.failNext = true;
      expect(
        await controller.save(const DailyEntry(date: '2026-09-10')),
        isFalse,
      );
      expect(controller.error, isNotNull);

      repo.failNext = true;
      expect(await controller.delete('2026-09-10'), isFalse);
      expect(controller.error, isNotNull);
    });

    test('listeners are notified on load, save and delete', () async {
      final controller = DailyEntryController(
        repository: _FakeEntries({
          '2026-09-10': const DailyEntry(date: '2026-09-10'),
        }),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.loadAll();
      expect(notifications, greaterThan(0));

      final beforeSave = notifications;
      await controller.save(const DailyEntry(date: '2026-09-12'));
      expect(notifications, greaterThan(beforeSave));

      final beforeDelete = notifications;
      await controller.delete('2026-09-10');
      expect(notifications, greaterThan(beforeDelete));
    });
  });
}
