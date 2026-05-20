import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/permission_service.dart';

// Provider pour l'état des permissions
final permissionStateProvider =
    StateNotifierProvider<PermissionStateNotifier, PermissionState>((ref) {
      return PermissionStateNotifier();
    });

class PermissionState {
  final bool isChecked;
  final bool microphoneGranted;
  final bool storageGranted;
  final Map<String, PermissionInfo>? permissions;
  final String? error;

  const PermissionState({
    this.isChecked = false,
    this.microphoneGranted = false,
    this.storageGranted = false,
    this.permissions,
    this.error,
  });

  PermissionState copyWith({
    bool? isChecked,
    bool? microphoneGranted,
    bool? storageGranted,
    Map<String, PermissionInfo>? permissions,
    String? error,
  }) {
    return PermissionState(
      isChecked: isChecked ?? this.isChecked,
      microphoneGranted: microphoneGranted ?? this.microphoneGranted,
      storageGranted: storageGranted ?? this.storageGranted,
      permissions: permissions ?? this.permissions,
      error: error ?? this.error,
    );
  }

  bool get hasMinimalPermissions => microphoneGranted;
  bool get hasAllPermissions => microphoneGranted && storageGranted;
}

class PermissionStateNotifier extends StateNotifier<PermissionState> {
  PermissionStateNotifier() : super(const PermissionState());

  Future<void> checkPermissions() async {
    try {
      final results = await PermissionService.requestAllPermissions();

      final micGranted =
          results['microphone']?.result == PermissionResult.granted;
      final storageGranted =
          results['storage']?.result == PermissionResult.granted;

      state = state.copyWith(
        isChecked: true,
        microphoneGranted: micGranted,
        storageGranted: storageGranted,
        permissions: results,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isChecked: true,
        error: 'Error checking permissions: $e',
      );
    }
  }

  void markAsSetup() {
    state = state.copyWith(isChecked: true);
  }

  void reset() {
    state = const PermissionState();
  }
}
