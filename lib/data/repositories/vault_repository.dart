import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';

import '../../core/crypto/crypto_service.dart';
import '../../domain/entities/vault_item.dart';

/// Đọc/ghi vault items vào Firestore — luôn ở dạng ciphertext.
class VaultRepository {
  VaultRepository({
    required this.userId,
    required this.crypto,
    required this.key,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final CryptoService crypto;
  final SecretKey key;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(userId).collection('vault');

  Future<void> addItem({
    required String serviceName,
    required String url,
    required VaultItemSecret secret,
  }) async {
    final payload = await crypto.encrypt(
      plaintext: jsonEncode(secret.toJson()),
      key: key,
    );
    final now = FieldValue.serverTimestamp();
    await _col.add({
      'serviceName': serviceName,
      'url': url,
      ...payload.toFirestore(),
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<List<VaultItem>> listItems() async {
    final snap = await _col.orderBy('serviceName').get();
    final results = <VaultItem>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final payload = EncryptedPayload.fromFirestore(data);
      final clear = await crypto.decrypt(payload: payload, key: key);
      final secret =
          VaultItemSecret.fromJson(jsonDecode(clear) as Map<String, dynamic>);
      results.add(VaultItem(
        id: doc.id,
        serviceName: data['serviceName'] as String,
        url: data['url'] as String? ?? '',
        username: secret.username,
        password: secret.password,
        note: secret.note,
      ));
    }
    return results;
  }

  Future<void> deleteItem(String id) => _col.doc(id).delete();
}
