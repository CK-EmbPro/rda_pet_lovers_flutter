import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class ShopReportsPage extends StatefulWidget {
  const ShopReportsPage({super.key});

  @override
  State<ShopReportsPage> createState() => _ShopReportsPageState();
}

class _ShopReportsPageState extends State<ShopReportsPage> {
  String _selectedPeriod = 'This Month';
  DateTimeRange? _customRange;
  
  // Mock data for reports
  final List<Map<String, dynamic>> _topProducts = [
    {'name': 'Premium Dog Food', 'sales': 156, 'revenue': 3900000, 'category': 'Dog', 'price': 25000, 'stock': 42, 'image': null},
    {'name': 'Cat Toys Bundle', 'sales': 98, 'revenue': 1470000, 'category': 'Cat', 'price': 15000, 'stock': 30, 'image': null},
    {'name': 'Pet Collar Set', 'sales': 75, 'revenue': 600000, 'category': 'Dog', 'price': 8000, 'stock': 18, 'image': null},
    {'name': 'Dog Shampoo', 'sales': 62, 'revenue': 744000, 'category': 'Dog', 'price': 12000, 'stock': 8, 'image': null},
    {'name': 'Bird Cage', 'sales': 45, 'revenue': 900000, 'category': 'Bird', 'price': 45000, 'stock': 0, 'image': null},
  ];

  final List<Map<String, dynamic>> _monthlySales = [
    {'month': 'Jan', 'sales': 450000, 'orders': 32},
    {'month': 'Feb', 'sales': 620000, 'orders': 45},
    {'month': 'Mar', 'sales': 580000, 'orders': 41},
    {'month': 'Apr', 'sales': 750000, 'orders': 52},
    {'month': 'May', 'sales': 820000, 'orders': 58},
    {'month': 'Jun', 'sales': 950000, 'orders': 67},
  ];

