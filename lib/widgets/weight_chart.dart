import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/weight_entry.dart';
import '../theme/app_theme.dart';

class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final double targetWeight;

  const WeightChart({
    super.key,
    required this.entries,
    required this.targetWeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (entries.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No weight logs recorded yet',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Recorded Weight',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 2,
                  color: AppTheme.accentTeal,
                ),
                const SizedBox(width: 6),
                Text(
                  'Target: ${targetWeight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentTeal,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Custom Canvas Chart
        SizedBox(
          height: 190,
          width: double.infinity,
          child: CustomPaint(
            painter: _WeightChartPainter(
              entries: entries,
              targetWeight: targetWeight,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Date range footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMM d').format(entries.first.date),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            if (entries.length > 2)
              Text(
                DateFormat('MMM d').format(entries[entries.length ~/ 2].date),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            Text(
              DateFormat('MMM d').format(entries.last.date),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final double targetWeight;
  final bool isDark;

  _WeightChartPainter({
    required this.entries,
    required this.targetWeight,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final weights = entries.map((e) => e.weightKg).toList();
    weights.add(targetWeight);

    double minWeight = weights.reduce((a, b) => a < b ? a : b) - 1.5;
    double maxWeight = weights.reduce((a, b) => a > b ? a : b) + 1.5;
    if (maxWeight - minWeight < 2.0) {
      maxWeight += 1.0;
      minWeight -= 1.0;
    }

    final double height = size.height;
    final double width = size.width;

    // Background horizontal gridlines
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Target Weight dashed line
    final targetY = height - ((targetWeight - minWeight) / (maxWeight - minWeight) * height);
    final targetLinePaint = Paint()
      ..color = AppTheme.accentTeal.withOpacity(0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double dashWidth = 5, dashSpace = 4, startX = 0;
    while (startX < width) {
      canvas.drawLine(Offset(startX, targetY), Offset(startX + dashWidth, targetY), targetLinePaint);
      startX += dashWidth + dashSpace;
    }

    // Coordinates of data points
    final points = <Offset>[];
    for (int i = 0; i < entries.length; i++) {
      final x = entries.length == 1 ? width / 2 : (i / (entries.length - 1)) * width;
      final y = height - ((entries[i].weightKg - minWeight) / (maxWeight - minWeight) * height);
      points.add(Offset(x, y));
    }

    // Fill gradient path
    if (points.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, height);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX = (p0.dx + p1.dx) / 2;
        fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }

      fillPath.lineTo(points.last.dx, height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.35),
            AppTheme.primaryGreen.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, width, height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Stroke curve path
    final strokePath = Path();
    strokePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      strokePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final strokePaint = Paint()
      ..color = AppTheme.primaryGreen
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(strokePath, strokePaint);

    // Draw point dots with value callouts
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];

      // Outer ring
      final outerDot = Paint()
        ..color = isDark ? const Color(0xFF0F172A) : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 6, outerDot);

      // Inner dot
      final innerDot = Paint()
        ..color = AppTheme.primaryGreen
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 4, innerDot);

      // Highlight latest weight
      if (i == points.length - 1) {
        final textSpan = TextSpan(
          text: '${entries[i].weightKg} kg',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            (pt.dx - textPainter.width / 2).clamp(0, width - textPainter.width),
            pt.dy - 20,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) => true;
}
