import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_check_circle.dart';
import '../../../core/socket/socket_service.dart';
import '../../auth/data/auth_provider.dart';

// KDS Orders Provider
class KdsOrdersState {
  final List<dynamic> orders;
  final bool isLoading;
  final String? error;

  KdsOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  KdsOrdersState copyWith({
    List<dynamic>? orders,
    bool? isLoading,
    String? error,
  }) {
    return KdsOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class KdsOrdersNotifier extends StateNotifier<KdsOrdersState> {
  final Ref _ref;
  int _currentCounter = 1;

  KdsOrdersNotifier(this._ref) : super(KdsOrdersState()) {
    _listenToSockets();
  }

  void _listenToSockets() {
    final socketService = _ref.read(socketServiceProvider);
    socketService.eventStream.listen((event) {
      if (!mounted) return;

      if (event.type == 'order_created') {
        // Refresh KDS order list on new order creation
        loadKdsOrders(_currentCounter);
      } else if (event.type == 'order_status_changed') {
        final data = event.data;
        final newStatus = data['new_status'];
        // Remove from list if order moves out of active states
        if (newStatus == 'ready' || newStatus == 'completed' || newStatus == 'cancelled') {
          state = state.copyWith(
            orders: state.orders.where((o) => o['order_id'] != data['order_id']).toList(),
          );
        } else {
          loadKdsOrders(_currentCounter);
        }
      } else if (event.type == 'kds_item_prepared') {
        final data = event.data;
        // Check if item is in our active items, update local UI state
        final updatedOrders = state.orders.map((order) {
          if (order['order_id'] == data['order_id']) {
            final updatedItems = (order['items'] as List).map((item) {
              if (item['id'] == data['item_id']) {
                return {...item, 'is_prepared': true};
              }
              return item;
            }).toList();
            return {...order, 'items': updatedItems};
          }
          return order;
        }).toList();

        // Filter out orders where all items for this counter are ready
        final filteredOrders = updatedOrders.where((order) {
          final itemsForCounter = (order['items'] as List)
              .where((item) => item['counter_number'] == _currentCounter);
          return itemsForCounter.any((item) => !item['is_prepared']);
        }).toList();

        state = state.copyWith(orders: filteredOrders);
      }
    });
  }

  Future<void> loadKdsOrders(int counter) async {
    _currentCounter = counter;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.dio.get(
        '/api/admin/kds/orders',
        queryParameters: {'counter': counter},
      );
      final list = response.data['orders'] ?? [];
      state = KdsOrdersState(orders: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> prepareItem(int itemId) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.dio.post('/api/admin/kds/items/$itemId/prepare');
      // Local state update happens automatically via socket trigger 'kds_item_prepared'
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final kdsOrdersProvider = StateNotifierProvider<KdsOrdersNotifier, KdsOrdersState>((ref) {
  return KdsOrdersNotifier(ref);
});

class KdsScreen extends ConsumerStatefulWidget {
  const KdsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends ConsumerState<KdsScreen> {
  int _selectedCounter = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(kdsOrdersProvider.notifier).loadKdsOrders(_selectedCounter);
    });
    // Refresh elapsed timers every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kdsState = ref.watch(kdsOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Kitchen Display System (KDS)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 24),
            _buildCounterTab(1),
            const SizedBox(width: 8),
            _buildCounterTab(2),
            const SizedBox(width: 8),
            _buildCounterTab(3),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryNeon),
            onPressed: () => ref.read(kdsOrdersProvider.notifier).loadKdsOrders(_selectedCounter),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: kdsState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon))
          : kdsState.orders.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisExtent: 280,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: kdsState.orders.length,
                  itemBuilder: (context, index) {
                    final order = kdsState.orders[index];
                    return _buildOrderCard(order);
                  },
                ),
    );
  }

  Widget _buildCounterTab(int counterNum) {
    final isSelected = _selectedCounter == counterNum;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCounter = counterNum;
        });
        ref.read(kdsOrdersProvider.notifier).loadKdsOrders(counterNum);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNeon : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.darkBorder,
            width: 1,
          ),
        ),
        child: Text(
          'Counter $counterNum',
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textDarkSecondary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_rounded, size: 60, color: AppColors.darkBorder),
          const SizedBox(height: 16),
          Text(
            'Counter $_selectedCounter is fully caught up!',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'New orders will pop up here in real-time.',
            style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final createdTime = DateTime.parse(order['created_at']).toLocal();
    final elapsedMin = DateTime.now().difference(createdTime).inMinutes;

    Color timerColor = Colors.grey;
    if (elapsedMin >= 10 && elapsedMin < 15) {
      timerColor = AppColors.warning;
    } else if (elapsedMin >= 15) {
      timerColor = AppColors.error;
    }

    final items = order['items'] as List;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: timerColor == AppColors.error
              ? AppColors.error.withOpacity(0.5)
              : AppColors.darkBorder,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Token: ${order['token']?['token_number'] ?? 'N/A'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: timerColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: timerColor),
                    const SizedBox(width: 4),
                    Text(
                      '${elapsedMin}m ago',
                      style: TextStyle(color: timerColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.darkBorder, height: 16),

          // Items list
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isPrepared = item['is_prepared'] == true;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      AnimatedCheckCircle(
                        isDone: isPrepared,
                        size: 32,
                        onTap: () {
                          if (!isPrepared) {
                            ref.read(kdsOrdersProvider.notifier).prepareItem(item['id']);
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${item['quantity']}x ${item['food_name']}',
                          style: TextStyle(
                            color: isPrepared ? AppColors.textDarkSecondary : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: isPrepared ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Notes or Pickup Slot
          if (order['notes'] != null && (order['notes'] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(6),
              ),
              width: double.infinity,
              child: Text(
                'Note: ${order['notes']}',
                style: const TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
