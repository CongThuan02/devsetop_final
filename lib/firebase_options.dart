// Firebase client configuration.
//
// LƯU Ý BẢO MẬT: Firebase API keys là client identifiers — bảo mật thực sự
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
      default:
        throw UnsupportedError(
          'Nền tảng ${defaultTargetPlatform.name} chưa được hỗ trợ.',
        );
    }
  }

  static const FirebaseOptions _web = FirebaseOptions(
    apiKey: 'AIzaSyB0jvbkl_mwzebrCL9E3UfFIBkr-zll0yg',
    appId: '1:171197120:web:77456ef93a56f55cb1a325',
    messagingSenderId: '171197120',
    projectId: 'pwmgr-devsecops',
    authDomain: 'pwmgr-devsecops.firebaseapp.com',
    storageBucket: 'pwmgr-devsecops.firebasestorage.app',
  );

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyDj3NCu4YNHiO0kMkG7NngmHRuL0p8bP3A',
    appId: '1:171197120:android:920dc070a544fef0b1a325',
    messagingSenderId: '171197120',
    projectId: 'pwmgr-devsecops',
    storageBucket: 'pwmgr-devsecops.firebasestorage.app',
  );
}
