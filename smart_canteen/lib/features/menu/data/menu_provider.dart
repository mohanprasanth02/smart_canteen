import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/socket/socket_service.dart';
import '../../auth/data/auth_provider.dart';
import 'menu_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.watch(apiClientProvider));
});

// Category Provider
final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(menuRepositoryProvider).getCategories();
});

// Todays Specials Provider
final specialsProvider = StateNotifierProvider<SpecialsNotifier, AsyncValue<List<dynamic>>>((ref) {
  final repo = ref.watch(menuRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return SpecialsNotifier(repo, socketService);
});

class SpecialsNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final MenuRepository _repo;
  final SocketService _socketService;

  SpecialsNotifier(this._repo, this._socketService) : super(const AsyncValue.loading()) {
    loadSpecials();
    _listenToSocket();
  }

  Future<void> loadSpecials() async {
    try {
      final data = await _repo.getSpecials();
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _listenToSocket() {
    _socketService.eventStream.listen((event) {
      if (!mounted) return;
      
      if (event.type == 'menu_updated') {
        loadSpecials(); // reload if menu modified
      } else if (event.type == 'stock_changed') {
        // dynamically adjust stocks in memory if needed or reload
        loadSpecials();
      }
    });
  }
}

// Main Menu Listing State
class MenuFilters {
  final int? categoryId;
  final bool? isVeg;
  final String sortBy;
  final String sortOrder;
  final String searchQuery;

  MenuFilters({
    this.categoryId,
    this.isVeg,
    this.sortBy = 'name',
    this.sortOrder = 'asc',
    this.searchQuery = '',
  });

  MenuFilters copyWith({
    int? categoryId,
    bool? isVeg,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
    bool clearCategory = false,
    bool clearVeg = false,
  }) {
    return MenuFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      isVeg: clearVeg ? null : (isVeg ?? this.isVeg),
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final menuFilterProvider = StateProvider<MenuFilters>((ref) => MenuFilters());

final foodItemsProvider = StateNotifierProvider<FoodItemsNotifier, AsyncValue<List<dynamic>>>((ref) {
  final repo = ref.watch(menuRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  final filters = ref.watch(menuFilterProvider);
  return FoodItemsNotifier(repo, socketService, filters);
});

class FoodItemsNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final MenuRepository _repo;
  final SocketService _socketService;
  final MenuFilters _filters;

  FoodItemsNotifier(this._repo, this._socketService, this._filters) : super(const AsyncValue.loading()) {
    loadFoodItems();
    _listenToSocket();
  }

  Future<void> loadFoodItems() async {
    try {
      if (_filters.searchQuery.isNotEmpty) {
        final data = await _repo.searchFood(_filters.searchQuery);
        state = AsyncValue.data(data);
        return;
      }
      final data = await _repo.getFoodItems(
        categoryId: _filters.categoryId,
        isVeg: _filters.isVeg,
        sortBy: _filters.sortBy,
        sortOrder: _filters.sortOrder,
      );
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _listenToSocket() {
    _socketService.eventStream.listen((event) {
      if (!mounted) return;

      if (event.type == 'menu_updated') {
        final action = event.data['action'];
        final item = event.data['item'];
        
        state.whenData((items) {
          final list = List<dynamic>.from(items);
          if (action == 'added') {
            if (_filters.categoryId == null || _filters.categoryId == item['category_id']) {
              list.add(item);
            }
          } else if (action == 'updated') {
            final idx = list.indexWhere((x) => x['id'] == item['id']);
            if (idx != -1) {
              list[idx] = item;
            } else {
              loadFoodItems(); // reload just in case
              return;
            }
          } else if (action == 'deleted') {
            list.removeWhere((x) => x['id'] == item['id']);
          }
          state = AsyncValue.data(list);
        });
      } else if (event.type == 'stock_changed') {
        final updatedItems = event.data['items'] as List<dynamic>;
        state.whenData((items) {
          final list = List<dynamic>.from(items);
          bool changed = false;
          for (var ui in updatedItems) {
            final idx = list.indexWhere((x) => x['id'] == ui['id']);
            if (idx != -1) {
              list[idx] = {
                ...list[idx],
                'quantity': ui['quantity'],
                'is_available': ui['is_available'],
              };
              changed = true;
            }
          }
          if (changed) {
            state = AsyncValue.data(list);
          }
        });
      }
    });
  }
}
