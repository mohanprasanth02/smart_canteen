import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../data/admin_provider.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _prepController = TextEditingController();

  bool _isVeg = true;
  bool _isSpecial = false;
  int _selectedCategoryId = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _prepController.dispose();
    super.dispose();
  }

  void _showForm({Map<String, dynamic>? item}) {
    if (item != null) {
      _nameController.text = item['name'];
      _descController.text = item['description'] ?? '';
      _priceController.text = item['price'].toString();
      _qtyController.text = item['quantity'].toString();
      _prepController.text = item['preparation_time'].toString();
      _isVeg = item['is_veg'] ?? true;
      _isSpecial = item['is_special'] ?? false;
      _selectedCategoryId = item['category_id'] ?? 1;
    } else {
      _nameController.clear();
      _descController.clear();
      _priceController.text = '50';
      _qtyController.text = '30';
      _prepController.text = '10';
      _isVeg = true;
      _isSpecial = false;
      _selectedCategoryId = 1;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item == null ? 'Add Food Item' : 'Edit Food Item',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Food Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (₹)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock Qty'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _prepController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prep Time (mins)'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Vegetarian', style: TextStyle(color: Colors.white)),
                  Switch(
                    value: _isVeg,
                    onChanged: (val) => setState(() => _isVeg = val),
                    activeColor: AppColors.success,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Todays Special', style: TextStyle(color: Colors.white)),
                  Switch(
                    value: _isSpecial,
                    onChanged: (val) => setState(() => _isSpecial = val),
                    activeColor: AppColors.primaryNeon,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final data = {
                    'name': _nameController.text.trim(),
                    'description': _descController.text.trim(),
                    'price': double.tryParse(_priceController.text) ?? 50.0,
                    'quantity': int.tryParse(_qtyController.text) ?? 30,
                    'preparation_time': int.tryParse(_prepController.text) ?? 10,
                    'is_veg': _isVeg,
                    'is_special': _isSpecial,
                    'category_id': _selectedCategoryId,
                  };

                  final repo = ref.read(adminRepositoryProvider);
                  if (item == null) {
                    await repo.addMenuItem(data);
                  } else {
                    await repo.updateMenuItem(item['id'], data);
                  }

                  ref.invalidate(adminStatsProvider);
                  // Refresh catalog listings
                  setState(() {});
                  if (mounted) context.pop();
                },
                child: const Text('Save Food Item'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(adminRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Catalog'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primaryNeon,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: repo.getMenu(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error loading menu'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, idx) {
              final item = items[idx];
              final isAvailable = item['is_available'] == true && item['quantity'] > 0;

              return Opacity(
                opacity: isAvailable ? 1.0 : 0.6,
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
                          child: item['image'] != null
                              ? Image.network(
                                  item['image'].startsWith('/')
                                      ? '${ApiConstants.baseUrl}${item['image']}'
                                      : item['image'],
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
                              item['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${item['price']} • Stock: ${item['quantity']}',
                              style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.primaryNeon, size: 20),
                            onPressed: () => _showForm(item: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            onPressed: () async {
                              await repo.deleteMenuItem(item['id']);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              );
            },
          );
        },
      ),
    );
  }
}
