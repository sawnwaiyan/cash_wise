import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/entry.dart';
import '../providers/entry_provider.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/cycle_helper.dart';
import '../widgets/add_entry_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EntryProvider>().loadCycle();
      context.read<BudgetProvider>().loadMonth();
    });
  }

  void _openAddEntry() {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    AppTheme.navyCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddEntrySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.savings_rounded, color: AppTheme.amber, size: 26),
            SizedBox(width: 8),
            Text('CashWise'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _openAddEntry,
        tooltip:   'Add Entry',
        child:     const Icon(Icons.add_rounded, size: 36),
      ),
      body: Consumer2<EntryProvider, BudgetProvider>(
        builder: (context, entry, budget, _) {
          if (entry.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            color:     AppTheme.amber,
            onRefresh: () async {
              await entry.loadCycle();
              await budget.loadMonth();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                _CycleLabelCard(label: entry.currentLabel),
                const SizedBox(height: 12),
                _BudgetProgressCard(budget: budget),
                const SizedBox(height: 12),
                _QuickStatsRow(entry: entry),
                const SizedBox(height: 20),
                _RecentEntriesSection(entry: entry),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Cycle Label Card ──────────────────────────────
class _CycleLabelCard extends StatelessWidget {
  final String label;
  const _CycleLabelCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.amber.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: AppTheme.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              CycleHelper.displayLabel(label),
              style: const TextStyle(
                color:      AppTheme.textPrimary,
                fontSize:   15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        AppTheme.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Current',
                style: TextStyle(
                    color: AppTheme.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Budget Progress Card ──────────────────────────
class _BudgetProgressCard extends StatelessWidget {
  final BudgetProvider budget;
  const _BudgetProgressCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final total     = budget.totalBudget;
    final spent     = budget.totalSpent;
    final ratio     = total == 0 ? 0.0 : (spent / total).clamp(0.0, 1.0);
    final isOver    = total > 0 && spent > total;
    final isNear    = total > 0 && !isOver && ratio >= 0.8;
    final barColor  = isOver ? AppTheme.danger : isNear ? AppTheme.warning : AppTheme.amber;
    final remaining = total - spent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Budget',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text(
                total == 0 ? 'No budget set' : '¥${_fmt(spent)} / ¥${_fmt(total)}',
                style: TextStyle(
                    color: barColor, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:           ratio,
              minHeight:       10,
              backgroundColor: AppTheme.navyLight,
              valueColor:      AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                total == 0
                    ? 'Set budgets in the Budget tab'
                    : isOver
                        ? '¥${_fmt(remaining.abs())} over budget'
                        : '¥${_fmt(remaining)} remaining',
                style: TextStyle(
                    color: total == 0 ? AppTheme.textSecondary : barColor,
                    fontSize: 12),
              ),
              if (total > 0)
                Text(
                  '${(ratio * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: barColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Stats Row ───────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  final EntryProvider entry;
  const _QuickStatsRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon:   Icons.today_rounded,
            label:  "Today's Spend",
            amount: entry.todaySpend,
            color:  AppTheme.amberLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon:   Icons.receipt_long_rounded,
            label:  'Cycle Total',
            amount: entry.cycleTotal,
            color:  AppTheme.amber,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      amount;
  final Color    color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text('¥${_fmt(amount)}',
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ── Recent Entries Section ────────────────────────
class _RecentEntriesSection extends StatelessWidget {
  final EntryProvider entry;
  const _RecentEntriesSection({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.entries.isEmpty) {
      return const _EmptyState();
    }
    final days = entry.sortedDayKeys.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Recent',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
        ),
        ...days.map((day) {
          final dayEntries = entry.groupedByDay[day]!;
          final total      = entry.dailyTotal(day);
          final date       = DateTime.parse(day);
          return _DaySection(date: date, entries: dayEntries, total: total);
        }),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  final DateTime    date;
  final List<Entry> entries;
  final int         total;
  const _DaySection({
    required this.date,
    required this.entries,
    required this.total,
  });

  String _dayLabel() {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const wd = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${wd[date.weekday]} ${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_dayLabel(),
                  style: const TextStyle(
                      color:      AppTheme.textSecondary,
                      fontSize:   12,
                      fontWeight: FontWeight.w600)),
              Text('¥${_fmt(total)}',
                  style: const TextStyle(
                      color:      AppTheme.amber,
                      fontSize:   12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ...entries.map((e) => _EntryRow(entry: e)),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final Entry entry;
  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cat = Categories.byId(entry.categoryId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color:        cat.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(cat.icon, color: cat.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                if (entry.note != null && entry.note!.isNotEmpty)
                  Text(entry.note!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text('¥${_fmt(entry.amount)}',
              style: const TextStyle(
                  color:      AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize:   14)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color:        AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 60, color: AppTheme.amber.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('No entries yet',
              style: TextStyle(
                  color:      AppTheme.textPrimary,
                  fontSize:   16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Tap ＋ to log your first expense',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Number formatter ──────────────────────────────
String _fmt(int n) {
  final s   = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-${buf.toString()}' : buf.toString();
}