import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/entry.dart';
import '../providers/entry_provider.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

class AddEntrySheet extends StatefulWidget {
  /// Pass an existing entry to enter Edit mode.
  final Entry? existing;
  const AddEntrySheet({super.key, this.existing});

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  late DateTime        _date;
  late int             _categoryId;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e     = widget.existing;
    _date       = e?.date ?? DateTime.now();
    _categoryId = e?.categoryId ?? Categories.all.first.id;
    _amountCtrl = TextEditingController(text: e != null ? e.amount.toString() : '');
    _noteCtrl   = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Date picker ───────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:      context,
      initialDate:  _date,
      firstDate:    DateTime(2020),
      lastDate:     DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary:   AppTheme.amber,
            onPrimary: Colors.black,
            surface:   AppTheme.navyCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // ── Save ──────────────────────────────────────────
  Future<void> _save() async {
    final raw = int.tryParse(_amountCtrl.text.trim());
    if (raw == null || raw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _saving = true);

    final entryProvider  = context.read<EntryProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    final entry = Entry(
      id:         widget.existing?.id,
      date:       _date,
      categoryId: _categoryId,
      amount:     raw,
      note:       _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      createdAt:  widget.existing?.createdAt ?? DateTime.now(),
    );

    if (_isEdit) {
      await entryProvider.updateEntry(entry);
    } else {
      await entryProvider.addEntry(entry);
    }

    // Refresh budget spend totals
    await budgetProvider.refreshSpend();

    if (mounted) Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width:  40, height: 4,
              decoration: BoxDecoration(
                color:        AppTheme.navyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            _isEdit ? 'Edit Entry' : 'Add Entry',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          // Date row
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color:        AppTheme.navyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppTheme.amber, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${_date.year}-'
                    '${_date.month.toString().padLeft(2, '0')}-'
                    '${_date.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Amount input
          TextField(
            controller:  _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style:       const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            decoration:  const InputDecoration(
              labelText:  'Amount (¥)',
              prefixText: '¥ ',
              prefixStyle: TextStyle(color: AppTheme.amber, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),

          // Note input
          TextField(
            controller:  _noteCtrl,
            style:       const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            maxLength:   80,
            decoration:  const InputDecoration(
              labelText:  'Note (optional)',
              hintText:   'e.g. Lawson, izakaya with friends',
              counterStyle: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 14),

          // Category label
          const Text('Category',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),

          // Category chips — scrollable wrap
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Categories.all.map((cat) {
                  final selected = cat.id == _categoryId;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryId = cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? cat.color.withOpacity(0.25)
                            : AppTheme.navyLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? cat.color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon,
                              size:  16,
                              color: selected ? cat.color : AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            cat.name,
                            style: TextStyle(
                              color: selected
                                  ? cat.color
                                  : AppTheme.textSecondary,
                              fontSize:   12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
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
                      height: 20,
                      width:  20,
                      child:  CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Text(_isEdit ? 'Update Entry' : 'Save Entry'),
            ),
          ),
        ],
      ),
    );
  }
}