import 'package:flutter/material.dart';
import '../../theme/formatters.dart';
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

  @override
  void initState() {
    super.initState();
    final st = widget.controller.checkIn;
    _entryId = st?.entry.id;
    if (st != null && st.focusKeyword && !st.entry.isExam) {
      Future.delayed(const Duration(milliseconds: 450), () {
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final st = widget.controller.checkIn;
        if (st == null) return const SizedBox.shrink();
        if (_entryId != st.entry.id) {
          _entryId = st.entry.id;
          _text.clear();
        }
        final e = st.entry;
        final s = Theme.of(context).colorScheme;
        final t = Theme.of(context).textTheme;
        final subtitle = [sheetDate(e.date), timeLine(e), if (e.room != null) e.room!].join(' · ');
        final ipText = st.ip == null ? 'looking up…' : (st.ip!.isEmpty ? 'unknown' : st.ip!);
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.subject, style: t.titleLarge),
                const SizedBox(height: 12),
                Text(subtitle, style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
                if (e.attendance != null) ...[
                  const SizedBox(height: 12),
                  Text(e.attendance!, style: t.labelLarge?.copyWith(color: s.tertiary)),
                ],
                const SizedBox(height: 12),
                if (e.isExam)
                  Text("Check-in isn't available for exams.", style: t.bodyMedium)
                else ...[
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _text,
                    builder: (context, value, _) {
                      final canSubmit = value.text.trim().isNotEmpty && !st.sending;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _text,
                            focusNode: _focus,
                            enabled: !st.sending,
                            textInputAction: TextInputAction.done,
                            autocorrect: false,
                            enableSuggestions: false,
                            onSubmitted: (v) => widget.controller.submitCheckIn(v),
                            decoration: const InputDecoration(
                              labelText: 'Attendance keyword',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('IP shown to the lecturer: $ipText',
                              style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: canSubmit
                                  ? () => widget.controller.submitCheckIn(_text.text)
                                  : null,
                              child: st.sending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Check in'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (st.result != null) ...[
                    const SizedBox(height: 12),
                    Text(st.result!,
                        style: t.bodyMedium
                            ?.copyWith(color: st.succeeded ? s.primary : s.error)),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
