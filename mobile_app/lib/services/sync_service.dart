import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_storage_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final int pendingCount;
  final int totalCount;
  final String? errorMessage;
  final DateTime? lastSyncTime;

  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.totalCount = 0,
    this.errorMessage,
    this.lastSyncTime,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    int? totalCount,
    String? errorMessage,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class SyncService extends StateNotifier<SyncState> {
  final OfflineStorageService _offlineStorage;
  final ApiService _apiService;
  final AuthService _authService;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isAutoSyncEnabled = true;

  SyncService(this._offlineStorage, this._apiService, this._authService)
    : super(const SyncState()) {
    _initializeSync();
  }

  void _initializeSync() {
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Start periodic sync (every 5 minutes when online)
    _startPeriodicSync();

    // Initial sync if online
    _checkAndSync();
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    if (result != ConnectivityResult.none && _isAutoSyncEnabled) {
      // Connected to internet, try to sync
      syncPendingRecordings();
    }
  }

  void _startPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkAndSync(),
    );
  }

  Future<void> _checkAndSync() async {
    if (!_isAutoSyncEnabled) return;

    final isOnline = await _isConnectedToInternet();
    if (isOnline) {
      await syncPendingRecordings();
    }
  }

  Future<bool> _isConnectedToInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Additional check by trying to reach a reliable server
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncPendingRecordings() async {
    if (state.status == SyncStatus.syncing) {
      return; // Already syncing
    }

    try {
      // Check if user is authenticated
      final token = await _authService.getToken();
      if (token == null) {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: 'User not authenticated',
        );
        return;
      }

      // Get pending recordings
      final pendingRecordings = await _offlineStorage.getPendingRecordings();

      if (pendingRecordings.isEmpty) {
        state = state.copyWith(
          status: SyncStatus.success,
          pendingCount: 0,
          totalCount: 0,
          lastSyncTime: DateTime.now(),
        );
        return;
      }

      state = state.copyWith(
        status: SyncStatus.syncing,
        pendingCount: pendingRecordings.length,
        totalCount: pendingRecordings.length,
      );

      int syncedCount = 0;
      int failedCount = 0;

      for (final recording in pendingRecordings) {
        try {
          await _syncSingleRecording(recording);
          syncedCount++;

          // Update progress
          state = state.copyWith(
            pendingCount: pendingRecordings.length - syncedCount,
          );
        } catch (e) {
          failedCount++;
          await _offlineStorage.markRecordingAsFailed(
            recording['id'] as String,
            e.toString(),
          );
        }
      }

      // Update final state
      if (failedCount == 0) {
        state = state.copyWith(
          status: SyncStatus.success,
          pendingCount: 0,
          lastSyncTime: DateTime.now(),
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: SyncStatus.error,
          pendingCount: failedCount,
          errorMessage: 'Failed to sync $failedCount recordings',
          lastSyncTime: DateTime.now(),
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _syncSingleRecording(Map<String, dynamic> recording) async {
    final filePath = recording['file_path'] as String;
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Audio file not found: $filePath');
    }

    // Upload to server
    await _apiService.uploadRecording(
      sentenceId: recording['sentence_id'] as String,
      audioFilePath: filePath,
    );

    // Mark as synced in local database
    await _offlineStorage.markRecordingAsSynced(recording['id'] as String);

    // Delete local file to save space (optional)
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> retrySyncFailedRecordings() async {
    // Reset failed recordings to pending status
    final db = await _offlineStorage.database;
    await db.update(
      'offline_recordings',
      {'sync_status': 'pending', 'retry_count': 0, 'error_message': null},
      where: 'sync_status = ?',
      whereArgs: ['failed'],
    );

    // Try to sync again
    await syncPendingRecordings();
  }

  void setAutoSyncEnabled(bool enabled) {
    _isAutoSyncEnabled = enabled;

    if (enabled) {
      _startPeriodicSync();
      _checkAndSync();
    } else {
      _periodicSyncTimer?.cancel();
    }
  }

  Future<void> forceSyncNow() async {
    await syncPendingRecordings();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    super.dispose();
  }
}

// Provider for sync service
final syncServiceProvider = StateNotifierProvider<SyncService, SyncState>((
  ref,
) {
  final offlineStorage = OfflineStorageService();
  final apiService = ref.read(apiServiceProvider);
  final authService = ref.read(authServiceProvider);

  return SyncService(offlineStorage, apiService, authService);
});

// Provider for connectivity status
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Provider for internet connection status
final internetConnectionProvider = FutureProvider<bool>((ref) async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
});
