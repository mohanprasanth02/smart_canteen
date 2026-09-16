import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/socket/socket_service.dart';
import 'auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return AuthStateNotifier(repo, socketService);
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;
  final String role; // student, admin, super_admin

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.role = 'student',
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? user,
    String? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      role: role ?? this.role,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final SocketService _socketService;

  AuthStateNotifier(this._repo, this._socketService) : super(AuthState()) {
    checkAuthentication();
  }

  Future<void> checkAuthentication() async {
    state = state.copyWith(isLoading: true);
    try {
      final isLoggedIn = await _repo.checkAuth();
      if (isLoggedIn) {
        final data = await _repo.getCurrentUser();
        final user = data['user'];
        final role = data['role'] ?? 'student';
        
        state = AuthState(
          isAuthenticated: true,
          user: user,
          role: role,
        );

        // Connect socket
        _socketService.connect(userId: user['id']);
        _registerFcmToken();
      } else {
        state = AuthState();
      }
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repo.login(email, password);
      final user = response['user'];
      
      state = AuthState(
        isAuthenticated: true,
        user: user,
        role: 'student',
      );

      _socketService.connect(userId: user['id']);
      _registerFcmToken();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> adminLogin(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repo.adminLogin(username, password);
      final admin = response['admin'];
      final role = admin['role'] ?? 'admin';
      
      state = AuthState(
        isAuthenticated: true,
        user: admin,
        role: role,
      );

      _socketService.connect(userId: admin['id']);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String registerNumber,
    required String department,
    required int year,
    required String mobileNumber,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repo.register(
        fullName: fullName,
        registerNumber: registerNumber,
        department: department,
        year: year,
        mobileNumber: mobileNumber,
        email: email,
        password: password,
      );
      final user = response['user'];
      
      state = AuthState(
        isAuthenticated: true,
        user: user,
        role: 'student',
      );

      _socketService.connect(userId: user['id']);
      _registerFcmToken();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    if (state.user != null) {
      _socketService.emitUserOffline(state.user!['id']);
    }
    _socketService.disconnect();
    await _repo.logout();
    state = AuthState();
  }

  Future<void> _registerFcmToken() async {
    if (state.role != 'student' || state.user == null) return;
    try {
      final token = 'mock_student_fcm_token_${state.user!['id']}';
      await _repo.saveFcmToken(token);
    } catch (e) {
      print('[FCM] Token auto-upload failed: $e');
    }
  }
}
