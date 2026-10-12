import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/charts/animated_charts.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    final expenses = expenseProvider.expenses;
    final total = expenseProvider.totalAllExpenses;
    final count = expenses.length;
    final avg = count > 0 ? total / count : 0.0;
    final maxExpense = expenses.fold(0.0, (m, e) => math.max(m, e.amount));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo & Thống Kê'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary stat cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Số hóa đơn',
                    value: '$count',
                    icon: Icons.receipt,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Trung bình/Đơn',
                    value: currencyFormatter.format(avg),
                    icon: Icons.trending_up,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Tổng chi tiêu',
                    value: currencyFormatter.format(total),
                    icon: Icons.account_balance_wallet,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Đơn lớn nhất',
                    value: currencyFormatter.format(maxExpense),
                    icon: Icons.star,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // CustomPainter Animated Charts Section
            AnimatedChartsSection(
              categoryBreakdown: expenseProvider.categoryBreakdown,
              weeklyBreakdown: expenseProvider.weeklyBreakdown,
              totalAllExpenses: expenseProvider.totalAllExpenses,
            ),
            const SizedBox(height: 20),

            // Spending by Category List
            Text(
              'Chi tiết theo danh mục',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenseProvider.categoryBreakdown.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = expenseProvider.categoryBreakdown.entries.elementAt(index);
                  final catTotal = entry.value;
                  final percentage = total > 0 ? (catTotal / total) * 100 : 0.0;
                  return ListTile(
                    title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormatter.format(catTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
