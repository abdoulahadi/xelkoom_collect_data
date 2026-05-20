import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/user.dart';
import '../models/recording.dart';
import '../models/leaderboard.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

// Stream controller pour les événements de logout
final logoutStreamController = StreamController<void>.broadcast();

// Auth Service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final authService = ref.read(authServiceProvider);
  final apiService = ApiService(authService);

  // Configurer la callback pour l'expiration du token
  apiService.onTokenExpired = () {
    logoutStreamController.add(null);
  };

  return apiService;
});

// Auth state provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((
  ref,
) {
  final authService = ref.read(authServiceProvider);
  final apiService = ref.read(apiServiceProvider);
  return AuthStateNotifier(authService, apiService);
});

// Current user provider
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.isAuthenticated && authState.user != null) {
    return authState.user;
  }
  return null;
});

// User stats provider
final userStatsProvider = FutureProvider<UserStats?>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated) return null;

  try {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getUserStats();
  } catch (e) {
    throw Exception('Failed to load user stats: $e');
  }
});

// Recent recordings provider
final recentRecordingsProvider = FutureProvider<List<Recording>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated) return [];

  try {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getRecentRecordings();
  } catch (e) {
    throw Exception('Failed to load recent recordings: $e');
  }
});

// Leaderboard provider
final leaderboardProvider = FutureProvider<LeaderboardResponse>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated) {
    throw Exception('User not authenticated');
  }

  try {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getLeaderboard();
  } catch (e) {
    throw Exception('Failed to load leaderboard: $e');
  }
});

// Auth state model
class AuthState {
  final bool isAuthenticated;
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth state notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final ApiService _apiService;
  StreamSubscription? _logoutSubscription;

  AuthStateNotifier(this._authService, this._apiService)
    : super(const AuthState()) {
    // Écouter les événements de logout forcé
    _logoutSubscription = logoutStreamController.stream.listen((_) {
      print('Token expired, forcing logout...');
      _forceLogout();
    });

    _checkAuthStatus();
  }

  void _forceLogout() {
    state = const AuthState();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // Try to get cached user first
        User? user = await _authService.getCurrentUser();

        // If no cached user, fetch from API
        if (user == null) {
          try {
            user = await _apiService.getCurrentUser();
            // Save the fresh user data
            final token = await _authService.getToken();
            if (token != null) {
              await _authService.saveAuthData(token, user);
            }
          } catch (e) {
            // If API call fails but we have a token, we might be offline
            print('Failed to fetch user from API: $e');
          }
        }

        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Authentication check failed: $e',
      );
    }
  }

  Future<void> register({
    required String username,
    required String password,
    required String gender,
    required String ageRange,
    required bool consentGiven,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.register(
        username: username,
        password: password,
        gender: gender,
        ageRange: ageRange,
        consentGiven: consentGiven,
      );

      final token = response['access_token'];
      final userData = response['user'];
      final user = User.fromJson(userData);

      await _authService.saveAuthData(token, user);

      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> login(String username, String password) async {
    print('AuthStateNotifier: Starting login for $username');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.login(username, password);
      print('AuthStateNotifier: API login response received');

      final token = response['access_token'];
      final userData = response['user'];
      final user = User.fromJson(userData);

      await _authService.saveAuthData(token, user);
      print('AuthStateNotifier: Auth data saved');

      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );

      print(
        'AuthStateNotifier: State updated - isAuthenticated: ${state.isAuthenticated}',
      );
    } catch (e) {
      print('AuthStateNotifier: Login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  Future<void> updateUser({String? username, bool? isActive}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedUser = await _apiService.updateUser(
        username: username,
        isActive: isActive,
      );

      // Update the user in auth service cache
      final currentToken = await _authService.getToken();
      if (currentToken != null) {
        await _authService.saveAuthData(currentToken, updatedUser);
      }

      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.deleteAccount();
      await _authService.logout();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _logoutSubscription?.cancel();
    super.dispose();
  }
}
