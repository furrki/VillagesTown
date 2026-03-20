import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: import your app's screens, services, and localizations
// import 'package:villages_town/screens/home_screen.dart';
// import 'package:villages_town/l10n/app_localizations.dart';

/// App Store Screenshot Tests
///
/// Run: make screenshots
///
/// Steps to implement:
///   1. Import your screens above
///   2. Seed SharedPreferences in setUpAll with impressive state
///   3. Init any singletons (GameState, PlayerData, etc.)
///   4. Add one testWidgets slot per screenshot (see slots below)
///
/// Locale map — fastlane dir name -> Flutter Locale:
const _locales = <String, Locale>{
  'en-US': Locale('en'),
  // Add more locales as you add fastlane metadata:
  // 'tr-TR': Locale('tr'),
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget buildScreen(Widget screen, Locale locale) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      // TODO: add localizationsDelegates + supportedLocales if your app has l10n
      home: screen,
    );
  }

  Future<void> pumpFrames(WidgetTester tester, {int frames = 20}) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> screenshot(String name) async {
    try {
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
      }
      await binding.takeScreenshot(name);
    } catch (e) {
      debugPrint('Screenshot failed: $e');
    }
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      // TODO: seed your app's SharedPreferences with impressive state
      // e.g. 'coins': 5000, 'level': 20, 'tutorialCompleted': true,
    });
    // TODO: await YourSingleton.instance.init();
  });

  testWidgets('screenshots', (tester) async {
    FlutterError.onError = (details) {
      debugPrint('FlutterError (screenshot mode): ${details.exceptionAsString()}');
    };

    for (final entry in _locales.entries) {
      final dir = entry.key;
      final locale = entry.value;

      // TODO: replace each slot with your actual screens
      // Follow this pattern for each screenshot:
      //
      // try {
      //   await tester.pumpWidget(buildScreen(const HomeScreen(), locale));
      //   await pumpFrames(tester, frames: 30);
      //   await screenshot('$dir/01_home');
      // } catch (e) {
      //   debugPrint('Slot 01 failed ($dir): $e');
      // }

      // Placeholder: remove once you add real slots
      try {
        await tester.pumpWidget(buildScreen(
          const Scaffold(body: Center(child: Text('TODO: add screenshots'))),
          locale,
        ));
        await pumpFrames(tester, frames: 5);
        await screenshot('$dir/01_placeholder');
      } catch (e) {
        debugPrint('Placeholder failed ($dir): $e');
      }
    }
  });
}
