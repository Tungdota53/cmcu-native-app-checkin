import 'package:flutter/material.dart';
import '../../core/academic_models.dart';
import '../../theme/campus_brand.dart';
import '../../theme/formatters.dart';

class AcademicOverview extends StatelessWidget {
  const AcademicOverview({super.key, required this.summary, this.term});
  final AcademicSummary summary;
  final AcademicTerm? term;
  @override
  Widget build(BuildContext context) {
    final hasProgress =
        term == null &&
        summary.earnedCredits != null &&
        summary.curriculumCredits != null &&
        summary.curriculumCredits! > 0;
    final progress = hasProgress
        ? (summary.earnedCredits! / summary.curriculumCredits!).clamp(0.0, 1.0)
        : null;
    return CampusSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacious =
              constraints.maxWidth >= 280 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.insights_rounded,
                    color: CampusColors.cyan,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      term?.label ?? 'TỔNG QUAN TÍCH LŨY',
                      style: const TextStyle(
                        fontSize: 11,
                        color: CampusColors.cyan,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gradeNumber(summary.average4),
                          style: const TextStyle(
                            fontSize: 52,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          term == null
                              ? 'GPA tích lũy / 4'
                              : 'Trung bình học kỳ / 4',
                          style: const TextStyle(
                            color: Color(0xFFC7E1EB),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (progress != null && spacious) ...[
                    const SizedBox(width: 16),
                    Semantics(
                      label: 'Tiến độ tín chỉ chương trình',
                      value: '${(progress * 100).round()} phần trăm',
                      child: ExcludeSemantics(
                        child: SizedBox(
                          width: 86,
                          height: 86,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 6,
                                  strokeCap: StrokeCap.round,
                                  color: CampusColors.cyan,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: .10,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(progress * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const Text(
                                    'TÍN CHỈ',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Color(0xFFBBD9E7),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: spacious
                        ? (constraints.maxWidth - 10) / 2
                        : constraints.maxWidth,
                    child: _AcademicMetric(
                      value: gradeNumber(summary.average10),
                      label: 'Điểm trung bình / 10',
                      icon: Icons.auto_graph_rounded,
                    ),
                  ),
                  SizedBox(
                    width: spacious
                        ? (constraints.maxWidth - 10) / 2
                        : constraints.maxWidth,
                    child: _AcademicMetric(
                      value: gradeNumber(summary.earnedCredits),
                      label: 'Tín chỉ tích lũy',
                      icon: Icons.workspace_premium_outlined,
                    ),
                  ),
                ],
              ),
              if (hasProgress) ...[
                const SizedBox(height: 14),
                Text(
                  '${gradeNumber(summary.earnedCredits)} / ${gradeNumber(summary.curriculumCredits)} tín chỉ chương trình',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFC7E1EB),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AcademicMetric extends StatelessWidget {
  const _AcademicMetric({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value, label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: CampusColors.mint, size: 17),
        const SizedBox(height: 9),
        Text(
          value,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFC7E1EB)),
        ),
      ],
    ),
  );
}
