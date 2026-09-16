import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/time_theme_provider.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../auth/data/auth_provider.dart';
import '../../cart/data/cart_provider.dart';
import '../../menu/data/menu_provider.dart';
import '../../orders/data/order_provider.dart';
import '../../notifications/data/notifications_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  Timer? _carouselTimer;
  int _carouselPage = 0;
  int _specialsCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88, initialPage: 0);
  }

  void _startCarouselTimer(int itemCount) {
    _carouselTimer?.cancel();
    if (itemCount <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _carouselPage = (_carouselPage + 1) % itemCount;
        _pageController.animateToPage(
          _carouselPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final timeTheme = ref.watch(timeThemeProvider);
    final cartVal = ref.watch(cartStateProvider);
    final cartCount = cartVal.when(
      data: (c) => (c['items'] as List?)?.length ?? 0,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      bottomNavigationBar: _AnimatedNavBar(
        currentIndex: _currentIndex,
        accentColor: timeTheme.accent,
        cartCount: cartCount,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) context.push('/menu');
          if (index == 2) context.push('/cart');
          if (index == 3) context.push('/orders');
          if (index == 4) context.push('/profile');
        },
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryNeon.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNeon.withOpacity(0.08),
                    blurRadius: 80,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(specialsProvider);
                ref.invalidate(activeOrdersProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Area
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // Active Order Tracking Panel
                    _buildActiveOrderWidget(),
                    const SizedBox(height: 24),

                    // Quick categories list
                    _buildCategoriesSection(),
                    const SizedBox(height: 28),

                    // Today's Specials Carousel
                    _buildSpecialsCarousel(),
                    const SizedBox(height: 28),

                    // Popular food selection list
                    const Text(
                      'Popular Choices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPopularList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = ref.watch(authStateProvider).user;
    final name = user?['full_name'] ?? 'Student';
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => !(n['is_read'] ?? false)).length,
      orElse: () => 0,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome,',
              style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 14),
            ),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
              onPressed: () => context.push('/notifications'),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
          ],
        ),
      ],
    );
  }

  Widget _buildActiveOrderWidget() {
    final activeOrdersVal = ref.watch(activeOrdersProvider);

    return activeOrdersVal.when(
      data: (orders) {
        if (orders.isEmpty) return const SizedBox.shrink();

        final firstOrder = orders.first;
        final status = firstOrder['status'];
        final orderId = firstOrder['order_id'];
        final token = firstOrder['token']?['token_number'] ?? 'N/A';

        return GestureDetector(
          onTap: () => context.push('/order-tracking/$orderId'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.neonGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNeon.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.delivery_dining, color: Colors.white, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Order: $token',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        'Status: ${status.toString().toUpperCase()}',
                        style: const TextStyle(color: Color(0xDEFFFFFF), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/order-tracking/$orderId'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.primaryNeon,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Track', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const ShimmerLoader(height: 80, borderRadius: 16),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoriesSection() {
    final categoriesVal = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: categoriesVal.when(
            data: (cats) {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                itemBuilder: (context, idx) {
                  final cat = cats[idx];
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: ActionChip(
                      label: Text(cat['name']),
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      backgroundColor: AppColors.darkSurface,
                      side: const BorderSide(color: AppColors.darkBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onPressed: () {
                        ref.read(menuFilterProvider.notifier).update(
                          (state) => state.copyWith(categoryId: cat['id']),
                        );
                        context.push('/menu');
                      },
                    ),
                  );
                },
              );
            },
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, idx) => Container(
                margin: const EdgeInsets.only(right: 10),
                child: const ShimmerLoader(width: 80, height: 40, borderRadius: 12),
              ),
            ),
            error: (_, __) => const Text('Error loading categories'),
          ),
        )
      ],
    );
  }

  Widget _buildSpecialsCarousel() {
    final specialsVal = ref.watch(specialsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Specials",
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        specialsVal.when(
          data: (items) {
            if (items.isEmpty) {
              return const GlassmorphicCard(
                height: 160,
                child: Center(
                  child: Text('No specials listed for today.', style: TextStyle(color: AppColors.textDarkSecondary)),
                ),
              );
            }

            // Keep carousel timer in sync with loaded items
            if (_carouselTimer == null || _specialsCount != items.length) {
              _specialsCount = items.length;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _startCarouselTimer(items.length);
              });
            }

            return Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: items.length,
                    onPageChanged: (page) {
                      setState(() {
                        _carouselPage = page;
                      });
                      // Reset timer on manual swipe to prevent sudden auto-scrolling
                      _startCarouselTimer(items.length);
                    },
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      final imageUrl = item['image'] != null
                          ? (item['image'].startsWith('/')
                              ? '${ApiConstants.baseUrl}${item['image']}'
                              : item['image'])
                          : '';

                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = _pageController.page! - idx;
                            value = (1 - (value.abs() * 0.06)).clamp(0.94, 1.0);
                          } else {
                            value = idx == _carouselPage ? 1.0 : 0.94;
                          }
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: GestureDetector(
                          onTap: () => context.push('/food-detail', extra: {'item': item}),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryNeon.withOpacity(0.12),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: GlassmorphicCard(
                              padding: EdgeInsets.zero,
                              borderRadius: 20,
                              borderColor: _carouselPage == idx 
                                  ? AppColors.primaryNeon.withOpacity(0.4) 
                                  : Colors.white.withOpacity(0.08),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (imageUrl.isNotEmpty)
                                    CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const ShimmerLoader(
                                        width: double.infinity,
                                        height: double.infinity,
                                        borderRadius: 20,
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: AppColors.darkSurface,
                                        child: const Icon(Icons.fastfood, size: 60, color: AppColors.primaryNeon),
                                      ),
                                    )
                                  else
                                    Container(
                                      color: AppColors.darkSurface,
                                      child: const Icon(Icons.fastfood, size: 60, color: AppColors.primaryNeon),
                                    ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.4),
                                          Colors.black.withOpacity(0.9),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    right: 16,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold, 
                                            fontSize: 18, 
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '₹${item['price']}',
                                              style: const TextStyle(
                                                color: AppColors.primaryNeon, 
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                shadows: [
                                                  Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: item['is_veg'] 
                                                    ? const Color(0xFF00F5D4).withOpacity(0.2) 
                                                    : const Color(0xFFFF006E).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: item['is_veg'] 
                                                      ? const Color(0xFF00F5D4).withOpacity(0.6) 
                                                      : const Color(0xFFFF006E).withOpacity(0.6),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                item['is_veg'] ? 'VEG' : 'NON-VEG',
                                                style: TextStyle(
                                                  color: item['is_veg'] ? const Color(0xFF00F5D4) : const Color(0xFFFF006E),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(items.length, (index) {
                    bool isActive = index == _carouselPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primaryNeon : Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isActive ? [
                          BoxShadow(
                            color: AppColors.primaryNeon.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ] : null,
                      ),
                    );
                  }),
                ),
              ],
            );
          },
          loading: () => const ShimmerLoader(width: double.infinity, height: 180, borderRadius: 20),
          error: (_, __) => const GlassmorphicCard(
            height: 160,
            child: Center(
              child: Text('Error loading specials', style: TextStyle(color: AppColors.error)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularList() {
    final foodVal = ref.watch(foodItemsProvider);

    return foodVal.when(
      data: (items) {
        if (items.isEmpty) return const Text('No popular items found.');
        
        // Take first 5 items as popular
        final popularItems = items.take(5).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: popularItems.length,
          itemBuilder: (context, idx) {
            final item = popularItems[idx];
            final imageUrl = item['image'] != null
                ? (item['image'].startsWith('/')
                    ? '${ApiConstants.baseUrl}${item['image']}'
                    : item['image'])
                : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassmorphicCard(
                padding: const EdgeInsets.all(8),
                borderColor: Colors.white.withOpacity(0.08),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 58,
                      height: 58,
                      color: AppColors.darkSurface,
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const ShimmerLoader(
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 12,
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.fastfood_outlined, 
                                color: AppColors.primaryNeon, 
                                size: 24,
                              ),
                            )
                          : const Icon(
                              Icons.fastfood_outlined, 
                              color: AppColors.primaryNeon, 
                              size: 24,
                            ),
                    ),
                  ),
                  title: Text(
                    item['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text(
                          '₹${item['price']}',
                          style: const TextStyle(
                            color: AppColors.primaryNeon, 
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${item['preparation_time']} mins prep',
                          style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryNeon.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20, color: AppColors.primaryNeon),
                      onPressed: () => context.push('/food-detail', extra: {'item': item}),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, idx) => const ShimmerFoodCard(),
      ),
      error: (_, __) => const Text('Error loading popular items'),
    );
  }
}

// ── Animated bottom nav bar ────────────────────────────────────────
class _AnimatedNavBar extends StatelessWidget {
  final int currentIndex;
  final Color accentColor;
  final int cartCount;
  final ValueChanged<int> onTap;

  const _AnimatedNavBar({
    required this.currentIndex,
    required this.accentColor,
    required this.cartCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home', 0),
      (Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Menu', 0),
      (Icons.shopping_cart_outlined, Icons.shopping_cart_rounded, 'Cart', cartCount),
      (Icons.receipt_long_outlined, Icons.receipt_long, 'Orders', 0),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile', 0),
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder, width: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((e) {
          final idx = e.key;
          final (outIcon, fillIcon, label, badge) = e.value;
          final isSelected = currentIndex == idx;

          return GestureDetector(
            onTap: () => onTap(idx),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Icon with scale + glow
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? accentColor.withOpacity(0.15) : Colors.transparent,
                          boxShadow: isSelected
                              ? [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 14)]
                              : [],
                        ),
                        child: AnimatedScale(
                          scale: isSelected ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            isSelected ? fillIcon : outIcon,
                            color: isSelected ? accentColor : AppColors.textDarkSecondary,
                            size: 22,
                          ),
                        ),
                      ),
                      // Cart badge bounce
                      if (badge > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: _BounceBadge(count: badge, color: accentColor),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSelected ? 11 : 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? accentColor : AppColors.textDarkSecondary,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Cart badge with bounce animation ──────────────────────────────
class _BounceBadge extends StatefulWidget {
  final int count;
  final Color color;
  const _BounceBadge({required this.count, required this.color});
  @override
  State<_BounceBadge> createState() => _BounceBadgeState();
}

class _BounceBadgeState extends State<_BounceBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  int _prevCount = 0;

  @override
  void initState() {
    super.initState();
    _prevCount = widget.count;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_BounceBadge old) {
    super.didUpdateWidget(old);
    if (widget.count != _prevCount) {
      _prevCount = widget.count;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 18, height: 18,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color,
            boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 6)]),
        child: Center(
          child: Text(
            widget.count > 9 ? '9+' : '${widget.count}',
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
