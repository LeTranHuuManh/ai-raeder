import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/reading_provider.dart';
import 'providers/category_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file if it exists (optional)
  try {
    if (kIsWeb) {
      // For web, flutter_dotenv automatically adds "assets/" prefix
      // So we just need ".env" not "assets/.env"
      await dotenv.load(fileName: ".env");
    } else {
      // For Android/iOS, try loading from assets first, then root
      try {
        await dotenv.load(fileName: "assets/.env");
      } catch (_) {
        // Fallback to root if assets not found
        await dotenv.load(fileName: ".env");
      }
    }
    debugPrint('✅ .env file loaded successfully');
  } catch (e) {
    debugPrint(
      '⚠️ Warning: .env file not found. Using default values. Error: $e',
    );
    // Continue without .env file - ApiConfig will use empty strings
  }

  // Initialize Firebase
  // Note: Firebase will use demo values if .env is not configured
  // This allows the app to run, but Firebase features will not work properly
  // To use real Firebase, create a .env file with your Firebase credentials
  try {
    // Check if Firebase is already initialized (e.g., during hot restart)
    try {
      Firebase.app(); // This will throw if not initialized
      debugPrint('✅ Firebase already initialized (hot restart)');
    } catch (_) {
      // Firebase not initialized, proceed with initialization
      final options = DefaultFirebaseOptions.currentPlatform;
      await Firebase.initializeApp(options: options);

      // Check if using demo values
      if (options.projectId == 'demo-project') {
        debugPrint(
          '⚠️ Firebase initialized with DEMO values. Create .env file with real Firebase config for production use.',
        );
      } else {
        debugPrint(
          '✅ Firebase initialized successfully with real configuration',
        );
      }
    }
  } catch (e) {
    // Check if it's a duplicate app error (during hot restart)
    if (e.toString().contains('duplicate-app')) {
      debugPrint('ℹ️ Firebase already initialized (hot restart detected)');
    } else {
      debugPrint('❌ Firebase initialization error: $e');
      debugPrint('App will continue but Firebase features will not work');
    }
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Set system UI (wrapped in try-catch to prevent System UI crashes)
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    debugPrint('Warning: Could not set system UI overlay style: $e');
  }

  // Lock orientation to portrait (wrapped in try-catch)
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Warning: Could not set preferred orientations: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => ReadingProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
