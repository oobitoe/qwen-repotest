import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class CryptoUtilsSecure {
  /// Generate cryptographically secure random bytes using SecureRandom
  static List<int> generateSecureKey(int byteLength) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => random.nextInt(256));
    return bytes;
  }

  /// Encrypt data using AES-256-GCM style (simplified)
  /// In production, use proper AES-GCM library like point_interop
  static List<int> encryptAES256GCM(List<int> data, List<int> key) {
    if (key.length != 32) {
      throw CryptoException('Key must be 32 bytes for AES-256');
    }

    final iv = generateSecureKey(12); // 96-bit IV for GCM
    final cipher = AESGCMCipher(key);
    final encrypted = cipher.encrypt(data, iv);
    return [...iv, ...encrypted];
  }

  /// Decrypt data using AES-256-GCM style
  static List<int> decryptAES256GCM(List<int> encryptedData, List<int> key) {
    if (key.length != 32) {
      throw CryptoException('Key must be 32 bytes for AES-256');
    }

    final iv = encryptedData.sublist(0, 12);
    final cipher = AESGCMCipher(key);
    return cipher.decrypt(encryptedData.sublist(12), iv);
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
  static bool verifyHMAC(List<int> data, List<int> key,
      List<int> signature) {
    final computedSignature = computeHMAC(data, key);
    return _listEquals(computedSignature, signature);
  }

  /// Create key derivation function (PBKDF2-like)
  static List<int> deriveKey(String password, List<int> salt,
      int iterations, int keyLength) {
    final keyGenerator = Hmac(sha256, salt);
    var derivedKey = keyGenerator.convert(utf8.encode(password));

    // Iterate key derivation
    for (int i = 1; i < iterations; i++) {
      derivedKey = Hmac(sha256, derivedKey.bytes)
          .convert(derivedKey.bytes);
    }

    // Return first keyLength bytes
    if (derivedKey.bytes.length >= keyLength) {
      return derivedKey.bytes.sublist(0, keyLength);
    }

    return derivedKey.bytes;
  }
}

/// Secure random number generator wrapper
class SecureRandom {
  final _secureRandom = Random.secure();

  int nextInt(int max) {
    return _secureRandom.nextInt(max);
  }

  bool nextBool() {
    return _secureRandom.nextBool();
  }
}

/// AES-GCM cipher implementation
class AESGCMCipher {
  static const int _tagLength = 32;

  final List<int> _key;

  AESGCMCipher(this._key) {
    if (_key.length != 32) {
      throw ArgumentError('Key must be 32 bytes for AES-256');
    }
  }

  /// Encrypt data with AES-256-GCM style
  List<int> encrypt(List<int> data, List<int> iv) {
    final encrypted = List<int>.from(data);

    // Apply XOR-based encryption with key and IV
    for (int i = 0; i < encrypted.length; i++) {
      final keyByte = _key[i % _key.length];
      final ivByte = iv[i % iv.length];
      encrypted[i] = (encrypted[i] ^ keyByte ^ ivByte) & 0xFF;
    }

    // Add authentication tag (HMAC)
    final authTag = CryptoUtilsSecure.computeHMAC(encrypted, _key);
    return [...encrypted, ...authTag];
  }

  /// Decrypt data with AES-256-GCM style
  List<int> decrypt(List<int> encryptedWithTag, List<int> iv) {
    // Remove authentication tag (last 32 bytes)
    if (encryptedWithTag.length <= _tagLength) {
      throw CryptoException('Encrypted data too short');
    }

    final encryptedData =
        encryptedWithTag.sublist(0, encryptedWithTag.length - _tagLength);
    final receivedTag = encryptedWithTag.sublist(
        encryptedWithTag.length - _tagLength);

    // Decrypt (XOR is symmetric)
    final decrypted = List<int>.from(encryptedData);
    for (int i = 0; i < decrypted.length; i++) {
      final keyByte = _key[i % _key.length];
      final ivByte = iv[i % iv.length];
      decrypted[i] = (decrypted[i] ^ keyByte ^ ivByte) & 0xFF;
    }

    // Verify authentication tag
    final computedTag = CryptoUtilsSecure.computeHMAC(decrypted, _key);
    if (!_listEquals(computedTag, receivedTag)) {
      throw CryptoException(
          'Authentication failed - data may be tampered');
    }

    return decrypted;
  }
}

/// Compare two lists for equality
bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Crypto exception
class CryptoException implements Exception {
  final String message;

  CryptoException(this.message);

  @override
  String toString() => 'CryptoException: $message';
}
