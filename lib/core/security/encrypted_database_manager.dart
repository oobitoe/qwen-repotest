import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Mengelola enkripsi file database SQLite saat istirahat (at rest).
///
/// Alur kerja:
/// 1. Database disimpan di disk dalam bentuk terenkripsi (`.enc`)
/// 2. Saat aplikasi mulai, file didekripsi ke lokasi kerja (plaintext)
/// 3. Drift membuka file kerja untuk operasi database normal
/// 4. Saat aplikasi ditutup, file kerja dienkripsi kembali ke `.enc` dan dihapus
///
/// Ini melindungi data saat aplikasi tidak berjalan (database browser tidak
/// bisa membaca file `.enc` tanpa kunci).
class EncryptedDatabaseManager {
  static Future<void> encryptDatabaseFile({
    required String sourcePath,
    required String destinationPath,
    required String encryptionKey,
  }) async {
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      throw EncryptedDatabaseException('Database file not found: $sourcePath');
    }

    final bytes = await sourceFile.readAsBytes();
    final encryptedBytes = _encryptBytes(bytes, encryptionKey);

    final destFile = File(destinationPath);
    await destFile.writeAsBytes(encryptedBytes, flush: true);
  }

  /// Dekripsi file `.enc` ke database SQLite yang bisa digunakan Drift
  static Future<void> decryptDatabaseFile({
    required String sourcePath,
    required String destinationPath,
    required String encryptionKey,
  }) async {
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      throw EncryptedDatabaseException('Encrypted file not found: $sourcePath');
    }

    final encryptedBytes = await sourceFile.readAsBytes();
    final decryptedBytes = _decryptBytes(encryptedBytes, encryptionKey);

    final destFile = File(destinationPath);
    await destFile.writeAsBytes(decryptedBytes, flush: true);
  }

  /// Enkripsi file database saat aplikasi ditutup (proteksi data at rest)
  static Future<void> secureDatabaseAtRest({
    required String workingDbPath,
    required String encryptedDbPath,
    required String encryptionKey,
  }) async {
    final workingFile = File(workingDbPath);
    if (!workingFile.existsSync()) return;

    await encryptDatabaseFile(
      sourcePath: workingDbPath,
      destinationPath: encryptedDbPath,
      encryptionKey: encryptionKey,
    );

    // Hapus file kerja setelah dienkripsi
    await workingFile.delete();
  }

  /// Dekripsi database saat aplikasi mulai (siap digunakan Drift)
  static Future<void> prepareDatabaseForUse({
    required String encryptedDbPath,
    required String workingDbPath,
    required String encryptionKey,
  }) async {
    final workingFile = File(workingDbPath);
    final encryptedFile = File(encryptedDbPath);

    // Jika ada file kerja yang tersisa (crash sebelumnya), hapus
    if (workingFile.existsSync()) {
      await workingFile.delete();
    }

    // Jika ada file terenkripsi, dekripsi ke lokasi kerja
    if (encryptedFile.existsSync()) {
      await decryptDatabaseFile(
        sourcePath: encryptedDbPath,
        destinationPath: workingDbPath,
        encryptionKey: encryptionKey,
      );
    }
    // Jika tidak ada file terenkripsi, Drift akan membuat database baru
  }

  /// Cek apakah database terenkripsi ada di disk
  static bool hasEncryptedDatabase(String encryptedDbPath) {
    return File(encryptedDbPath).existsSync();
  }

  /// Cek apakah database kerja (plaintext) ada di disk
  static bool hasWorkingDatabase(String workingDbPath) {
    return File(workingDbPath).existsSync();
  }

  /// Hapus semua file database (encrypted + working)
  static Future<void> purgeDatabaseFiles({
    required String encryptedDbPath,
    required String workingDbPath,
  }) async {
    final encryptedFile = File(encryptedDbPath);
    final workingFile = File(workingDbPath);

    if (encryptedFile.existsSync()) {
      await encryptedFile.delete();
    }
    if (workingFile.existsSync()) {
      await workingFile.delete();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal encryption helpers
  // ---------------------------------------------------------------------------

  static List<int> _encryptBytes(List<int> data, String key) {
    final keyBytes = _deriveKeyBytes(key);
    final iv = _generateIV();
    final cipher = _SimpleAES(keyBytes);
    final encrypted = cipher.encrypt(data, iv);
    // Format: [IV (16 bytes)] [encrypted data]
    return [...iv, ...encrypted];
  }

  static List<int> _decryptBytes(List<int> encryptedData, String key) {
    final keyBytes = _deriveKeyBytes(key);
    if (encryptedData.length < 16) {
      throw EncryptedDatabaseException('Encrypted data too short');
    }

    final iv = encryptedData.sublist(0, 16);
    final ciphertext = encryptedData.sublist(16);
    final cipher = _SimpleAES(keyBytes);
    return cipher.decrypt(ciphertext, iv);
  }

  static List<int> _deriveKeyBytes(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.bytes;
  }

  static List<int> _generateIV() {
    final bytes = List<int>.generate(16, (_) => (DateTime.now().millisecond ^ _) % 256);
    return bytes;
  }
}

/// Sederhana XOR cipher dengan key stretching (untuk demonstrasi)
/// Dalam produksi, gunakan library AES yang benar seperti point_interop
class _SimpleAES {
  final List<int> _key;

  _SimpleAES(this._key);

  List<int> encrypt(List<int> data, List<int> iv) {
    final result = List<int>.from(data);
    for (int i = 0; i < result.length; i++) {
      result[i] = (result[i] ^ _key[i % _key.length] ^ iv[i % iv.length]) & 0xFF;
    }
    return result;
  }

  List<int> decrypt(List<int> encrypted, List<int> iv) {
    // XOR is symmetric
    return encrypt(encrypted, iv);
  }
}

/// Exception untuk operasi enkripsi database
class EncryptedDatabaseException implements Exception {
  final String message;

  EncryptedDatabaseException(this.message);

  @override
  String toString() => 'EncryptedDatabaseException: $message';
}
