# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Mini-Project 3: Receipt OCR & Expense Tracker  
**Team / Student Name:** Nguyễn Thanh Sinh (GitHub: ThanhSinh-910)  
**Submission Date:** 14/10/2026  

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Team Members:**
  1. Nguyễn Thanh Sinh — Student ID: [22ITxxx] — Role: Full-stack Mobile Architecture & Core Logic — Contribution: [100%]
* **🔗 Live Demo / APK Deliverable:** [Download Signed app-release.apk](https://github.com/ThanhSinh-910/VKU-Receipt-Expense-Tracker/raw/master/app-release.apk) *(Cũng có sẵn tại thư mục gốc dự án: `./app-release.apk`)*
* **💻 GitHub Repository:** [https://github.com/ThanhSinh-910/VKU-Receipt-Expense-Tracker](https://github.com/ThanhSinh-910/VKU-Receipt-Expense-Tracker)
* **🎥 Video Demo:** [Watch Demo Video (vid_demo_mnprj3.mp4)](https://github.com/ThanhSinh-910/VKU-Receipt-Expense-Tracker/blob/master/vid_demo_mnprj3.mp4) *(Xem trực tiếp trên GitHub hoặc tệp `vid_demo_mnprj3.mp4` tại thư mục gốc)*

---

## 2. FEATURE IMPLEMENTATION CHECKLIST
| # | Required Feature | Status | Implementation Details & Acceptance Level |
|:---:|---|:---:|---|
| 1 | **On-Device OCR & Heuristics (3.5 pts)** | ✅ Complete | Chụp ảnh camera & chọn thư viện (`image_picker`), nhận diện chữ ngoại tuyến 100% bằng **Google ML Kit Text Recognition**. Bộ máy **Dart Heuristics Regex Engine** tự động trích xuất chính xác Tổng tiền (VND, số nghìn, viết tắt 'k'), Ngày giao dịch, Tên cửa hàng và suy luận danh mục chi tiêu. |
| 2 | **Custom Canvas Visualization (2.5 pts)** | ✅ Complete | Không sử dụng thư viện chart bên thứ 3; tự vẽ 100% bằng `CustomPainter` & `AnimationController`: **Animated Donut Chart** (hiển thị tâm tổng tiền, chạm mở rộng lát cắt) và **Animated Weekly Bar Chart** (thống kê 7 ngày, vạch chia tỉ lệ, góc bo tròn và gradient nổi bật ngày hôm nay). |
| 3 | **Local Persistence & State Management (2.0 pts)** | ✅ Complete | Quản lý trạng thái bằng kiến trúc **Provider** (`ExpenseProvider`, `ThemeProvider`). Cơ sở dữ liệu cục bộ **SQLite** (`sqflite`) thực hiện đầy đủ CRUD, lưu trữ tệp ảnh hóa đơn vật lý vào thư mục ứng dụng qua `path_provider`, tự động dọn dẹp file khi xóa. |
| 4 | **UI/UX Polish & Review Flow (1.0 pt)** | ✅ Complete | Giao diện chuẩn **Material 3**, hỗ trợ chuyển đổi tức thì **Light / Dark Mode**. Quy trình **Review & Manual Correction Dialog** cho phép phóng to ảnh (`InteractiveViewer`), kiểm tra dữ liệu OCR, sửa thông tin trước khi lưu. Hỗ trợ vuốt để xóa (`Dismissible`), tìm kiếm và lọc danh mục. |
| 5 | **Deliverables & Engineering Quality (1.0 pt)** | ✅ Complete | Tệp Signed APK sẵn sàng cài đặt (`app-release.apk`), bộ kiểm thử tự động `flutter test` đạt 100% Passed, phân tích mã nguồn `flutter analyze` đạt 0 cảnh báo/lỗi, cấu hình `compileSdk = 36` tương thích Android 14/15. |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE

### 3.1. Directory Structure
```text
lib/
├── main.dart                          # Điểm khởi chạy, MultiProvider, Material 3 Theme (Light/Dark)
├── models/
│   └── expense.dart                   # Model Expense, SQLite toMap/fromMap serialization
├── services/
│   ├── database_helper.dart           # SQLite CRUD, tự động khởi tạo dữ liệu mẫu VKU
│   ├── ocr_service.dart               # Trình bao bọc Google ML Kit On-Device Text Recognition
│   ├── regex_parser.dart              # Bộ phân tích Heuristics Regex (Total, Date, Merchant, Category)
│   └── receipt_image_generator.dart   # Hóa đơn mẫu giả lập hỗ trợ chạy thử nghiệm trên máy ảo/desktop
├── providers/
│   ├── expense_provider.dart          # Quản lý danh sách chi tiêu, tìm kiếm, bộ lọc, lưu ảnh vật lý
│   └── theme_provider.dart            # Quản lý trạng thái chuyển đổi giao diện Sáng / Tối
├── widgets/
│   ├── charts/
│   │   ├── donut_chart_painter.dart   # CustomPainter vẽ biểu đồ Donut kèm Sweep Animation & tương tác
│   │   ├── weekly_bar_chart_painter.dart # CustomPainter vẽ biểu đồ cột 7 ngày với gradient
│   │   └── animated_charts.dart       # Widget bao bọc điều khiển AnimationController
│   └── expense_card.dart              # Thẻ hiển thị hóa đơn, thumbnail ảnh, vuốt để xóa
└── screens/
    ├── home_screen.dart               # Màn hình chính: Tổng quan số dư, danh sách hóa đơn, tìm kiếm
    ├── scanner_screen.dart            # Màn hình quét hóa đơn: Chụp/chọn ảnh, hiệu ứng laser scanner
    ├── review_expense_screen.dart     # Hộp thoại xác thực dữ liệu OCR và chỉnh sửa thủ công
    ├── statistics_screen.dart         # Màn hình thống kê chuyên sâu với 2 biểu đồ CustomPainter
    └── expense_detail_screen.dart     # Chi tiết hóa đơn, xem ảnh full-size và chuỗi OCR thô
```

### 3.2. State Management & Data Flow
* Luồng dữ liệu tuân thủ mô hình một chiều (**Unidirectional Data Flow**):
  `ScannerScreen (Capture Image)` ➔ `OcrService (Extract Raw Text)` ➔ `RegexParserEngine (Parse Fields)` ➔ `ReviewExpenseScreen (User Verified)` ➔ `ExpenseProvider` ➔ `DatabaseHelper (SQLite Insert)` ➔ `NotifyListeners()` ➔ `HomeScreen & StatisticsScreen Update`.
* **Exception Handling & Resilience:**
  - Nếu OCR không nhận diện được chữ (ảnh mờ/cháy sáng), hệ thống kích hoạt cơ chế fallback an toàn, không làm ứng ứng dụng bị crash và cho phép người dùng tự điền số tiền tại màn hình Review.
  - Quản lý tệp ngoại tuyến: Tệp ảnh được copy sang thư mục riêng của app; khối `try-catch` đảm bảo nếu tệp ảnh bị xóa ngoài ý muốn, UI vẫn hiển thị icon giữ chỗ an toàn.

---

## 4. EMPIRICAL EVIDENCE & SCREENSHOTS

*(Chèn 3–4 ảnh chụp màn hình ứng dụng thực tế trên thiết bị hoặc máy ảo)*

| 1. Màn hình chính & Danh sách chi tiêu | 2. Màn hình quét & Review OCR |
|:---:|:---:|
| ![Home Screen](assets/screenshots/screenshot_home.png)<br>*(Tổng quan số dư, bộ lọc danh mục và thẻ hóa đơn vuốt để xóa)* | ![Review Screen](assets/screenshots/screenshot_review.png)<br>*(Ảnh hóa đơn, tự động trích xuất Tổng tiền, Ngày tháng, Tên quán)* |

| 3. Biểu đồ thống kê CustomPainter (Donut) | 4. Biểu đồ cột chi tiêu tuần & Dark Mode |
|:---:|:---:|
| ![Donut Chart](assets/screenshots/screenshot_donut.png)<br>*(Biểu đồ Donut tự vẽ 100%, chạm tương tác xem chi tiết)* | ![Bar Chart & Dark Mode](assets/screenshots/screenshot_barchart.png)<br>*(Biểu đồ cột 7 ngày có dải màu gradient và giao diện Dark Theme)* |

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS

### Thách thức 1: Độ phân mảnh định dạng hóa đơn tiếng Việt và xử lý nhiễu OCR
* **Vấn đề:** Hóa đơn tại các quán cà phê, nhà sách, siêu thị Việt Nam có quy cách viết số tiền rất đa dạng (dấu chấm hàng nghìn như `117.720 đ`, dấu phẩy, viết tắt `50k`, hoặc chữ in hoa/thường lẫn lộn). Ngoài ra, OCR thường quét dính các dòng rác ở đầu hóa đơn (như "Phiếu thanh toán", "Mã số thuế", "Địa chỉ").
* **Giải pháp:** Xây dựng **Dart Regex Parser Heuristics** đa tầng:
  1. *Lọc tên quán:* Quét 7 dòng đầu tiên kết hợp Blacklist Regex để loại bỏ toàn bộ từ khóa hành chính/tiêu đề rác.
  2. *Trích xuất tiền:* Quét ngược từ dưới lên (vì tổng tiền luôn ở đáy hóa đơn), ưu tiên các từ khóa trọng số cao (`TỔNG CỘNG`, `THÀNH TIỀN`, `TOTAL DUE`).
  3. *Chuẩn hóa số học:* Thuật toán bóc tách dấu phân cách hàng nghìn và quy đổi đuôi `k` thành bội số 1.000, có cơ chế fallback lấy giá trị cực đại hợp lý nếu từ khóa bị mờ.

### Thách thức 2: Xung đột biên dịch Kotlin DSL và tương thích Android SDK 36
* **Vấn đề:** Khi biên dịch trên thiết bị thật (OPPO A74), thư viện `permission_handler_android: 14.1.0` gặp lỗi biên dịch cú pháp trong script Gradle Kotlin DSL (`Unresolved reference: compilerOptions, jvmTarget`), đồng thời các plugin ML Kit thế hệ mới yêu cầu `compileSdk >= 36`.
* **Giải pháp:** 
  1. Khóa phiên bản phụ thuộc trong `pubspec.yaml` về `permission_handler: 11.3.1` (sử dụng plugin Android tương thích `12.1.0` ổn định).
  2. Nâng cấp cấu hình `compileSdk = 36` trong `android/app/build.gradle.kts`. Bản build debug và release sau đó đã biên dịch thành công 100% mà không còn bất kỳ lỗi nào.
