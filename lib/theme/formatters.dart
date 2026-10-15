import 'package:intl/intl.dart';
import '../core/models.dart';

String dayTitle(DateTime d) => DateFormat('EEEE, d MMMM').format(d);
String sheetDate(DateTime d) => DateFormat('EEE d MMM').format(d);
String shortWeekday(DateTime d) => DateFormat('E').format(d);
String weekLabel(DateTime start) {
  final end = start.add(const Duration(days: 6));
  final f = DateFormat('d MMM');
  return '${f.format(start)} – ${f.format(end)} ${end.year}';
}

String timeLine(ScheduleEntry e) {
  final String? detail = e.isExam
      ? e.examShift
      : (e.firstPeriod != null ? 'Periods ${e.firstPeriod}–${e.lastPeriod ?? e.firstPeriod}' : null);
  return [e.timeRange, if (detail != null) detail].join(' · ');
}
