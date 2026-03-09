import 'package:flutter/foundation.dart' hide Category;

import '../db/database_helper.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../utils/cycle_helper.dart';

/// Holds the budget + spent amount for a single category.
class CategoryBudgetStatus {
  final Category category;
  final int budgetAmount; // 0 = not set
  final int spentAmount;

  const CategoryBudgetStatus({
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
  });

  /// 0.0 – 1.0+ (can exceed 1.0 when over budget).
  double get usageRatio =>
      budgetAmount == 0 ? 0.0 : spentAmount / budgetAmount;

  bool get isOverBudget => budgetAmount > 0 && spentAmount > budgetAmount;

  /// True when usage is at or above 80 % but not yet over budget.
  bool get isNearLimit =>
      budgetAmount > 0 && !isOverBudget && usageRatio >= 0.8;

  int get remaining => budgetAmount - spentAmount;
}

class BudgetProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ── State ────────────────────────────────────────

  String _monthLabel = CycleHelper.monthLabel(DateTime.now());
  List<CategoryBudgetStatus> _statuses = [];
  bool _loading = false;

  // ── Getters ──────────────────────────────────────

  String get monthLabel => _monthLabel;
  List<CategoryBudgetStatus> get statuses => _statuses;
  bool get loading => _loading;

  /// Sum of all set budget amounts for the current month.
  int get totalBudget =>
      _statuses.fold(0, (sum, s) => sum + s.budgetAmount);

  /// Sum of all spent amounts across all categories for the current month.
  int get totalSpent =>
      _statuses.fold(0, (sum, s) => sum + s.spentAmount);

  double get totalUsageRatio =>
      totalBudget == 0 ? 0.0 : totalSpent / totalBudget;

  // ── Load ─────────────────────────────────────────

  /// Load budgets + spent totals for [label]. Defaults to current month.
  Future<void> loadMonth([String? label]) async {
    _loading = true;
    notifyListeners();

    _monthLabel = label ?? CycleHelper.monthLabel(DateTime.now());
    final budgets = await _db.getBudgetsForMonth(_monthLabel);
    final budgetMap = {for (final b in budgets) b.categoryId: b.amount};

    final statuses = <CategoryBudgetStatus>[];
    for (final cat in Categories.all) {
      final spent = await _db.categoryTotalForCycle(cat.id, _monthLabel);
      statuses.add(CategoryBudgetStatus(
        category: cat,
        budgetAmount: budgetMap[cat.id] ?? 0,
        spentAmount: spent,
      ));
    }

    _statuses = statuses;
    _loading = false;
    notifyListeners();
  }

  // ── CRUD ─────────────────────────────────────────

  /// Save (insert or replace) a budget for [categoryId] in the current month.
  Future<void> setBudget(int categoryId, int amount) async {
    final budget = Budget(
      categoryId: categoryId,
      monthLabel: _monthLabel,
      amount: amount,
    );
    await _db.upsertBudget(budget);
    await loadMonth(_monthLabel);
  }

  /// Remove the budget for [categoryId] in the current month.
  Future<void> removeBudget(int categoryId) async {
    await _db.deleteBudget(categoryId, _monthLabel);
    await loadMonth(_monthLabel);
  }

  // ── Convenience ──────────────────────────────────

  /// Get the status for a single category (null-safe).
  CategoryBudgetStatus? statusFor(int categoryId) {
    try {
      return _statuses.firstWhere((s) => s.category.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  /// Refresh spent amounts without reloading budget rows from DB.
  /// Useful when EntryProvider notifies of a new entry.
  Future<void> refreshSpend() => loadMonth(_monthLabel);
}