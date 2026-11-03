import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class CryptoKeyManager {
  // Key derivation parameters
  static const int _keyDerivationIterations = 60000;
  static const String _keyDerivationSalt = 'prime_pos_db_encryption_salt_2026';

  /// Derive encryption key from master password using PBKDF2
  static Future<String> deriveKeyFromPassword(String password) async {
    final salt = utf8.encode(_keyDerivationSalt);

    // Use PBKDF2 with SHA256
    final keyBytes = _pbkdf2(utf8.encode(password), salt,
        _keyDerivationIterations, 32);

    // Convert to base64 for storage
    return base64Url.encode(keyBytes);
  }

  /// Validate key format
  static bool isValidKeyFormat(String key) {
    try {
      base64Url.decode(key);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate a random key
  static Future<String> generateRandomKey() async {
    final keyBytes = _secureRandomBytes(32);
    return base64Url.encode(keyBytes);
  }

  /// Get key derivation version
  static int getKeyDerivationVersion() {
    return 1;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// PBKDF2 implementation using HmacSha256
  static List<int> _pbkdf2(List<int> password, List<int> salt,
      int iterations, int keyLength) {
    final keyGenerator = Hmac(sha256, salt);
    var derivedKey = keyGenerator.convert(password);

    // Iterate key derivation
    for (int i = 1; i < iterations; i++) {
      derivedKey = Hmac(sha256, derivedKey.bytes).convert(derivedKey.bytes);
    }

    // Return first keyLength bytes
    if (derivedKey.bytes.length >= keyLength) {
      return derivedKey.bytes.sublist(0, keyLength);
    }

    return derivedKey.bytes;
  }

  /// Generate cryptographically secure random bytes
  static List<int> _secureRandomBytes(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return bytes;
  }
}
