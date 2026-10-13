import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ocr_service.dart';
import '../services/receipt_image_generator.dart';
import 'review_expense_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
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

  // ─── Chụp ảnh hoặc chọn từ thư viện ───────────────────────────────────────
  Future<void> _captureOrPickImage(ImageSource source) async {
    try {
      // Khi dùng Camera, xin quyền máy ảnh một cách nhẹ nhàng
      if (source == ImageSource.camera && Platform.isAndroid) {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          if (!mounted) return;
          final open = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cần quyền máy ảnh'),
              content: const Text(
                'Vui lòng cấp quyền Máy ảnh trong Cài đặt để có thể chụp ảnh hóa đơn.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Mở Cài đặt'),
                ),
              ],
            ),
          );
          if (open == true) openAppSettings();
          return;
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (pickedFile == null) return;

      setState(() {
        _isProcessing = true;
        _statusMessage = 'Đang nhận diện hóa đơn bằng AI Google ML Kit...';
      });

      final imageFile = File(pickedFile.path);
      final ocrResult = await _ocrService.processReceipt(imageFile.path);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Mở màn hình xác thực Review
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
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e. Hãy thử lại hoặc dùng mục Hóa đơn mẫu bên dưới.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }
  }

  // ─── Demo với hóa đơn mẫu (Tạo ảnh hóa đơn thật + Chạy OCR) ───────────────
  Future<void> _testWithSampleReceipt(String type) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang nạp ảnh hóa đơn thật và nhận diện bằng ML Kit...';
    });

    try {
      // 1. Tạo file ảnh PNG hóa đơn thật
      final imageFile = await ReceiptImageGenerator.generateReceiptImage(type);

      // 2. Chạy qua pipeline OCR thực tế
      final ocrResult = await _ocrService.processReceipt(imageFile.path);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // 3. Mở màn hình Review với ảnh hóa đơn thật và dữ liệu đã trích xuất
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
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi nạp hóa đơn mẫu: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                          child: const Icon(
                            Icons.receipt_long,
                            size: 70,
                            color: Colors.grey,
                          ),
                        ),
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
                                      color: Colors.redAccent
                                          .withValues(alpha: 0.8),
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
                    const SizedBox(height: 8),
                    Text(
                      'Mô hình Google ML Kit đang quét ký tự on-device...',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
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
                  // Banner giới thiệu
                  Container(
                    padding: const EdgeInsets.all(20),
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
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Quét Tự Động Bằng AI OCR',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Chụp trực tiếp từ Camera, chọn từ Thư viện ảnh, hoặc thử ngay với Kho Hóa Đơn Mẫu có sẵn (hỗ trợ kiểm thử trên máy ảo Android Studio).',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút Chụp Camera
                  FilledButton.icon(
                    onPressed: () => _captureOrPickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 22),
                    label: const Text(
                      'CHỤP ẢNH TỪ MÁY ẢNH (CAMERA)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nút Chọn Thư viện
                  OutlinedButton.icon(
                    onPressed: () => _captureOrPickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 22),
                    label: const Text(
                      'CHỌN ẢNH TỪ THƯ VIỆN',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nút Nhập thủ công
                  TextButton.icon(
                    onPressed: () async {
                      final saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReviewExpenseScreen(),
                        ),
                      );
                      if (!context.mounted) return;
                      if (saved == true) {
                        Navigator.pop(context, true);
                      }
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Hoặc nhập chi tiêu thủ công không dùng ảnh'),
                  ),
                  const SizedBox(height: 28),

                  // Header Hóa đơn mẫu
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'KHO HÓA ĐƠN MẪU THỬ NGHIỆM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Danh sách hóa đơn mẫu dạng Card
                  _buildSampleCard(
                    title: 'Highlands Coffee (Đà Nẵng)',
                    subtitle: 'Trà sen vàng, Phin sữa đá • 122.040 đ',
                    icon: Icons.coffee,
                    color: const Color(0xFFF97316),
                    onTap: () => _testWithSampleReceipt('highlands'),
                  ),
                  const SizedBox(height: 8),

                  _buildSampleCard(
                    title: 'Siêu thị WinMart+ (Ngũ Hành Sơn)',
                    subtitle: 'Bánh mì, sữa tươi, mì tôm • 90.500 đ',
                    icon: Icons.shopping_cart,
                    color: const Color(0xFF0D9488),
                    onTap: () => _testWithSampleReceipt('winmart'),
                  ),
                  const SizedBox(height: 8),

                  _buildSampleCard(
                    title: 'Nhà sách Fahasa (Lê Duẩn)',
                    subtitle: 'Sổ tay VKU, bút bi Pilot • 117.000 đ',
                    icon: Icons.menu_book,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _testWithSampleReceipt('fahasa'),
                  ),
                  const SizedBox(height: 8),

                  _buildSampleCard(
                    title: 'Grab Bike (KTX VKU -> Trung tâm)',
                    subtitle: 'Chuyến xe di chuyển • 32.000 đ',
                    icon: Icons.directions_bike,
                    color: const Color(0xFF3B82F6),
                    onTap: () => _testWithSampleReceipt('grab'),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSampleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: FilledButton.tonal(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('Quét thử', style: TextStyle(fontSize: 12)),
        ),
        onTap: onTap,
      ),
    );
  }
}
