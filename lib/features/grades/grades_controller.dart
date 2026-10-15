import 'package:flutter/foundation.dart';

import '../../core/academic_models.dart';
import '../../core/portal_api.dart';
import '../../core/display_text.dart';

enum GradeSort { term, name, highest, lowest }

extension GradeSortLabel on GradeSort {
  String get label => switch (this) {
    GradeSort.term => 'Học kỳ mới nhất',
    GradeSort.name => 'Tên học phần A–Z',
    GradeSort.highest => 'Điểm cao trước',
    GradeSort.lowest => 'Điểm thấp trước',
  };
}

class GradesController extends ChangeNotifier {
  GradesController(this.api);
  final PortalApi api;
  List<StudyProgram> programs = const [];
  String? programId;
  AcademicRecord? record;
  AcademicTerm? term;
  String query = '';
  GradeSort sort = GradeSort.term;
  bool gradedOnly = false;
  String? error;
  DateTime? updatedAt;
  bool loading = false;
  bool sessionExpired = false;
  bool _disposed = false;
  int _generation = 0;

  List<CourseGrade> get visibleCourses {
    final search = searchKey(query);
    final courses =
        record?.courses
            .where(
              (c) =>
                  (term == null || c.term.id == term!.id) &&
                  (!gradedOnly || c.score10 != null) &&
                  (search.isEmpty ||
                      searchKey('${c.name} ${c.code}').contains(search)),
            )
            .toList() ??
        const [];
    final sorted = List<CourseGrade>.of(courses);
    sorted.sort((a, b) {
      if (sort == GradeSort.name)
        return searchKey(a.name).compareTo(searchKey(b.name));
      if (sort == GradeSort.highest || sort == GradeSort.lowest) {
        if (a.score10 == null && b.score10 != null) return 1;
        if (b.score10 == null && a.score10 != null) return -1;
        if (a.score10 != null && b.score10 != null) {
          final score = sort == GradeSort.highest
              ? b.score10!.compareTo(a.score10!)
              : a.score10!.compareTo(b.score10!);
          if (score != 0) return score;
        }
      }
      final year = b.term.year.compareTo(a.term.year);
      if (year != 0) return year;
      final semester = (int.tryParse(b.term.semester) ?? 0).compareTo(
        int.tryParse(a.term.semester) ?? 0,
      );
      return semester != 0
          ? semester
          : searchKey(a.name).compareTo(searchKey(b.name));
    });
    return sorted;
  }

  void selectSort(GradeSort value) {
    sort = value;
    _emit();
  }

  void showGradedOnly(bool value) {
    gradedOnly = value;
    _emit();
  }

  void resetFilters() {
    term = null;
    query = '';
    gradedOnly = false;
    sort = GradeSort.term;
    _emit();
  }

  void selectTerm(AcademicTerm? value) {
    term = value;
    _emit();
  }

  void search(String value) {
    query = value;
    _emit();
  }

  Future<void> selectProgram(String value) async {
    if (programId == value) return;
    programId = value;
    record = null;
    term = null;
    updatedAt = null;
    await refresh();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    loading = true;
    error = null;
    _emit();
    try {
      var available = programs;
      if (available.isEmpty) available = await api.studyPrograms();
      if (_disposed || generation != _generation) return;
      programs = available;
      if (available.isEmpty) {
        programId = null;
        record = null;
        updatedAt = null;
      } else {
        final selected = available.any((p) => p.id == programId)
            ? programId!
            : available.first.id;
        programId = selected;
        final result = await api.academicRecord(selected);
        if (_disposed || generation != _generation) return;
        record = result;
        if (term != null && !result.terms.any((t) => t.id == term!.id))
          term = null;
        updatedAt = DateTime.now();
      }
    } on SessionExpiredException {
      if (!_disposed && generation == _generation) sessionExpired = true;
    } on PortalException catch (e) {
      if (!_disposed && generation == _generation) error = e.message;
    } catch (_) {
      if (!_disposed && generation == _generation) error = offlineMessage;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        _emit();
      }
    }
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
