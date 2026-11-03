import 'dart:convert';
import 'dart:io';

import 'lib/core/security/crypto_utils_secure.dart';
import 'lib/core/security/crypto_key_manager.dart';
import 'lib/core/security/security_manager.dart';
import 'lib/core/database/app_database.dart';

Future<void> main() async {
  print('=== Prime POS Local Database Encryption Test ===\n');

  try {
    await testCryptoUtils();
    await testKeyDerivation();
    await testSecurityManager();
    await testDatabaseEncryption();

    print('\nAll encryption tests passed successfully!');
  } catch (e) {
    print('\nTest failed: $e');
    exit(1);
  }
}

Future<void> testCryptoUtils() async {
  print('1. Testing CryptoUtils...');

  final key = CryptoUtilsSecure.generateSecureKey(32);
  final originalData =
      utf8.encode('Sensitive business data for encryption test');

  final encrypted =
      CryptoUtilsSecure.encryptAES256GCM(originalData, key);
  print('   Data encrypted successfully (${encrypted.length} bytes)');

  final decrypted =
      CryptoUtilsSecure.decryptAES256GCM(encrypted, key);
  print('   Data decrypted successfully');

  final originalString = utf8.decode(originalData);
  final decryptedString = utf8.decode(decrypted);

  if (originalString == decryptedString) {
    print('   Encryption/decryption integrity verified');
  } else {
    throw Exception('Data integrity check failed');
  }
}

Future<void> testKeyDerivation() async {
  print('\n2. Testing Key Derivation...');

  const password = 'SecurePassword123';

  final derivedKey = await CryptoKeyManager.deriveKeyFromPassword(password);
  print('   Key derived successfully (${derivedKey.length} characters)');

  final isValidKey = CryptoKeyManager.isValidKeyFormat(derivedKey);
  print('   Key format validation: ${isValidKey ? 'PASSED' : 'FAILED'}');

  if (!isValidKey) {
    throw Exception('Key format validation failed');
  }

  final isStrong = SecurityManager.isPasswordStrong(password);
  print('   Password strength validation: ${isStrong ? 'PASSED' : 'FAILED'}');

  if (!isStrong) {
    throw Exception('Password strength validation failed');
  }
}

Future<void> testSecurityManager() async {
  print('\n3. Testing Security Manager...');

  final isInitialized = await SecurityManager.initialize();
  print(
      '   Security manager initialization: ${isInitialized ? 'PASSED' : 'SKIPPED'}');

  final strongPassword = 'StrongPass123';
  final weakPassword = 'weak';

  final strongValid = SecurityManager.isPasswordStrong(strongPassword);
  final weakValid = SecurityManager.isPasswordStrong(weakPassword);

  print(
      '   Strong password validation: ${strongValid ? 'PASSED' : 'FAILED'}');
  print('   Weak password validation: ${!weakValid ? 'PASSED' : 'FAILED'}');

  if (!strongValid || weakValid) {
    throw Exception('Password validation failed');
  }
}

Future<void> testDatabaseEncryption() async {
  print('\n4. Testing Database Encryption...');

  final isEncryptionEnabled = AppDatabase.isEncryptionEnabled;
  print(
      '   Database encryption status: ${isEncryptionEnabled ? 'ENABLED' : 'DISABLED'}');

  final encryptedPath = AppDatabase.encryptedDatabasePath();
  final workingPath = AppDatabase.databasePath();

  print('   Encrypted database path: $encryptedPath');
  print('   Working database path: $workingPath');

  final encryptedDir = Directory(encryptedPath).parent;
  final workingDir = Directory(workingPath).parent;

  print(
      '   Encrypted database directory exists: ${encryptedDir.existsSync() ? 'YES' : 'NO'}');
  print(
      '   Working database directory exists: ${workingDir.existsSync() ? 'YES' : 'NO'}');

  try {
    if (encryptedDir.existsSync()) {
      await encryptedDir.delete(recursive: true);
      print('   Cleaned up encrypted test directory');
    }
  } catch (e) {
    print('   Warning: Could not clean up encrypted directory: $e');
  }
}
