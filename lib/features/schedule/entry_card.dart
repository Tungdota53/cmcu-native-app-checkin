import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/formatters.dart';

class EntryCard extends StatelessWidget {
  const EntryCard({super.key, required this.entry, required this.onTap});
  final ScheduleEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final lines = [
      if (entry.room != null) 'Phòng ${entry.room}',
      if (entry.classSection != null) entry.classSection!,
      if (entry.lecturer != null) entry.lecturer!,
    ];
    return Card(
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                color: AppColors.forClass(entry.classSectionId),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeLine(entry),
                        style: text.labelLarge?.copyWith(color: s.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.subject,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      for (final l in lines) ...[
                        const SizedBox(height: 2),
                        Text(
                          l,
                          style: text.bodyMedium?.copyWith(
                            color: s.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (entry.isExam) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Lịch thi',
                          style: text.labelMedium?.copyWith(color: s.error),
                        ),
                      ],
                      if (entry.attendance != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          entry.attendance!,
                          style: text.labelMedium?.copyWith(color: s.tertiary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
