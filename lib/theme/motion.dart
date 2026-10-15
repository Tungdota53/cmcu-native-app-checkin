import 'package:flutter/material.dart';

Duration motionDuration(BuildContext context, [int milliseconds = 260]) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

/// Chỉ chạy một lần khi item được gắn vào cây, không chạy animation liên tục.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: motionDuration(context, 320),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (_, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, (1 - value) * 12),
        child: child,
      ),
    ),
  );
}
