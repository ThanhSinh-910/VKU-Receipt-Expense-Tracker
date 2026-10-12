import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'regex_parser.dart';

class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  TextRecognizer? _textRecognizer;

  TextRecognizer get recognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Process receipt image from given file path and extract structured data
  Future<ParsedReceiptResult> processReceipt(String imagePath) async {
    try {
      // Check platform compatibility (ML Kit is mobile Android/iOS native)
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        return _fallbackDesktopOcr(imagePath);
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await recognizer.processImage(inputImage);
      
      final rawText = recognizedText.text;
      debugPrint('--- [ML Kit OCR Detected Text] ---');
      debugPrint(rawText);
      debugPrint('----------------------------------');

      if (rawText.trim().isEmpty) {
        return ParsedReceiptResult(
          merchant: 'Hóa đơn chưa nhận diện được chữ',
          totalAmount: 0.0,
          date: DateTime.now(),
          category: 'Khác',
          rawText: '(Không phát hiện văn bản trong ảnh)',
          confidenceScore: 0.0,
        );
      }

      return RegexParserEngine.parse(rawText);
    } catch (e, stack) {
      debugPrint('Error processing OCR: $e\n$stack');
      return ParsedReceiptResult(
        merchant: 'Cửa hàng (Cần nhập tay)',
        totalAmount: 0.0,
        date: DateTime.now(),
        category: 'Khác',
        rawText: 'Lỗi OCR: $e',
        confidenceScore: 0.0,
      );
    }
  }

  /// Fallback parser when testing on Windows/macOS/Web
  ParsedReceiptResult _fallbackDesktopOcr(String imagePath) {
    // Provide realistic simulated test data for desktop debugging
    const simulatedRawText = '''
HIGHLANDS COFFEE
Chi nhánh Danang Riverside
Đ/C: 74 Bạch Đằng, Hải Châu, Đà Nẵng
Mã HĐ: HD-884920
Ngày: 12/10/2026  10:15:30
Thu ngân: Trang

1. Phin Sữa Đá (L)        39,000
2. Trà Sen Vàng (M)       45,000
3. Bánh Mì Thịt Nướng     25,000
--------------------------------
CỘNG TIỀN:               109,000
VAT (8%):                  8,720
TỔNG CỘNG:               117,720 VNĐ
TIỀN MẶT:                120,000
TIỀN THỐI:                 2,280

CẢM ƠN QUÝ KHÁCH VÀ HẸN GẶP LẠI!
''';
    return RegexParserEngine.parse(simulatedRawText);
  }

  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}
