import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_counter.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../cart/data/cart_provider.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> foodItem;

  const FoodDetailScreen({Key? key, required this.foodItem}) : super(key: key);

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  int _quantity = 1;
  bool _isAdding = false;

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    final success = await ref.read(cartStateProvider.notifier).addToCart(
          widget.foodItem['id'],
          _quantity,
        );
    setState(() => _isAdding = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.foodItem['name']} added to cart!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add item. Check available stock.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.foodItem;
    final isAvailable = item['is_available'] == true && item['quantity'] > 0;
    final maxAvailable = item['quantity'] as int;

    return Scaffold(
      body: Stack(
        children: [
          // Food Hero Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Hero(
              tag: 'food-${item['id']}',
              child: item['image'] != null
                  ? Image.network(
                      item['image'].startsWith('/')
                          ? '${ApiConstants.baseUrl}${item['image']}'
                          : item['image'],
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.darkSurface,
                      child: const Icon(Icons.fastfood, size: 100, color: AppColors.primaryNeon),
                    ),
            ),
          ),

          // Custom back button
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                onPressed: () => context.pop(),
              ),
            ),
          ),

          // Sliding Details Panel
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.55,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.darkBorder,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title + Veg Tag
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item['name'],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: item['is_veg'] ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: item['is_veg'] ? Colors.green : Colors.red),
                              ),
                              child: Text(
                                item['is_veg'] ? 'VEG' : 'NON-VEG',
                                style: TextStyle(
                                  color: item['is_veg'] ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Price
                        Text(
                          '₹${item['price']}',
                          style: const TextStyle(
                            color: AppColors.primaryNeon,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Badges Row
                        Row(
                          children: [
                            _buildInfoBadge(Icons.timer_outlined, '${item['preparation_time']} mins'),
                            const SizedBox(width: 12),
                            _buildInfoBadge(Icons.local_fire_department_outlined, item['is_veg'] ? 'Low Cal' : 'High Protein'),
                            const SizedBox(width: 12),
                            _buildInfoBadge(
                              Icons.check_circle_outline,
                              isAvailable ? 'In Stock' : 'Sold Out',
                              color: isAvailable ? AppColors.success : AppColors.error,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['description'] ?? 'No description available for this item.',
                          style: TextStyle(color: AppColors.textDarkSecondary, height: 1.5),
                        ),
                        const SizedBox(height: 30),

                        // Quantity Selector & Add Button
                        if (isAvailable) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select Quantity',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                              ),
                              AnimatedCounter(
                                count: _quantity,
                                maxCount: maxAvailable,
                                onIncrement: () => setState(() => _quantity++),
                                onDecrement: () => setState(() => _quantity--),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          GradientButton(
                            text: 'Add to Cart • ₹${(item['price'] * _quantity).toStringAsFixed(2)}',
                            isLoading: _isAdding,
                            onPressed: _addToCart,
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.error.withOpacity(0.2)),
                            ),
                            child: const Center(
                              child: Text(
                                'This item is currently sold out.',
                                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, {Color? color}) {
    final themeColor = color ?? AppColors.textDarkSecondary;

    return Expanded(
      child: GlassmorphicCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        borderRadius: 12,
        child: Column(
          children: [
            Icon(icon, color: themeColor, size: 20),
            const SizedBox(height: 6),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
