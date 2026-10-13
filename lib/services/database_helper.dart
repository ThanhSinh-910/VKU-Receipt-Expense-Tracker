import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'receipt_expenses.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        imagePath TEXT,
        rawOcrText TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Seed realistic sample expenses for VKU student / club manager showcase
    final now = DateTime.now();
    final sampleExpenses = [
      Expense(
        merchant: 'Highlands Coffee',
        amount: 89000,
        date: now.subtract(const Duration(days: 0)),
        category: 'Ăn uống',
        note: 'Họp ban chủ nhiệm CLB Tin Học VKU',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Expense(
        merchant: 'WinMart+ Ngũ Hành Sơn',
        amount: 215000,
        date: now.subtract(const Duration(days: 1)),
        category: 'Mua sắm',
        note: 'Mua bánh kẹo và nước suối cho hội thảo',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Expense(
        merchant: 'Grab Bike',
        amount: 32000,
        date: now.subtract(const Duration(days: 2)),
        category: 'Di chuyển',
        note: 'Đi từ KTX VKU đến trung tâm thành phố',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Expense(
        merchant: 'Nhà sách Fahasa Đà Nẵng',
        amount: 145000,
        date: now.subtract(const Duration(days: 3)),
        category: 'Học tập',
        note: 'Mua tập vẽ giáo trình và bút dạ quang',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Expense(
        merchant: 'Viettel Telecom',
        amount: 120000,
        date: now.subtract(const Duration(days: 4)),
        category: 'Hóa đơn',
        note: 'Cước 4G tháng học tập trực tuyến',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Expense(
        merchant: 'Phúc Long Tea & Coffee',
        amount: 65000,
        date: now.subtract(const Duration(days: 5)),
        category: 'Ăn uống',
        note: 'Trà đào cam sả cùng bạn học',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Expense(
        merchant: 'Cơm tấm Sài Gòn VKU',
        amount: 35000,
        date: now.subtract(const Duration(days: 6)),
        category: 'Ăn uống',
        note: 'Bữa trưa tại canteen',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
    ];

    for (final expense in sampleExpenses) {
      await db.insert('expenses', expense.toMap());
    }
  }

  /// Seeds realistic initial data if the database is empty or upon user reset
  Future<void> seedInitialData() async {
    final db = await database;
    final now = DateTime.now();
    final sampleExpenses = [
      Expense(
        merchant: 'Highlands Coffee',
        amount: 89000,
        date: now.subtract(const Duration(days: 0)),
        category: 'Ăn uống',
        note: 'Họp ban chủ nhiệm CLB Tin Học VKU',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Expense(
        merchant: 'WinMart+ Ngũ Hành Sơn',
        amount: 215000,
        date: now.subtract(const Duration(days: 1)),
        category: 'Mua sắm',
        note: 'Mua bánh kẹo và nước suối cho hội thảo',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Expense(
        merchant: 'Grab Bike',
        amount: 32000,
        date: now.subtract(const Duration(days: 2)),
        category: 'Di chuyển',
        note: 'Đi từ KTX VKU đến trung tâm thành phố',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Expense(
        merchant: 'Nhà sách Fahasa Đà Nẵng',
        amount: 145000,
        date: now.subtract(const Duration(days: 3)),
        category: 'Học tập',
        note: 'Mua tập vẽ giáo trình và bút dạ quang',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Expense(
        merchant: 'Viettel Telecom',
        amount: 120000,
        date: now.subtract(const Duration(days: 4)),
        category: 'Hóa đơn',
        note: 'Cước 4G tháng học tập trực tuyến',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Expense(
        merchant: 'Phúc Long Tea & Coffee',
        amount: 65000,
        date: now.subtract(const Duration(days: 5)),
        category: 'Ăn uống',
        note: 'Trà đào cam sả cùng bạn học',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Expense(
        merchant: 'Cơm tấm Sài Gòn VKU',
        amount: 35000,
        date: now.subtract(const Duration(days: 6)),
        category: 'Ăn uống',
        note: 'Bữa trưa tại canteen',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
    ];

    for (final expense in sampleExpenses) {
      await db.insert('expenses', expense.toMap());
    }
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('expenses');
  }
}
