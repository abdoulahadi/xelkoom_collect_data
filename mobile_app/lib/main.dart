import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/app_wrapper.dart';
import 'utils/performance_utils.dart';
import 'services/permission_service.dart';
import 'dart:async';

// Create a provider to track if app is ready
final appReadyProvider = StateProvider<bool>((ref) => false);

Future<void> main() async {
  // Ensure Flutter is initialized before calling any platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // MOB-003: Initialize Firebase for crash reporting & analytics
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  } catch (e) {
    debugPrint('Firebase initialization failed (may not be configured): $e');
  }

  // Initialize app in a safer way - no deferring frames which causes assertion errors
  try {
    // Run basic initializations first
    PerformanceUtils.optimizeImageCache();

    // Set orientation and other non-UI initializations
    await PerformanceUtils.initializeApp();
  } catch (e) {
    // Log error but continue with app startup
    debugPrint('Error during app initialization: $e');
  }

  // Run the app with Riverpod
  runApp(const ProviderScope(child: XelkoomApp()));
}

class XelkoomApp extends StatefulWidget {
  const XelkoomApp({super.key});

  @override
  State<XelkoomApp> createState() => _XelkoomAppState();
}

class _XelkoomAppState extends State<XelkoomApp> with WidgetsBindingObserver {
  final _appRouter = GlobalKey<NavigatorState>();
  bool _assetsPreloaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Use a safer way to defer initialization - avoid manipulating the scheduler directly
    // Use a simple Future.delayed instead of postFrameCallback to avoid race conditions
    Future<void>.delayed(const Duration(milliseconds: 200)).then((_) {
      if (mounted) {
        _deferredInit();
      }
    });
  }

  Future<void> _deferredInit() async {
    // Wrap in try-catch to prevent errors from breaking the app
    try {
      if (!mounted) return;

      // Don't preload assets again if already done
      if (!_assetsPreloaded) {
        // Use a simpler approach that doesn't manipulate frame scheduling
        await PerformanceUtils.preloadAssets(context);

        if (mounted) {
          setState(() {
            _assetsPreloaded = true;
          });
        }
      }

      // Mark app as ready in provider
      if (mounted && context.mounted) {
        // Use read instead of watch to avoid triggering rebuilds
        ProviderScope.containerOf(context)
            .read(appReadyProvider.notifier)
            .state = true;
      }
    } catch (e) {
      debugPrint('Error in deferred initialization: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Optimize resource usage based on app lifecycle
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Release resources when app goes to background - use Future to avoid blocking
      Future<void>.microtask(() => PerformanceUtils.clearMemory());
    } else if (state == AppLifecycleState.resumed) {
      // MOB-008: Invalidate permission cache when app resumes
      // User may have changed permissions in system settings
      PermissionService.clearCache();

      // Reinitialize resources when app comes to foreground - with safety checks
      if (!_assetsPreloaded && mounted) {
        // Use a delayed future to avoid frame scheduling issues
        Future<void>.delayed(const Duration(milliseconds: 100)).then((_) async {
          if (mounted) {
            await PerformanceUtils.preloadAssets(context);

            if (mounted) {
              setState(() {
                _assetsPreloaded = true;
              });
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xelkoom Audio Collector',
      // MOB-009: Localization support (French + Wolof)
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // Optimize text rendering but avoid complex typography customization
        // that might cause performance issues on startup
      ),
      initialRoute: '/',
      navigatorKey: _appRouter,
      routes: {'/': (context) => const AppWrapper()},
      debugShowCheckedModeBanner: false,
      // Add error handling
      builder: (context, child) {
        // Add error boundary
        ErrorWidget.builder = (FlutterErrorDetails details) {
          // In debug mode, use Flutter's default error widget
          if (debugMode) {
            return ErrorWidget(details.exception);
          }
          // In release mode, show a simpler error widget
          return Material(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[700]),
                    const SizedBox(height: 16),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Restart the app or navigate to home
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        };

        // Add performance optimizations but avoid MediaQuery changes that might
        // interfere with system-level accessibility features
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

// Debug flag to control error handling behavior
const bool debugMode = false;
