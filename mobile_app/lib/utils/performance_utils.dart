import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

/// A utility class to optimize performance in the app
class PerformanceUtils {
  /// Initialize app performance optimizations
  static Future<void> initializeApp() async {
    // Set device orientation
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Optimize platform channels
    await SystemChannels.platform
        .invokeMethod<void>(
          'SystemChrome.setApplicationSwitcherDescription',
          <String, dynamic>{
            'label': 'Xelkoom Audio Collector',
            'primaryColor': 0xFF1E88E5,
          },
        )
        .catchError((e) {
          debugPrint('Failed to set app switcher description: $e');
          return null;
        });

    // Don't use direct frame callback as it's causing scheduler errors
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  /// Preload critical assets to avoid jank when they're first displayed
  static Future<void> preloadAssets(BuildContext? context) async {
    // List of assets to preload
    final assetList = <Future<void>>[];

    // Add fonts preloading
    assetList.add(_cacheFont('Roboto'));

    // Add images preloading if needed
    // if (context != null) {
    //   assetList.add(
    //     precacheImage(const AssetImage('assets/images/logo.png'), context),
    //   );
    // }

    // Wait for all assets to preload with a timeout
    await Future.wait(assetList).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        // If timeout, continue anyway
        debugPrint('Asset preloading timed out, continuing...');
        return <void>[];
      },
    );
  }

  /// Helper function to warm up fonts
  static Future<void> _cacheFont(String fontFamily) async {
    final ParagraphBuilder builder = ParagraphBuilder(
      ParagraphStyle(fontFamily: fontFamily, fontSize: 14.0),
    );
    builder.addText('.');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 100.0));

    return;
  }

  /// Optimize images for memory
  static void optimizeImageCache() {
    PaintingBinding.instance.imageCache.maximumSize = 50; // Limit to 50 images
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        50 * 1024 * 1024; // 50MB
  }

  /// Optimize memory usage by clearing caches
  static void clearMemory() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
