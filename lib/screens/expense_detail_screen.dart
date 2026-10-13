import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'review_expense_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final currentExpense = expenseProvider.expenses.firstWhere(
      (e) => e.id == expense.id,
      orElse: () => expense,
    );
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Chỉnh sửa',
            onPressed: () async {
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewExpenseScreen(existingExpense: currentExpense),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Xóa',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content: Text('Bạn có chắc muốn xóa hóa đơn "${expense.merchant}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await Provider.of<ExpenseProvider>(context, listen: false).deleteExpense(expense.id!);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Receipt Image Preview
            if (currentExpense.imagePath != null && File(currentExpense.imagePath!).existsSync()) ...[
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      child: InteractiveViewer(
                        child: Image.file(File(currentExpense.imagePath!)),
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(
                    File(currentExpense.imagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Main Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      currentExpense.merchant,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(currentExpense.amount),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(
                        currentExpense.category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: theme.colorScheme.primaryContainer,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metadata card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Ngày thanh toán'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(currentExpense.date)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Thời gian tạo'),
                    subtitle: Text(dateFormatter.format(currentExpense.createdAt)),
                  ),
                  if (currentExpense.note != null && currentExpense.note!.isNotEmpty) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notes),
                      title: const Text('Ghi chú'),
                      subtitle: Text(currentExpense.note!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Raw OCR data if saved
            if (currentExpense.rawOcrText != null && currentExpense.rawOcrText!.isNotEmpty) ...[
              ExpansionTile(
                title: const Text('Văn bản nhận diện từ OCR'),
                leading: const Icon(Icons.document_scanner),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    child: SelectableText(
                      currentExpense.rawOcrText!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
