import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/time_theme_provider.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/morph_add_button.dart';
import '../../cart/data/cart_provider.dart';
import '../data/menu_provider.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(menuFilterProvider.notifier).update(
          (state) => state.copyWith(searchQuery: query),
        );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(menuFilterProvider);
    final categoriesVal = ref.watch(categoriesProvider);
    final foodItemsVal = ref.watch(foodItemsProvider);
    final timeTheme = ref.watch(timeThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Parallax Hero Banner
          SizedBox(
            height: 110,
            child: ClipRect(
              child: Stack(
                children: [
                  Transform.translate(
                    offset: Offset(0, _scrollOffset * 0.4),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [timeTheme.accent.withOpacity(0.5), AppColors.darkBackground],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Today's Menu",
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: timeTheme.accent.withOpacity(0.8), blurRadius: 12)])),
                        const SizedBox(height: 4),
                        const Text('Fresh • Hot • Made to order', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search + Sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search food items...',
                    leading: const Icon(Icons.search, color: AppColors.primaryNeon),
                    onChanged: _onSearchChanged,
                    backgroundColor: WidgetStateProperty.all(AppColors.darkSurface),
                    elevation: WidgetStateProperty.all(0),
                    shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.darkBorder),
                    )),
                    textStyle: WidgetStateProperty.all(const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                _buildSortButton(),
              ],
            ),
          ),

          // Veg/Non-Veg chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Veg Only'),
                  selected: filters.isVeg == true,
                  onSelected: (val) => ref.read(menuFilterProvider.notifier).update(
                        (state) => state.copyWith(isVeg: val ? true : null, clearVeg: !val),
                      ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Non-Veg'),
                  selected: filters.isVeg == false,
                  onSelected: (val) => ref.read(menuFilterProvider.notifier).update(
                        (state) => state.copyWith(isVeg: val ? false : null, clearVeg: !val),
                      ),
                ),
              ],
            ),
          ),

          // Categories with scale animation
          categoriesVal.when(
            data: (cats) => SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: cats.length + 1,
                itemBuilder: (context, idx) {
                  final isAll = idx == 0;
                  final cat = isAll ? null : cats[idx - 1];
                  final isSelected = isAll ? (filters.categoryId == null) : (filters.categoryId == cat['id']);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(right: 8),
                    transform: Matrix4.identity()..scale(isSelected ? 1.08 : 1.0),
                    transformAlignment: Alignment.center,
                    child: ChoiceChip(
                      label: Text(isAll ? 'All' : cat['name']),
                      selected: isSelected,
                      selectedColor: timeTheme.accent.withOpacity(0.25),
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(menuFilterProvider.notifier).update(
                                (state) => state.copyWith(categoryId: isAll ? null : cat['id'], clearCategory: isAll),
                              );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            loading: () => const SizedBox(height: 50),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Food items with stagger
          Expanded(
            child: foodItemsVal.when(
              data: (items) {
                if (items.isEmpty) return const Center(child: Text('No food items found.', style: TextStyle(color: Colors.grey)));
                final sorted = [...items]..sort((a, b) => (b['total_orders'] ?? 0).compareTo(a['total_orders'] ?? 0));
                final topIds = sorted.take(3).map((e) => e['id']).toSet();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isAvailable = item['is_available'] == true && item['quantity'] > 0;
                    final isPopular = topIds.contains(item['id']);
                    return _StaggeredMenuItem(index: index, item: item, isAvailable: isAvailable, isPopular: isPopular, timeTheme: timeTheme);
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, idx) => const ShimmerFoodCard(),
              ),
              error: (_, __) => const Center(child: Text('Error loading menu items')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort, color: AppColors.primaryNeon),
      onSelected: (val) {
        String sortBy = 'name'; String sortOrder = 'asc';
        if (val == 'price_low') { sortBy = 'price'; sortOrder = 'asc'; }
        else if (val == 'price_high') { sortBy = 'price'; sortOrder = 'desc'; }
        else if (val == 'pop') { sortBy = 'popularity'; sortOrder = 'desc'; }
        ref.read(menuFilterProvider.notifier).update((state) => state.copyWith(sortBy: sortBy, sortOrder: sortOrder));
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
        const PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
        const PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
        const PopupMenuItem(value: 'pop', child: Text('Most Popular')),
      ],
    );
  }
}

class _StaggeredMenuItem extends ConsumerStatefulWidget {
  final int index;
  final Map<String, dynamic> item;
  final bool isAvailable;
  final bool isPopular;
  final TimeTheme timeTheme;
  const _StaggeredMenuItem({required this.index, required this.item, required this.isAvailable, required this.isPopular, required this.timeTheme});
  @override
  ConsumerState<_StaggeredMenuItem> createState() => _StaggeredMenuItemState();
}

class _StaggeredMenuItemState extends ConsumerState<_StaggeredMenuItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: 50 * widget.index), () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isAvailable = widget.isAvailable;
    final imageUrl = item['image'] != null
        ? (item['image'].startsWith('/') ? '${ApiConstants.baseUrl}${item['image']}' : item['image'])
        : null;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassmorphicCard(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isAvailable
                  ? () => context.push('/food-detail', extra: {'item': item})
                  : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This item is currently unavailable'), duration: Duration(seconds: 2))),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Hero(
                        tag: 'food-${item['id']}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 80, height: 80,
                            child: imageUrl != null
                                ? ColorFiltered(
                                    colorFilter: isAvailable
                                        ? const ColorFilter.mode(Colors.transparent, BlendMode.saturation)
                                        : const ColorFilter.matrix([0.213,0.715,0.072,0,0, 0.213,0.715,0.072,0,0, 0.213,0.715,0.072,0,0, 0,0,0,1,0]),
                                    child: Image.network(imageUrl, fit: BoxFit.cover),
                                  )
                                : Container(color: AppColors.darkSurface, child: const Icon(Icons.fastfood, color: AppColors.primaryNeon)),
                          ),
                        ),
                      ),
                      if (!isAvailable)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                            child: const Center(child: Icon(Icons.lock_outline, color: Colors.white70, size: 22)),
                          ),
                        ),
                      if (widget.isPopular) const Positioned(top: 4, left: 4, child: _PopularBadge()),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(item['name'], maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isAvailable ? Colors.white : Colors.white54))),
                            const SizedBox(width: 6),
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(border: Border.all(color: item['is_veg'] ? Colors.green : Colors.red, width: 1.5)),
                              padding: const EdgeInsets.all(2),
                              child: Container(decoration: BoxDecoration(color: item['is_veg'] ? Colors.green : Colors.red, shape: BoxShape.circle)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rs.${item['price']}',
                                    style: TextStyle(color: isAvailable ? widget.timeTheme.accent : Colors.white38, fontWeight: FontWeight.bold, fontSize: 16)),
                                if (isAvailable) ...[
                                  const SizedBox(height: 2),
                                  Text('Stock: ${item['quantity']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ],
                            ),
                            if (!isAvailable)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.error.withOpacity(0.3))),
                                child: const Text('SOLD OUT', style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.bold)),
                              )
                            else
                              MorphAddButton(
                                onAdd: () async {
                                  return await ref.read(cartStateProvider.notifier).addToCart(item['id'], 1);
                                },
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
      ),
    );
  }
}

class _PopularBadge extends StatefulWidget {
  const _PopularBadge();
  @override
  State<_PopularBadge> createState() => _PopularBadgeState();
}

class _PopularBadgeState extends State<_PopularBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFFFB703), Colors.white, const Color(0xFFFFB703)],
            stops: [(_anim.value - 0.5).clamp(0.0, 1.0), _anim.value.clamp(0.0, 1.0), (_anim.value + 0.5).clamp(0.0, 1.0)],
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('HOT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }
}
