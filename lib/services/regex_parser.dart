class ParsedReceiptResult {
  final String merchant;
  final double totalAmount;
  final DateTime date;
  final String category;
  final String rawText;
  final double confidenceScore;

  ParsedReceiptResult({
    required this.merchant,
    required this.totalAmount,
    required this.date,
    required this.category,
    required this.rawText,
    this.confidenceScore = 1.0,
  });
}

class RegexParserEngine {
  /// Main parser method taking raw OCR lines and returning structured receipt data
  static ParsedReceiptResult parse(String rawOcrText) {
    if (rawOcrText.trim().isEmpty) {
      return ParsedReceiptResult(
        merchant: 'Không rõ cửa hàng',
        totalAmount: 0.0,
        date: DateTime.now(),
        category: 'Khác',
        rawText: '',
        confidenceScore: 0.0,
      );
    }

    final lines = rawOcrText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchant = extractMerchant(lines);
    final total = extractTotalAmount(lines, rawOcrText);
    final date = extractDate(lines, rawOcrText);
    final category = inferCategory(merchant, rawOcrText);

    return ParsedReceiptResult(
      merchant: merchant,
      totalAmount: total,
      date: date,
      category: category,
      rawText: rawOcrText,
    );
  }

  /// Extracts Merchant/Store Name from top lines of receipt
  static String extractMerchant(List<String> lines) {
    final junkPatterns = [
      RegExp(r'^(h[oó]a\s*đ[oơ]n|phi[eê]u\s*thanh\s*to[aá]n|receipt|invoice|tax\s*invoice|bill)', caseSensitive: false),
      RegExp(r'^(b[aá]n\s*l[eẻ]|gi[aá]\s*tr[iị]\s*gia\s*t[aă]ng|gtgt|vat)', caseSensitive: false),
      RegExp(r'^(xin\s*ch[aà]o|welcome|c[aả]m\s*[oơ]n|thank\s*you)', caseSensitive: false),
      RegExp(r'^(m[aã]\s*s[oố]\s*thu[eế]|mst|tax\s*code|mst:)', caseSensitive: false),
      RegExp(r'^(đ[iị]a\s*ch[iỉ]|address|đ\/c:|dc:)', caseSensitive: false),
      RegExp(r'^(s[oố]\s*đi[eệ]n\s*tho[aạ]i|tel|phone|hotline|dt:)', caseSensitive: false),
      RegExp(r'^(ng[aà]y|date|time|gi[oờ]|thu\s*ng[aâ]n|cashier)', caseSensitive: false),
      RegExp(r'^(b[aà]n\s*s[oố]|table|order\s*no|stt)', caseSensitive: false),
      RegExp(r'^\d+$'), // Only numbers
      RegExp(r'^[=\-_*#.~]{3,}$'), // Separators
    ];

    // Check top 6 lines
    final searchLines = lines.take(7).toList();
    for (final line in searchLines) {
      final trimmed = line.trim();
      if (trimmed.length < 3) continue;

      bool isJunk = false;
      for (final pattern in junkPatterns) {
        if (pattern.hasMatch(trimmed)) {
          isJunk = true;
          break;
        }
      }

      if (!isJunk) {
        // Clean up common merchant prefixes
        var cleaned = trimmed
            .replaceAll(RegExp(r'^(C[uử]a\s*h[aà]ng|Chi\s*nh[aá]nh|Qu[aá]n|Shop|Store)\s*[:\-]?\s*', caseSensitive: false), '')
            .trim();
        if (cleaned.isNotEmpty && cleaned.length >= 3) {
          return cleaned;
        }
      }
    }

    // Fallback: Return first non-empty line
    return lines.isNotEmpty ? lines.first : 'Cửa hàng không tên';
  }

  /// Extracts Total Amount with prioritize regex keywords for Vietnamese & English
  static double extractTotalAmount(List<String> lines, String fullText) {
    // 1. High priority keywords for Total
    final totalKeywords = [
      RegExp(r'(t[oổ]ng\s*c[oộ]ng|tong\s*cong)', caseSensitive: false),
      RegExp(r'(th[aà]nh\s*ti[eề]n|thanh\s*tien)', caseSensitive: false),
      RegExp(r'(t[oổ]ng\s*ti[eề]n|tong\s*tien)', caseSensitive: false),
      RegExp(r'(thanh\s*to[aá]n|thanh\s*toan)', caseSensitive: false),
      RegExp(r'(c[oộ]ng\s*ti[eề]n|cong\s*tien)', caseSensitive: false),
      RegExp(r'(ti[eề]n\s*ph[aả]i\s*tr[aả]|phai\s*tra)', caseSensitive: false),
      RegExp(r'(grand\s*total|total\s*due|amount\s*due|total\s*amount|\btotal\b)', caseSensitive: false),
      RegExp(r'(\bnet\b|subtotal)', caseSensitive: false),
    ];

    // Search lines from bottom to top for total keywords (totals are usually at the bottom)
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      for (final keyword in totalKeywords) {
        if (keyword.hasMatch(line)) {
          final amount = _parseAmountFromLine(line);
          if (amount != null && amount > 0) {
            return amount;
          }
          // Sometimes the amount is on the next line or previous line
          if (i + 1 < lines.length) {
            final nextAmount = _parseAmountFromLine(lines[i + 1]);
            if (nextAmount != null && nextAmount > 0) return nextAmount;
          }
        }
      }
    }

