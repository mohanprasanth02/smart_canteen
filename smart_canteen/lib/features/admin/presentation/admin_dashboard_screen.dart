import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../auth/data/auth_provider.dart';
import '../data/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsVal = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppColors.error),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard header
              const Text(
                'Live Stats Today',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              statsVal.when(
                data: (stats) {
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _buildStatCard('Revenue Today', '₹${stats['revenue_today']}', Icons.currency_rupee, AppColors.success),
                      _buildStatCard('Orders Today', '${stats['orders_today']}', Icons.receipt_long, AppColors.primaryNeon),
                      _buildStatCard('Pending Prep', '${stats['pending_orders']}', Icons.timer_outlined, AppColors.warning),
                      _buildStatCard('Low Stock Alerts', '${stats['low_stock_alerts']}', Icons.warning_amber_rounded, AppColors.error),
                    ],
                  );
                },
                loading: () => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: List.generate(4, (_) => const ShimmerLoader(borderRadius: 16)),
                ),
                error: (_, __) => const Center(child: Text('Failed to load stats')),
              ),

              const SizedBox(height: 30),

              // Canteen Staff Operations Grid
              const Text(
                'Canteen Operations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildOpCard(context, 'Verify QR', Icons.qr_code_scanner, '/qr-scanner', AppColors.primaryNeon),
                  _buildOpCard(context, 'Orders Queue', Icons.dinner_dining_outlined, '/admin-orders', AppColors.warning),
                  _buildOpCard(context, 'Kitchen KDS', Icons.kitchen_outlined, '/admin-kds', AppColors.error),
                  _buildOpCard(context, 'Support Chat', Icons.chat_bubble_outline, '/admin-chat-hub', AppColors.success),
                  _buildOpCard(context, 'Menu Catalog', Icons.restaurant_menu, '/admin-menu', AppColors.accentCyan),
                  _buildOpCard(context, 'Raw Inventory', Icons.warehouse_outlined, '/admin-inventory', AppColors.accentCyan),
                  _buildOpCard(context, 'User Directory', Icons.people_outline, '/admin-users', AppColors.info),
                  _buildOpCard(context, 'Sales Insights', Icons.insights, '/admin-analytics', AppColors.primaryNeon),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassmorphicCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildOpCard(BuildContext context, String title, IconData icon, String route, Color color) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: GlassmorphicCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
