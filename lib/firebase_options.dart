// File này thay thế bản do `flutterfire configure` sinh ra.
// Đọc cấu hình từ .env (đóng gói qua flutter_dotenv).
//
// LƯU Ý BẢO MẬT: .env được đóng gói vào APK / web bundle như asset,
// nên các giá trị bên trong KHÔNG bí mật với người dùng cuối.
// Firebase API keys vốn là client identifier — bảo mật thực sự
// nằm ở Firestore Rules + App Check, KHÔNG ở việc giấu key.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static const _dartDefineValues = {
    'FIREBASE_PROJECT_ID': String.fromEnvironment('FIREBASE_PROJECT_ID'),
    'FIREBASE_MESSAGING_SENDER_ID': String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    ),
    'FIREBASE_AUTH_DOMAIN': String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    'FIREBASE_STORAGE_BUCKET': String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
    ),
    'FIREBASE_WEB_API_KEY': String.fromEnvironment('FIREBASE_WEB_API_KEY'),
    'FIREBASE_WEB_APP_ID': String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    'FIREBASE_ANDROID_API_KEY': String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
    ),
    'FIREBASE_ANDROID_APP_ID': String.fromEnvironment(
      'FIREBASE_ANDROID_APP_ID',
    ),
  };

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      default:
        throw UnsupportedError(
          'Nền tảng ${defaultTargetPlatform.name} chưa được hỗ trợ.',
        );
    }
  }

  static String _need(String key) {
    final dartDefineValue = _dartDefineValues[key] ?? '';
    final v =
        dartDefineValue.isNotEmpty ? dartDefineValue : dotenv.maybeGet(key);
    if (v == null || v.isEmpty) {
      throw StateError(
        'Thiếu biến $key. Truyền bằng --dart-define hoặc tạo file .env từ .env.example.',
      );
    }
    return v;
  }

  static FirebaseOptions get _web => FirebaseOptions(
    apiKey: _need('FIREBASE_WEB_API_KEY'),
    appId: _need('FIREBASE_WEB_APP_ID'),
    messagingSenderId: _need('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _need('FIREBASE_PROJECT_ID'),
    authDomain: _need('FIREBASE_AUTH_DOMAIN'),
    storageBucket: _need('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get _android => FirebaseOptions(
    apiKey: _need('FIREBASE_ANDROID_API_KEY'),
    appId: _need('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: _need('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _need('FIREBASE_PROJECT_ID'),
    storageBucket: _need('FIREBASE_STORAGE_BUCKET'),
  );
}
