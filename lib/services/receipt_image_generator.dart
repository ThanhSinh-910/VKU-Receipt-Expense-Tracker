import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SampleReceiptData {
  final String title;
  final String subtitle;
  final String address;
  final String invoiceNo;
  final String dateStr;
  final List<Map<String, String>> items;
  final String subtotal;
  final String vat;
  final String total;
  final String category;
  final String rawText;

  SampleReceiptData({
    required this.title,
    required this.subtitle,
    required this.address,
    required this.invoiceNo,
    required this.dateStr,
    required this.items,
    required this.subtotal,
    required this.vat,
    required this.total,
    required this.category,
    required this.rawText,
  });
}

class ReceiptImageGenerator {
  static final Map<String, SampleReceiptData> samples = {
    'highlands': SampleReceiptData(
      title: 'HIGHLANDS COFFEE',
      subtitle: 'Chi nhánh Danang Riverside',
      address: '74 Bạch Đằng, Hải Châu, Đà Nẵng',
      invoiceNo: 'HD-884920',
      dateStr: '12/10/2026 10:15:30',
      items: [
        {'name': '1. Phin Sữa Đá (L)', 'price': '39.000'},
        {'name': '2. Trà Sen Vàng (M)', 'price': '45.000'},
        {'name': '3. Bánh Croissant', 'price': '29.000'},
      ],
      subtotal: '113.000',
      vat: '9.040',
      total: '122.040',
      category: 'Ăn uống',
      rawText: '''HIGHLANDS COFFEE
Chi nhánh Danang Riverside
Đ/C: 74 Bạch Đằng, Hải Châu, Đà Nẵng
Số HĐ: HD-884920
Ngày: 12/10/2026 10:15:30

1. Phin Sữa Đá (L)        39,000
2. Trà Sen Vàng (M)       45,000
3. Bánh Croissant         29,000
--------------------------------
CỘNG TIỀN:               113,000
THUẾ VAT (8%):             9,040
TỔNG CỘNG:               122,040 VNĐ
TIỀN MẶT:                150,000
TIỀN THỐI:                27,960

CẢM ƠN QUÝ KHÁCH VÀ HẸN GẶP LẠI!''',
    ),
    'winmart': SampleReceiptData(
      title: 'SIÊU THỊ WINMART+',
      subtitle: 'Cửa hàng 142 Ngô Thì Sĩ',
      address: '142 Ngô Thì Sĩ, Ngũ Hành Sơn, Đà Nẵng',
      invoiceNo: 'WM-20261011-094',
      dateStr: '11/10/2026 18:45:00',
      items: [
        {'name': '1. Bánh mì sandwich', 'price': '18.000'},
        {'name': '2. Sữa TH True Milk', 'price': '36.000'},
        {'name': '3. Mì Hảo Hảo (5 gói)', 'price': '22.500'},
        {'name': '4. Snack khoai tây', 'price': '14.000'},
      ],
      subtotal: '90.500',
      vat: '0',
      total: '90.500',
      category: 'Mua sắm',
      rawText: '''SIÊU THỊ WINMART+
Cửa hàng 142 Ngô Thì Sĩ
Đ/C: 142 Ngô Thì Sĩ, Ngũ Hành Sơn, Đà Nẵng
Ngày bán: 11/10/2026 18:45:00
Mã HĐ: WM-20261011-094

1. Bánh mì sandwich       18,000
2. Sữa TH True Milk       36,000
3. Mì Hảo Hảo (5 gói)     22,500
4. Snack khoai tây        14,000
--------------------------------
THÀNH TIỀN:               90,500 đ
GIẢM GIÁ:                      0
THANH TOÁN:               90,500 đ''',
    ),
    'fahasa': SampleReceiptData(
      title: 'NHÀ SÁCH FAHASA ĐÀ NẴNG',
      subtitle: 'Trung tâm sách Fahasa',
      address: '300-302 Lê Duẩn, Thanh Khê, Đà Nẵng',
      invoiceNo: 'FHS-77291',
      dateStr: '10/10/2026 15:10:00',
      items: [
        {'name': '1. Sổ tay A5 Lò xo VKU', 'price': '35.000'},
        {'name': '2. Bút bi Pilot G2 (x2)', 'price': '64.000'},
        {'name': '3. Bút dạ quang Highlight', 'price': '18.000'},
      ],
      subtotal: '117.000',
      vat: '0',
      total: '117.000',
      category: 'Học tập',
      rawText: '''NHÀ SÁCH FAHASA ĐÀ NẴNG
300-302 Lê Duẩn, Thanh Khê, Đà Nẵng
Ngày: 10/10/2026 15:10:00
Mã HĐ: FHS-77291

1. Sổ tay A5 Lò xo VKU    35,000
2. Bút bi Pilot G2 (x2)   64,000
3. Bút dạ quang Highlight 18,000
--------------------------------
TỔNG TIỀN:               117,000 VNĐ
TIỀN KHÁCH ĐƯA:          120,000
TIỀN TRẢ LẠI:              3,000''',
    ),
    'grab': SampleReceiptData(
      title: 'GRAB VIETNAM',
      subtitle: 'Chuyến xe GrabBike',
      address: 'KTX VKU -> Trung tâm Đà Nẵng',
      invoiceNo: 'GRB-99120',
      dateStr: '09/10/2026 08:30:00',
      items: [
        {'name': '1. Cước phí chuyến đi', 'price': '30.000'},
        {'name': '2. Phí nền tảng', 'price': '2.000'},
      ],
      subtotal: '32.000',
      vat: '0',
      total: '32.000',
      category: 'Di chuyển',
      rawText: '''GRAB VIETNAM
Chuyến xe GrabBike
Ngày: 09/10/2026 08:30:00
Mã chuyến: GRB-99120

1. Cước phí chuyến đi     30,000
2. Phí nền tảng            2,000
--------------------------------
THANH TOÁN:               32,000 đ''',
    ),
  };

