import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/socket/socket_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../auth/data/auth_provider.dart';
import 'notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<dynamic>>>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  final authState = ref.watch(authStateProvider);
  final currentUserId = authState.user?['id'];
  return NotificationsNotifier(repo, socketService, currentUserId);
});

class NotificationsNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final NotificationsRepository _repo;
  final SocketService _socketService;
  final int? _currentUserId;

  NotificationsNotifier(this._repo, this._socketService, this._currentUserId) : super(const AsyncValue.loading()) {
    loadNotifications();
    _listenToSocket();
  }

  Future<void> loadNotifications() async {
    if (_currentUserId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final data = await _repo.getNotifications();
      state = AsyncValue.data(data['notifications'] ?? []);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(int notifId) async {
    try {
      await _repo.markAsRead(notifId);
      if (state.hasValue) {
        final currentList = state.value!;
        final updatedList = currentList.map((n) {
          if (n['id'] == notifId) {
            return {...n as Map<String, dynamic>, 'is_read': true};
          }
          return n;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      // Ignore or log error
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repo.markAllAsRead();
      if (state.hasValue) {
        final currentList = state.value!;
        final updatedList = currentList.map((n) => {...n as Map<String, dynamic>, 'is_read': true}).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      // Ignore or log error
    }
  }

  void _listenToSocket() {
    if (_currentUserId == null) return;

    _socketService.eventStream.listen((event) {
      if (!mounted) return;

      if (event.type == 'notification_sent') {
        final data = event.data;
        final targetUserId = data['user_id'];
        
        if (targetUserId == _currentUserId) {
          final String title = data['title'] ?? 'Notification';
          final String message = data['message'] ?? '';
          
          // Show real mobile/system notification
          LocalNotificationService.showNotification(
            title: title,
            body: message,
          );

          // Reload notifications list
          loadNotifications();
        }
      }
    });
  }
}
