import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/expense_card.dart';
import 'scanner_screen.dart';
import 'review_expense_screen.dart';
import 'expense_detail_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDatePickerFilter(BuildContext context) async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final initialRange = provider.selectedDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
      helpText: 'Chọn khoảng thời gian lọc hóa đơn',
    );

    if (picked != null) {
      provider.setDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final isDark = theme.brightness == Brightness.dark;

    final pages = [
      // PAGE 0: Expenses List & Dashboard
      RefreshIndicator(
        onRefresh: () => expenseProvider.loadExpenses(),
        child: CustomScrollView(
          slivers: [
            // Sliver App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 180,
              title: const Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.tealAccent),
                  SizedBox(width: 8),
                  Text('VKU Receipt Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                // Dark mode toggle
                IconButton(
                  tooltip: isDark ? 'Chuyển giao diện Sáng' : 'Chuyển giao diện Tối',
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () => themeProvider.toggleTheme(!isDark),
                ),
                // Date range filter
                IconButton(
                  tooltip: 'Lọc theo ngày',
                  icon: Icon(
                    expenseProvider.selectedDateRange != null
                        ? Icons.filter_alt
                        : Icons.calendar_month_outlined,
                    color: expenseProvider.selectedDateRange != null ? Colors.amberAccent : null,
                  ),
                  onPressed: () => _openDatePickerFilter(context),
                ),
                if (expenseProvider.selectedDateRange != null)
                  IconButton(
                    tooltip: 'Xóa bộ lọc ngày',
                    icon: const Icon(Icons.filter_alt_off),
                    onPressed: () => expenseProvider.setDateRange(null),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
                  alignment: Alignment.bottomLeft,
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                expenseProvider.selectedDateRange != null
                                    ? 'Chi tiêu đã lọc'
                                    : 'Tổng chi tiêu hiện tại',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter.format(expenseProvider.totalSpent),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ScannerScreen()),
                              );
                            },
                            icon: const Icon(Icons.document_scanner),
                            label: const Text('Quét HĐ'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Search Bar & Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: [
                    // Search text field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm cửa hàng hoặc ghi chú...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  expenseProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      onChanged: (val) => expenseProvider.setSearchQuery(val),
                    ),
                    const SizedBox(height: 10),

                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Tất cả'),
                            selected: expenseProvider.selectedCategory == null ||
                                expenseProvider.selectedCategory == 'Tất cả',
                            onSelected: (_) => expenseProvider.setSelectedCategory('Tất cả'),
                          ),
                          const SizedBox(width: 8),
                          ...Expense.categories.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: expenseProvider.selectedCategory == cat,
                                onSelected: (_) => expenseProvider.setSelectedCategory(cat),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Danh sách chi tiêu (${expenseProvider.filteredExpenses.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Vuốt để xóa',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ),

            // Expense List Items
            if (expenseProvider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (expenseProvider.filteredExpenses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 72,
                          color: theme.hintColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có hóa đơn nào',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.hintColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bấm nút Quét hoặc Thêm bên dưới để lưu hóa đơn đầu tiên!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ScannerScreen()),
                            );
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Quét Hóa Đơn Ngay'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final expense = expenseProvider.filteredExpenses[index];
                      return ExpenseCard(
                        expense: expense,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExpenseDetailScreen(expense: expense),
                            ),
                          );
                        },
                        onDelete: () {
                          expenseProvider.deleteExpense(expense.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã xóa hóa đơn "${expense.merchant}"'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                    childCount: expenseProvider.filteredExpenses.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),

      // PAGE 1: Statistics and Charts View
      const StatisticsScreen(),
    ];

    return Scaffold(
      body: pages[_currentNavIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddOptionsBottomSheet(context);
        },
        icon: const Icon(Icons.document_scanner),
        label: const Text('QUÉT / THÊM HĐ', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Sổ chi tiêu',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Báo cáo biểu đồ',
          ),
        ],
      ),
    );
  }

  void _showAddOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thêm chi tiêu mới',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Quét hóa đơn bằng AI OCR (Khuyên dùng)'),
                subtitle: const Text('Chụp ảnh và nhận diện tự động số tiền, ngày, cửa hàng'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.shade100,
                  child: const Icon(Icons.edit_note, color: Colors.orange),
                ),
                title: const Text('Nhập chi tiêu thủ công'),
                subtitle: const Text('Tự điền tên cửa hàng, số tiền và danh mục'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReviewExpenseScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
