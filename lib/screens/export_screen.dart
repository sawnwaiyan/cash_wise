import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../db/database_helper.dart';
import '../models/category.dart';
import '../models/entry.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/cycle_helper.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late List<String> _labels;
  late String       _selectedLabel;
  bool _exporting = false;
  String? _lastSavedPath;

  @override
  void initState() {
    super.initState();
    _labels        = CycleHelper.recentLabels(count: 24);
    _selectedLabel = _labels.first;
  }

  // ── PDF Generation ────────────────────────────────
  Future<void> _export() async {
    setState(() {
      _exporting    = true;
      _lastSavedPath = null;
    });

    try {
      final db      = DatabaseHelper.instance;
      final entries = await db.getEntriesByCycle(_selectedLabel);
      final total   = await db.cycleTotalSpend(_selectedLabel);

      // Build category summary
      final catSummary = <int, int>{};
      for (final e in entries) {
        catSummary[e.categoryId] =
            (catSummary[e.categoryId] ?? 0) + e.amount;
      }

      final pdf  = pw.Document();
      final font = pw.Font.helvetica();
      final bold = pw.Font.helveticaBold();

      // ── Colours ──
      const headerBg  = PdfColor.fromInt(0xFF1A2D42);
      const accentCol = PdfColor.fromInt(0xFFFFC107);
      const bodyBg    = PdfColor.fromInt(0xFF0D1B2A);
      const white     = PdfColors.white;
      const grey      = PdfColor.fromInt(0xFF90A4AE);

      // ── Group entries by date ──
      final grouped = <String, List<Entry>>{};
      for (final e in entries) {
        final key = _fmtDate(e.date);
        grouped.putIfAbsent(key, () => []).add(e);
      }
      final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

      pdf.addPage(
        pw.MultiPage(
          pageFormat:  PdfPageFormat.a4,
          margin:      const pw.EdgeInsets.all(32),
          theme:       pw.ThemeData.withFont(base: font, bold: bold),
          build: (ctx) => [
            // ── Header ──────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color:        headerBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CashWise',
                          style: pw.TextStyle(
                              font:      bold,
                              fontSize:  22,
                              color:     accentCol)),
                      pw.SizedBox(height: 4),
                      pw.Text(CycleHelper.displayLabel(_selectedLabel),
                          style: pw.TextStyle(
                              font:     font,
                              fontSize: 12,
                              color:    white)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total Spend',
                          style: pw.TextStyle(
                              font:     font,
                              fontSize: 10,
                              color:    grey)),
                      pw.SizedBox(height: 4),
                      pw.Text('¥${_fmt(total)}',
                          style: pw.TextStyle(
                              font:      bold,
                              fontSize:  20,
                              color:     accentCol)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // ── Category Summary ─────────────────────
            pw.Text('Category Summary',
                style: pw.TextStyle(
                    font: bold, fontSize: 14, color: white)),
            pw.SizedBox(height: 8),
            pw.Table(
              border:          pw.TableBorder.all(color: headerBg, width: 1),
              columnWidths:    const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1.5),
              },
              children: [
                // Table header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: headerBg),
                  children: [
                    _thCell('Category', bold),
                    _thCell('Amount',   bold, align: pw.TextAlign.right),
                    _thCell('% of Total', bold, align: pw.TextAlign.right),
                  ],
                ),
                // Category rows (sorted by amount descending)
                ...(catSummary.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .map((e) {
                  final cat = Categories.byId(e.key);
                  final pct = total == 0 ? 0.0 : (e.value / total * 100);
                  return pw.TableRow(
                    decoration: const pw.BoxDecoration(color: bodyBg),
                    children: [
                      _tdCell(cat.name, font),
                      _tdCell('¥${_fmt(e.value)}', font,
                          align: pw.TextAlign.right),
                      _tdCell('${pct.toStringAsFixed(1)}%', font,
                          align: pw.TextAlign.right),
                    ],
                  );
                }),
                // Grand total row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: headerBg),
                  children: [
                    _thCell('Grand Total', bold),
                    _thCell('¥${_fmt(total)}', bold,
                        align: pw.TextAlign.right),
                    _thCell('100%', bold, align: pw.TextAlign.right),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 28),

            // ── Daily Entries ────────────────────────
            if (entries.isEmpty)
              pw.Text('No entries for this cycle.',
                  style: pw.TextStyle(font: font, color: grey))
            else ...[
              pw.Text('Daily Entries',
                  style: pw.TextStyle(
                      font: bold, fontSize: 14, color: white)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: headerBg, width: 1),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.5),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(3),
                  3: pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: headerBg),
                    children: [
                      _thCell('Date',     bold),
                      _thCell('Category', bold),
                      _thCell('Note',     bold),
                      _thCell('Amount',   bold, align: pw.TextAlign.right),
                    ],
                  ),
                  // Entry rows grouped by day
                  for (final day in sortedDays)
                    ...grouped[day]!.map((e) {
                      final cat = Categories.byId(e.categoryId);
                      return pw.TableRow(
                        decoration: const pw.BoxDecoration(color: bodyBg),
                        children: [
                          _tdCell(_fmtDate(e.date), font),
                          _tdCell(cat.name, font),
                          _tdCell(e.note ?? '—', font,
                              color: e.note != null ? white : grey),
                          _tdCell('¥${_fmt(e.amount)}', font,
                              align: pw.TextAlign.right),
                        ],
                      );
                    }),
                ],
              ),
            ],

            pw.SizedBox(height: 24),

            // ── Footer ──────────────────────────────
            pw.Divider(color: headerBg),
            pw.SizedBox(height: 6),
            pw.Text(
              'Generated by CashWise · ${_fmtDate(DateTime.now())}',
              style: pw.TextStyle(font: font, fontSize: 9, color: grey),
            ),
          ],
        ),
      );

      // ── Save to Downloads ──────────────────────────
      final path = await _savePath(_selectedLabel);
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _exporting    = false;
        _lastSavedPath = path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Documents/${_pdfFileName(_selectedLabel)}'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _exporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  // ── Save path ─────────────────────────────────────
  Future<String> _savePath(String label) async {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Documents');
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
    }
    dir ??= await getApplicationDocumentsDirectory();
    return '${dir.path}/${_pdfFileName(label)}';
  }

  String _pdfFileName(String label) {
    final parts = label.split('-');
    const m = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return 'CashWise_${m[int.parse(parts[1])]}_${parts[0]}.pdf';
  }

  // ── Build ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: Consumer<BudgetProvider>(
        builder: (context, budget, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:        AppTheme.navyCard,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppTheme.amber.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color:        AppTheme.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded,
                          color: AppTheme.amber, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Export to PDF',
                              style: TextStyle(
                                  color:      AppTheme.textPrimary,
                                  fontSize:   16,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text(
                            'Daily entries + category summary\nSaved to Downloads folder',
                            style: TextStyle(
                                color:    AppTheme.textSecondary,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Month selector label
              const Text('Select Cycle',
                  style: TextStyle(
                      color:      AppTheme.textPrimary,
                      fontSize:   15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),

              // Month picker list
              Container(
                height:     320,
                decoration: BoxDecoration(
                  color:        AppTheme.navyCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount:   _labels.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (_, i) {
                      final label    = _labels[i];
                      final selected = label == _selectedLabel;
                      return ListTile(
                        onTap: () =>
                            setState(() => _selectedLabel = label),
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.amber.withOpacity(0.15)
                                : AppTheme.navyLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            size:  18,
                            color: selected
                                ? AppTheme.amber
                                : AppTheme.textSecondary,
                          ),
                        ),
                        title: Text(
                          CycleHelper.displayLabel(label),
                          style: TextStyle(
                            color: selected
                                ? AppTheme.amber
                                : AppTheme.textPrimary,
                            fontSize:   13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppTheme.amber, size: 20)
                            : null,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Export button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exporting ? null : _export,
                  icon: _exporting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.download_rounded, size: 20),
                  label: Text(_exporting
                      ? 'Generating PDF...'
                      : 'Export & Save PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              // Last saved path
              if (_lastSavedPath != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:        AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.success, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PDF saved successfully',
                                style: TextStyle(
                                    color:      AppTheme.success,
                                    fontSize:   13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              _lastSavedPath!,
                              style: const TextStyle(
                                  color:    AppTheme.textSecondary,
                                  fontSize: 11),
                              maxLines:  2,
                              overflow:  TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── PDF Table Cell Helpers ────────────────────────
pw.Widget _thCell(String text, pw.Font bold,
    {pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
          font:      bold,
          fontSize:  10,
          color:     PdfColors.white),
    ),
  );
}

pw.Widget _tdCell(String text, pw.Font font,
    {pw.TextAlign align = pw.TextAlign.left,
    PdfColor color = PdfColors.white}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(font: font, fontSize: 9, color: color),
    ),
  );
}

// ── Helpers ───────────────────────────────────────
String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _fmt(int n) {
  final s   = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-${buf.toString()}' : buf.toString();
}