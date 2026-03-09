import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/cycle_helper.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadMonth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budget, _) {
          if (budget.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            color:     AppTheme.amber,
            onRefresh: () => budget.loadMonth(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                // Month label
                _MonthLabel(label: budget.monthLabel),
                const SizedBox(height: 12),

                // Total summary card
                _TotalSummaryCard(budget: budget),
                const SizedBox(height: 20),

                // Category list header
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('Categories',
                      style: TextStyle(
                          color:      AppTheme.textPrimary,
                          fontSize:   16,
                          fontWeight: FontWeight.w700)),
                ),

                // Per-category rows
                ...budget.statuses.map((s) => _CategoryBudgetCard(
                      status: s,
                      onEdit: () => _openEditSheet(context, budget, s),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openEditSheet(
      BuildContext context, BudgetProvider budget, CategoryBudgetStatus s) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    AppTheme.navyCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BudgetEditSheet(
        status:        s,
        budgetProvider: budget,
      ),
    );
  }
}

// ── Month Label ───────────────────────────────────
class _MonthLabel extends StatelessWidget {
  final String label;
  const _MonthLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppTheme.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded,
              color: AppTheme.amber, size: 18),
          const SizedBox(width: 10),
          Text(
            CycleHelper.displayLabel(label),
            style: const TextStyle(
                color:      AppTheme.textPrimary,
                fontSize:   13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Total Summary Card ────────────────────────────
class _TotalSummaryCard extends StatelessWidget {
  final BudgetProvider budget;
  const _TotalSummaryCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final total    = budget.totalBudget;
    final spent    = budget.totalSpent;
    final ratio    = total == 0 ? 0.0 : (spent / total).clamp(0.0, 1.0);
    final isOver   = total > 0 && spent > total;
    final isNear   = total > 0 && !isOver && ratio >= 0.8;
    final barColor = isOver
        ? AppTheme.danger
        : isNear
            ? AppTheme.warning
            : AppTheme.success;
    final remaining = total - spent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppTheme.navyCard,
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: barColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Budget',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
              if (total > 0)
                _StatusBadge(
                  isOver: isOver,
                  isNear: isNear,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Big spent number
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥${_fmt(spent)}',
                style: TextStyle(
                    color:      barColor,
                    fontSize:   32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
              if (total > 0) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ ¥${_fmt(total)}',
                    style: const TextStyle(
                        color:    AppTheme.textSecondary,
                        fontSize: 15),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:           total == 0 ? 0 : ratio,
              minHeight:       10,
              backgroundColor: AppTheme.navyLight,
              valueColor:      AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 10),

          // Remaining / over
          if (total == 0)
            const Text('Tap any category below to set a budget',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOver
                      ? '¥${_fmt(remaining.abs())} over budget'
                      : '¥${_fmt(remaining)} remaining',
                  style: TextStyle(color: barColor, fontSize: 12),
                ),
                Text(
                  '${(ratio * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color:      barColor,
                      fontSize:   12,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOver;
  final bool isNear;
  const _StatusBadge({required this.isOver, required this.isNear});

  @override
  Widget build(BuildContext context) {
    final color = isOver
        ? AppTheme.danger
        : isNear
            ? AppTheme.warning
            : AppTheme.success;
    final label = isOver ? 'Over Budget' : isNear ? 'Near Limit' : 'On Track';
    final icon  = isOver
        ? Icons.warning_rounded
        : isNear
            ? Icons.error_outline_rounded
            : Icons.check_circle_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color:      color,
                  fontSize:   11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Category Budget Card ──────────────────────────
class _CategoryBudgetCard extends StatelessWidget {
  final CategoryBudgetStatus status;
  final VoidCallback          onEdit;
  const _CategoryBudgetCard({required this.status, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final cat       = status.category;
    final hasbudget = status.budgetAmount > 0;
    final ratio     = status.usageRatio.clamp(0.0, 1.0);
    final barColor  = status.isOverBudget
        ? AppTheme.danger
        : status.isNearLimit
            ? AppTheme.warning
            : cat.color;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin:  const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppTheme.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: status.isOverBudget
              ? Border.all(color: AppTheme.danger.withOpacity(0.4))
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color:        cat.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 20),
                ),
                const SizedBox(width: 12),

                // Name + spent
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.name,
                          style: const TextStyle(
                              color:      AppTheme.textPrimary,
                              fontSize:   14,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        hasbudget
                            ? '¥${_fmt(status.spentAmount)} / ¥${_fmt(status.budgetAmount)}'
                            : '¥${_fmt(status.spentAmount)} spent · No budget',
                        style: TextStyle(
                            color:    hasbudget ? barColor : AppTheme.textSecondary,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Edit icon
                Icon(
                  hasbudget ? Icons.edit_rounded : Icons.add_rounded,
                  color: AppTheme.textSecondary,
                  size:  18,
                ),
              ],
            ),

            // Progress bar (only when budget is set)
            if (hasbudget) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value:           ratio,
                  minHeight:       6,
                  backgroundColor: AppTheme.navyLight,
                  valueColor:      AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),

              // Warning messages
              if (status.isOverBudget || status.isNearLimit) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      status.isOverBudget
                          ? Icons.warning_rounded
                          : Icons.error_outline_rounded,
                      color:  barColor,
                      size:   12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.isOverBudget
                          ? '¥${_fmt(status.remaining.abs())} over budget'
                          : '¥${_fmt(status.remaining)} remaining (${(ratio * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(color: barColor, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ── Budget Edit Sheet ─────────────────────────────
class _BudgetEditSheet extends StatefulWidget {
  final CategoryBudgetStatus status;
  final BudgetProvider        budgetProvider;
  const _BudgetEditSheet({
    required this.status,
    required this.budgetProvider,
  });

  @override
  State<_BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends State<_BudgetEditSheet> {
  late TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = widget.status.budgetAmount;
    _ctrl = TextEditingController(
        text: current > 0 ? current.toString() : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = int.tryParse(_ctrl.text.trim());
    if (raw == null || raw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.budgetProvider.setBudget(
        widget.status.category.id, raw);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _remove() async {
    if (widget.status.budgetAmount == 0) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.navyCard,
        title: const Text('Remove Budget',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Remove the budget for ${widget.status.category.name}?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.budgetProvider.removeBudget(widget.status.category.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat      = widget.status.category;
    final hasbudget = widget.status.budgetAmount > 0;
    final bottom   = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.navyLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Category header
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color:        cat.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: cat.color, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name,
                      style: const TextStyle(
                          color:      AppTheme.textPrimary,
                          fontSize:   17,
                          fontWeight: FontWeight.w700)),
                  Text(
                    'Spent this cycle: ¥${_fmt(widget.status.spentAmount)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Amount input
          TextField(
            controller:      _ctrl,
            autofocus:       true,
            keyboardType:    TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 18),
            decoration: const InputDecoration(
              labelText:   'Monthly Budget (¥)',
              prefixText:  '¥ ',
              prefixStyle: TextStyle(
                  color:      AppTheme.amber,
                  fontWeight: FontWeight.w700,
                  fontSize:   18),
            ),
          ),
          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : Text(hasbudget ? 'Update Budget' : 'Set Budget'),
            ),
          ),

          // Remove button (only when budget already set)
          if (hasbudget) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _remove,
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.danger),
                child: const Text('Remove Budget'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────
String _fmt(int n) {
  final s   = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-${buf.toString()}' : buf.toString();
}