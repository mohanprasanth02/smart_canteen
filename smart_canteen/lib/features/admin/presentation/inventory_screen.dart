import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../data/admin_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryVal = ref.watch(adminInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raw Inventory'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminInventoryProvider);
        },
        child: inventoryVal.when(
          data: (data) {
            final items = data['items'] as List<dynamic>;
            if (items.isEmpty) {
              return const Center(child: Text('No inventory records.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, idx) {
                final item = items[idx];
                final isLow = item['is_low_stock'] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassmorphicCard(
                    borderColor: isLow ? AppColors.error.withOpacity(0.5) : null,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['item_name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Supplier: ${item['supplier'] ?? "Local"}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item['quantity']} ${item['unit']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isLow ? AppColors.error : AppColors.success,
                                    fontSize: 16,
                                  ),
                                ),
                                if (isLow)
                                  const Text(
                                    'LOW STOCK',
                                    style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryNeon),
                              onPressed: () {
                                _showRestockDialog(context, ref, item);
                              },
                            )
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
          error: (_, __) => const Center(child: Text('Error loading inventory')),
        ),
      ),
    );
  }

  void _showRestockDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> item) {
    final qtyController = TextEditingController(text: item['quantity'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text('Restock ${item['item_name']}', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'New Quantity (${item['unit']})',
            labelStyle: const TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQty = double.tryParse(qtyController.text) ?? 0.0;
              await ref.read(adminInventoryProvider.notifier).restockItem(
                    item['id'],
                    newQty,
                  );
              if (context.mounted) context.pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
