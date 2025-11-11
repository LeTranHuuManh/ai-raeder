import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get(String key) => dotenv.env[key] ?? '';

  static Map<String, String> getWebConfig() => {
    'apiKey': get('API_KEY_WEB'),
    'appId': get('APP_ID_WEB'),
    'messagingSenderId': get('MESSAGING_SENDER_ID'),
    'projectId': get('PROJECT_ID'),
    'authDomain': get('AUTH_DOMAIN'),
    'storageBucket': get('STORAGE_BUCKET'),
  };

  static Map<String, String> getAndroidConfig() => {
    'apiKey': get('API_KEY_ANDROID'),
    'appId': get('APP_ID_ANDROID'),
    'messagingSenderId': get('MESSAGING_SENDER_ID'),
    'projectId': get('PROJECT_ID'),
    'storageBucket': get('STORAGE_BUCKET'),
  };

  static Map<String, String> getIosConfig() => {
    'apiKey': get('API_KEY_IOS'),
    'appId': get('APP_ID_IOS'),
    'messagingSenderId': get('MESSAGING_SENDER_ID'),
    'projectId': get('PROJECT_ID'),
    'storageBucket': get('STORAGE_BUCKET'),
    'iosBundleId': get('IOS_BUNDLE_ID'),
  };
}