  /// Generates a realistic receipt image file on device and returns the File object
  static Future<File> generateReceiptImage(String sampleKey) async {
    final data = samples[sampleKey] ?? samples['highlands']!;
    const width = 420.0;
    const height = 620.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    // 1. Draw paper background
    final bgPaint = Paint()..color = const Color(0xFFFFFDF8);
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), bgPaint);

    // Subtle paper border shadow
    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(const Rect.fromLTWH(2, 2, width - 4, height - 4), borderPaint);

    double y = 28.0;

    // 2. Draw Store Header
    _drawText(canvas, data.title, y, fontSize: 20, isBold: true, center: true, width: width);
    y += 28;
    _drawText(canvas, data.subtitle, y, fontSize: 13, center: true, width: width);
    y += 20;
    _drawText(canvas, data.address, y, fontSize: 11, color: Colors.black54, center: true, width: width);
    y += 20;
    _drawText(canvas, 'Số HĐ: ${data.invoiceNo}  •  Ngày: ${data.dateStr}', y, fontSize: 11, color: Colors.black54, center: true, width: width);
    y += 24;

    // 3. Dashed line
    _drawDashedLine(canvas, y, width);
    y += 18;

    // Column header
    _drawRow(canvas, 'TÊN MẶT HÀNG', 'THÀNH TIỀN (VNĐ)', y, width, isHeader: true);
    y += 22;

    // 4. Items
    for (final item in data.items) {
      _drawRow(canvas, item['name']!, item['price']!, y, width);
      y += 24;
    }

    // 5. Divider
    y += 8;
    _drawDashedLine(canvas, y, width);
    y += 16;

    // 6. Subtotal & VAT
    _drawRow(canvas, 'CỘNG TIỀN:', '${data.subtotal} đ', y, width);
    y += 22;
    if (data.vat != '0') {
      _drawRow(canvas, 'THUẾ VAT (8%):', '${data.vat} đ', y, width);
      y += 22;
    }

    // 7. TOTAL DUE (Bold & Highlighted)
    final totalBoxPaint = Paint()..color = const Color(0xFF0D9488).withValues(alpha: 0.1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(20, y - 4, width - 40, 36), const Radius.circular(8)),
      totalBoxPaint,
    );
    _drawRow(canvas, 'TỔNG CỘNG:', '${data.total} VNĐ', y + 4, width, isBold: true, color: const Color(0xFF0D9488));
    y += 46;

    // 8. Footer
    _drawDashedLine(canvas, y, width);
    y += 18;
    _drawText(canvas, 'CẢM ƠN QUÝ KHÁCH - HẸN GẶP LẠI!', y, fontSize: 12, isBold: true, center: true, width: width);
    y += 20;
    _drawText(canvas, 'Hóa đơn điện tử khởi tạo từ máy tính tiền', y, fontSize: 10, color: Colors.black45, center: true, width: width);
    y += 22;

    // 9. Fake barcode stripes
    final barcodePaint = Paint()..color = Colors.black87;
    double barX = 60.0;
    while (barX < width - 60.0) {
      final barW = (barX % 7 == 0 || barX % 5 == 0) ? 3.0 : 1.5;
      canvas.drawRect(Rect.fromLTWH(barX, y, barW, 26), barcodePaint);
      barX += barW + 2.5;
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/sample_receipt_${sampleKey}_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(buffer);
    return file;
  }

  static void _drawText(Canvas canvas, String text, double y,
      {double fontSize = 12, bool isBold = false, bool center = false, Color color = Colors.black87, required double width}) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );
    final painter = TextPainter(
      text: span,
      textAlign: center ? TextAlign.center : TextAlign.left,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 40);

    final x = center ? (width - painter.width) / 2 : 24.0;
    painter.paint(canvas, Offset(x, y));
  }

  static void _drawRow(Canvas canvas, String left, String right, double y, double width,
      {bool isBold = false, bool isHeader = false, Color? color}) {
    final leftSpan = TextSpan(
      text: left,
      style: TextStyle(
        color: color ?? (isHeader ? Colors.black54 : Colors.black87),
        fontSize: isBold ? 14 : (isHeader ? 11 : 12),
        fontWeight: (isBold || isHeader) ? FontWeight.bold : FontWeight.w500,
      ),
    );
    final leftPainter = TextPainter(
      text: leftSpan,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width * 0.6);

    final rightSpan = TextSpan(
      text: right,
      style: TextStyle(
        color: color ?? (isHeader ? Colors.black54 : Colors.black87),
        fontSize: isBold ? 15 : (isHeader ? 11 : 12),
        fontWeight: (isBold || isHeader) ? FontWeight.bold : FontWeight.w500,
      ),
    );
    final rightPainter = TextPainter(
      text: rightSpan,
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width * 0.4);

    leftPainter.paint(canvas, Offset(24, y));
    rightPainter.paint(canvas, Offset(width - 24 - rightPainter.width, y));
  }

  static void _drawDashedLine(Canvas canvas, double y, double width) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1;
    double startX = 24;
    while (startX < width - 24) {
      canvas.drawLine(Offset(startX, y), Offset(startX + 4, y), paint);
      startX += 8;
    }
  }
}
