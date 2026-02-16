import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/order_providers.dart';

class ShopReportsPage extends ConsumerStatefulWidget {
  const ShopReportsPage({super.key});

  @override
  ConsumerState<ShopReportsPage> createState() => _ShopReportsPageState();
}

class _ShopReportsPageState extends ConsumerState<ShopReportsPage> {
  String _selectedPeriod = 'This Month';
  DateTimeRange? _customRange;

  String get _displayPeriod {
    if (_selectedPeriod == 'Custom' && _customRange != null) {
      final fmt = DateFormat('dd MMM');
      return '${fmt.format(_customRange!.start)} - ${fmt.format(_customRange!.end)}';
    }
    return _selectedPeriod;
  }

  // Filter orders based on selected period
  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    if (_selectedPeriod == 'Custom' && _customRange != null) {
      start = _customRange!.start;
      end = _customRange!.end.add(const Duration(days: 1)); // Includes the end day
    } else if (_selectedPeriod == 'This Week') {
      // Start of week (Monday)
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
    } else if (_selectedPeriod == 'This Month') {
      start = DateTime(now.year, now.month, 1);
    } else if (_selectedPeriod == 'This Year') {
      start = DateTime(now.year, 1, 1);
    } else {
      start = DateTime(2000); // All time fallback
    }

