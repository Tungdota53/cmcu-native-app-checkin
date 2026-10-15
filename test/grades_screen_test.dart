import 'dart:io';
import 'dart:ui' as ui;
import 'package:cmc_checkin/core/academic_models.dart';
import 'package:cmc_checkin/core/models.dart';
import 'package:cmc_checkin/core/portal_api.dart';
import 'package:cmc_checkin/features/schedule/schedule_controller.dart';
import 'package:cmc_checkin/features/schedule/schedule_screen.dart';
import 'package:cmc_checkin/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'academic_fixture.dart';

class ScreenApi extends PortalApi {
  ScreenApi()
    : super(
        session: testSession,
        userAgent: 'test',
        cookieHeader: (_) async => null,
      );
  int detailsRequests = 0;
  @override
  Future<List<ScheduleEntry>> weekSchedule(
    DateTime from,
    DateTime to,
  ) async => parseSchedule([
    {
      'ID': 'lesson-synthetic',
      'IDLOPHOCPHAN': 'mobile-class',
      'TENHOCPHAN': 'Lập trình di động',
      'NGAYHOC':
          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      'GIOBATDAU': 7,
      'GIOKETTHUC': 9,
      'TENPHONGHOC': '301',
      'GIANGVIEN': 'Giảng viên bộ môn',
    },
    {
      'ID': 'exam-synthetic',
      'TENHOCPHAN': 'Mạng máy tính',
      'PHANLOAI': 'LICHTHI',
      'NGAYHOC':
          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      'GIOBATDAU': 13,
      'GIOKETTHUC': 15,
      'TENPHONGHOC': '402',
    },
  ]);
  @override
  Future<List<StudyProgram>> studyPrograms() async => const [
    StudyProgram('a', 'Công nghệ thông tin'),
  ];
  @override
  Future<AcademicRecord> academicRecord(String programId) async =>
      AcademicRecord.parse(academicFixture());
  @override
  Future<List<GradeComponent>> gradeComponents(String resultId) async {
    detailsRequests++;
    return [
      GradeComponent({
        'DIEM_THANHPHANDIEM_TEN': 'Chuyên cần',
        'DIEM': 10,
        'LANHOC': 1,
        'LANTHI': 1,
      }),
    ];
  }
}

void main() {
  const previewKey = ValueKey('preview');
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final path = Platform.environment['CMC_PREVIEW_FONT'];
    if (path != null) {
      final loader = FontLoader('Roboto')
        ..addFont(File(path).readAsBytes().then(ByteData.sublistView));
      await loader.load();
    }
  });

  Future<void> capture(WidgetTester tester, String name) async {
    final directory = Platform.environment['CMC_PREVIEW_DIR'];
    if (directory == null) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(previewKey),
      );
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$directory/$name.png').create(recursive: true);
      await File(
        '$directory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<ScreenApi> mount(
    WidgetTester tester,
    Size size, {
    double scale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ScreenApi();
    final controller = ScheduleController(api: api, fallbackIp: '');
    addTearDown(controller.dispose);
    addTearDown(api.close);
    await tester.pumpWidget(
      RepaintBoundary(
        key: previewKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(brightness),
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: ScheduleScreen(
            controller: controller,
            checkInRequested: false,
            onCheckInRequestHandled: () {},
            onSignOut: () {},
            onSessionExpired: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Đóng sheet đề xuất lớp hiện tại nếu giờ chạy test rơi vào buổi học giả lập.
    if (find.text('Từ khóa điểm danh').evaluate().isNotEmpty ||
        find
            .text('Không hỗ trợ điểm danh cho lịch thi.')
            .evaluate()
            .isNotEmpty) {
      final context = tester.element(find.byType(ScheduleScreen));
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
    }
    return api;
  }

  testWidgets('Navigates, filters, searches and loads course details', (
    tester,
  ) async {
    final api = await mount(tester, const Size(390, 844));
    await capture(tester, 'schedule-light');
    await tester.tap(find.text('Kết quả'));
    await tester.pumpAndSettle();
    expect(find.text('GPA tích lũy / 4'), findsOneWidget);
    expect(find.text('3.2'), findsOneWidget);
    await capture(tester, 'grades-light');
    final scrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Toàn bộ học kỳ').last,
      180,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Toàn bộ học kỳ').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('HK 2 · 2025-2026').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'MOB101');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lập trình di động'),
      180,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Lập trình di động'));
    await tester.pumpAndSettle();
    expect(find.text('Điểm thành phần'), findsOneWidget);
    expect(find.text('Chuyên cần'), findsOneWidget);
    expect(api.detailsRequests, 1);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('No overflow at 320px and large text: $brightness', (
      tester,
    ) async {
      await mount(
        tester,
        const Size(320, 720),
        scale: 1.5,
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Kết quả'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(
        tester,
        brightness == Brightness.dark
            ? 'grades-dark-small'
            : 'grades-light-small',
      );
    });
  }
}
