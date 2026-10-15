import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../theme/formatters.dart';
import 'schedule_controller.dart';

class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.controller});
  final ScheduleController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final today = DateTime.now();
    final busy = {for (final e in c.entries) dateOnly(e.date)};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
              onPressed: c.previousWeek,
              tooltip: 'Previous week',
              icon: const Icon(Icons.chevron_left)),
          for (final day in c.weekDays)
            Expanded(
              child: _DayCell(
                day: day,
                selected: sameDay(day, c.selectedDay),
                isToday: sameDay(day, today),
                busy: busy.contains(dateOnly(day)),
                onTap: () => c.selectDay(day),
              ),
            ),
          IconButton(
              onPressed: c.nextWeek,
              tooltip: 'Next week',
              icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.busy,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final background = selected
        ? s.primary
        : (isToday ? s.primaryContainer : Colors.transparent);
    final content = selected
        ? s.onPrimary
        : (isToday ? s.onPrimaryContainer : s.onSurface);
    return Semantics(
      selected: selected,
      button: true,
      label: dayTitle(day) + (busy ? ', has classes' : ''),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(shortWeekday(day),
                      maxLines: 1,
                      style: text.labelSmall?.copyWith(color: content)),
                  const SizedBox(height: 2),
                  Text('${day.day}',
                      style: text.titleMedium
                          ?.copyWith(color: content, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: busy ? content : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
