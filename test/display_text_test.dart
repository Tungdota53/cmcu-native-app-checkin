import 'dart:convert';
import 'package:cmc_checkin/core/display_text.dart';
import 'package:cmc_checkin/core/models.dart';
import 'package:cmc_checkin/core/portal_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'academic_fixture.dart';

void main() {
  test(
    'Decodes portal HTML, encoded breaks and entities without exposing tags',
    () {
      expect(
        portalPlainText('Lớp &amp; nhóm<BR/>Có mặt<br>'),
        'Lớp & nhóm\nCó mặt',
      );
      expect(portalPlainText('Lớp&lt;br&gt;Có mặt&lt;br/&gt;'), 'Lớp\nCó mặt');
      expect(
        portalPlainText('<p>Môn&nbsp;học</p><div><b>Có mặt</b></div>'),
        'Môn học\nCó mặt',
      );
      expect(
        portalPlainText('<script>secret()</script><style>body{}</style>Có mặt'),
        'Có mặt',
      );
      expect(portalPlainText('2 < 3 và 5 > 4'), '2 < 3 và 5 > 4');
      expect(portalPlainText(null), isEmpty);
    },
  );
  test(
    'Separates attendance from class label and leaves request values intact',
    () {
      final entry = parseSchedule([
        {
          'ID': 'session-id',
          'IDLOPHOCPHAN': 'class-id',
          'TENHOCPHAN': 'Phát triển <b>ứng dụng web</b>',
          'NGAYHOC': '15/10/2026',
          'TENLOPHOCPHAN': 'Web-01<br>Có mặt<br>',
          'THONGTINCHUYENCAN': '<b>Có mặt</b>(3)',
          'TENPHONGHOC': 'Phòng&nbsp;A301',
          'GIANGVIEN': '<span>Giảng viên</span>',
          'GIOBATDAU': 7,
          'TIETBATDAU': 1,
          'TIETKETTHUC': 3,
        },
      ]).single;
      expect(entry.classSectionLabel, 'Web-01');
      expect(entry.attendanceLabel, 'Có mặt');
      expect(entry.subjectLabel, 'Phát triển ứng dụng web');
      expect(entry.roomLabel, 'Phòng A301');
      expect(entry.lecturerLabel, 'Giảng viên');
      expect(entry.isPresent, isTrue);
      expect(entry.periodCount, 3);
      final fields = PortalApi.checkInFields(
        testSession,
        entry,
        'keyword<br>',
        '192.0.2.1',
      );
      expect(fields['strDiem_DanhSach_Id'], 'class-id');
      expect(fields['strNgayGhiNhan'], '15/10/2026');
      expect(fields['strNoiDungTuGhiNhan'], 'keyword<br>');
      expect(entry.attendance, '<b>Có mặt</b>(3)');
    },
  );
  test('Attendance never mistakes a negative phrase for present', () {
    for (final status in ['Chưa có mặt', 'Không có mặt', null]) {
      final e = parseSchedule([
        {'ID': 'x', 'NGAYHOC': '15/10/2026', 'THONGTINCHUYENCAN': status},
      ]).single;
      expect(e.isPresent, isFalse);
    }
  });
  test('Search ignores Vietnamese accents and display markup', () {
    expect(searchKey('ĐIỂM &amp; <b>Lập trình</b>'), 'diem & lap trinh');
    expect(searchKey('Va\u0306n'), 'van');
  });
  test('Business errors are displayed as plain text', () {
    expect(
      () => parseResponse(
        jsonEncode({
          'Success': false,
          'Message': '<b>Chưa mở</b><br>Thử lại sau',
        }),
      ),
      throwsA(
        isA<PortalException>().having(
          (e) => e.message,
          'message',
          'Chưa mở\nThử lại sau',
        ),
      ),
    );
  });
}
