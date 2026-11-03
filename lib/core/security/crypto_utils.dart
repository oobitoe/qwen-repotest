import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  /// Generate cryptographically secure random bytes
  static List<int> generateSecureKey(int byteLength) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => random.nextInt(256));
    return bytes;
  }

  /// Encrypt data using XOR-based cipher (simplified for demonstration)
  /// In production, use proper AES encryption library
  static List<int> encryptXOR(List<int> data, List<int> key) {
    final result = List<int>.from(data);
    for (int i = 0; i < result.length; i++) {
      result[i] = (result[i] ^ key[i % key.length]) & 0xFF;
    }
    return result;
  }

  /// Decrypt data using XOR-based cipher
  static List<int> decryptXOR(List<int> encrypted, List<int> key) {
    // XOR is symmetric, same operation as encrypt
    return encryptXOR(encrypted, key);
  }

  /// Compute SHA-256 hash
  static String computeSHA256(List<int> data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  /// Create HMAC-SHA256 signature
  static List<int> computeHMAC(List<int> data, List<int> key) {
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(data);
    return digest.bytes;
  }

  /// Verify HMAC
  static bool verifyHMAC(List<int> data, List<int> key, List<int> signature) {
    final computedSignature = computeHMAC(data, key);
    return _listEquals(computedSignature, signature);
  }

  /// Create key derivation function (PBKDF2-like)
  static List<int> deriveKey(
      String password, List<int> salt, int iterations, int keyLength) {
    final keyGenerator = Hmac(sha256, salt);
    var derivedKey = keyGenerator.convert(utf8.encode(password));

    // Simple key derivation (in production, use proper PBKDF2)
    for (int i = 1; i < iterations; i++) {
      derivedKey = Hmac(sha256, derivedKey.bytes).convert(derivedKey.bytes);
    }

    // Return first keyLength bytes
    if (derivedKey.bytes.length >= keyLength) {
      return derivedKey.bytes.sublist(0, keyLength);
    }

    return derivedKey.bytes;
  }
}

/// Crypto exception
class CryptoException implements Exception {
  final String message;

  CryptoException(this.message);

  @override
  String toString() => 'CryptoException: $message';
}

/// Compare two lists for equality
bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
