import 'package:flutter/material.dart';

import '../../core/academic_models.dart';
import '../../core/portal_api.dart';
import '../../theme/motion.dart';
import '../../theme/formatters.dart';
import 'academic_overview.dart';
import 'grades_controller.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({
    super.key,
    required this.controller,
    required this.onSessionExpired,
  });
  final GradesController controller;
  final VoidCallback onSessionExpired;
  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  late final TextEditingController _search = TextEditingController(
    text: widget.controller.query,
  );
  bool _expiredHandled = false;
  GradesController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
    if (c.record == null && !c.loading) c.refresh();
  }

  void _changed() {
    if (c.sessionExpired && !_expiredHandled) {
      _expiredHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSessionExpired();
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    c.removeListener(_changed);
    super.dispose();
  }

  void _showCourse(CourseGrade course) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _CourseDetails(
        course: course,
        api: c.api,
        onSessionExpired: () {
          Navigator.of(context).pop();
          widget.onSessionExpired();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final s = Theme.of(context).colorScheme;
      final t = Theme.of(context).textTheme;
      final record = c.record;
      final courses = c.visibleCourses;
      return RefreshIndicator(
        onRefresh: c.refresh,
        child: CustomScrollView(
          key: const PageStorageKey('grades-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Hành trình học tập',
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kết quả học tập từ cổng sinh viên CMC',
                    style: TextStyle(color: s.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  if (c.programs.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey(c.programId),
                      initialValue: c.programId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Chương trình học',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: c.programs
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        if (id != null) c.selectProgram(id);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (c.loading) ...[
                    const LinearProgressIndicator(minHeight: 3),
                    const SizedBox(height: 16),
                    if (record == null)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Đang tải kết quả học tập…',
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                  if (c.error != null) ...[
                    Card(
                      color: s.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.error!,
                              style: TextStyle(color: s.onErrorContainer),
                            ),
                            if (record != null)
                              const Text(
                                'Đang hiển thị dữ liệu đã tải trước đó.',
                              ),
                            TextButton.icon(
                              onPressed: c.loading ? null : c.refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (record != null) ...[
                    Reveal(
                      child: AcademicOverview(
                        summary: record.summary(c.term),
                        term: c.term,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      key: ValueKey('${c.programId}-${c.term?.id}'),
                      initialValue: c.term?.id ?? '',
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Học kỳ',
                        prefixIcon: Icon(Icons.filter_alt_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Toàn bộ học kỳ'),
                        ),
                        for (final term in record.terms)
                          DropdownMenuItem(
                            value: term.id,
                            child: Text(term.label),
                          ),
                      ],
                      onChanged: (id) => c.selectTerm(
                        id == null || id.isEmpty
                            ? null
                            : record.terms.firstWhere((t) => t.id == id),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('grade-search'),
                      controller: _search,
                      onChanged: c.search,
                      decoration: InputDecoration(
                        hintText: 'Tìm tên hoặc mã học phần',
                        prefixIcon: const Icon(Icons.search),
                        labelText: 'Tìm học phần',
                        suffixIcon: c.query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Xóa tìm học phần',
                                onPressed: () {
                                  _search.clear();
                                  c.search('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilterChip(
                          label: const Text('Đã có điểm'),
                          avatar: const Icon(Icons.checklist_rounded, size: 17),
                          selected: c.gradedOnly,
                          onSelected: c.showGradedOnly,
                        ),
                        PopupMenuButton<GradeSort>(
                          tooltip: 'Sắp xếp bảng điểm',
                          initialValue: c.sort,
                          onSelected: c.selectSort,
                          itemBuilder: (_) => [
                            for (final sort in GradeSort.values)
                              CheckedPopupMenuItem(
                                value: sort,
                                checked: c.sort == sort,
                                child: Text(sort.label),
                              ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sort_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(c.sort.label, style: t.labelLarge),
                              ],
                            ),
                          ),
                        ),
                        if (c.term != null ||
                            c.query.isNotEmpty ||
                            c.gradedOnly ||
                            c.sort != GradeSort.term)
                          TextButton(
                            onPressed: () {
                              _search.clear();
                              c.resetFilters();
                            },
                            child: const Text('Đặt lại'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Bảng điểm · ${courses.length} học phần',
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (c.updatedAt != null)
                          Text(
                            'Cập nhật ${TimeOfDay.fromDateTime(c.updatedAt!).format(context)}',
                            style: t.bodySmall?.copyWith(
                              color: s.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (courses.isEmpty)
                      const _EmptyResults(
                        message:
                            'Chưa có học phần phù hợp.\nThử đổi học kỳ hoặc từ khóa tìm kiếm.',
                      ),
                    for (final course in courses) ...[
                      Reveal(
                        key: ValueKey('${course.id}-${course.term.id}'),
                        child: Card(
                          child: InkWell(
                            onTap: () => _showCourse(course),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          course.name.isEmpty
                                              ? 'Học phần'
                                              : course.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
                                          child: Text(
                                            [
                                                  course.code,
                                                  '${gradeNumber(course.credits)} tín chỉ',
                                                  course.term.label,
                                                  if (course
                                                      .assessment
                                                      .isNotEmpty)
                                                    course.assessment,
                                                ]
                                                .where((s) => s.isNotEmpty)
                                                .join(' · '),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: s.primary.withValues(alpha: .07),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          gradeNumber(course.score10),
                                          style: t.titleLarge?.copyWith(
                                            color: s.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          course.letter.isEmpty
                                              ? '/ 10'
                                              : course.letter,
                                          style: t.labelMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${record.incompleteCount} học phần chưa hoàn thành trong chương trình. '
                      'Điểm và tín chỉ theo dữ liệu portal; “—” là chưa có dữ liệu.',
                      style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
                    ),
                  ] else if (!c.loading && c.error == null)
                    const _EmptyResults(
                      message: 'Chưa có chương trình học để hiển thị kết quả.',
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Column(
      children: [
        Icon(
          Icons.school_outlined,
          size: 44,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _CourseDetails extends StatefulWidget {
  const _CourseDetails({
    required this.course,
    required this.api,
    required this.onSessionExpired,
  });
  final CourseGrade course;
  final PortalApi api;
  final VoidCallback onSessionExpired;
  @override
  State<_CourseDetails> createState() => _CourseDetailsState();
}

class _CourseDetailsState extends State<_CourseDetails> {
  late Future<List<GradeComponent>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.course.id.isEmpty ? Future.value(const []) : _load();
  }

  Future<List<GradeComponent>> _load() async {
    try {
      return await widget.api.gradeComponents(widget.course.id);
    } on SessionExpiredException {
      if (mounted) widget.onSessionExpired();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '${c.code} · ${c.term.label} · ${gradeNumber(c.credits)} tín chỉ',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Chip(label: Text('Hệ 10: ${gradeNumber(c.score10)}')),
                Chip(label: Text('Hệ 4: ${gradeNumber(c.score4)}')),
                Chip(
                  label: Text('Điểm chữ: ${c.letter.isEmpty ? '—' : c.letter}'),
                ),
              ],
            ),
            Text('Lần học: ${c.studyAttempt} · Lần thi: ${c.examAttempt}'),
            if (c.assessment.isNotEmpty) Text(c.assessment),
            if (c.note.isNotEmpty) Text(c.note),
            const Divider(height: 32),
            Text(
              'Điểm thành phần',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (c.id.isEmpty)
              const Text('Học phần chưa có mã tổng kết để xem chi tiết.')
            else
              FutureBuilder<List<GradeComponent>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError)
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.error is PortalException
                              ? (snapshot.error as PortalException).message
                              : offlineMessage,
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _future = _load()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    );
                  final components = snapshot.data ?? const [];
                  if (components.isEmpty)
                    return const Text('Portal chưa công bố điểm thành phần.');
                  return Column(
                    children: [
                      for (final part in components)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(part.name),
                          subtitle: Text(
                            'Lần học ${part.studyAttempt} · Lần thi ${part.examAttempt}',
                          ),
                          trailing: Text(
                            gradeNumber(part.score),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
