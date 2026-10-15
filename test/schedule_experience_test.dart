import 'dart:async';
import 'package:cmc_checkin/core/models.dart';
import 'package:cmc_checkin/core/portal_api.dart';
import 'package:cmc_checkin/features/schedule/schedule_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'academic_fixture.dart';

class ScheduleApiFake extends PortalApi {
  ScheduleApiFake()
    : super(
        session: testSession,
        userAgent: 'test',
        cookieHeader: (_) async => null,
      );
  int submissions = 0;
  final result = Completer<String>();
  @override
  Future<List<ScheduleEntry>> weekSchedule(DateTime from, DateTime to) async =>
      parseSchedule([
        {
          'ID': 'present',
          'IDLOPHOCPHAN': 'a',
          'NGAYHOC': '15/10/2026',
          'TENHOCPHAN': 'Lập trình web',
          'TENPHONGHOC': 'A301',
          'GIANGVIEN': 'Giảng viên A',
          'GIOBATDAU': 7,
          'GIOKETTHUC': 9,
          'THONGTINCHUYENCAN': 'Có mặt(3)',
        },
        {
          'ID': 'exam',
          'NGAYHOC': '15/10/2026',
          'TENHOCPHAN': 'Mạng máy tính',
          'PHANLOAI': 'LICHTHI',
        },
        {'ID': 'next', 'NGAYHOC': '16/10/2026', 'TENHOCPHAN': 'Cơ sở dữ liệu'},
        {
          'ID': 'open',
          'IDLOPHOCPHAN': 'b',
          'NGAYHOC': '15/10/2026',
          'TENHOCPHAN': 'Công nghệ phần mềm',
          'GIOBATDAU': 10,
          'GIOKETTHUC': 12,
        },
      ]);
  @override
  Future<String> checkIn(ScheduleEntry entry, String keyword, String ip) {
    submissions++;
    return result.future;
  }
}

void main() {
  late ScheduleApiFake api;
  late ScheduleController c;
  setUp(() async {
    api = ScheduleApiFake();
    c = ScheduleController(
      api: api,
      fallbackIp: '',
      clock: () => DateTime(2026, 10, 15, 8),
      ipLookup: () async => '192.0.2.1',
    );
    await c.refresh();
  });
  tearDown(() {
    c.dispose();
    api.close();
  });
  test(
    'Loading current class does not interrupt with an automatic keyword sheet',
    () {
      expect(c.checkIn, isNull);
      expect(c.updatedAt, DateTime(2026, 10, 15, 8));
      c.checkInNow();
      expect(c.checkIn!.entry.id, 'present');
    },
  );
  test('Combines accent-insensitive search, type filter and week view', () {
    c.search('lap trinh');
    expect(c.visibleEntries.single.id, 'present');
    c.search('a301');
    expect(c.visibleEntries.single.id, 'present');
    c.search('');
    c.selectFilter(ScheduleFilter.exams);
    expect(c.visibleEntries.single.id, 'exam');
    c.resetFilters();
    c.showWeek(true);
    expect(c.visibleEntries, hasLength(4));
    c.goToDate(DateTime(2026, 10, 16));
    expect(c.weekOverview, isFalse);
    expect(c.visibleEntries.single.id, 'next');
    c.goToToday();
    expect(c.dayEntries, hasLength(3));
  });
  test('Present and exam entries cannot submit again', () async {
    for (final id in ['present', 'exam']) {
      c.openCheckIn(c.entries.firstWhere((e) => e.id == id));
      await c.submitCheckIn('key');
    }
    expect(api.submissions, 0);
  });
  test(
    'Blocks repeated taps while sending and after successful check-in',
    () async {
      c.openCheckIn(c.entries.firstWhere((e) => e.id == 'open'));
      await Future<void>.delayed(Duration.zero);
      final sending = c.submitCheckIn('key');
      await c.submitCheckIn('key');
      expect(api.submissions, 1);
      api.result.complete('Đã ghi nhận');
      await sending;
      expect(c.checkIn!.succeeded, isTrue);
      await c.submitCheckIn('key');
      expect(api.submissions, 1);
    },
  );
}
