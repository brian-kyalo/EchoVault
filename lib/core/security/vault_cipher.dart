import 'dart:convert';

import 'package:cryptography/cryptography.dart';

enum VaultSecurityFailure { invalidEnvelope, authentication, keyUnavailable }

class VaultSecurityException implements Exception {
  const VaultSecurityException(this.failure);

  final VaultSecurityFailure failure;

  @override
  String toString() => 'Vault security operation failed (${failure.name}).';
}

enum VaultPayloadKind { entry, header }

class VaultCipher {
  static const formatVersion = 1;
  final _algorithm = AesGcm.with256bits();

  Future<SecretKey> newKey() => _algorithm.newSecretKey();

  Future<String> encrypt(
    List<int> plaintext, {
    required SecretKey key,
    required String vaultId,
    required String recordId,
    required VaultPayloadKind kind,
  }) async {
    final box = await _algorithm.encrypt(
      plaintext,
      secretKey: key,
      aad: _context(vaultId, recordId, kind),
    );
    return jsonEncode({
      'version': formatVersion,
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'tag': base64Encode(box.mac.bytes),
    });
  }

  Future<List<int>> decrypt(
    String envelope, {
    required SecretKey key,
    required String vaultId,
    required String recordId,
    required VaultPayloadKind kind,
  }) async {
    final context = _context(vaultId, recordId, kind);
    final SecretBox box;
    try {
      final decoded = jsonDecode(envelope);
      if (decoded is! Map<String, dynamic> ||
          decoded.length != 4 ||
          decoded['version'] is! int ||
          decoded['version'] != formatVersion ||
          decoded['nonce'] is! String ||
          decoded['ciphertext'] is! String ||
          decoded['tag'] is! String) {
        throw const FormatException();
      }
      final nonce = base64Decode(decoded['nonce'] as String);
      final ciphertext = base64Decode(decoded['ciphertext'] as String);
      final tag = base64Decode(decoded['tag'] as String);
      if (nonce.length != 12 || tag.length != 16) {
        throw const FormatException();
      }
      box = SecretBox(ciphertext, nonce: nonce, mac: Mac(tag));
    } on FormatException {
      throw const VaultSecurityException(VaultSecurityFailure.invalidEnvelope);
    }
    try {
      return await _algorithm.decrypt(box, secretKey: key, aad: context);
    } on SecretBoxAuthenticationError {
      throw const VaultSecurityException(VaultSecurityFailure.authentication);
    }
  }

  List<int> _context(String vaultId, String recordId, VaultPayloadKind kind) {
    if (vaultId.isEmpty || recordId.isEmpty) {
      throw ArgumentError('Vault and record identifiers must not be empty.');
    }
    return utf8.encode(
      jsonEncode(['EchoVault', vaultId, kind.name, formatVersion, recordId]),
    );
  }
}
