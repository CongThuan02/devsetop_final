import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/crypto/crypto_service.dart';
import '../../core/storage/secure_storage_service.dart';

/// Kết quả đăng nhập / đăng ký: trả về SecretKey đã dẫn xuất để dùng cho vault.
class UnlockedSession {
  UnlockedSession({required this.uid, required this.encryptionKey});
  final String uid;
  final SecretKey encryptionKey;
}

class AuthRepository {
  AuthRepository({
    required this.crypto,
    required this.storage,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final CryptoService crypto;
  final SecureStorageService storage;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Đăng ký:
  /// 1. Tạo tài khoản Auth (email + master password — Firebase tự hash)
  /// 2. Sinh salt ngẫu nhiên, lưu vào secure storage + Firestore profile
  /// 3. Dẫn xuất key từ master password + salt
  Future<UnlockedSession> register({
    required String email,
    required String masterPassword,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: masterPassword,
    );
    final uid = cred.user!.uid;

    final salt = crypto.generateSalt();
    final saltB64 = base64Encode(salt);
    await storage.writeSalt(saltB64);

    await _firestore.collection('users').doc(uid).set({
      'salt': saltB64,
      'kdfIterations': 100000,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final key = await crypto.deriveKey(
      masterPassword: masterPassword,
      salt: salt,
    );
    return UnlockedSession(uid: uid, encryptionKey: key);
  }

  /// Đăng nhập: Auth → đọc salt từ Firestore → dẫn xuất key.
  Future<UnlockedSession> signIn({
    required String email,
    required String masterPassword,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: masterPassword,
    );
    final uid = cred.user!.uid;

    final profile = await _firestore.collection('users').doc(uid).get();
    final saltB64 = profile.data()?['salt'] as String?;
    if (saltB64 == null) {
      throw StateError('User profile thiếu salt — dữ liệu hỏng.');
    }
    await storage.writeSalt(saltB64);

    final key = await crypto.deriveKey(
      masterPassword: masterPassword,
      salt: base64Decode(saltB64),
    );
    return UnlockedSession(uid: uid, encryptionKey: key);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String? get currentUid => _auth.currentUser?.uid;
}