    return orders.where((o) {
      return o.createdAt.isAfter(start) && o.createdAt.isBefore(end.add(const Duration(days: 1)));
    }).toList();
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
    // Fetch up to 100 orders for reporting
    final ordersAsync = ref.watch(sellerReportOrdersProvider(100));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ordersAsync.when(
            loading: () => SizedBox(height: MediaQuery.of(context).size.height, child: const Center(child: CircularProgressIndicator())),
            error: (e, _) => SizedBox(height: MediaQuery.of(context).size.height, child: Center(child: Text('Error: $e'))),
            data: (paginatedResponse) {
              final allOrders = paginatedResponse.data; // Raw orders
              final orders = _filterOrders(allOrders);  // Filtered orders

              // Compute Stats
              final totalSales = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
              final orderCount = orders.length;
              final avgOrder = orderCount > 0 ? totalSales / orderCount : 0.0;
              final productCount = orders.fold<int>(0, (sum, o) => sum + o.items.length); // Total distinct items sold

              // Compute Top Products
              final productStats = <String, Map<String, dynamic>>{};
              for (var o in orders) {
                for (var item in o.items) {
                  // Assuming item.productName exists and is unique enough for now
                  // Use productId if available for key
                  final key = item.productName; 
                  if (!productStats.containsKey(key)) {
                    productStats[key] = {
                      'name': item.productName,
                      'sales': 0,
                      'revenue': 0.0,
                      'image': item.imageUrl, // Assumption: item has image or we don't have it easily
                      'price': item.unitPrice,
                    };
                  }
                  productStats[key]!['sales'] = (productStats[key]!['sales'] as int) + item.quantity;
                  productStats[key]!['revenue'] = (productStats[key]!['revenue'] as double) + (item.unitPrice * item.quantity);
                }
              }
              final topProducts = productStats.values.toList()
                ..sort((a, b) => (b['sales'] as int).compareTo(a['sales'] as int));
              final top5 = topProducts.take(5).toList();

              // Compute Chart Data (Monthly for 'This Year', Daily for others?)
              // For simplicity, let's just do Monthly aggregation of the filtered orders
              final monthlyStats = <String, Map<String, dynamic>>{};
              // Initialize last 6 months 
              // (Or just aggregate existing orders logic)
              for (var o in orders) {
                final monthKey = DateFormat('MMM').format(o.createdAt);
                if (!monthlyStats.containsKey(monthKey)) {
                  monthlyStats[monthKey] = {'month': monthKey, 'sales': 0.0, 'orders': 0};
                }
                monthlyStats[monthKey]!['sales'] = (monthlyStats[monthKey]!['sales'] as double) + o.totalAmount;
                monthlyStats[monthKey]!['orders'] = (monthlyStats[monthKey]!['orders'] as int) + 1;
              }
              final chartData = monthlyStats.values.toList(); 
              // Sort chart data? Map key sorting is tricky without proper date.
              // If filtered by "This Year", we can enforce Jan-Dec order.
              // For now, let's just use what we have.

              final salesFmt = NumberFormat.currency(symbol: 'RWF', decimalDigits: 0, customPattern: '#,##0 \u00A4');
              
              return Column(
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
                            color: AppColors.secondary.withValues(alpha: 0.1),
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
                                  border: Border.all(color: AppColors.secondary.withValues(alpha: 80/255)),
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
                        _buildStatCard('Total Sales', salesFmt.format(totalSales), Icons.monetization_on, AppColors.success),
                        const SizedBox(width: 12),
                        _buildStatCard('Orders', '$orderCount', Icons.receipt_long, AppColors.secondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildStatCard('Avg Order', salesFmt.format(avgOrder), Icons.shopping_cart, Colors.orange),
                        const SizedBox(width: 12),
                        _buildStatCard('Items Sold', '$productCount', Icons.inventory_2, Colors.purple),
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
                          chartData.isEmpty 
                              ? const SizedBox(height: 100, child: Center(child: Text("No data for chart")))
                              : SizedBox(
                                  height: 200,
                                  child: CustomPaint(
                                    size: const Size(double.infinity, 200),
                                    painter: _BarChartPainter(chartData),
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
                        top5.isEmpty
                            ? const Text("No sales yet")
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: top5.length,
                                itemBuilder: (context, index) {
                                  final product = top5[index];
                                  return GestureDetector(
                                    onTap: () => _showProductDetailSheet(context, product, index + 1),
                                    child: _buildProductRankCard(index + 1, product, salesFmt),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showProductDetailSheet(BuildContext context, Map<String, dynamic> product, int rank) {
    final price = product['price'] as double;
    final sales = product['sales'] as int;
    final revenue = product['revenue'] as double;
    final imageUrl = product['image'] as String?;
    final fmt = NumberFormat.currency(symbol: 'RWF', decimalDigits: 0, customPattern: '#,##0 \u00A4');

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
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _productPlaceholder())
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
                      color: AppColors.secondary.withValues(alpha: 25/255),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('#$rank Top Seller', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _detailStat('Price', fmt.format(price), Icons.monetization_on, AppColors.secondary),
                  const SizedBox(width: 12),
                  _detailStat('Units Sold', '$sales', Icons.shopping_cart, Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _detailStat('Revenue', fmt.format(revenue), Icons.trending_up, AppColors.success),
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
          color: color.withValues(alpha: 15/255),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 40/255)),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
             Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 color: color.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(10),
               ),
               child: Icon(icon, color: color, size: 20),
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

  Widget _buildProductRankCard(int rank, Map<String, dynamic> product, NumberFormat fmt) {
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
              color: rankColor.withValues(alpha: 0.15),
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
                fmt.format(product['revenue']),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 12),
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
    if (data.isEmpty) return;
    
    // Safety check for empty data
    final barUnitWidth = (size.width - 60) / data.length;
    final barWidth = barUnitWidth / 2.5;
    
    final maxSales = data.fold<double>(0, (max, item) => (item['sales'] as double) > max ? (item['sales'] as double) : max);
    final maxOrders = data.fold<int>(0, (max, item) => (item['orders'] as int) > max ? (item['orders'] as int) : max);

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
      final x = 30 + (i * barUnitWidth) + (barUnitWidth - barWidth * 2 - 4) / 2;
      
      // Sales bar
      if (maxSales > 0) {
        final salesHeight = ((item['sales'] as double) / maxSales) * (size.height - 40);
        final salesRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - 30 - salesHeight, barWidth, salesHeight),
          const Radius.circular(4),
        );
        canvas.drawRRect(salesRect, salesPaint);
      }
      
      // Orders bar (Use separate scale or normalized? Users usually prefer dual axis but here we just show relative height or normalized to maxOrders)
      // To show them side-by-side but with reasonable visibility, let's normalize to available height independently.
      if (maxOrders > 0) {
        final ordersHeight = ((item['orders'] as int) / maxOrders) * (size.height - 40);
        final ordersRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + barWidth + 4, size.height - 30 - ordersHeight, barWidth, ordersHeight),
          const Radius.circular(4),
        );
        canvas.drawRRect(ordersRect, orderPaint);
      }
      
      // Month label
      textPainter.text = TextSpan(
        text: item['month'] as String,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + barWidth - textPainter.width / 2, size.height - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
