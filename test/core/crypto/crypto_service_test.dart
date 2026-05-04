import 'package:flutter_test/flutter_test.dart';
import 'package:password_manager_mini/core/crypto/crypto_service.dart';

void main() {
  late CryptoService crypto;

  setUp(() => crypto = CryptoService());

  test('encrypt then decrypt roundtrip restores plaintext', () async {
    final salt = crypto.generateSalt();
    final key = await crypto.deriveKey(
      masterPassword: 'correct-horse-battery-staple',
      salt: salt,
    );

    final payload = await crypto.encrypt(plaintext: 'hunter2', key: key);
    final clear = await crypto.decrypt(payload: payload, key: key);

    expect(clear, 'hunter2');
  });

  test('decrypt with wrong password fails (auth tag mismatch)', () async {
    final salt = crypto.generateSalt();
    final goodKey = await crypto.deriveKey(
      masterPassword: 'right-password',
      salt: salt,
    );
    final badKey = await crypto.deriveKey(
      masterPassword: 'wrong-password',
      salt: salt,
    );

    final payload = await crypto.encrypt(plaintext: 'secret', key: goodKey);

    expect(
      () => crypto.decrypt(payload: payload, key: badKey),
      throwsA(isA<Exception>()),
    );
  });

  test('tampered ciphertext is rejected by GCM auth tag', () async {
    final salt = crypto.generateSalt();
    final key = await crypto.deriveKey(masterPassword: 'pw', salt: salt);
    final payload = await crypto.encrypt(plaintext: 'data', key: key);

    payload.ciphertext[0] ^= 0xFF;

    expect(
      () => crypto.decrypt(payload: payload, key: key),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'two encryptions of same plaintext produce different ciphertext',
    () async {
      final salt = crypto.generateSalt();
      final key = await crypto.deriveKey(masterPassword: 'pw', salt: salt);

      final a = await crypto.encrypt(plaintext: 'hello', key: key);
      final b = await crypto.encrypt(plaintext: 'hello', key: key);

      expect(a.nonce, isNot(equals(b.nonce)));
      expect(a.ciphertext, isNot(equals(b.ciphertext)));
    },
  );

  test('salt is 16 bytes and reasonably random', () {
    final s1 = crypto.generateSalt();
    final s2 = crypto.generateSalt();
    expect(s1.length, 16);
    expect(s1, isNot(equals(s2)));
  });
}
