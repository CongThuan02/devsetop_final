import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Lõi mã hoá zero-knowledge.
///
/// - Dẫn xuất khoá từ master password bằng PBKDF2-HMAC-SHA256 (100k iter).
/// - Mã hoá / giải mã chuỗi UTF-8 bằng AES-GCM 256-bit (auth tag chống tampering).
/// - Sinh salt và nonce ngẫu nhiên bằng [Random.secure].
///
/// Mọi dữ liệu nhạy cảm phải đi qua [encrypt] trước khi rời thiết bị.
class CryptoService {
  static const int _pbkdf2Iterations = 100000;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;

  final Pbkdf2 _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _pbkdf2Iterations,
    bits: 256,
  );
  final AesGcm _aes = AesGcm.with256bits();

  Uint8List generateSalt() => _randomBytes(_saltLength);

  Future<SecretKey> deriveKey({
    required String masterPassword,
    required Uint8List salt,
  }) {
    return _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(masterPassword)),
      nonce: salt,
    );
  }

  Future<EncryptedPayload> encrypt({
    required String plaintext,
    required SecretKey key,
  }) async {
    final nonce = _randomBytes(_nonceLength);
    final box = await _aes.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    return EncryptedPayload(
      ciphertext: Uint8List.fromList(box.cipherText),
      nonce: Uint8List.fromList(box.nonce),
      mac: Uint8List.fromList(box.mac.bytes),
    );
  }

  Future<String> decrypt({
    required EncryptedPayload payload,
    required SecretKey key,
  }) async {
    final box = SecretBox(
      payload.ciphertext,
      nonce: payload.nonce,
      mac: Mac(payload.mac),
    );
    final clear = await _aes.decrypt(box, secretKey: key);
    return utf8.decode(clear);
  }

  Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }
}

class EncryptedPayload {
  EncryptedPayload({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });

  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List mac;

  Map<String, String> toFirestore() => {
    'ciphertext': base64Encode(ciphertext),
    'nonce': base64Encode(nonce),
    'mac': base64Encode(mac),
  };

  factory EncryptedPayload.fromFirestore(Map<String, dynamic> data) {
    return EncryptedPayload(
      ciphertext: base64Decode(data['ciphertext'] as String),
      nonce: base64Decode(data['nonce'] as String),
      mac: base64Decode(data['mac'] as String),
    );
  }
}
