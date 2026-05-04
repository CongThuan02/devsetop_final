import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/crypto/crypto_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/vault_repository.dart';

final cryptoServiceProvider = Provider<CryptoService>((_) => CryptoService());
final secureStorageProvider =
    Provider<SecureStorageService>((_) => SecureStorageService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    crypto: ref.watch(cryptoServiceProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

/// Session sau khi unlock — chứa SecretKey trong RAM.
/// Được set bởi login screen, clear bởi logout / auto-lock.
class SessionNotifier extends Notifier<UnlockedSession?> {
  @override
  UnlockedSession? build() => null;

  void set(UnlockedSession session) => state = session;
  void clear() => state = null;
}

final sessionProvider =
    NotifierProvider<SessionNotifier, UnlockedSession?>(SessionNotifier.new);

final vaultRepositoryProvider = Provider<VaultRepository?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) return null;
  return VaultRepository(
    userId: session.uid,
    crypto: ref.watch(cryptoServiceProvider),
    key: session.encryptionKey,
  );
});
