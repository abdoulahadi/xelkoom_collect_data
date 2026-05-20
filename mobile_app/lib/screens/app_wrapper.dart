import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import 'auth/onboarding_screen.dart';
import 'auth/permission_setup_screen.dart';
import 'home/home_screen.dart';

// Create a provider for app initialization state to avoid multiple rebuilds
final appInitProvider = StateProvider<bool>((ref) => false);

// Loading state provider to manage loading state in one place
final loadingStateProvider = StateProvider<bool>((ref) => true);

// Create a provider for lazy loading screens
final _screensProvider = Provider<Map<String, Widget>>((ref) {
  // Lazy initialize screens only once
  return {'onboarding': const OnboardingScreen(), 'home': const HomeScreen()};
});

class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper>
    with WidgetsBindingObserver {
  // Deferred flag to avoid multiple permission checks
  bool _permissionCheckInitiated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Defer authentication check to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // Check if we need to refresh permissions when app resumes
      final authState = ref.read(authStateProvider);
      if (authState.isAuthenticated && !_permissionCheckInitiated) {
        _checkPermissions();
      }
    }
  }

  // Initialize app in stages to avoid UI blocking
  Future<void> _initializeApp() async {
    // Listen for auth changes only once
    ref.listenManual<AuthState>(authStateProvider, (previous, next) {
      // Don't use print for logs in production
      // Debug.log('Auth state changed: ${previous?.isAuthenticated} -> ${next.isAuthenticated}');

      // If user was logged in and now logged out (expired token)
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        // Debug.log('User logged out, redirecting to onboarding...');
        // Reset permissions state when user logs out
        ref.read(permissionStateProvider.notifier).reset();
        _permissionCheckInitiated = false;
      }

      // If user just logged in, check permissions
      if (previous?.isAuthenticated == false && next.isAuthenticated) {
        // Debug.log('User just logged in, checking permissions...');
        _checkPermissions();
      }

      // Update loading state
      ref.read(loadingStateProvider.notifier).state = false;
    });
  }

  Future<void> _checkPermissions() async {
    if (_permissionCheckInitiated) return;
    _permissionCheckInitiated = true;

    // Check permissions in background
    await Future.microtask(
      () => ref.read(permissionStateProvider.notifier).checkPermissions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use select instead of watch to minimize rebuilds
    final isAuthenticated = ref.watch(
      authStateProvider.select((state) => state.isAuthenticated),
    );
    final isLoading = ref.watch(
      authStateProvider.select((state) => state.isLoading),
    );
    final error = ref.watch(authStateProvider.select((state) => state.error));

    // Use select to minimize rebuilds from permission state
    final permissionChecked = ref.watch(
      permissionStateProvider.select((state) => state.isChecked),
    );

    // Show loading spinner while checking authentication
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // Handle authentication errors
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Authentication Error',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Retry authentication - invalidate the provider
                  ref.invalidate(authStateProvider);
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // If not authenticated, show onboarding
    if (!isAuthenticated) {
      // Use cached screen from provider to avoid rebuilds
      return ref.watch(_screensProvider)['onboarding']!;
    }

    // If authenticated but permissions not set up, show permission setup
    if (!permissionChecked) {
      // Create permission setup screen on demand
      return PermissionSetupScreen(
        onPermissionsGranted: () {
          ref.read(permissionStateProvider.notifier).markAsSetup();
        },
      );
    }

    // Show home screen if everything is ready
    return ref.watch(_screensProvider)['home']!;
  }
}
