// Firebase client configuration.
//
// Cấu hình client được commit trực tiếp để CI/CD không cần truyền --dart-define.
// Firebase API keys là client identifiers — bảo mật thực sự
// nằm ở Firestore Rules + App Check, KHÔNG ở việc giấu key.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      default:
        throw UnsupportedError(
          'Nền tảng ${defaultTargetPlatform.name} chưa được hỗ trợ.',
        );
    }
  }

  static const _projectId = "pwmgr-devsecops";
  static const _messagingSenderId = "171197120";
  static const _authDomain = "pwmgr-devsecops.firebaseapp.com";
  static const _storageBucket = "pwmgr-devsecops.firebasestorage.app";
  static const _webApiKey =
      "AIzaSyB0jvbkl_mwzebrCL9E3UfFIBkr-zll0yg"; // gitleaks:allow
  static const _webAppId = "1:171197120:web:77456ef93a56f55cb1a325";
  static const _androidApiKey =
      "AIzaSyDj3NCu4YNHiO0kMkG7NngmHRuL0p8bP3A"; // gitleaks:allow
  static const _androidAppId = "1:171197120:android:920dc070a544fef0b1a325";
  static const _iosApiKey =
      "AIzaSyDfZfCq528oSVRCFEj131380BYouzO1Kes"; // gitleaks:allow
  static const _iosAppId = "1:171197120:ios:fcd5af0441cf4b08b1a325";
  static const _iosBundleId = "com.example.passwordManagerMini";

  static const FirebaseOptions _web = FirebaseOptions(
    apiKey: _webApiKey,
    appId: _webAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: _androidApiKey,
    appId: _androidAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: _iosApiKey,
    appId: _iosAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: _iosBundleId,
  );
}
