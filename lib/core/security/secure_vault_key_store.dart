import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'vault_key_store.dart';

class SecureVaultKeyStore implements VaultKeyStore {
  static const storageKey = 'echovault.vault.key.v1';
  static const androidOptions = AndroidOptions(
    resetOnError: false,
    migrateWithBackup: true,
    storageNamespace: 'echovault_vault',
  );
  static const iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
    synchronizable: false,
  );
  static const _storage = FlutterSecureStorage(
    aOptions: androidOptions,
    iOptions: iosOptions,
  );

  @override
  Future<String?> read() => _storage.read(key: storageKey);

  @override
  Future<void> write(String encodedKey) =>
      _storage.write(key: storageKey, value: encodedKey);
}
