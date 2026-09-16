import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/admin_provider.dart';

class OrderManagementScreen extends ConsumerWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersVal = ref.watch(adminOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Orders Queue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminOrdersProvider);
        },
        child: ordersVal.when(
          data: (orders) {
            if (orders.isEmpty) {
              return const Center(
                child: Text('No active orders in queue.', style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, idx) {
                final order = orders[idx];
                final token = order['token']?['token_number'] ?? 'N/A';
                final status = order['status']?.toString().toLowerCase() ?? 'placed';
                final items = order['items'] as List<dynamic>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: GlassmorphicCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Order ID + Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order['order_id'],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                            ),
                            StatusBadge(status: status),
                          ],
                        ),
                        const Divider(color: AppColors.darkBorder, height: 20),

                        // Student Profile
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: AppColors.primaryNeon),
                            const SizedBox(width: 8),
                            Text(
                              order['user']?['full_name'] ?? 'Unknown',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${order['user']?['department'] ?? 'CS'})',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Food Items
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, itemIdx) {
                            final item = items[itemIdx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                '• ${item['food_name']} x${item['quantity']}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Pickup instructions
                        if (order['notes'] != null && order['notes'].toString().isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.comment_outlined, size: 14, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    order['notes'],
                                    style: const TextStyle(color: AppColors.warning, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Control Buttons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Token: $token',
                              style: const TextStyle(color: AppColors.primaryNeon, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            _buildActionButtons(context, ref, order['order_id'], status),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon)),
          error: (_, __) => const Center(child: Text('Error loading live orders')),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, String orderId, String status) {
    final notifier = ref.read(adminOrdersProvider.notifier);

    if (status == 'placed') {
      return Row(
        children: [
          TextButton(
            onPressed: () => notifier.updateStatus(orderId, 'cancelled'),
            child: const Text('Reject', style: TextStyle(color: AppColors.error)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => notifier.updateStatus(orderId, 'accepted'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.black),
            child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else if (status == 'accepted') {
      return ElevatedButton(
        onPressed: () => notifier.updateStatus(orderId, 'preparing'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.black),
        child: const Text('Prepare', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (status == 'preparing') {
      return ElevatedButton(
        onPressed: () => notifier.updateStatus(orderId, 'ready'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNeon, foregroundColor: Colors.black),
        child: const Text('Ready', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (status == 'ready') {
      return const Text(
        'Awaiting Collection',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
      );
    }

    return const SizedBox.shrink();
  }
}
