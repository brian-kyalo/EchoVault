import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:echo_vault/core/security/secure_vault_key_store.dart';
import 'package:echo_vault/core/security/vault_cipher.dart';
import 'package:echo_vault/core/security/vault_key_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cipher = VaultCipher();
  late SecretKey key;

  test('native adapter disables reset and Apple synchronization', () {
    final android = SecureVaultKeyStore.androidOptions.toMap();
    final ios = SecureVaultKeyStore.iosOptions.toMap();
    expect(android['resetOnError'], 'false');
    expect(android['migrateWithBackup'], 'true');
    expect(android['storageNamespace'], 'echovault_vault');
    expect(ios['synchronizable'], 'false');
    expect(ios['accessibility'], 'unlocked_this_device');
  });

  setUp(() async {
    key = await cipher.newKey();
  });

  Future<String> encrypt(List<int> bytes) => cipher.encrypt(
    bytes,
    key: key,
    vaultId: 'vault-1',
    recordId: 'entry-1',
    kind: VaultPayloadKind.entry,
  );

  Future<List<int>> decrypt(String envelope) => cipher.decrypt(
    envelope,
    key: key,
    vaultId: 'vault-1',
    recordId: 'entry-1',
    kind: VaultPayloadKind.entry,
  );

  test('AES-256-GCM matches the zero-key NIST known-answer vector', () async {
    final box = await AesGcm.with256bits().encrypt(
      List<int>.filled(16, 0),
      secretKey: SecretKey(List<int>.filled(32, 0)),
      nonce: List<int>.filled(12, 0),
    );
    String hex(List<int> bytes) =>
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    expect(hex(box.cipherText), 'cea7403d4d606b6e074ec5d3baf39d18');
    expect(hex(box.mac.bytes), 'd0d1c8a799996bf0265b98b5d48ab919');
  });

  test('round trips bytes, Unicode, and empty payloads', () async {
    for (final bytes in [
      <int>[],
      utf8.encode('Sample \u00e9 \u4f60\u597d \u{1f600}\nwriting'),
      List<int>.generate(256, (index) => index),
    ]) {
      expect(await decrypt(await encrypt(bytes)), bytes);
    }
  });

  test('generates fresh nonces on repeated encryption', () async {
    final first = jsonDecode(await encrypt([1, 2, 3])) as Map;
    final second = jsonDecode(await encrypt([1, 2, 3])) as Map;
    expect(first['nonce'], isNot(second['nonce']));
    expect(first['ciphertext'], isNot(second['ciphertext']));
    expect(base64Decode(first['nonce'] as String), hasLength(12));
    expect(base64Decode(first['tag'] as String), hasLength(16));
  });

  test('rejects altered ciphertext, nonce, and authentication tag', () async {
    final original =
        jsonDecode(await encrypt([1, 2, 3])) as Map<String, dynamic>;
    for (final field in ['ciphertext', 'nonce', 'tag']) {
      final changed = Map<String, dynamic>.from(original);
      final bytes = base64Decode(changed[field] as String);
      bytes[0] ^= 1;
      changed[field] = base64Encode(bytes);
      await expectLater(
        decrypt(jsonEncode(changed)),
        throwsA(isA<VaultSecurityException>()),
      );
    }
  });

  test(
    'rejects wrong keys and cross-record, vault, or kind substitution',
    () async {
      final envelope = await encrypt([1, 2, 3]);
      for (final context in [
        (await cipher.newKey(), 'vault-1', 'entry-1', VaultPayloadKind.entry),
        (key, 'vault-2', 'entry-1', VaultPayloadKind.entry),
        (key, 'vault-1', 'entry-2', VaultPayloadKind.entry),
        (key, 'vault-1', 'entry-1', VaultPayloadKind.header),
      ]) {
        await expectLater(
          cipher.decrypt(
            envelope,
            key: context.$1,
            vaultId: context.$2,
            recordId: context.$3,
            kind: context.$4,
          ),
          throwsA(isA<VaultSecurityException>()),
        );
      }
    },
  );

  test(
    'rejects malformed envelopes, lengths, and unsupported versions',
    () async {
      final original = jsonDecode(await encrypt([1])) as Map<String, dynamic>;
      for (final invalid in [
        'not json',
        'null',
        '[]',
        '{}',
        jsonEncode({...original, 'version': 2}),
        jsonEncode({...original, 'version': 1.0}),
        jsonEncode({...original, 'nonce': 12}),
        jsonEncode({...original, 'nonce': '%%%'}),
        jsonEncode({
          ...original,
          'nonce': base64Encode([1]),
        }),
        jsonEncode({...original, 'tag': ''}),
        jsonEncode({...original, 'extra': 'field'}),
      ]) {
        await expectLater(
          decrypt(invalid),
          throwsA(isA<VaultSecurityException>()),
        );
      }
    },
  );

  test('requires nonempty context identifiers', () async {
    await expectLater(
      cipher.encrypt(
        [1],
        key: key,
        vaultId: '',
        recordId: 'entry',
        kind: VaultPayloadKind.entry,
      ),
      throwsArgumentError,
    );
  });

  test('creates once and reuses keys across service restarts', () async {
    final store = MemoryKeyStore();
    final created = await VaultKeyService(store).load(vaultExists: false);
    final restored = await VaultKeyService(store).load(vaultExists: true);
    final interrupted = await VaultKeyService(store).load(vaultExists: false);
    expect(await created.extractBytes(), hasLength(32));
    expect(await restored.extractBytes(), await created.extractBytes());
    expect(await interrupted.extractBytes(), await created.extractBytes());
    expect(store.writes, 1);
  });

  test(
    'serializes concurrent initialization through the shared service',
    () async {
      final store = MemoryKeyStore();
      final service = VaultKeyService(store);
      final keys = await Future.wait([
        service.load(vaultExists: false),
        service.load(vaultExists: false),
      ]);
      expect(await keys.first.extractBytes(), await keys.last.extractBytes());
      expect(store.writes, 1);
    },
  );

  test('never creates a key for an existing vault', () async {
    final store = MemoryKeyStore();
    await expectLater(
      VaultKeyService(store).load(vaultExists: true),
      throwsA(isA<VaultSecurityException>()),
    );
    expect(store.writes, 0);
  });

  test('rejects invalid stored keys without overwriting them', () async {
    for (final value in [
      '',
      '%%%',
      base64Encode([1, 2, 3]),
    ]) {
      final store = MemoryKeyStore()..value = value;
      await expectLater(
        VaultKeyService(store).load(vaultExists: false),
        throwsA(isA<VaultSecurityException>()),
      );
      expect(store.value, value);
      expect(store.writes, 0);
    }
  });

  test('read errors are sanitized and a later retry works', () async {
    final store = MemoryKeyStore()..failRead = true;
    final service = VaultKeyService(store);
    await expectLater(
      service.load(vaultExists: false),
      throwsA(
        isA<VaultSecurityException>().having(
          (error) => error.toString(),
          'safe error',
          isNot(contains('sensitive detail')),
        ),
      ),
    );
    expect(store.writes, 0);
    store.failRead = false;
    await service.load(vaultExists: false);
    expect(store.writes, 1);
  });

  test('failed writes and missing readback prevent initialization', () async {
    for (final store in [
      MemoryKeyStore()..failWrite = true,
      MemoryKeyStore()..discardWrite = true,
      MemoryKeyStore()..replaceWrite = true,
      MemoryKeyStore()..failReadback = true,
    ]) {
      await expectLater(
        VaultKeyService(store).load(vaultExists: false),
        throwsA(isA<VaultSecurityException>()),
      );
      expect(store.writes, 1);
    }
  });
}

class MemoryKeyStore implements VaultKeyStore {
  String? value;
  int writes = 0;
  bool failRead = false;
  bool failWrite = false;
  bool discardWrite = false;
  bool replaceWrite = false;
  bool failReadback = false;

  @override
  Future<String?> read() async {
    if (failRead || (failReadback && writes > 0)) {
      throw StateError('sensitive detail');
    }
    return value;
  }

  @override
  Future<void> write(String encodedKey) async {
    writes++;
    if (failWrite) throw StateError('sensitive detail');
    if (!discardWrite) {
      value = replaceWrite ? base64Encode(List<int>.filled(32, 0)) : encodedKey;
    }
  }
}
