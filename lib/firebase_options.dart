import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'core/config/api_config_service.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static final FirebaseOptions web = FirebaseOptions(
    apiKey: ApiConfig.get('API_KEY_WEB'),
    appId: ApiConfig.get('APP_ID_WEB'),
    messagingSenderId: ApiConfig.get('MESSAGING_SENDER_ID'),
    projectId: ApiConfig.get('PROJECT_ID'),
    authDomain: ApiConfig.get('AUTH_DOMAIN'),
    storageBucket: ApiConfig.get('STORAGE_BUCKET'),
  );

  static final FirebaseOptions android = FirebaseOptions(
    apiKey: ApiConfig.get('API_KEY_ANDROID'),
    appId: ApiConfig.get('APP_ID_ANDROID'),
    messagingSenderId: ApiConfig.get('MESSAGING_SENDER_ID'),
    projectId: ApiConfig.get('PROJECT_ID'),
    storageBucket: ApiConfig.get('STORAGE_BUCKET'),
  );

  static final FirebaseOptions ios = FirebaseOptions(
    apiKey: ApiConfig.get('API_KEY_IOS'),
    appId: ApiConfig.get('APP_ID_IOS'),
    messagingSenderId: ApiConfig.get('MESSAGING_SENDER_ID'),
    projectId: ApiConfig.get('PROJECT_ID'),
    storageBucket: ApiConfig.get('STORAGE_BUCKET'),
    iosBundleId: ApiConfig.get('IOS_BUNDLE_ID'),
  );

  static final FirebaseOptions macos = FirebaseOptions(
    apiKey: ApiConfig.get('API_KEY_IOS'),
    appId: ApiConfig.get('APP_ID_IOS'),
    messagingSenderId: ApiConfig.get('MESSAGING_SENDER_ID'),
    projectId: ApiConfig.get('PROJECT_ID'),
    storageBucket: ApiConfig.get('STORAGE_BUCKET'),
    iosBundleId: ApiConfig.get('IOS_BUNDLE_ID'),
  );
}
