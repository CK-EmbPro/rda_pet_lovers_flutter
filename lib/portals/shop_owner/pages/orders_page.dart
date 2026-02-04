import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

final List<Map<String, dynamic>> _mockOrders = [
  {'id': 'ORD-001', 'customer': 'John Doe', 'items': 3, 'total': 45000, 'date': 'Today', 'status': 'pending'},
  {'id': 'ORD-002', 'customer': 'Jane Smith', 'items': 1, 'total': 25000, 'date': 'Today', 'status': 'processing'},
  {'id': 'ORD-003', 'customer': 'Mike Wilson', 'items': 5, 'total': 80000, 'date': 'Yesterday', 'status': 'shipped'},
  {'id': 'ORD-004', 'customer': 'Sarah Connor', 'items': 2, 'total': 35000, 'date': 'Feb 1', 'status': 'delivered'},
];

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Orders', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Manage customer orders', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 20),
                // Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelColor: AppColors.secondary,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Pending'),
                      Tab(text: 'Processing'),
                      Tab(text: 'Shipped'),
                      Tab(text: 'Delivered'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('pending'),
                _buildOrderList('processing'),
                _buildOrderList('shipped'),
                _buildOrderList('delivered'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    final filtered = _mockOrders.where((o) => o['status'] == status).toList();
    if (filtered.isEmpty) {
      return EmptyState(icon: Icons.receipt_long, title: 'No orders', subtitle: 'No $status orders');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _OrderCard(order: filtered[index]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shopping_bag, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(order['customer'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text('${order['total']} RWF', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order['items']} items', style: const TextStyle(color: AppColors.textSecondary)),
                Text(order['date'] as String, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44), backgroundColor: AppColors.success),
              child: const Text('Process Order'),
            ),
          ],
          if (status == 'processing') ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44), backgroundColor: AppColors.secondary),
              child: const Text('Mark as Shipped'),
            ),
          ],
        ],
      ),
    );
  }
}

