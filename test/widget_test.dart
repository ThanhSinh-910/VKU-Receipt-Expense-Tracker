import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_expense_tracker/services/regex_parser.dart';
import 'package:receipt_expense_tracker/models/expense.dart';

void main() {
  group('RegexParserEngine Heuristics Tests', () {
    test('Correctly extracts Total, Date, and Merchant from Highlands Coffee receipt', () {
      const sampleText = '''
HIGHLANDS COFFEE
Chi nhánh Danang Riverside
Đ/C: 74 Bạch Đằng, Hải Châu, Đà Nẵng
Số HĐ: HD884920
Ngày: 12/10/2026  10:15:30

1. Phin Sữa Đá (L)        39,000
2. Trà Sen Vàng (M)       45,000
--------------------------------
CỘNG TIỀN:                84,000
VAT (8%):                  6,720
TỔNG CỘNG:               117,720 VNĐ
TIỀN MẶT:                120,000
''';

      final result = RegexParserEngine.parse(sampleText);

      expect(result.merchant, contains('HIGHLANDS COFFEE'));
      expect(result.totalAmount, equals(117720.0));
      expect(result.date.year, equals(2026));
      expect(result.date.month, equals(10));
      expect(result.date.day, equals(12));
      expect(result.category, equals('Ăn uống'));
    });

    test('Correctly extracts Total and Category for Supermarket receipt', () {
      const sampleText = '''
SIÊU THỊ WINMART+
Đà Nẵng
Ngày bán: 05/09/2026

Bánh mì sandwich           18.000
Sữa tươi TH True Milk      36.000
-----------------------------------
THÀNH TIỀN:                54.000 đ
''';

      final result = RegexParserEngine.parse(sampleText);

      expect(result.merchant, contains('SIÊU THỊ WINMART+'));
      expect(result.totalAmount, equals(54000.0));
      expect(result.category, equals('Mua sắm'));
      expect(result.date.day, equals(5));
      expect(result.date.month, equals(9));
    });

    test('Correctly extracts Transportation and Bookstore category heuristics', () {
      const grabReceipt = '''
GRAB VIETNAM
Chuyến xe GrabBike
Ngày: 01/10/2026
THANH TOÁN: 35.000 đ
''';
      final grabResult = RegexParserEngine.parse(grabReceipt);
      expect(grabResult.category, equals('Di chuyển'));
      expect(grabResult.totalAmount, equals(35000.0));

      const bookReceipt = '''
NHÀ SÁCH FAHASA
Ngày: 02/10/2026
TỔNG TIỀN: 89.000 VNĐ
''';
      final bookResult = RegexParserEngine.parse(bookReceipt);
      expect(bookResult.category, equals('Học tập'));
      expect(bookResult.totalAmount, equals(89000.0));
    });
  });

  group('Expense Model Tests', () {
    test('Expense model serialization toMap and fromMap works accurately', () {
      final expense = Expense(
        id: 1,
        merchant: 'Phúc Long Tea',
        amount: 65000,
        date: DateTime(2026, 10, 12),
        category: 'Ăn uống',
        note: 'Trà sữa',
      );

      final map = expense.toMap();
      final reconstructed = Expense.fromMap(map);

      expect(reconstructed.id, equals(1));
      expect(reconstructed.merchant, equals('Phúc Long Tea'));
      expect(reconstructed.amount, equals(65000.0));
      expect(reconstructed.category, equals('Ăn uống'));
      expect(reconstructed.note, equals('Trà sữa'));
    });
  });
}
