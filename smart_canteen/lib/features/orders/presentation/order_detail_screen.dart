import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailVal = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailVal.when(
        data: (order) {
          final items = order['items'] as List<dynamic>;
          final tokenNum = order['token']?['token_number'] ?? 'N/A';
          final payment = order['payment'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Glassmorphic Receipt Header
                GlassmorphicCard(
                  child: Column(
                    children: [
                      Text(
                        'Token Number',
                        style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tokenNum,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNeon,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StatusBadge(status: order['status']),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Order Meta Details
                GlassmorphicCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Order ID', order['order_id']),
                      _buildDetailRow('Pickup Slot', order['pickup_time'] ?? 'N/A'),
                      if (order['notes'] != null && order['notes'].toString().isNotEmpty)
                        _buildDetailRow('Instructions', order['notes']),
                      _buildDetailRow('Payment Method', payment?['payment_method'].toString().toUpperCase() ?? 'N/A'),
                      _buildDetailRow('Payment Status', payment?['status'].toString().toUpperCase() ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Ordered Items Invoice Card
                const Text(
                  'Items Ordered',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                GlassmorphicCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item['food_name']} x${item['quantity']}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Text(
                                  '₹${item['total_price']}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(color: AppColors.darkBorder, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: TextStyle(color: AppColors.textDarkSecondary)),
                          Text('₹${order['subtotal']}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GST (5%)', style: TextStyle(color: AppColors.textDarkSecondary)),
                          Text('₹${order['tax']}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(
                            '₹${order['total_amount']}',
                            style: const TextStyle(color: AppColors.primaryNeon, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon)),
        error: (_, __) => const Center(child: Text('Error loading order details')),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
