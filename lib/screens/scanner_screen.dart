import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/regex_parser.dart';
import 'review_expense_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;
  String _statusMessage = '';

  late AnimationController _scanAnimController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    super.dispose();
  }

  Future<void> _captureOrPickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      setState(() {
        _isProcessing = true;
        _statusMessage = 'Đang nhận diện văn bản bằng AI Google ML Kit...';
      });

      final imageFile = File(pickedFile.path);
      final ocrResult = await _ocrService.processReceipt(imageFile.path);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });

      // Navigate to Review Screen
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewExpenseScreen(
            imageFile: imageFile,
            ocrResult: ocrResult,
          ),
        ),
      );

      if (saved == true && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi quét hóa đơn: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Provides instant test samples (useful for demo without camera or on emulators)
  void _testWithSampleReceipt(String receiptType) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang nạp hóa đơn mẫu và chạy Regex Parser...';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    String sampleRawText = '';
    if (receiptType == 'highlands') {
      sampleRawText = '''
HIGHLANDS COFFEE
Tầng 1 TTTM Vincom Đà Nẵng
Đ/C: 910A Ngô Quyền, Sơn Trà, Đà Nẵng
Số HĐ: HD90483
Ngày: 12/10/2026 09:20:15
Thu ngân: Hương Ly

1. Phin Sữa Tươi (L)        45,000
2. Trà Thạch Đào (M)        49,000
3. Bánh Croissant           29,000
-----------------------------------
CỘNG TIỀN:                 123,000
THUẾ VAT (8%):               9,840
TỔNG CỘNG:                 132,840 VNĐ
TIỀN MẶT:                  150,000
TIỀN THỐI:                  17,160

CẢM ƠN QUÝ KHÁCH - HẸN GẶP LẠI!
''';
    } else if (receiptType == 'winmart') {
      sampleRawText = '''
SIÊU THỊ WINMART+
Cửa hàng: 142 Ngô Thì Sĩ, Đà Nẵng
Ngày bán: 11/10/2026 18:45:00
Mã giao dịch: WM-20261011-094

Bánh mì sandwich           18,000
Sữa tươi TH True Milk      36,000
Mì tôm Hảo Hảo (5 gói)     22,500
Snack khoai tây Ostar      14,000
-----------------------------------
THÀNH TIỀN:                90,500 đ
GIẢM GIÁ THÀNH VIÊN:            0
THANH TOÁN:                90,500 đ
''';
    } else {
      sampleRawText = '''
NHÀ SÁCH FAHASA ĐÀ NẴNG
300-302 Lê Duẩn, Tân Chính, Thanh Khê
Ngày: 10/10/2026 15:10:00

Sổ tay A5 Lò xo VKU         35,000
Bút bi Pilot G2 (x2)        64,000
Bút dạ quang Highlighter    18,000
-----------------------------------
TỔNG TIỀN:                 117,000 VNĐ
TIỀN KHÁCH ĐƯA:            120,000
TIỀN TRẢ LẠI:                3,000
''';
    }

    final ocrResult = RegexParserEngine.parse(sampleRawText);

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewExpenseScreen(
          imageFile: null,
          ocrResult: ocrResult,
        ),
      ),
    );

    if (saved == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Hóa Đơn OCR'),
      ),
      body: _isProcessing
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long, size: 70, color: Colors.grey),
                        ),
                        // Animated scanner line
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: 20 + (_scanAnimation.value * 140),
                              child: Container(
                                width: 130,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withValues(alpha: 0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Scanner graphic / tip
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.surfaceContainerHighest,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.document_scanner,
                          size: 72,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Quét tự động hóa đơn',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chụp ảnh hoặc chọn hóa đơn từ thư viện. Mô hình Google ML Kit on-device sẽ nhận diện số tiền, ngày và tên cửa hàng.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Capture Buttons
                  FilledButton.icon(
                    onPressed: () => _captureOrPickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 24),
                    label: const Text('CHỤP TỪ MÁY ẢNH (CAMERA)', style: TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  OutlinedButton.icon(
                    onPressed: () => _captureOrPickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 24),
                    label: const Text('CHỌN TỪ THƯ VIỆN ẢNH', style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Divider with Sample Receipts for Demo
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'HÓA ĐƠN THỬ NGHIỆM DEMO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick test cards
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.coffee, size: 18),
                        label: const Text('Highlands Coffee (132k)'),
                        onPressed: () => _testWithSampleReceipt('highlands'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.shopping_cart, size: 18),
                        label: const Text('WinMart+ (90.5k)'),
                        onPressed: () => _testWithSampleReceipt('winmart'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.menu_book, size: 18),
                        label: const Text('Nhà sách Fahasa (117k)'),
                        onPressed: () => _testWithSampleReceipt('fahasa'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
