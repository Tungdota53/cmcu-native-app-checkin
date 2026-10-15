import 'package:flutter/foundation.dart';

import '../../core/academic_models.dart';
import '../../core/portal_api.dart';

class GradesController extends ChangeNotifier {
  GradesController(this.api);
  final PortalApi api;
  List<StudyProgram> programs = const [];
  String? programId;
  AcademicRecord? record;
  AcademicTerm? term;
  String query = '';
  String? error;
  DateTime? updatedAt;
  bool loading = false;
  bool sessionExpired = false;
  bool _disposed = false;
  int _generation = 0;

  List<CourseGrade> get visibleCourses {
    final search = query.toLowerCase().trim();
    return record?.courses
            .where(
              (c) =>
                  (term == null || c.term.id == term!.id) &&
                  (search.isEmpty ||
                      '${c.name} ${c.code}'.toLowerCase().contains(search)),
            )
            .toList() ??
        const [];
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
