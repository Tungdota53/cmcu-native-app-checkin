import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../theme/formatters.dart';
import '../../theme/status_pill.dart';

class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.compact = false,
    this.now,
  });
  final ScheduleEntry entry;
  final VoidCallback onTap;
  final bool compact;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final time = now ?? DateTime.now();
    final live =
        sameDay(e.date, time) &&
        minuteOfDay(time) >= e.startMinutes &&
        minuteOfDay(time) < e.endMinutes;
    final success = s.brightness == Brightness.dark
        ? const Color(0xFF9BE3C1)
        : const Color(0xFF16714D);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    timeLine(e),
                    style: t.labelLarge?.copyWith(
                      color: s.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (live)
                    StatusPill(
                      label: e.isExam ? 'Đang thi' : 'Đang học',
                      icon: Icons.radio_button_checked_rounded,
                    ),
                  if (e.isExam && !live)
                    StatusPill(
                      label: 'Lịch thi',
                      icon: Icons.edit_calendar_rounded,
                      color: s.tertiary,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      e.subjectLabel,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: s.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoLine(icon: Icons.location_on_outlined, label: e.roomLabel),
              if (!compact && e.lecturerLabel.isNotEmpty) ...[
                const SizedBox(height: 7),
                _InfoLine(
                  icon: Icons.person_outline_rounded,
                  label: e.lecturerLabel,
                ),
              ],
              if (e.attendanceLabel.isNotEmpty) ...[
                const SizedBox(height: 14),
                StatusPill(
                  label: e.attendanceLabel,
                  icon: e.isPresent
                      ? Icons.check_circle_outline_rounded
                      : e.isAbsent
                      ? Icons.cancel_outlined
                      : Icons.fact_check_outlined,
                  color: e.isPresent
                      ? success
                      : e.isAbsent
                      ? s.error
                      : s.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 17, color: s.onSurfaceVariant),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: s.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
