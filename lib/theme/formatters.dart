import 'package:intl/intl.dart';

import '../core/models.dart';

String dayTitle(DateTime d) =>
    '${d.weekday == 7 ? 'Chủ nhật' : 'Thứ ${d.weekday + 1}'}, ${DateFormat('dd/MM/yyyy').format(d)}';
String sheetDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
String shortWeekday(DateTime d) => d.weekday == 7 ? 'CN' : 'T${d.weekday + 1}';
String weekLabel(DateTime start) {
  final end = start.add(const Duration(days: 6));
  final f = DateFormat('dd/MM');
  return '${f.format(start)} – ${f.format(end)} ${end.year}';
}

String timeLine(ScheduleEntry e) {
  final String? detail = e.isExam
      ? e.examShift
      : (e.firstPeriod != null
            ? 'Tiết ${e.firstPeriod}–${e.lastPeriod ?? e.firstPeriod}'
            : null);
  return [e.timeRange, if (detail != null) detail].join(' · ');
}
