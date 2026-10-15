import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'models.dart';

const appGroupId = 'group.com.example.cmccheckin'; // đổi cho khớp entitlement
const _iosWidgetName = 'CheckInWidget';
const _snapshotKey = 'widget_snapshot';

/// Ghi `WidgetSnapshot` (JSON dùng chung với bản SwiftUI) vào App Group rồi nhờ WidgetKit vẽ lại.
class WidgetBridge {
  WidgetBridge._();

  static Future<void> init() => HomeWidget.setAppGroupId(appGroupId);

  static Future<void> publish({
    required bool signedIn,
    DateTime? weekStart,
    List<ScheduleEntry> entries = const [],
  }) async {
    final iso = DateFormat('yyyy-MM-dd');
    final snapshot = {
      'signedIn': signedIn,
      'loaded': signedIn && weekStart != null,
      'weekStart': iso.format(weekStart ?? startOfWeek(DateTime.now())),
      'items': [
        for (final e in entries)
          {
            'id': e.id,
            'subject': e.subject,
            'room': e.room,
            'date': iso.format(e.date),
            'start': e.startMinutes,
            'end': e.endMinutes,
            'exam': e.isExam,
            'timeRange': e.timeRange,
          }
      ],
    };
    await HomeWidget.saveWidgetData<String>(_snapshotKey, jsonEncode(snapshot));
    await HomeWidget.updateWidget(iOSName: _iosWidgetName);
  }

  static Future<void> clear() async {
    await HomeWidget.saveWidgetData<String>(_snapshotKey, null);
    await HomeWidget.updateWidget(iOSName: _iosWidgetName);
  }
}
