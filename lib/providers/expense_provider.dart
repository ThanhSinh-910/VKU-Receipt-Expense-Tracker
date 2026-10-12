import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/expense.dart';
import '../services/database_helper.dart';

class DailyExpenseTotal {
  final DateTime date;
  final String dayLabel; // e.g., "T2", "T3", or "Mon"
  final double total;
  final bool isToday;

  DailyExpenseTotal({
    required this.date,
    required this.dayLabel,
    required this.total,
    required this.isToday,
  });
}

class ExpenseProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  DateTimeRange? get selectedDateRange => _selectedDateRange;

  ExpenseProvider() {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();
    try {
      _expenses = await _dbHelper.getAllExpenses();
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Expense> get filteredExpenses {
    return _expenses.where((expense) {
      // Filter by category
      if (_selectedCategory != null &&
          _selectedCategory != 'Tất cả' &&
          expense.category != _selectedCategory) {
        return false;
      }

      // Filter by search query (merchant or note)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchMerchant = expense.merchant.toLowerCase().contains(query);
        final matchNote = (expense.note ?? '').toLowerCase().contains(query);
        if (!matchMerchant && !matchNote) return false;
      }

      // Filter by date range
      if (_selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );
        if (expense.date.isBefore(start) || expense.date.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  double get totalSpent {
    return filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalAllExpenses {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Calculates distribution of spending across categories for CustomPainter Donut Chart
  Map<String, double> get categoryBreakdown {
    final Map<String, double> breakdown = {};
    for (final cat in Expense.categories) {
      breakdown[cat] = 0.0;
    }

    for (final exp in _expenses) {
      breakdown[exp.category] = (breakdown[exp.category] ?? 0.0) + exp.amount;
    }

    // Filter out categories with 0 for clean chart rendering, unless all are 0
    final result = Map<String, double>.fromEntries(
      breakdown.entries.where((e) => e.value > 0),
    );

    return result.isEmpty ? {'Chưa có chi tiêu': 0.0} : result;
  }

  /// Calculates weekly totals for the last 7 days for CustomPainter Bar Chart
  List<DailyExpenseTotal> get weeklyBreakdown {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<DailyExpenseTotal> days = [];

    // Mon to Sun or last 7 days
    for (int i = 6; i >= 0; i--) {
      final targetDate = today.subtract(Duration(days: i));
      
      // Calculate total for this day
      double daySum = 0.0;
      for (final exp in _expenses) {
        final expDate = DateTime(exp.date.year, exp.date.month, exp.date.day);
        if (expDate.isAtSameMomentAs(targetDate)) {
          daySum += exp.amount;
        }
      }

      final label = _getDayLabel(targetDate);
      days.add(DailyExpenseTotal(
        date: targetDate,
        dayLabel: label,
        total: daySum,
        isToday: i == 0,
      ));
    }

    return days;
  }

  String _getDayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
    notifyListeners();
  }

  /// Saves receipt photo to persistent app storage
  Future<String?> _persistImage(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, 'receipt_photos'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}';
      final savedPath = p.join(receiptsDir.path, fileName);
      final savedFile = await imageFile.copy(savedPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Failed to save receipt image to disk: $e');
      return imageFile.path;
    }
  }

  Future<void> addExpense({
    required Expense expense,
    File? imageFile,
  }) async {
    String? storedImagePath = expense.imagePath;
    if (imageFile != null) {
      storedImagePath = await _persistImage(imageFile);
    }

    final newExpense = expense.copyWith(imagePath: storedImagePath);
    await _dbHelper.insertExpense(newExpense);
    await loadExpenses();
  }

  Future<void> updateExpense({
    required Expense expense,
    File? newImageFile,
  }) async {
    String? storedImagePath = expense.imagePath;
    if (newImageFile != null) {
      storedImagePath = await _persistImage(newImageFile);
    }

    final updated = expense.copyWith(imagePath: storedImagePath);
    await _dbHelper.updateExpense(updated);
    await loadExpenses();
  }

  Future<void> deleteExpense(int id) async {
    // Check if expense has an image to clean up
    try {
      final item = _expenses.firstWhere((e) => e.id == id);
      if (item.imagePath != null && item.imagePath!.isNotEmpty) {
        final file = File(item.imagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {}

    await _dbHelper.deleteExpense(id);
    await loadExpenses();
  }
}
