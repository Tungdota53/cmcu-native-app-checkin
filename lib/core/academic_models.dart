import 'display_text.dart';

/// Schema từ diemhoc.js và response trong HAR. Không tự quy đổi điểm/GPA.
typedef PortalRow = Map<String, dynamic>;

String portalText(Object? value) => value is num && value % 1 == 0
    ? value.toInt().toString()
    : value?.toString().trim() ?? '';
double? portalNumber(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(portalText(value).replaceAll(',', '.'));

List<PortalRow> portalRows(Object? value) {
  if (value is! List) throw const FormatException('Expected portal rows');
  return value
      .map((row) {
        if (row is! Map) throw const FormatException('Invalid portal row');
        return Map<String, dynamic>.from(row);
      })
      .toList(growable: false);
}

class StudyProgram {
  const StudyProgram(this.id, this.name);
  final String id;
  final String name;

  static List<StudyProgram> parse(Object? data) => portalRows(data)
      .where((r) => portalText(r['DAOTAO_TOCHUCCHUONGTRINH_ID']).isNotEmpty)
      .map(
        (r) => StudyProgram(
          portalText(r['DAOTAO_TOCHUCCHUONGTRINH_ID']),
          portalPlainText(portalText(r['DAOTAO_CHUONGTRINH_TEN'])),
        ),
      )
      .toList(growable: false);
}

class AcademicTerm {
  const AcademicTerm(this.year, this.semester);
  final String year;
  final String semester;
  String get id => '$year|$semester';
  String get label => 'HK $semester · $year';
}

class CourseGrade {
  CourseGrade(PortalRow row)
    : id = portalText(row['ID']),
      code = portalText(row['DAOTAO_HOCPHAN_MA']),
      name = portalPlainText(portalText(row['DAOTAO_HOCPHAN_TEN'])),
      credits = portalNumber(row['DAOTAO_HOCPHAN_HOCTRINH']),
      score10 = portalNumber(row['DIEM']),
      score4 = portalNumber(row['DIEMQUYDOI']),
      letter = portalText(row['DIEMQUYDOI_TEN']),
      assessment = portalPlainText(portalText(row['DANHGIA_TEN'])),
      note = portalPlainText(portalText(row['GHICHU'])),
      studyAttempt = portalText(row['LANHOC']),
      examAttempt = portalText(row['LANTHI']),
      term = AcademicTerm(portalText(row['NAMHOC']), portalText(row['HOCKY']));

  final String id, code, name, letter, assessment, note;
  final String studyAttempt, examAttempt;
  final double? credits, score10, score4;
  final AcademicTerm term;
}

class GradeComponent {
  GradeComponent(PortalRow row)
    : name = portalPlainText(portalText(row['DIEM_THANHPHANDIEM_TEN'])),
      score = portalNumber(row['DIEM']),
      studyAttempt = portalText(row['LANHOC']),
      examAttempt = portalText(row['LANTHI']);
  final String name, studyAttempt, examAttempt;
  final double? score;
}

class AcademicSummary {
  const AcademicSummary({
    this.average10,
    this.average4,
    this.earnedCredits,
    this.curriculumCredits,
  });
  final double? average10, average4, earnedCredits, curriculumCredits;
}

class AcademicRecord {
  AcademicRecord._(this.courses, this._averages, this.incompleteCount);
  final List<CourseGrade> courses;
  final List<PortalRow> _averages;
  final int incompleteCount;

  factory AcademicRecord.parse(Object? data) {
    if (data is! Map ||
        !data.containsKey('rsDiemKetThucHocPhan') ||
        !data.containsKey('rsDiemTrungBinhChung')) {
      throw const FormatException('Unknown academic schema');
    }
    return AcademicRecord._(
      portalRows(data['rsDiemKetThucHocPhan']).map(CourseGrade.new).toList(),
      portalRows(data['rsDiemTrungBinhChung']),
      data['rsHocPhanChuaHoanThanh'] == null
          ? 0
          : portalRows(data['rsHocPhanChuaHoanThanh']).length,
    );
  }

  List<AcademicTerm> get terms {
    final unique = {for (final c in courses) c.term.id: c.term};
    return unique.values.toList()..sort((a, b) {
      final year = b.year.compareTo(a.year);
      return year != 0
          ? year
          : (int.tryParse(b.semester) ?? 0).compareTo(
              int.tryParse(a.semester) ?? 0,
            );
    });
  }

  /// Cùng điều kiện chọn điểm như genHtml_TongDiem của portal.
  /// Tổng quan dùng trung bình tích lũy; học kỳ dùng trung bình chung học kỳ.
  AcademicSummary summary([AcademicTerm? term]) {
    PortalRow? find(String scale, String type) {
      for (final r in _averages) {
        if (portalText(r['THANGDIEM_MA']) != scale ||
            portalText(r['LOAIDIEMTRUNGBINH_MA']) != type ||
            portalNumber(r['THUOCTINHLANTINH']) != 0)
          continue;
        if (term == null) {
          if (r['DAOTAO_THOIGIANDAOTAO_ID'] == null) return r;
        } else if (r['DAOTAO_THOIGIANDAOTAO_ID'] != null &&
            portalText(r['NAMHOC']) == term.year &&
            portalText(r['DAOTAO_THOIGIANDAOTAO_KY']) == term.semester &&
            r['DOTHOC'] == null &&
            portalText(r['PHAMVITONGHOPDIEM_TEN']) == 'HOCKY') {
          return r;
        }
      }
      return null;
    }

    final type = term == null ? 'TRUNGBINHTICHLUY' : 'TRUNGBINHCHUNG';
    final ten = find('10', type), four = find('4', type);
    final earned = find('10', 'TRUNGBINHTICHLUY');
    final curriculum = find('10', 'TRUNGBINHCHUNG');
    return AcademicSummary(
      average10: portalNumber(ten?['DIEMTRUNGBINH']),
      average4: portalNumber(four?['DIEMTRUNGBINH']),
      earnedCredits: portalNumber(earned?['TONGSOTINCHI']),
      curriculumCredits: portalNumber(curriculum?['TONGSOTINCHICTDT']),
    );
  }
}
