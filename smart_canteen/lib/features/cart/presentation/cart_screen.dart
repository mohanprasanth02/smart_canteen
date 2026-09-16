import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_counter.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../orders/data/order_provider.dart';
import '../data/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _notesController = TextEditingController();
  String _selectedPickup = 'Immediate (10-15 mins)';
  String _paymentMethod = 'cash';
  late ConfettiController _confettiCtrl;

  final List<String> _pickupTimes = [
    'Immediate (10-15 mins)',
    'In 30 minutes',
    'In 1 hour',
    'Next Break',
  ];

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _notesController.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkout(Map<String, dynamic> cart) async {
    if (cart['items'].isEmpty) return;

    final checkoutNotifier = ref.read(checkoutStateProvider.notifier);
    final success = await checkoutNotifier.placeOrder(
      pickupTime: _selectedPickup,
      notes: _notesController.text.trim(),
      paymentMethod: _paymentMethod,
    );

    if (success && mounted) {
      final order = ref.read(checkoutStateProvider).value;
      if (order != null) {
        ref.invalidate(activeOrdersProvider);
        _confettiCtrl.play();
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pushReplacement('/order-tracking/${order['order_id']}');
      }
    } else if (mounted) {
      final err = ref.read(checkoutStateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err?.toString() ?? 'Checkout failed. Stock unavailable.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartStateProvider);
    final checkoutState = ref.watch(checkoutStateProvider);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Cart'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                onPressed: () => ref.read(cartStateProvider.notifier).clearCart(),
              )
            ],
          ),
          body: cartState.when(
            data: (cart) {
              final items = cart['items'] as List<dynamic>;
              if (items.isEmpty) {
                return _buildEmptyState();

          }

          return Column(
            children: [
              // Items List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    final food = item['food_item'];

                    return Dismissible(
                      key: ValueKey<int>(item['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                      ),
                      onDismissed: (_) {
                        ref.read(cartStateProvider.notifier).removeFromCart(item['id']);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GlassmorphicCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.darkSurface,
                                  child: food['image'] != null
                                      ? Image.network(
                                          food['image'].startsWith('/')
                                              ? '${ApiConstants.baseUrl}${food['image']}'
                                              : food['image'],
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.fastfood, color: AppColors.primaryNeon),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      food['name'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${item['unit_price']}',
                                      style: const TextStyle(color: AppColors.primaryNeon),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedCounter(
                                count: item['quantity'],
                                maxCount: food['quantity'],
                                onIncrement: () {
                                  ref.read(cartStateProvider.notifier).updateQuantity(
                                        item['id'],
                                        item['quantity'] + 1,
                                      );
                                },
                                onDecrement: () {
                                  ref.read(cartStateProvider.notifier).updateQuantity(
                                        item['id'],
                                        item['quantity'] - 1,
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Sheet Form
              _buildCheckoutForm(cart, checkoutState.isLoading),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon)),
        error: (_, __) => const Center(child: Text('Error loading cart')),
      ),
        ),
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.08,
            numberOfParticles: 20,
            gravity: 0.3,
            colors: const [
              AppColors.primaryNeon,
              AppColors.success,
              Color(0xFFFFB703),
              Color(0xFFE040FB),
              Colors.white,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.darkBorder),
          const SizedBox(height: 16),
          const Text('Your cart is empty', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Add items from the menu to get started.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/menu'),
            child: const Text('Browse Menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutForm(Map<String, dynamic> cart, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pickup Time Dropdown
            DropdownButtonFormField<String>(
              value: _selectedPickup,
              decoration: const InputDecoration(labelText: 'Pickup Time'),
              dropdownColor: AppColors.darkSurface,
              items: _pickupTimes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPickup = val);
              },
            ),
            const SizedBox(height: 12),

            // Cooking Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Cooking Instructions / Notes',
                hintText: 'e.g. Make it spicy, no onions',
              ),
            ),
            const SizedBox(height: 16),

            // Payment Option Selector
            Row(
              children: [
                Expanded(child: _buildPayOption('cash', 'Cash')),
                const SizedBox(width: 8),
                Expanded(child: _buildPayOption('upi', 'UPI / QR')),
                const SizedBox(width: 8),
                Expanded(child: _buildPayOption('wallet', 'Wallet')),
              ],
            ),
            const SizedBox(height: 20),

            // Bill receipt breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: TextStyle(color: AppColors.textDarkSecondary)),
                Text('₹${cart['subtotal']}', style: const TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CGST & SGST (5%)', style: TextStyle(color: AppColors.textDarkSecondary)),
                Text('₹${cart['tax']}', style: const TextStyle(color: Colors.white)),
              ],
            ),
            const Divider(color: AppColors.darkBorder, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                Text(
                  '₹${cart['total']}',
                  style: const TextStyle(color: AppColors.primaryNeon, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Confirm Place Order
            GradientButton(
              text: 'Place Order',
              isLoading: isLoading,
              onPressed: () => _checkout(cart),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayOption(String key, String label) {
    final isSelected = _paymentMethod == key;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNeon.withOpacity(0.15) : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : AppColors.darkBorder,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primaryNeon : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
