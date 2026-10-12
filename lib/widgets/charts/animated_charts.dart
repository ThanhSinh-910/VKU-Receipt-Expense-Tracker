import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'donut_chart_painter.dart';
import 'weekly_bar_chart_painter.dart';
import '../../providers/expense_provider.dart';

class AnimatedChartsSection extends StatefulWidget {
  final Map<String, double> categoryBreakdown;
  final List<DailyExpenseTotal> weeklyBreakdown;
  final double totalAllExpenses;

  const AnimatedChartsSection({
    super.key,
    required this.categoryBreakdown,
    required this.weeklyBreakdown,
    required this.totalAllExpenses,
  });

  @override
  State<AnimatedChartsSection> createState() => _AnimatedChartsSectionState();
}

class _AnimatedChartsSectionState extends State<AnimatedChartsSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  int _selectedChartTab = 0; // 0: Donut, 1: Bar
  int? _selectedSliceIndex;

  static const List<Color> _categoryColors = [
    Color(0xFF0D9488), // Teal
    Color(0xFFF59E0B), // Amber
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFF64748B), // Slate
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedChartsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAllExpenses != widget.totalAllExpenses) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _replayAnimation() {
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    // Prepare slices for donut chart
    final List<CategorySlice> slices = [];
    int colorIdx = 0;
    widget.categoryBreakdown.forEach((category, amount) {
      if (amount > 0) {
        final percentage = widget.totalAllExpenses > 0
            ? (amount / widget.totalAllExpenses) * 100
            : 0.0;
        slices.add(CategorySlice(
          category: category,
          amount: amount,
          color: _categoryColors[colorIdx % _categoryColors.length],
          percentage: percentage,
        ));
        colorIdx++;
      }
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Tab Switch and Replay button
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Danh mục'),
                        icon: Icon(Icons.pie_chart_outline, size: 18),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('Tuần này'),
                        icon: Icon(Icons.bar_chart, size: 18),
                      ),
                    ],
                    selected: {_selectedChartTab},
                    onSelectionChanged: (newSet) {
                      setState(() {
                        _selectedChartTab = newSet.first;
                      });
                      _replayAnimation();
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Phát lại hiệu ứng',
                  icon: const Icon(Icons.replay, size: 20),
                  onPressed: _replayAnimation,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Animated Chart Display
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                if (_selectedChartTab == 0) {
                  // Donut Chart View
                  return Column(
                    children: [
                      SizedBox(
                        height: 220,
                        width: 220,
                        child: CustomPaint(
                          painter: DonutChartPainter(
                            slices: slices,
                            animationProgress: _animation.value,
                            totalAmount: widget.totalAllExpenses,
                            isDark: isDark,
                            selectedIndex: _selectedSliceIndex,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Legend list
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: slices.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final s = entry.value;
                          final isSelected = _selectedSliceIndex == idx;
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() {
                                _selectedSliceIndex = isSelected ? null : idx;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? s.color.withValues(alpha: 0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected ? Border.all(color: s.color, width: 1.5) : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: s.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${s.category}: ${s.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                } else {
                  // Weekly Bar Chart View
                  final weekSum = widget.weeklyBreakdown.fold(0.0, (sum, i) => sum + i.total);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chi tiêu 7 ngày qua',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currencyFormatter.format(weekSum * _animation.value),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: CustomPaint(
                          size: const Size(double.infinity, 200),
                          painter: WeeklyBarChartPainter(
                            dailyData: widget.weeklyBreakdown,
                            animationProgress: _animation.value,
                            isDark: isDark,
                            primaryColor: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
