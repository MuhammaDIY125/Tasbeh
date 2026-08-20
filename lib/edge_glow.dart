import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Насколько далеко свечение уходит от края поверхности.
const double kEdgeGlowSpread = 28;

/// Рисует свечение снаружи [shape] — вместо обводки по краю.
///
/// Экран под всплывающими поверхностями чёрный, поэтому глубину даёт не тень,
/// а свет: силуэт формы размывается, сама форма из результата вырезается, и
/// наружу остаётся дымка, обтекающая скругления.
///
/// Слоёв два: узкий и плотный держит кромку, широкий и слабый растворяет её в
/// экране. Одним слоем получается либо линия, либо мутное пятно.
void paintEdgeGlow(
  Canvas canvas, {
  required Path shape,
  required Rect bounds,
  required Color color,
  required double spread,
}) {
  if (bounds.isEmpty || spread <= 0) return;

  final area = Path()..addRect(bounds.inflate(spread));

  canvas.save();
  canvas.clipPath(Path.combine(PathOperation.difference, area, shape));
  canvas.drawPath(shape, _glowPaint(color, alpha: 0.9, sigma: spread / 6));
  canvas.drawPath(shape, _glowPaint(color, alpha: 0.45, sigma: spread / 2));
  canvas.restore();
}

Paint _glowPaint(Color color, {required double alpha, required double sigma}) =>
    Paint()
      ..color = color.withValues(alpha: color.a * alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

/// Форма поверхности со свечением по краю вместо обводки.
///
/// Подходит там, где Material не клипит себя по `shape` — это диалоги и нижние
/// листы (`Clip.none` по умолчанию). `Drawer` же при заданном `shape` включает
/// `Clip.hardEdge`, и всё, что ушло бы за край, обрезалось бы вместе с
/// содержимым; для него есть [EdgeGlow].
class EdgeGlowBorder extends ShapeBorder {
  final BorderRadiusGeometry borderRadius;
  final double spread;
  final Color color;

  const EdgeGlowBorder({
    required this.borderRadius,
    this.spread = kEdgeGlowSpread,
    this.color = AppTheme.edgeGlow,
  });

  /// Свечение лежит снаружи и места внутри поверхности не занимает.
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) =>
      paintEdgeGlow(
        canvas,
        shape: getOuterPath(rect, textDirection: textDirection),
        bounds: rect,
        color: color,
        spread: spread,
      );

  @override
  ShapeBorder scale(double t) => EdgeGlowBorder(
    borderRadius: borderRadius * t,
    spread: spread * t,
    color: color,
  );

  @override
  bool operator ==(Object other) =>
      other is EdgeGlowBorder &&
      other.borderRadius == borderRadius &&
      other.spread == spread &&
      other.color == color;

  @override
  int get hashCode => Object.hash(borderRadius, spread, color);
}

/// Свечение вокруг ребёнка — для поверхностей, которые клипят себя сами.
///
/// Рисуется снаружи ребёнка, поэтому и живёт снаружи него: [EdgeGlowBorder]
/// внутри клипящего Material'а был бы срезан по той же форме.
class EdgeGlow extends StatelessWidget {
  final BorderRadiusGeometry borderRadius;
  final double spread;
  final Color color;
  final Widget child;

  const EdgeGlow({
    super.key,
    required this.borderRadius,
    required this.child,
    this.spread = kEdgeGlowSpread,
    this.color = AppTheme.edgeGlow,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _EdgeGlowPainter(
      borderRadius: borderRadius.resolve(Directionality.maybeOf(context)),
      spread: spread,
      color: color,
    ),
    child: child,
  );
}

class _EdgeGlowPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final double spread;
  final Color color;

  const _EdgeGlowPainter({
    required this.borderRadius,
    required this.spread,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    paintEdgeGlow(
      canvas,
      shape: Path()..addRRect(borderRadius.toRRect(bounds)),
      bounds: bounds,
      color: color,
      spread: spread,
    );
  }

  @override
  bool shouldRepaint(_EdgeGlowPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.spread != spread ||
      oldDelegate.color != color;
}
