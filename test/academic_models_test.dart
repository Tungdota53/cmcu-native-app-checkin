import 'package:cmc_checkin/core/academic_models.dart';
import 'package:cmc_checkin/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'academic_fixture.dart';

void main() {
  test('Parses numeric terms, zero scores, nulls and strings from portal', () {
    final record = AcademicRecord.parse(academicFixture());
    expect(record.courses.first.term.semester, '2');
    expect(record.courses.first.studyAttempt, '1');
    expect(record.courses.first.credits, 3);
    expect(record.courses[1].score10, isNull);
    expect(record.courses.last.score10, 0);
    expect(record.terms.map((t) => t.id), [
      '2025-2026|2',
      '2025-2026|1',
      '2024-2025|2',
    ]);
    expect(portalNumber('8,5'), 8.5);
  });
  test('Selects official cumulative GPA and semester averages separately', () {
    final fixture = academicFixture();
    (fixture['rsDiemTrungBinhChung'] as List).insert(0, {
      ...average('TRUNGBINHTICHLUY', '4', 4),
      'THUOCTINHLANTINH': 1,
    });
    final record = AcademicRecord.parse(fixture);
    expect(record.summary().average4, 3.2);
    expect(record.summary().earnedCredits, 48);
    expect(record.summary().curriculumCredits, 130);
    expect(record.summary(record.terms.first).average4, 3.9);
    expect(record.summary(record.terms.first).average10, 9.1);
    expect(record.summary(record.terms.first).earnedCredits, 30);
    expect(record.summary(record.terms.last).average4, isNull);
  });
  test('Rejects schema drift instead of reporting an empty transcript', () {
    expect(() => AcademicRecord.parse([]), throwsFormatException);
    expect(() => AcademicRecord.parse({'newField': []}), throwsFormatException);
    expect(
      () => AcademicRecord.parse({
        ...academicFixture(),
        'rsDiemKetThucHocPhan': [null],
      }),
      throwsFormatException,
    );
  });
  test('Restores older sessions without inventing grades permission', () {
    final old = Session.decode('{"token":"t","userId":"u"}')!;
    expect(old.gradesChucNangId, isEmpty);
    expect(
      Session.decode(testSession.encode())!.gradesChucNangId,
      'grades-menu',
    );
  });
}
