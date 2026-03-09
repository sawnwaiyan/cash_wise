import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../models/entry.dart';
import '../utils/cycle_helper.dart';

class EntryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ── State ────────────────────────────────────────

  List<Entry> _entries = [];
  String _currentLabel = CycleHelper.monthLabel(DateTime.now());
  int _todaySpend = 0;
  int _cycleTotal = 0;
  bool _loading = false;

  // ── Getters ──────────────────────────────────────

  List<Entry> get entries => _entries;
  String get currentLabel => _currentLabel;
  int get todaySpend => _todaySpend;
  int get cycleTotal => _cycleTotal;
  bool get loading => _loading;

  /// Entries grouped by date string (yyyy-MM-dd), sorted newest first.
  Map<String, List<Entry>> get groupedByDay {
    final map = <String, List<Entry>>{};
    for (final e in _entries) {
      final key =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-'
          '${e.date.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  /// Sorted date keys (newest first) from [groupedByDay].
  List<String> get sortedDayKeys {
    final keys = groupedByDay.keys.toList();
    keys.sort((a, b) => b.compareTo(a));
    return keys;
  }

  /// Daily subtotal for a given date key.
  int dailyTotal(String dateKey) =>
      (groupedByDay[dateKey] ?? []).fold(0, (sum, e) => sum + e.amount);

  // ── Load ─────────────────────────────────────────

  /// Load (or reload) entries for [label]. Defaults to current cycle.
  Future<void> loadCycle([String? label]) async {
    _loading = true;
    notifyListeners();

    _currentLabel = label ?? CycleHelper.monthLabel(DateTime.now());
    _entries = await _db.getEntriesByCycle(_currentLabel);
    _cycleTotal = await _db.cycleTotalSpend(_currentLabel);
    _todaySpend = await _db.todaySpend();

    _loading = false;
    notifyListeners();
  }

  // ── CRUD ─────────────────────────────────────────

  Future<void> addEntry(Entry entry) async {
    await _db.insertEntry(entry);
    // Only reload if this entry belongs to the currently viewed cycle.
    if (CycleHelper.monthLabel(entry.date) == _currentLabel) {
      await loadCycle(_currentLabel);
    }
  }

  Future<void> updateEntry(Entry entry) async {
    await _db.updateEntry(entry);
    await loadCycle(_currentLabel);
  }

  Future<void> deleteEntry(int id) async {
    await _db.deleteEntry(id);
    await loadCycle(_currentLabel);
  }

  // ── Convenience ──────────────────────────────────

  /// Total spent for a specific category in the current cycle.
  Future<int> categoryTotal(int categoryId) =>
      _db.categoryTotalForCycle(categoryId, _currentLabel);
}