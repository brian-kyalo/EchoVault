import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'vault_cipher.dart';

abstract interface class VaultKeyStore {
  Future<String?> read();

  Future<void> write(String encodedKey);
}

class VaultKeyService {
  VaultKeyService(this._store);

  final VaultKeyStore _store;
  final _cipher = VaultCipher();
  Future<void> _pending = Future<void>.value();

  Future<SecretKey> load({required bool vaultExists}) {
    final operation = _pending.then((_) => _load(vaultExists: vaultExists));
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<SecretKey> _load({required bool vaultExists}) async {
    try {
      final encoded = await _store.read();
      if (encoded != null) return _decode(encoded);
      if (vaultExists) {
        throw const VaultSecurityException(VaultSecurityFailure.keyUnavailable);
      }
      final key = await _cipher.newKey();
      final storedValue = base64Encode(await key.extractBytes());
      await _store.write(storedValue);
      final readback = await _store.read();
      if (readback != storedValue) {
        throw const VaultSecurityException(VaultSecurityFailure.keyUnavailable);
      }
      return key;
    } catch (_) {
      throw const VaultSecurityException(VaultSecurityFailure.keyUnavailable);
    }
  }

  SecretKey _decode(String encoded) {
    final bytes = base64Decode(encoded);
    if (bytes.length != 32 || base64Encode(bytes) != encoded) {
      throw const VaultSecurityException(VaultSecurityFailure.keyUnavailable);
    }
    return SecretKey(bytes);
  }
}
