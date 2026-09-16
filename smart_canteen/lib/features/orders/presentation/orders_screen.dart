import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/order_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrdersVal = ref.watch(activeOrdersProvider);
    final historyOrdersVal = ref.watch(orderHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeOrdersProvider);
          ref.invalidate(orderHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Orders Section
              const Text(
                'Active Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              activeOrdersVal.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return const GlassmorphicCard(
                      child: Center(
                        child: Text(
                          'No active orders right now.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, idx) {
                      final order = orders[idx];
                      return _buildOrderCard(context, order);
                    },
                  );
                },
                loading: () => const ShimmerLoader(height: 120, borderRadius: 16),
                error: (_, __) => const Center(child: Text('Error loading active orders')),
              ),

              const SizedBox(height: 28),

              // Past Orders History
              const Text(
                'Order History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              historyOrdersVal.when(
                data: (orders) {
                  // Filter out active orders from history
                  final activeIds = activeOrdersVal.value?.map((x) => x['id']).toList() ?? [];
                  final history = orders.where((x) => !activeIds.contains(x['id'])).toList();

                  if (history.isEmpty) {
                    return const Center(
                      child: Text('No order history found.', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    itemBuilder: (context, idx) {
                      final order = history[idx];
                      return _buildOrderCard(context, order);
                    },
                  );
                },
                loading: () => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, idx) => const ShimmerFoodCard(),
                ),
                error: (_, __) => const Center(child: Text('Error loading history')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final orderId = order['order_id'];
    final total = order['total_amount'];
    final status = order['status'];
    final dateStr = order['created_at'];
    final itemsCount = order['item_count'];
    final token = order['token_number'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () => context.push('/order-tracking/$orderId'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    orderId,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                  StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$itemsCount Items • ₹$total',
                        style: const TextStyle(color: AppColors.primaryNeon, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(dateStr),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      children: [
                        const Text('TOKEN', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
                        Text(
                          token,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
