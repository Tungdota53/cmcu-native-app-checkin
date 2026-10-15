import 'dart:async';

import 'package:cmc_checkin/core/academic_models.dart';
import 'package:cmc_checkin/core/portal_api.dart';
import 'package:cmc_checkin/features/grades/grades_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'academic_fixture.dart';

class FakeAcademicApi extends PortalApi {
  FakeAcademicApi()
    : super(
        session: testSession,
        userAgent: 'test',
        cookieHeader: (_) async => null,
      );
  final pending = <String, Completer<AcademicRecord>>{};
  bool expired = false;
  @override
  Future<List<StudyProgram>> studyPrograms() async => const [
    StudyProgram('a', 'A'),
    StudyProgram('b', 'B'),
  ];
  @override
  Future<AcademicRecord> academicRecord(String programId) {
    if (expired) throw SessionExpiredException();
    return (pending[programId] = Completer<AcademicRecord>()).future;
  }
}

void main() {
  test(
    'Sorts official scores with missing scores last and searches without accents',
    () {
      final api = FakeAcademicApi();
      final c = GradesController(api);
      addTearDown(c.dispose);
      addTearDown(api.close);
      c.record = AcademicRecord.parse(academicFixture());
      c.selectSort(GradeSort.highest);
      expect(c.visibleCourses.map((e) => e.score10), [8.5, 0, null]);
      c.selectSort(GradeSort.lowest);
      expect(c.visibleCourses.map((e) => e.score10), [0, 8.5, null]);
      c.showGradedOnly(true);
      expect(c.visibleCourses, hasLength(2));
      c.search('lap trinh');
      expect(c.visibleCourses, hasLength(2));
      c.resetFilters();
      expect(c.visibleCourses, hasLength(3));
      expect(c.sort, GradeSort.term);
    },
  );
  test(
    'Switching program ignores late responses from previous program',
    () async {
      final api = FakeAcademicApi();
      final c = GradesController(api);
      addTearDown(c.dispose);
      addTearDown(api.close);
      final first = c.refresh();
      await Future<void>.delayed(Duration.zero);
      final second = c.selectProgram('b');
      api.pending['b']!.complete(
        AcademicRecord.parse(academicFixture(name: 'Program B')),
      );
      await second;
      api.pending['a']!.complete(
        AcademicRecord.parse(academicFixture(name: 'Program A')),
      );
      await first;
      expect(c.programId, 'b');
      expect(c.record!.courses.first.name, 'Program B');
      expect(c.loading, isFalse);
      c.selectTerm(c.record!.terms.first);
      c.search('MOB101');
      expect(c.visibleCourses, hasLength(1));
      c.search('not-found');
      expect(c.visibleCourses, isEmpty);
    },
  );
  test(
    'Retains previous data with error and timestamp if refresh fails',
    () async {
      final api = FakeAcademicApi();
      final c = GradesController(api);
      addTearDown(c.dispose);
      addTearDown(api.close);
      final load = c.refresh();
      await Future<void>.delayed(Duration.zero);
      api.pending['a']!.complete(AcademicRecord.parse(academicFixture()));
      await load;
      final previous = c.record, time = c.updatedAt;
      final retry = c.refresh();
      api.pending['a']!.completeError(PortalException('Mất kết nối'));
      await retry;
      expect(c.record, same(previous));
      expect(c.updatedAt, time);
      expect(c.error, 'Mất kết nối');
      expect(c.loading, isFalse);
    },
  );
  test(
    'Propagates session expiry and ignores completion after dispose',
    () async {
      final api = FakeAcademicApi();
      final c = GradesController(api);
      addTearDown(api.close);
      api.expired = true;
      await c.refresh();
      expect(c.sessionExpired, isTrue);
      api.expired = false;
      final load = c.refresh();
      c.dispose();
      api.pending['a']!.complete(AcademicRecord.parse(academicFixture()));
      await load;
    },
  );
}
