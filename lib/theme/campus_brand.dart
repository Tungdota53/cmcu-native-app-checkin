import 'package:flutter/material.dart';
import '../core/app_brand.dart';

abstract final class CampusColors {
  static const navy = Color(0xFF092C46);
  static const cyan = Color(0xFF4AD8E9);
  static const mint = Color(0xFF91DEC5);
  static const gold = Color(0xFFF0CA82);
}

/// Dấu nhận diện gọn cho thanh điều hướng; biểu trưng gốc dùng ở cài đặt/icon.
class CampusMark extends StatelessWidget {
  const CampusMark({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * .3),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF16768E), CampusColors.navy],
              ),
              border: Border.all(
                color: CampusColors.cyan.withValues(alpha: .35),
              ),
              boxShadow: [
                BoxShadow(
                  color: CampusColors.cyan.withValues(alpha: .12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'IU',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * .43,
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
              ),
            ),
          ),
          Positioned(
            right: -3,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: CampusColors.mint,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check_rounded,
                size: size * .22,
                color: CampusColors.navy,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class CampusWordmark extends StatelessWidget {
  const CampusWordmark({super.key, required this.subtitle});
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const CampusMark(),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                AppBrand.name,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class CampusEmblem extends StatelessWidget {
  const CampusEmblem({super.key, this.size = 60});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Biểu trưng trường',
    image: true,
    child: Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: CampusColors.cyan.withValues(alpha: .6),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          AppBrand.emblemAsset,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}

/// Tấm nền nhận diện: ánh sáng cyan, đường nét khiên/check và lưới campus.
/// Đồ họa vector tĩnh, không chạy animation liên tục hoặc dùng backdrop blur.
class CampusSurface extends StatelessWidget {
  const CampusSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF103653), Color(0xFF0C5367)],
      ),
      border: Border.all(color: CampusColors.cyan.withValues(alpha: .26)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF07546C).withValues(alpha: .16),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _CampusBackdrop()),
            ),
          ),
        ),
        Padding(
          padding: padding,
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: child,
          ),
        ),
      ],
    ),
  );
}

class _CampusBackdrop extends CustomPainter {
  const _CampusBackdrop();
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Offset(size.width * .96, 0);
    canvas.drawCircle(
      glow,
      230,
      Paint()
        ..shader = RadialGradient(
          colors: [
            CampusColors.cyan.withValues(alpha: .19),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: glow, radius: 230)),
    );
    final lines = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width + size.height; x += 30) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        lines,
      );
    }
    final x = size.width - 116, y = size.height - 140;
    final shield = Path()
      ..moveTo(x + 60, y)
      ..lineTo(x + 112, y + 22)
      ..cubicTo(x + 112, y + 87, x + 94, y + 112, x + 60, y + 130)
      ..cubicTo(x + 26, y + 112, x + 8, y + 87, x + 8, y + 22)
      ..close();
    canvas.drawPath(
      shield,
      Paint()
        ..color = CampusColors.cyan.withValues(alpha: .07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final check = Path()
      ..moveTo(x + 35, y + 64)
      ..lineTo(x + 53, y + 82)
      ..lineTo(x + 89, y + 43);
    canvas.drawPath(
      check,
      Paint()
        ..color = CampusColors.mint.withValues(alpha: .07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CampusBackdrop oldDelegate) => false;
}

class CampusGlassStat extends StatelessWidget {
  const CampusGlassStat({
    super.key,
    required this.icon,
    required this.label,
    this.color = CampusColors.cyan,
  });
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
