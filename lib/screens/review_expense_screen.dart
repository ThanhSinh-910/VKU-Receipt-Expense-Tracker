import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/regex_parser.dart';

class ReviewExpenseScreen extends StatefulWidget {
  final File? imageFile;
  final ParsedReceiptResult? ocrResult;
  final Expense? existingExpense;

  const ReviewExpenseScreen({
    super.key,
    this.imageFile,
    this.ocrResult,
    this.existingExpense,
  });

  @override
  State<ReviewExpenseScreen> createState() => _ReviewExpenseScreenState();
}

class _ReviewExpenseScreenState extends State<ReviewExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  bool _showRawOcr = false;
  File? _currentImageFile;

  /// Validates that the given category is in Expense.categories list
  String _validatedCategory(String? cat) {
    if (cat != null && Expense.categories.contains(cat)) return cat;
    return Expense.categories.first;
  }

  @override
  void initState() {
    super.initState();
    _currentImageFile = widget.imageFile;

    if (widget.existingExpense != null) {
      final exp = widget.existingExpense!;
      _merchantController = TextEditingController(text: exp.merchant);
      _amountController =
          TextEditingController(text: exp.amount.toStringAsFixed(0));
      _noteController = TextEditingController(text: exp.note ?? '');
      _selectedDate = exp.date;
      _selectedCategory = _validatedCategory(exp.category);
      if (exp.imagePath != null && File(exp.imagePath!).existsSync()) {
        _currentImageFile = File(exp.imagePath!);
      }
    } else if (widget.ocrResult != null) {
      final res = widget.ocrResult!;
      _merchantController = TextEditingController(text: res.merchant);
      _amountController = TextEditingController(
        text: res.totalAmount > 0 ? res.totalAmount.toStringAsFixed(0) : '',
      );
      _noteController = TextEditingController(text: '');
      _selectedDate = res.date;
      _selectedCategory = _validatedCategory(res.category);
    } else {
      _merchantController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedCategory = Expense.categories.first;
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  double _parseVndAmount(String input) {
    var raw = input.trim();
    if (raw.toLowerCase().endsWith('k')) {
      final numPart = double.tryParse(raw.substring(0, raw.length - 1).replaceAll(',', '.')) ?? 0.0;
      return numPart * 1000;
    }
    raw = raw.replaceAll(RegExp(r'[^\d.,]'), '');
    if (raw.contains('.') && raw.contains(',')) {
      if (raw.indexOf('.') < raw.indexOf(',')) {
        raw = raw.replaceAll('.', '').replaceAll(',', '.');
      } else {
        raw = raw.replaceAll(',', '');
      }
      return double.tryParse(raw) ?? 0.0;
    } else if (raw.contains('.')) {
      final parts = raw.split('.');
      if (parts.length > 1 && parts.last.length == 3) {
        return double.tryParse(raw.replaceAll('.', '')) ?? 0.0;
      } else if (parts.length > 2) {
        return double.tryParse(raw.replaceAll('.', '')) ?? 0.0;
      }
      return double.tryParse(raw) ?? 0.0;
    } else if (raw.contains(',')) {
      final parts = raw.split(',');
      if (parts.length > 1 && parts.last.length == 3) {
        return double.tryParse(raw.replaceAll(',', '')) ?? 0.0;
      }
      return double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
    }
    return double.tryParse(raw.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
  }

  void _addQuickAmount(double delta) {
    final current = _parseVndAmount(_amountController.text);
    final next = (current + delta).clamp(0.0, 1000000000.0);
    setState(() {
      _amountController.text = next.toStringAsFixed(0);
    });
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final merchant = _merchantController.text.trim();
    final amount = _parseVndAmount(_amountController.text);
    final note = _noteController.text.trim();

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    if (widget.existingExpense != null) {
      final updated = widget.existingExpense!.copyWith(
        merchant: merchant,
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        note: note.isNotEmpty ? note : null,
      );
      await expenseProvider.updateExpense(
        expense: updated,
        newImageFile: _currentImageFile,
      );
    } else {
      final newExpense = Expense(
        merchant: merchant,
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        note: note.isNotEmpty ? note : null,
        rawOcrText: widget.ocrResult?.rawText,
      );
      await expenseProvider.addExpense(
        expense: newExpense,
        imageFile: _currentImageFile,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.existingExpense != null
              ? 'Đã cập nhật hóa đơn thành công!'
              : 'Đã lưu hóa đơn thành công!',
        ),
        backgroundColor: Colors.green.shade600,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final isEditing = widget.existingExpense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa hóa đơn' : 'Xác thực & Kiểm tra OCR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Lưu hóa đơn',
            onPressed: _saveExpense,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Receipt Image Preview
              if (_currentImageFile != null && _currentImageFile!.existsSync()) ...[
                GestureDetector(
                  onTap: () {
                    // Full screen preview dialog
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        child: InteractiveViewer(
                          child: Image.file(_currentImageFile!),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          _currentImageFile!,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          alignment: Alignment.bottomRight,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Chạm để phóng to ảnh',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notice Banner if from OCR
              if (widget.ocrResult != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dữ liệu đã được AI ML Kit tự động trích xuất. Vui lòng kiểm tra lại trước khi lưu.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Merchant Field
              TextFormField(
                controller: _merchantController,
                decoration: InputDecoration(
                  labelText: 'Tên cửa hàng / Đơn vị',
                  hintText: 'VD: Highlands Coffee, WinMart, Grab...',
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên cửa hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Total Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Tổng tiền (VND)',
                  hintText: 'VD: 85000 hoặc 85.000 hoặc 85k',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixText: '₫',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final parsed = _parseVndAmount(val);
                  if (parsed <= 0) {
                    return 'Số tiền không hợp lệ (phải lớn hơn 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),

              // Quick amount adjustment chips
              Row(
                children: [
                  const Text('Tăng nhanh: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 4),
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: const Text('+10k', style: TextStyle(fontSize: 11)),
                    onPressed: () => _addQuickAmount(10000),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: const Text('+50k', style: TextStyle(fontSize: 11)),
                    onPressed: () => _addQuickAmount(50000),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: const Text('+100k', style: TextStyle(fontSize: 11)),
                    onPressed: () => _addQuickAmount(100000),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: const Text('+200k', style: TextStyle(fontSize: 11)),
                    onPressed: () => _addQuickAmount(200000),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date Field with Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ngày giao dịch',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    dateFormatter.format(_selectedDate),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Category Dropdown — dùng InputDecorator + DropdownButton để tránh API lỗi thời
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Danh mục chi tiêu',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    isDense: true,
                    items: Expense.categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Note Field
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Ghi chú thêm (Tùy chọn)',
                  hintText: 'VD: Họp nhóm bài tập lớn, mua dụng cụ...',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Collapsible Raw OCR Inspection Box
              if (widget.ocrResult != null || (widget.existingExpense?.rawOcrText != null)) ...[
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  leading: const Icon(Icons.document_scanner_outlined),
                  title: const Text('Xem văn bản OCR gốc'),
                  subtitle: const Text('Kiểm tra các dòng chữ ML Kit nhận diện'),
                  trailing: Icon(_showRawOcr ? Icons.expand_less : Icons.expand_more),
                  onTap: () {
                    setState(() {
                      _showRawOcr = !_showRawOcr;
                    });
                  },
                ),
                if (_showRawOcr) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      widget.ocrResult?.rawText ?? widget.existingExpense?.rawOcrText ?? '',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],

              // Save Action Button
              FilledButton.icon(
                onPressed: _saveExpense,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  isEditing ? 'CẬP NHẬT HÓA ĐƠN' : 'LƯU VÀO SỔ CHI TIÊU',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),

              // Cancel Button
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Hủy bỏ'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
