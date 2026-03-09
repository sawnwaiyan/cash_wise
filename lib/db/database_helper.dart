import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/entry.dart';
import '../models/budget.dart';
import '../utils/cycle_helper.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'cashwise.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        date        TEXT    NOT NULL,
        category_id INTEGER NOT NULL,
        amount      INTEGER NOT NULL,
        note        TEXT,
        created_at  TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id  INTEGER NOT NULL,
        month_label  TEXT    NOT NULL,
        amount       INTEGER NOT NULL,
        UNIQUE(category_id, month_label)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_entries_date ON entries (date)',
    );
  }

  // ── Entries ──────────────────────────────────────

  Future<int> insertEntry(Entry entry) async {
    final db = await database;
    return db.insert('entries', entry.toMap());
  }

  Future<int> updateEntry(Entry entry) async {
    final db = await database;
    return db.update('entries', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Entry>> getEntriesByCycle(String label) async {
    final db           = await database;
    final (start, end) = CycleHelper.rangeForLabel(label);
    final maps = await db.query(
      'entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [_fmt(start), _fmt(end)],
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map(Entry.fromMap).toList();
  }

  Future<int> categoryTotalForCycle(int categoryId, String label) async {
    final db           = await database;
    final (start, end) = CycleHelper.rangeForLabel(label);
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM entries
      WHERE category_id = ? AND date >= ? AND date <= ?
    ''', [categoryId, _fmt(start), _fmt(end)]);
    return (result.first['total'] as num).toInt();
  }

  Future<int> cycleTotalSpend(String label) async {
    final db           = await database;
    final (start, end) = CycleHelper.rangeForLabel(label);
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM entries
      WHERE date >= ? AND date <= ?
    ''', [_fmt(start), _fmt(end)]);
    return (result.first['total'] as num).toInt();
  }

  Future<int> todaySpend() async {
    final db     = await database;
    final today  = _fmt(DateTime.now());
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM entries WHERE date = ?',
      [today],
    );
    return (result.first['total'] as num).toInt();
  }

  // ── Budgets ──────────────────────────────────────

  Future<void> upsertBudget(Budget budget) async {
    final db = await database;
    await db.insert('budgets', budget.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Budget>> getBudgetsForMonth(String monthLabel) async {
    final db   = await database;
    final maps = await db.query('budgets',
        where: 'month_label = ?', whereArgs: [monthLabel]);
    return maps.map(Budget.fromMap).toList();
  }

  Future<Budget?> getBudget(int categoryId, String monthLabel) async {
    final db   = await database;
    final maps = await db.query('budgets',
        where: 'category_id = ? AND month_label = ?',
        whereArgs: [categoryId, monthLabel],
        limit: 1);
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  Future<int> deleteBudget(int categoryId, String monthLabel) async {
    final db = await database;
    return db.delete('budgets',
        where: 'category_id = ? AND month_label = ?',
        whereArgs: [categoryId, monthLabel]);
  }

  // ── Helper ───────────────────────────────────────

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}