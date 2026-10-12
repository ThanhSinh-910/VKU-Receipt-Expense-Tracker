import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../providers/expense_provider.dart';

class WeeklyBarChartPainter extends CustomPainter {
  final List<DailyExpenseTotal> dailyData;
  final double animationProgress;
  final bool isDark;
  final Color primaryColor;

  WeeklyBarChartPainter({
    required this.dailyData,
    required this.animationProgress,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyData.isEmpty) return;

    final bottomPadding = 28.0;
    final topPadding = 24.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final chartWidth = size.width;

    // Find highest value for scaling
    double maxAmount = dailyData.fold(0.0, (max, item) => math.max(max, item.total));
    if (maxAmount <= 0) maxAmount = 100000; // default scale if all 0

    // Round up maxAmount to a friendly number
    final niceMax = _getNiceMax(maxAmount);

    // 1. Draw horizontal gridlines (3 lines: 0%, 50%, 100%)
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white12 : Colors.black12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final levels = [0.0, 0.5, 1.0];
    for (final level in levels) {
      final y = topPadding + chartHeight * (1.0 - level);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // 2. Draw bars
    final totalBars = dailyData.length;
    final barSpacing = chartWidth / totalBars;
    final barWidth = math.min(26.0, barSpacing * 0.55);

    for (int i = 0; i < totalBars; i++) {
      final data = dailyData[i];
      final centerX = barSpacing * i + (barSpacing / 2);

      // Height proportional to amount * animationProgress
      final normalizedHeight = (data.total / niceMax).clamp(0.0, 1.0);
      final animatedBarHeight = chartHeight * normalizedHeight * animationProgress;

      final barLeft = centerX - (barWidth / 2);
      final barRight = centerX + (barWidth / 2);
      final barBottom = topPadding + chartHeight;
      final barTop = barBottom - animatedBarHeight;

      // Draw background bar track (subtle)
      final trackPaint = Paint()
        ..color = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill;
      final trackRRect = RRect.fromRectAndCorners(
        Rect.fromLTRB(barLeft, topPadding, barRight, barBottom),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(trackRRect, trackPaint);

      // Draw animated value bar
      if (animatedBarHeight > 0) {
        final barPaint = Paint()
          ..style = PaintingStyle.fill;

        if (data.isToday) {
          // Highlight today with primary / accent gradient
          barPaint.shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              primaryColor,
              primaryColor.withValues(alpha: 0.75),
            ],
          ).createShader(Rect.fromLTRB(barLeft, barTop, barRight, barBottom));
        } else {
          barPaint.color = isDark
              ? Colors.tealAccent.withValues(alpha: 0.7)
              : const Color(0xFF0284C7);
        }

        final barRRect = RRect.fromRectAndCorners(
          Rect.fromLTRB(barLeft, barTop, barRight, barBottom),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(barRRect, barPaint);

        // Draw amount text above bar
        if (data.total > 0 && animationProgress > 0.4) {
          final amountText = _formatShortAmount(data.total);
          final textSpan = TextSpan(
            text: amountText,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          );
          final textPainter = TextPainter(
            text: textSpan,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          )..layout();

          textPainter.paint(
            canvas,
            Offset(centerX - (textPainter.width / 2), barTop - textPainter.height - 3),
          );
        }
      }

      // Draw day label below bar
      final labelSpan = TextSpan(
        text: data.dayLabel,
        style: TextStyle(
          color: data.isToday
              ? primaryColor
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          fontSize: 11,
          fontWeight: data.isToday ? FontWeight.bold : FontWeight.w500,
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(centerX - (labelPainter.width / 2), barBottom + 7),
      );
    }
  }

  double _getNiceMax(double val) {
    if (val <= 50000) return 50000;
    if (val <= 100000) return 100000;
    if (val <= 200000) return 200000;
    if (val <= 500000) return 500000;
    if (val <= 1000000) return 1000000;
    return (val * 1.25);
  }

  String _formatShortAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.dailyData != dailyData ||
        oldDelegate.isDark != isDark ||
        oldDelegate.primaryColor != primaryColor;
  }
}
