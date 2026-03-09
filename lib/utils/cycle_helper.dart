class CycleHelper {
  static DateTime cycleMonth(DateTime date) {
    if (date.day >= 26) {
      final next = DateTime(date.year, date.month + 1, 1);
      return DateTime(next.year, next.month);
    }
    return DateTime(date.year, date.month);
  }

  static String monthLabel(DateTime date) {
    final m = cycleMonth(date);
    return '${m.year}-${m.month.toString().padLeft(2, '0')}';
  }

  static DateTime cycleStart(DateTime date) {
    final m = cycleMonth(date);
    final prev = DateTime(m.year, m.month - 1, 26);
    return DateTime(prev.year, prev.month, 26);
  }

  static DateTime cycleEnd(DateTime date) {
    final m = cycleMonth(date);
    return DateTime(m.year, m.month, 25);
  }

  static (DateTime start, DateTime end) rangeForLabel(String label) {
    final parts = label.split('-');
    final year  = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final start = DateTime(year, month - 1, 26);
    final end   = DateTime(year, month, 25);
    return (start, end);
  }

  static String displayLabel(String label) {
    final (start, end) = rangeForLabel(label);
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const short = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final p     = label.split('-');
    final lYear = int.parse(p[0]);
    final lMonth= int.parse(p[1]);
    return '${months[lMonth]} $lYear '
        '(${short[start.month]} ${start.day} – '
        '${short[end.month]} ${end.day})';
  }

  static List<String> recentLabels({int count = 12}) {
    final today   = DateTime.now();
    final current = monthLabel(today);
    final results = <String>[current];
    var ref = cycleStart(today);
    for (int i = 1; i < count; i++) {
      ref = ref.subtract(const Duration(days: 1));
      results.add(monthLabel(ref));
      ref = cycleStart(ref);
    }
    return results;
  }
}