  String get _displayPeriod {
    if (_selectedPeriod == 'Custom' && _customRange != null) {
      final fmt = DateFormat('dd MMM');
      return '${fmt.format(_customRange!.start)} - ${fmt.format(_customRange!.end)}';
    }
    return _selectedPeriod;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    DateTime startDate = _customRange?.start ?? now.subtract(const Duration(days: 30));
    DateTime endDate = _customRange?.end ?? now;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final fmt = DateFormat('dd MMM yyyy');
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  const Text('Select Date Range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // From date
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(now.year - 2),
                              lastDate: endDate,
                              builder: (c, child) => Theme(
                                data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: AppColors.secondary, onPrimary: Colors.white, onSurface: AppColors.textPrimary)),
                                child: child!,
                              ),
                            );
                            if (picked != null) setModalState(() => startDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.secondary),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('From', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    Text(fmt.format(startDate), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.arrow_forward, color: AppColors.textSecondary, size: 18),
                      ),
                      // To date
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: now,
                              builder: (c, child) => Theme(
                                data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: AppColors.secondary, onPrimary: Colors.white, onSurface: AppColors.textPrimary)),
                                child: child!,
                              ),
                            );
                            if (picked != null) setModalState(() => endDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.secondary),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('To', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    Text(fmt.format(endDate), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _customRange = DateTimeRange(start: startDate, end: endDate);
                          _selectedPeriod = 'Custom';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sales Report', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Track your shop performance', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.download, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              
              // Date Range Picker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: ['This Week', 'This Month', 'This Year', 'Custom'].map((period) {
                          final isSelected = _selectedPeriod == period;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (period == 'Custom') {
                                  _pickCustomRange();
                                } else {
                                  setState(() {
                                    _selectedPeriod = period;
                                    _customRange = null;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.secondary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (period == 'Custom')
                                      Icon(
                                        Icons.calendar_month,
                                        size: 14,
                                        color: isSelected ? Colors.white : AppColors.textSecondary,
                                      ),
                                    if (period == 'Custom') const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        period == 'Custom' && isSelected && _customRange != null
                                            ? _displayPeriod
                                            : period,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          fontSize: period == 'Custom' && isSelected && _customRange != null ? 10 : 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Custom range display below filter bar
                    if (_selectedPeriod == 'Custom' && _customRange != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: GestureDetector(
                          onTap: _pickCustomRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.secondary.withAlpha(80)),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.date_range, color: AppColors.secondary, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '${DateFormat('dd MMM yyyy').format(_customRange!.start)}  →  ${DateFormat('dd MMM yyyy').format(_customRange!.end)}',
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Key Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildStatCard('Total Sales', '4.17M RWF', Icons.monetization_on, AppColors.success, '+12.5%'),
                    const SizedBox(width: 12),
                    _buildStatCard('Orders', '295', Icons.receipt_long, AppColors.secondary, '+8.2%'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildStatCard('Avg Order', '14,135 RWF', Icons.shopping_cart, Colors.orange, '+3.1%'),
                    const SizedBox(width: 12),
                    _buildStatCard('Products', '48', Icons.inventory_2, Colors.purple, ''),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Sales Chart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sales Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              _buildLegendItem('Sales', AppColors.secondary),
                              const SizedBox(width: 16),
                              _buildLegendItem('Orders', AppColors.success),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: CustomPaint(
                          size: const Size(double.infinity, 200),
                          painter: _BarChartPainter(_monthlySales),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Top Selling Products
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top Selling Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _topProducts.length,
                      itemBuilder: (context, index) {
                        final product = _topProducts[index];
                        return GestureDetector(
                          onTap: () => _showProductDetailSheet(context, product, index + 1),
                          child: _buildProductRankCard(index + 1, product),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetailSheet(BuildContext context, Map<String, dynamic> product, int rank) {
    final price = product['price'] as int;
    final stock = product['stock'] as int;
    final sales = product['sales'] as int;
    final revenue = product['revenue'] as int;
    final imageUrl = product['image'] as String?;
    final fmt = (int v) => v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),

            // Product image or placeholder
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE86A2C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _productPlaceholder())
                    : _productPlaceholder(),
              ),
            ),
            const SizedBox(height: 16),

            // Name and rank
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(product['name'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('#$rank Top Seller', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Category: ${product['category']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _detailStat('Price', '${fmt(price)} RWF', Icons.monetization_on, AppColors.secondary),
                  const SizedBox(width: 12),
                  _detailStat('Stock', '$stock left', Icons.inventory, stock > 0 ? AppColors.success : AppColors.error),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _detailStat('Units Sold', '$sales', Icons.shopping_cart, Colors.orange),
                  const SizedBox(width: 12),
                  _detailStat('Revenue', '${fmt(revenue)} RWF', Icons.trending_up, AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _productPlaceholder() {
    return Center(child: Icon(Icons.inventory_2, size: 50, color: Colors.white.withAlpha(150)));
  }

  Widget _detailStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String growth) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (growth.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      growth,
                      style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildProductRankCard(int rank, Map<String, dynamic> product) {
    Color rankColor;
    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Gold
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Silver
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        rankColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${product['sales']} sold',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(product['revenue'] as int) ~/ 1000}K RWF',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
              const Text(
                'Revenue',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Bar Chart Painter
class _BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = (size.width - 60) / data.length / 2.5;
    final maxSales = data.fold<double>(0, (max, item) => item['sales'] as int > max ? (item['sales'] as int).toDouble() : max);
    
    final salesPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;
    
    final orderPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final x = 30 + (i * (size.width - 60) / data.length) + barWidth / 2;
      
      // Sales bar
      final salesHeight = ((item['sales'] as int) / maxSales) * (size.height - 40);
      final salesRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - 30 - salesHeight, barWidth, salesHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(salesRect, salesPaint);
      
      // Orders bar (scaled differently)
      final ordersHeight = ((item['orders'] as int) / 70) * (size.height - 40);
      final ordersRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + barWidth + 4, size.height - 30 - ordersHeight, barWidth, ordersHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(ordersRect, orderPaint);
      
      // Month label
      textPainter.text = TextSpan(
        text: item['month'] as String,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + barWidth / 2 - textPainter.width / 2, size.height - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
