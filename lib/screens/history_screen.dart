import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/entry.dart';
import '../providers/entry_provider.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/cycle_helper.dart';
import '../widgets/add_entry_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late String _selectedLabel;
  late List<String> _availableLabels;

  @override
  void initState() {
    super.initState();
    _availableLabels = CycleHelper.recentLabels(count: 24);
    _selectedLabel   = _availableLabels.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EntryProvider>().loadCycle(_selectedLabel);
    });
  }

  void _switchCycle(String label) {
    if (label == _selectedLabel) return;
    setState(() => _selectedLabel = label);
    context.read<EntryProvider>().loadCycle(label);
  }

  void _openMonthPicker() {
    showModalBottomSheet(
      context:         context,
      backgroundColor: AppTheme.navyCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MonthPickerSheet(
        labels:        _availableLabels,
        selectedLabel: _selectedLabel,
        onSelected:    (l) {
          Navigator.pop(context);
          _switchCycle(l);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          TextButton.icon(
            onPressed: _openMonthPicker,
            icon: const Icon(Icons.calendar_month_rounded,
                color: AppTheme.amber, size: 18),
            label: Text(
              _monthShort(_selectedLabel),
              style: const TextStyle(color: AppTheme.amber, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Consumer<EntryProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Cycle header
          return Column(
            children: [
              _CycleHeader(label: _selectedLabel, total: provider.cycleTotal),
              Expanded(
                child: provider.entries.isEmpty
                    ? const _EmptyState()
                    : _EntryList(provider: provider),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Cycle Header ──────────────────────────────────
class _CycleHeader extends StatelessWidget {
  final String label;
  final int    total;
  const _CycleHeader({required this.label, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppTheme.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              color: AppTheme.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              CycleHelper.displayLabel(label),
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '¥${_fmt(total)}',
            style: const TextStyle(
                color:      AppTheme.amber,
                fontSize:   15,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ── Entry List ────────────────────────────────────
class _EntryList extends StatelessWidget {
  final EntryProvider provider;
  const _EntryList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final days = provider.sortedDayKeys;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final day     = days[i];
        final entries = provider.groupedByDay[day]!;
        final total   = provider.dailyTotal(day);
        final date    = DateTime.parse(day);
        return _DayGroup(date: date, entries: entries, dailyTotal: total);
      },
    );
  }
}

// ── Day Group ─────────────────────────────────────
class _DayGroup extends StatelessWidget {
  final DateTime    date;
  final List<Entry> entries;
  final int         dailyTotal;
  const _DayGroup({
    required this.date,
    required this.entries,
    required this.dailyTotal,
  });

  String _dayLabel() {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const wd = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${wd[date.weekday]}, ${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_dayLabel(),
                  style: const TextStyle(
                      color:      AppTheme.textSecondary,
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              Text('¥${_fmt(dailyTotal)}',
                  style: const TextStyle(
                      color:      AppTheme.amber,
                      fontSize:   12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),

        // Entry cards
        Container(
          decoration: BoxDecoration(
            color:        AppTheme.navyCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: entries.asMap().entries.map((mapEntry) {
              final idx   = mapEntry.key;
              final entry = mapEntry.value;
              return Column(
                children: [
                  _EntryTile(entry: entry),
                  if (idx < entries.length - 1)
                    const Divider(
                        indent: 62, endIndent: 16, height: 1),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Entry Tile ────────────────────────────────────
class _EntryTile extends StatelessWidget {
  final Entry entry;
  const _EntryTile({required this.entry});

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context:         context,
      backgroundColor: AppTheme.navyCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EntryOptions(entry: entry, parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = Categories.byId(entry.categoryId);

    return InkWell(
      onTap:         () => _showOptions(context),
      borderRadius:  BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color:        cat.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
            const SizedBox(width: 12),

            // Name + note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name,
                      style: const TextStyle(
                          color:      AppTheme.textPrimary,
                          fontSize:   14,
                          fontWeight: FontWeight.w500)),
                  if (entry.note != null && entry.note!.isNotEmpty)
                    Text(entry.note!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // Amount
            Text('¥${_fmt(entry.amount)}',
                style: const TextStyle(
                    color:      AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize:   15)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Entry Options Sheet ───────────────────────────
class _EntryOptions extends StatelessWidget {
  final Entry        entry;
  final BuildContext parentContext;
  const _EntryOptions({required this.entry, required this.parentContext});

  void _edit(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context:            parentContext,
      isScrollControlled: true,
      backgroundColor:    AppTheme.navyCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddEntrySheet(existing: entry),
    );
  }

  void _confirmDelete(BuildContext context) {
    Navigator.pop(context); // close the options sheet
    showDialog(
      context: parentContext, // use parent context — sheet is already closed
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.navyCard,
        title: const Text('Delete Entry',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Delete ¥${_fmt(entry.amount)} from '
          '${Categories.byId(entry.categoryId).name}?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(parentContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(parentContext);
              await parentContext.read<EntryProvider>().deleteEntry(entry.id!);
              await parentContext.read<BudgetProvider>().refreshSpend();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = Categories.byId(entry.categoryId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.navyLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Entry summary
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name,
                        style: const TextStyle(
                            color:      AppTheme.textPrimary,
                            fontSize:   15,
                            fontWeight: FontWeight.w600)),
                    if (entry.note != null && entry.note!.isNotEmpty)
                      Text(entry.note!,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Text('¥${_fmt(entry.amount)}',
                  style: const TextStyle(
                      color:      AppTheme.textPrimary,
                      fontSize:   18,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          _ActionButton(
            icon:    Icons.edit_rounded,
            label:   'Edit Entry',
            color:   AppTheme.amber,
            onTap:   () => _edit(context),
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon:    Icons.delete_rounded,
            label:   'Delete Entry',
            color:   AppTheme.danger,
            onTap:   () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Month Picker Sheet ────────────────────────────
class _MonthPickerSheet extends StatelessWidget {
  final List<String> labels;
  final String       selectedLabel;
  final void Function(String) onSelected;
  const _MonthPickerSheet({
    required this.labels,
    required this.selectedLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: AppTheme.navyLight,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Select Month',
                style: TextStyle(
                    color:      AppTheme.textPrimary,
                    fontSize:   17,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        SizedBox(
          height: 320,
          child: ListView.builder(
            padding:     const EdgeInsets.symmetric(horizontal: 16),
            itemCount:   labels.length,
            itemBuilder: (_, i) {
              final label    = labels[i];
              final selected = label == selectedLabel;
              return ListTile(
                onTap:       () => onSelected(label),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                tileColor:   selected
                    ? AppTheme.amber.withOpacity(0.12)
                    : Colors.transparent,
                leading: Icon(
                  Icons.circle,
                  size:  10,
                  color: selected ? AppTheme.amber : Colors.transparent,
                ),
                title: Text(
                  CycleHelper.displayLabel(label),
                  style: TextStyle(
                    color:      selected
                        ? AppTheme.amber
                        : AppTheme.textPrimary,
                    fontSize:   14,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_rounded,
                        color: AppTheme.amber, size: 18)
                    : null,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 60, color: AppTheme.amber.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('No entries this cycle',
              style: TextStyle(
                  color:      AppTheme.textPrimary,
                  fontSize:   16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Switch months or add a new entry',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────
String _monthShort(String label) {
  final parts = label.split('-');
  const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${m[int.parse(parts[1])]} ${parts[0]}';
}

String _fmt(int n) {
  final s   = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-${buf.toString()}' : buf.toString();
}