import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class ShopReportsPage extends StatefulWidget {
  const ShopReportsPage({super.key});

  @override
  State<ShopReportsPage> createState() => _ShopReportsPageState();
}

class _ShopReportsPageState extends State<ShopReportsPage> {
  String _selectedPeriod = 'This Month';
  
  // Mock data for reports
  final List<Map<String, dynamic>> _topProducts = [
    {'name': 'Premium Dog Food', 'sales': 156, 'revenue': 3900000},
    {'name': 'Cat Toys Bundle', 'sales': 98, 'revenue': 1470000},
    {'name': 'Pet Collar Set', 'sales': 75, 'revenue': 600000},
    {'name': 'Dog Shampoo', 'sales': 62, 'revenue': 744000},
    {'name': 'Bird Cage', 'sales': 45, 'revenue': 900000},
  ];

  final List<Map<String, dynamic>> _monthlySales = [
    {'month': 'Jan', 'sales': 450000, 'orders': 32},
    {'month': 'Feb', 'sales': 620000, 'orders': 45},
    {'month': 'Mar', 'sales': 580000, 'orders': 41},
    {'month': 'Apr', 'sales': 750000, 'orders': 52},
    {'month': 'May', 'sales': 820000, 'orders': 58},
    {'month': 'Jun', 'sales': 950000, 'orders': 67},
  ];

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
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['This Week', 'This Month', 'This Year'].map((period) {
                      final isSelected = _selectedPeriod == period;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = period),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.secondary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              period,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
                        return _buildProductRankCard(index + 1, product);
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
