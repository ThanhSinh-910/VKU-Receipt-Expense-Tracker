# 🧾 VKU Receipt OCR & Expense Tracker

> **Mini-Project 3: Receipt OCR & Expense Tracker**  
> **Trường Đại học Công nghệ Thông tin và Truyền thông Việt - Hàn (VKU)**  
> Ứng dụng di động Flutter nhận diện hóa đơn giấy qua máy ảnh (On-Device OCR) và quản lý chi tiêu cho sinh viên & ban quản lý câu lạc bộ VKU.

---

## 🌟 Tính Năng Nổi Bật

- 📸 **On-Device OCR Offline (3.5 pts):** Chụp ảnh qua camera hoặc chọn từ thư viện ảnh (`image_picker`). Nhận diện văn bản hoàn toàn ngoại tuyến không cần internet bằng **Google ML Kit Text Recognition**.
- 🧠 **Smart Dart Regex Parser Heuristics:** Tự động trích xuất chính xác **Tổng tiền** (hỗ trợ định dạng VND/USD/k/chấm/phẩy), **Ngày giao dịch**, **Tên cửa hàng/đơn vị**, và tự động phân loại danh mục thông minh.
- 🎨 **Custom Canvas Visualization (2.5 pts):** 100% tự vẽ bằng `CustomPainter` kèm chuyển động mượt mà (`AnimationController`):
  - **Biểu đồ tròn / Donut Chart:** Phân bổ chi tiêu theo danh mục, hiển thị tổng tiền ở tâm, hỗ trợ chạm tương tác phóng to lát cắt.
  - **Biểu đồ cột / Weekly Bar Chart:** Thống kê chi tiêu 7 ngày qua với các vạch chia tỉ lệ, góc bo tròn và hiệu ứng gradient nổi bật ngày hiện tại.
- 🗄️ **Clean State Management & Persistent SQLite DB (2.0 pts):**
  - Quản lý trạng thái bằng kiến trúc **Provider** (`ExpenseProvider`, `ThemeProvider`).
  - Cơ sở dữ liệu **SQLite** (`sqflite`) thực hiện đầy đủ các thao tác CRUD.
  - Lưu trữ tệp ảnh hóa đơn vào bộ nhớ ứng dụng (`path_provider`), tự động dọn dẹp khi xóa hóa đơn.
- ✨ **UI/UX Polish (1.0 pt):** Giao diện Material 3, Dark Mode toggle tức thì, Responsive layout, hộp thoại **Review & Manual Correction Dialog** hỗ trợ người dùng kiểm tra và điều chỉnh thông tin trước khi lưu.
- 📦 **Deliverables & Report (1.0 pt):**
  - Tệp **Signed Release APK:** [`app-release.apk`](app-release.apk) (đã biên dịch sẵn ở thư mục gốc).
  - 🎥 **Video Demo Ứng Dụng:** [`vid_demo_mnprj3.mp4`](vid_demo_mnprj3.mp4) (chạy trực tiếp trên thiết bị thực tế).
  - Báo cáo kỹ thuật chi tiết: [`TECHNICAL_REPORT.md`](TECHNICAL_REPORT.md) & [`SHORT_TECHNICAL_REPORT.md`](SHORT_TECHNICAL_REPORT.md).
  - Bộ kiểm thử tự động `flutter test` đạt 100%.

---

## 🏗️ Kiến Trúc Thư Mục

```
lib/
├── main.dart                          # Cấu hình MultiProvider, Material 3 Light/Dark theme
├── models/
│   └── expense.dart                   # Mô hình Expense, serialization SQLite toMap/fromMap
├── services/
│   ├── database_helper.dart           # SQLite helper CRUD & seeding dữ liệu mẫu VKU
│   ├── ocr_service.dart               # Trình bao bọc Google ML Kit on-device
│   └── regex_parser.dart              # Bộ máy phân tích Heuristics Regex (Total, Date, Merchant)
├── providers/
│   ├── expense_provider.dart          # Quản lý danh sách chi tiêu, bộ lọc, lưu ảnh vật lý
│   └── theme_provider.dart            # Quản lý chuyển đổi Light/Dark mode
├── widgets/
│   ├── charts/
│   │   ├── donut_chart_painter.dart   # CustomPainter vẽ biểu đồ Donut animated
│   │   ├── weekly_bar_chart_painter.dart # CustomPainter vẽ biểu đồ Bar chart 7 ngày
│   │   └── animated_charts.dart       # Widget điều khiển AnimationController và tương tác
│   └── expense_card.dart              # Thẻ hiển thị hóa đơn, thumbnail ảnh, vuốt để xóa
└── screens/
    ├── home_screen.dart               # Màn hình chính, tổng quan chi tiêu, tìm kiếm & bộ lọc
    ├── scanner_screen.dart            # Màn hình quét hóa đơn, hiệu ứng laser scanner
    ├── review_expense_screen.dart     # Hộp thoại xác thực dữ liệu và chỉnh sửa thủ công
    ├── statistics_screen.dart         # Màn hình thống kê chi tiết với biểu đồ CustomPainter
    └── expense_detail_screen.dart     # Xem chi tiết hóa đơn, xem ảnh full-size & văn bản OCR gốc
```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### 1. Cài đặt trực tiếp file APK lên thiết bị Android
Tệp cài đặt sẵn `app-release.apk` nằm ngay tại thư mục gốc của dự án:
```bash
adb install app-release.apk
```

### 2. Chạy ứng dụng từ mã nguồn Flutter
```bash
# Cài đặt các thư viện phụ thuộc
flutter pub get

# Chạy kiểm thử tự động
flutter test

# Kiểm tra phân tích mã nguồn
flutter analyze

# Chạy ứng dụng trên máy thật hoặc emulator
flutter run
```

---

## 📊 Bảng Điểm Đánh Giá (Rubric Checklist)

- [x] **On-Device OCR & Heuristics (3.5 pts):** Máy ảnh capture, Google ML Kit OCR offline, Regex trích xuất Total, Date, Merchant, Category.
- [x] **Custom Canvas Visualization (2.5 pts):** Tự vẽ 100% bằng `CustomPainter` (Donut Chart & Weekly Bar Chart), không dùng thư viện vẽ biểu đồ bên thứ 3.
- [x] **State Management & DB (2.0 pts):** Provider sạch sẽ, SQLite persistent CRUD, sao chép và lưu trữ ảnh hóa đơn ngoại tuyến.
- [x] **UI/UX Polish (1.0 pt):** Material 3, Dark Mode, Responsive, Hộp thoại Review & Manual Correction.
- [x] **Deliverables & Report (1.0 pt):** Signed Release APK (`app-release.apk`), báo cáo kỹ thuật `TECHNICAL_REPORT.md`, unit test 100% passed.