    // 2. Fallback heuristic: Find all currency amounts in the receipt, pick the maximum reasonable value
    final allAmounts = <double>[];
    for (final line in lines) {
      final amount = _parseAmountFromLine(line);
      if (amount != null && amount > 0 && amount < 1000000000) {
        allAmounts.add(amount);
      }
    }

    if (allAmounts.isNotEmpty) {
      allAmounts.sort();
      return allAmounts.last; // largest amount is usually total
    }

    return 0.0;
  }

  /// Parses a numeric currency amount from a line of text
  static double? _parseAmountFromLine(String line) {
    // Matches patterns like:
    // 150.000 / 150,000 / 150000 / 25.50 / 50k / 150.000đ / 150.000 VND
    final moneyRegex = RegExp(
      r'(\d{1,3}(?:[.,\s]\d{3})+(?:[.,]\d{1,2})?|\d{1,3}(?:[.,]\d{3})+|\d+(?:[.,]\d{2})?|\d+)\s*(?:[kK]|đ|vnd|vnđ|\$)?',
    );

    final matches = moneyRegex.allMatches(line);
    double? bestAmount;

    for (final match in matches) {
      var raw = match.group(0) ?? '';
      bool isKilo = raw.toLowerCase().endsWith('k');
      
      // Remove currency symbols, letters, spaces
      raw = raw.replaceAll(RegExp(r'[^\d.,]'), '');

      if (raw.isEmpty) continue;

      // Handle dot vs comma separation
      double parsedValue = 0.0;
      if (raw.contains('.') && raw.contains(',')) {
        // e.g. 1,250.00 or 1.250,00
        if (raw.indexOf('.') < raw.indexOf(',')) {
          // European/Vietnamese: 1.250,50 -> 1250.50
          raw = raw.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // US: 1,250.50 -> 1250.50
          raw = raw.replaceAll(',', '');
        }
        parsedValue = double.tryParse(raw) ?? 0.0;
      } else if (raw.contains('.')) {
        // In VN: 150.000 is 150000
        final parts = raw.split('.');
        if (parts.length > 1 && parts.last.length == 3) {
          // Thousand separator
          parsedValue = double.tryParse(raw.replaceAll('.', '')) ?? 0.0;
        } else if (parts.length > 2) {
          parsedValue = double.tryParse(raw.replaceAll('.', '')) ?? 0.0;
        } else {
          parsedValue = double.tryParse(raw) ?? 0.0;
        }
      } else if (raw.contains(',')) {
        final parts = raw.split(',');
        if (parts.length > 1 && parts.last.length == 3) {
          parsedValue = double.tryParse(raw.replaceAll(',', '')) ?? 0.0;
        } else if (parts.length > 2) {
          parsedValue = double.tryParse(raw.replaceAll(',', '')) ?? 0.0;
        } else {
          // Could be decimal comma: 25,50 -> 25.5
          parsedValue = double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
        }
      } else {
        parsedValue = double.tryParse(raw) ?? 0.0;
      }

      if (isKilo) {
        parsedValue *= 1000;
      }

      // Ignore single small digits like quantity "1", "2" or phone parts unless reasonable
      if (parsedValue >= 1000 || (parsedValue > 0 && parsedValue < 1000 && (line.contains('\$') || line.toLowerCase().contains('usd')))) {
        bestAmount = parsedValue;
      }
    }

    return bestAmount;
  }

  /// Extracts transaction date from receipt text
  static DateTime extractDate(List<String> lines, String fullText) {
    // Patterns:
    // 1. DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
    final ddmmyyyy = RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[/\-.](0?[1-9]|1[012])[/\-.](20\d\d)\b');
    // 2. YYYY-MM-DD, YYYY/MM/DD
    final yyyymmdd = RegExp(r'\b(20\d\d)[/\-.](0?[1-9]|1[012])[/\-.](0?[1-9]|[12][0-9]|3[01])\b');
    // 3. DD/MM/YY
    final ddmmyy = RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[/\-.](0?[1-9]|1[012])[/\-.](\d{2})\b');
    // 4. Vietnamese text: Ngày 12 tháng 10 năm 2026
    final vnDate = RegExp(r'ng[aà]y\s*(0?[1-9]|[12][0-9]|3[01])\s*th[aá]ng\s*(0?[1-9]|1[012])\s*n[aă]m\s*(20\d\d)', caseSensitive: false);

    // Search full text
    var matchVn = vnDate.firstMatch(fullText);
    if (matchVn != null) {
      final day = int.parse(matchVn.group(1)!);
      final month = int.parse(matchVn.group(2)!);
      final year = int.parse(matchVn.group(3)!);
      return _buildSafeDateTime(year, month, day);
    }

    var match1 = ddmmyyyy.firstMatch(fullText);
    if (match1 != null) {
      final day = int.parse(match1.group(1)!);
      final month = int.parse(match1.group(2)!);
      final year = int.parse(match1.group(3)!);
      return _buildSafeDateTime(year, month, day);
    }

    var match2 = yyyymmdd.firstMatch(fullText);
    if (match2 != null) {
      final year = int.parse(match2.group(1)!);
      final month = int.parse(match2.group(2)!);
      final day = int.parse(match2.group(3)!);
      return _buildSafeDateTime(year, month, day);
    }

    var match3 = ddmmyy.firstMatch(fullText);
    if (match3 != null) {
      final day = int.parse(match3.group(1)!);
      final month = int.parse(match3.group(2)!);
      final yearShort = int.parse(match3.group(3)!);
      final year = 2000 + yearShort;
      return _buildSafeDateTime(year, month, day);
    }

    // Default to current date if not found
    return DateTime.now();
  }

  static DateTime _buildSafeDateTime(int year, int month, int day) {
    try {
      if (year < 2010 || year > 2040) return DateTime.now();
      if (month < 1 || month > 12) return DateTime.now();
      if (day < 1 || day > 31) return DateTime.now();
      return DateTime(year, month, day);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Automatically infers spending category based on keywords (Merchant priority, then full text)
  static String inferCategory(String merchant, String fullText) {
    final m = merchant.toLowerCase();

    // 1. Check Merchant name first (Highest precision)
    if (m.contains('siêu thị') ||
        m.contains('sieu thi') ||
        m.contains('mart') ||
        m.contains('circle k') ||
        m.contains('winmart') ||
        m.contains('co.opmart') ||
        m.contains('ministop') ||
        m.contains('7-eleven') ||
        m.contains('bách hóa') ||
        m.contains('shop') ||
        m.contains('store') ||
        m.contains('quần áo') ||
        m.contains('thời trang')) {
      return 'Mua sắm';
    }

    if (m.contains('nhà sách') ||
        m.contains('nha sach') ||
        m.contains('fahasa') ||
        m.contains('phương nam') ||
        m.contains('văn phòng phẩm') ||
        m.contains('vku') ||
        m.contains('trường')) {
      return 'Học tập';
    }

    if (m.contains('grab') ||
        m.contains('be ') ||
        m.contains('gojek') ||
        m.contains('xăng') ||
        m.contains('petrol') ||
        m.contains('pvoil') ||
        m.contains('taxi') ||
        m.contains('bãi xe') ||
        m.contains('gửi xe')) {
      return 'Di chuyển';
    }

    if (m.contains('tiền điện') ||
        m.contains('tiền nước') ||
        m.contains('internet') ||
        m.contains('viettel') ||
        m.contains('vnpt') ||
        m.contains('fpt')) {
      return 'Hóa đơn';
    }

    if (m.contains('cafe') ||
        m.contains('coffee') ||
        m.contains('trà sữa') ||
        m.contains('tra sua') ||
        m.contains('tea') ||
        m.contains('quán') ||
        m.contains('cơm') ||
        m.contains('phở') ||
        m.contains('bún') ||
        m.contains('mì') ||
        m.contains('lẩu') ||
        m.contains('nướng') ||
        m.contains('bbq') ||
        m.contains('pizza') ||
        m.contains('burger') ||
        m.contains('kfc') ||
        m.contains('lotteria') ||
        m.contains('jollibee') ||
        m.contains('highland') ||
        m.contains('phúc long') ||
        m.contains('starbucks') ||
        m.contains('nhà hàng') ||
        m.contains('restaurant')) {
      return 'Ăn uống';
    }

    // 2. Secondary fallback: check entire text body
    final combined = '$merchant $fullText'.toLowerCase();

    if (combined.contains('siêu thị') ||
        combined.contains('winmart') ||
        combined.contains('circle k') ||
        combined.contains('co.opmart')) {
      return 'Mua sắm';
    }

    if (combined.contains('cafe') ||
        combined.contains('coffee') ||
        combined.contains('trà sữa') ||
        combined.contains('quán') ||
        combined.contains('bánh mì') ||
        combined.contains('phở') ||
        combined.contains('cơm')) {
      return 'Ăn uống';
    }

    if (combined.contains('grab') ||
        combined.contains('xăng') ||
        combined.contains('taxi')) {
      return 'Di chuyển';
    }

    if (combined.contains('nhà sách') ||
        combined.contains('sách') ||
        combined.contains('in ấn') ||
        combined.contains('học phí')) {
      return 'Học tập';
    }

    if (combined.contains('tiền điện') ||
        combined.contains('tiền nước') ||
        combined.contains('internet')) {
      return 'Hóa đơn';
    }

    return 'Khác';
  }
}
