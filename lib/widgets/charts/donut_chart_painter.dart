import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class CategorySlice {
  final String category;
  final double amount;
  final Color color;
  final double percentage;

  CategorySlice({
    required this.category,
    required this.amount,
    required this.color,
    required this.percentage,
  });
}

class DonutChartPainter extends CustomPainter {
  final List<CategorySlice> slices;
  final double animationProgress; // 0.0 to 1.0
  final double totalAmount;
  final bool isDark;
  final int? selectedIndex;

  DonutChartPainter({
    required this.slices,
    required this.animationProgress,
    required this.totalAmount,
    required this.isDark,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 12;
    const strokeWidth = 28.0;
    final innerRadius = outerRadius - strokeWidth;

    // Draw background track / empty ring if no data
    if (slices.isEmpty || totalAmount <= 0) {
      final emptyPaint = Paint()
        ..color = isDark ? Colors.grey.shade800 : Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, outerRadius - strokeWidth / 2, emptyPaint);

      _drawCenterText(canvas, center, 'Chưa có', 'chi tiêu');
      return;
    }

    // Starting at top (-pi / 2)
    double startAngle = -math.pi / 2;
    final maxSweep = 2 * math.pi * animationProgress;
    double currentProgressSweep = 0;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final targetSliceSweep = (slice.amount / totalAmount) * 2 * math.pi;

      // Slice sweep constrained by animation progress
      final remainingAllowedSweep = maxSweep - currentProgressSweep;
      if (remainingAllowedSweep <= 0) break;

      final actualSweep = math.min(targetSliceSweep, remainingAllowedSweep);
      final isSelected = selectedIndex == i;

      // Slice arc
      final arcPaint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth + 6 : strokeWidth
        ..strokeCap = StrokeCap.butt;

      // Give a tiny gap between slices if multiple
      const gap = 0.03;
      final adjustedSweep = actualSweep > gap ? actualSweep - gap : actualSweep;
      final adjustedStart = startAngle + (gap / 2);

      final rect = Rect.fromCircle(
        center: center,
        radius: isSelected ? outerRadius - strokeWidth / 2 + 3 : outerRadius - strokeWidth / 2,
      );

      canvas.drawArc(rect, adjustedStart, adjustedSweep, false, arcPaint);

      startAngle += targetSliceSweep;
      currentProgressSweep += targetSliceSweep;
    }

    // Inner subtle shadow / circle
    final innerFillPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerFillPaint);

    // Draw center total display
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final formattedAmount = currencyFormatter.format(totalAmount * animationProgress);
    _drawCenterText(canvas, center, 'Tổng chi tiêu', formattedAmount);
  }

  void _drawCenterText(Canvas canvas, Offset center, String title, String value) {
    // 1. Draw Title
    final titleSpan = TextSpan(
      text: title,
      style: TextStyle(
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
    final titlePainter = TextPainter(
      text: titleSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 140);

    // 2. Draw Amount Value
    final valueSpan = TextSpan(
      text: value,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    final valuePainter = TextPainter(
      text: valueSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 140);

    final totalTextHeight = titlePainter.height + valuePainter.height + 4;
    final titleOffset = Offset(
      center.dx - (titlePainter.width / 2),
      center.dy - (totalTextHeight / 2),
    );
    final valueOffset = Offset(
      center.dx - (valuePainter.width / 2),
      titleOffset.dy + titlePainter.height + 4,
    );

    titlePainter.paint(canvas, titleOffset);
    valuePainter.paint(canvas, valueOffset);
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.totalAmount != totalAmount ||
        oldDelegate.slices != slices ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isDark != isDark;
  }
}
