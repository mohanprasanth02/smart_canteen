import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/socket/socket_service.dart';
import '../../auth/data/auth_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiClientProvider));
});

class ChatRepository {
  final ApiClient _apiClient;
  ChatRepository(this._apiClient);

  Future<Map<String, dynamic>> getOrCreateRoom({int? orderId}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/chat/rooms',
        data: orderId != null ? {'order_id': orderId} : {},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getActiveRooms() async {
    try {
      final response = await _apiClient.dio.get('/api/chat/rooms/active');
      return response.data['rooms'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getRoomMessages(int roomId) async {
    try {
      final response = await _apiClient.dio.get('/api/chat/rooms/$roomId/messages');
      return response.data['messages'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> closeRoom(int roomId) async {
    try {
      await _apiClient.dio.post('/api/chat/rooms/$roomId/close');
    } catch (e) {
      rethrow;
    }
  }
}

class ChatState {
  final Map<String, dynamic>? activeRoom;
  final List<dynamic> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    this.activeRoom,
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    Map<String, dynamic>? activeRoom,
    List<dynamic>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      activeRoom: activeRoom ?? this.activeRoom,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatStateNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repo;
  final SocketService _socketService;
  final int? _userId;

  ChatStateNotifier(this._repo, this._socketService, this._userId) : super(ChatState()) {
    _listenToMessages();
  }

  void _listenToMessages() {
    _socketService.eventStream.listen((event) {
      if (!mounted) return;

      if (event.type == 'new_chat_message') {
        final msg = event.data;
        if (state.activeRoom != null && msg['room_id'] == state.activeRoom!['id']) {
          state = state.copyWith(
            messages: [...state.messages, msg],
          );
        }
      } else if (event.type == 'chat_room_closed') {
        final data = event.data;
        if (state.activeRoom != null && data['room_id'] == state.activeRoom!['id']) {
          state = state.copyWith(
            activeRoom: {
              ...state.activeRoom!,
              'status': 'closed',
            },
          );
        }
      }
    });
  }

  Future<void> initRoom({int? orderId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repo.getOrCreateRoom(orderId: orderId);
      final room = response['room'];
      
      final history = await _repo.getRoomMessages(room['id']);

      state = ChatState(
        activeRoom: room,
        messages: history,
        isLoading: false,
      );

      _socketService.socket?.emit('join_chat', {'room_id': room['id']});
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectAdminRoom(Map<String, dynamic> room) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _repo.getRoomMessages(room['id']);
      state = ChatState(
        activeRoom: room,
        messages: history,
        isLoading: false,
      );

      _socketService.socket?.emit('join_chat', {'room_id': room['id']});
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void sendMessage(String message, String role) {
    if (state.activeRoom == null || _userId == null) return;

    _socketService.socket?.emit('send_chat_message', {
      'room_id': state.activeRoom!['id'],
      'sender_id': _userId,
      'sender_role': role,
      'message': message,
    });
  }

  Future<void> closeActiveRoom() async {
    if (state.activeRoom == null) return;
    try {
      await _repo.closeRoom(state.activeRoom!['id']);
      state = state.copyWith(
        activeRoom: {
          ...state.activeRoom!,
          'status': 'closed',
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final chatStateProvider = StateNotifierProvider<ChatStateNotifier, ChatState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?['id'];
  return ChatStateNotifier(repo, socketService, userId);
});

final activeChatRoomsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getActiveRooms();
});
