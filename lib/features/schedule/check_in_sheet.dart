import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models.dart';
import '../../theme/formatters.dart';
import '../../theme/motion.dart';
import '../../theme/status_pill.dart';
import 'schedule_controller.dart';

class CheckInSheet extends StatefulWidget {
  const CheckInSheet({super.key, required this.controller});
  final ScheduleController controller;
  @override
  State<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<CheckInSheet> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  String? _entryId;
  bool _copied = false;
  @override
  void initState() {
    super.initState();
    final state = widget.controller.checkIn;
    _entryId = state?.entry.id;
    if (state != null &&
        state.focusKeyword &&
        !state.entry.isExam &&
        !state.entry.isPresent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _copy(ScheduleEntry entry) async {
    var copied = true;
    try {
      await Clipboard.setData(
        ClipboardData(
          text: [
            entry.subjectLabel,
            '${dayTitle(entry.date)} · ${timeLine(entry)}',
            entry.roomLabel,
            if (entry.lecturerLabel.isNotEmpty) entry.lecturerLabel,
            if (entry.classSectionLabel.isNotEmpty) entry.classSectionLabel,
            if (entry.attendanceLabel.isNotEmpty) entry.attendanceLabel,
          ].join('\n'),
        ),
      );
    } catch (_) {
      copied = false;
    }
    if (mounted) {
      setState(() => _copied = copied);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copied
                ? 'Đã sao chép thông tin buổi học.'
                : 'Chưa sao chép được. Vui lòng thử lại.',
          ),
        ),
      );
    }
  }

  Future<void> _submit() async {
    _focus.unfocus();
    await widget.controller.submitCheckIn(_text.text);
    if (mounted && widget.controller.checkIn?.succeeded == true)
      HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final state = widget.controller.checkIn;
      if (state == null) return const SizedBox.shrink();
      final e = state.entry;
      if (_entryId != e.id) {
        _entryId = e.id;
        _text.clear();
        _copied = false;
      }
      final s = Theme.of(context).colorScheme;
      final t = Theme.of(context).textTheme;
      final success = s.brightness == Brightness.dark
          ? const Color(0xFF9BE3C1)
          : const Color(0xFF16714D);
      return AnimatedPadding(
        duration: motionDuration(context, 180),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .88,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        e.subjectLabel,
                        style: t.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Đóng chi tiết',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  sheetDate(e.date),
                  style: TextStyle(color: s.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: s.primary.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailLine(
                        icon: Icons.schedule_rounded,
                        text: timeLine(e),
                      ),
                      const SizedBox(height: 12),
                      _DetailLine(
                        icon: Icons.location_on_outlined,
                        text: e.roomLabel,
                      ),
                      if (e.lecturerLabel.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DetailLine(
                          icon: Icons.person_outline_rounded,
                          text: e.lecturerLabel,
                        ),
                      ],
                      if (e.classSectionLabel.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DetailLine(
                          icon: Icons.groups_outlined,
                          text: e.classSectionLabel,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _copy(e),
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _copied ? 'Đã sao chép thông tin' : 'Sao chép thông tin',
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSize(
                  duration: motionDuration(context),
                  alignment: Alignment.topCenter,
                  child: state.succeeded || e.isPresent
                      ? Semantics(
                          liveRegion: true,
                          child: Container(
                            key: const ValueKey('attendance-success'),
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: success.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatusPill(
                                  label: 'Có mặt',
                                  icon: Icons.check_circle_outline_rounded,
                                  color: success,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  state.result ??
                                      'Portal đã ghi nhận bạn có mặt trong buổi học này.',
                                  style: TextStyle(color: success),
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Hoàn tất'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : e.isExam
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Không hỗ trợ điểm danh cho lịch thi.'),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (e.attendanceLabel.isNotEmpty) ...[
                              StatusPill(
                                label: e.attendanceLabel,
                                icon: Icons.fact_check_outlined,
                                color: e.isAbsent
                                    ? s.error
                                    : s.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              'Điểm danh buổi học',
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Nhập từ khóa do giảng viên cung cấp tại lớp.',
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _text,
                              focusNode: _focus,
                              enabled: !state.sending,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Từ khóa điểm danh',
                                prefixIcon: Icon(Icons.key_rounded),
                              ),
                            ),
                            if (state.result != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    state.result!,
                                    style: TextStyle(color: s.error),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              'IP gửi cho giảng viên: ${state.ip == null
                                  ? 'đang tra cứu…'
                                  : state.ip!.isEmpty
                                  ? 'chưa xác định'
                                  : state.ip}',
                              style: t.bodySmall?.copyWith(
                                color: s.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _text,
                              builder: (context, value, _) => SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed:
                                      value.text.trim().isEmpty || state.sending
                                      ? null
                                      : _submit,
                                  icon: state.sending
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.how_to_reg_outlined,
                                          size: 20,
                                        ),
                                  label: Text(
                                    state.sending
                                        ? 'Đang gửi…'
                                        : 'Xác nhận điểm danh',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(text)),
    ],
  );
}
