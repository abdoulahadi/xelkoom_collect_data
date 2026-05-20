import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../models/user.dart';
import '../models/sentence.dart';
import '../models/recording.dart';
import '../models/leaderboard.dart';
import 'auth_service.dart';
import 'certificate_pinning.dart';

class ApiService {
  // MOB-002: Environment-based URL configuration via --dart-define
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend-xelkoom-collect.onrender.com/api/v1',
  );
  late final Dio _dio;
  final AuthService _authService;

  // Callback pour notifier l'expiration du token
  Function()? onTokenExpired;

  ApiService(this._authService, {this.onTokenExpired}) {
    _dio = Dio();
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // SEC-011: Apply certificate pinning if configured
    CertificatePinning.apply(_dio);

    // Add logger interceptor for debugging
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );

    // Add auth interceptor — CTR-008: token refresh on 401
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/refresh') &&
              !error.requestOptions.path.contains('/auth/login')) {
            // Try to refresh the token before logging out
            try {
              final currentToken = await _authService.getToken();
              if (currentToken != null) {
                final refreshDio = Dio();
                refreshDio.options.baseUrl = baseUrl;
                final refreshResponse = await refreshDio.post(
                  '/auth/refresh',
                  options: Options(
                    headers: {'Authorization': 'Bearer $currentToken'},
                  ),
                );
                if (refreshResponse.statusCode == 200) {
                  final newToken = refreshResponse.data['access_token'] as String;
                  // Update stored token
                  final user = await _authService.getCurrentUser();
                  if (user != null) {
                    await _authService.saveAuthData(newToken, user);
                  }
                  // Retry the original request with the new token
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newToken';
                  final retryResponse = await _dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                }
              }
            } catch (_) {
              // Refresh failed, proceed to logout
            }

            print('Token expired, logging out user');
            await _authService.logout();

            // Notifier le provider d'authentification
            if (onTokenExpired != null) {
              onTokenExpired!();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String gender,
    required String ageRange,
    required bool consentGiven,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'gender': gender,
          'age_range': ageRange,
          'consent_given': consentGiven,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // loginLegacy removed — use login() with password instead

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return User.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Sentences endpoints
  Future<Sentence> getNextSentence({String? difficulty}) async {
    try {
      final response = await _dio.get(
        '/sentences/next',
        queryParameters: {if (difficulty != null) 'difficulty': difficulty},
      );
      return Sentence.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Sentence>> getSentences({
    int skip = 0,
    int limit = 100,
    String? difficulty,
  }) async {
    try {
      final response = await _dio.get(
        '/sentences/',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (difficulty != null) 'difficulty': difficulty,
        },
      );

      final List<dynamic> data = response.data;
      return data.map((json) => Sentence.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Recordings endpoints
  Future<Recording> uploadRecording({
    required String sentenceId,
    required String audioFilePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'audio_file': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'recording.wav',
        ),
      });

      final response = await _dio.post(
        '/recordings/',
        data: formData,
        queryParameters: {'sentence_id': sentenceId},
      );
      return Recording.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Recording>> getMyRecordings({
    int skip = 0,
    int limit = 100,
    RecordingStatus? statusFilter,
  }) async {
    try {
      final response = await _dio.get(
        '/recordings/',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (statusFilter != null) 'status_filter': statusFilter.name,
        },
      );

      final List<dynamic> data = response.data;
      return data.map((json) => Recording.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Recording>> getRecentRecordings({int limit = 5}) async {
    try {
      final response = await _dio.get(
        '/recordings/',
        queryParameters: {'skip': 0, 'limit': limit},
      );

      final List<dynamic> data = response.data;
      return data.map((json) => Recording.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteRecording(String recordingId) async {
    try {
      await _dio.delete('/recordings/$recordingId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // User endpoints
  Future<UserStats> getUserStats() async {
    try {
      final response = await _dio.get('/users/me/stats');
      return UserStats.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<LeaderboardResponse> getLeaderboard({int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/users/leaderboard',
        queryParameters: {'limit': limit},
      );
      return LeaderboardResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> updateUser({String? username, bool? isActive}) async {
    try {
      final response = await _dio.put(
        '/users/me',
        data: {
          if (username != null) 'username': username,
          if (isActive != null) 'is_active': isActive,
        },
      );
      return User.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/users/me');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception(
            'Connection timeout. Please check your internet connection.',
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['detail'] ?? 'Server error';
          return Exception('$statusCode: $message');
        case DioExceptionType.cancel:
          return Exception('Request was cancelled');
        case DioExceptionType.unknown:
          return Exception(
            'Network error. Please check your internet connection.',
          );
        default:
          return Exception('Unknown error occurred');
      }
    }
    return Exception('Unexpected error: $error');
  }
}
