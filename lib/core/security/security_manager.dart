import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../database/app_database.dart';
import 'crypto_key_manager.dart';

/// Security state tracking
class SecurityState {
  final bool isInitialized;
  final bool requiresAuthentication;
  final DateTime? lastAuthTime;
  final int failedAttemptCount;
  final bool isAccountLocked;

  SecurityState({
    this.isInitialized = false,
    this.requiresAuthentication = false,
    this.lastAuthTime,
    this.failedAttemptCount = 0,
    this.isAccountLocked = false,
  });

  SecurityState copyWith({
    bool? isInitialized,
    bool? requiresAuthentication,
    DateTime? lastAuthTime,
    int? failedAttemptCount,
    bool? isAccountLocked,
  }) {
    return SecurityState(
      isInitialized: isInitialized ?? this.isInitialized,
      requiresAuthentication: requiresAuthentication ?? this.requiresAuthentication,
      lastAuthTime: lastAuthTime ?? this.lastAuthTime,
      failedAttemptCount: failedAttemptCount ?? this.failedAttemptCount,
      isAccountLocked: isAccountLocked ?? this.isAccountLocked,
    );
  }
}

/// Security exception class
class SecurityException implements Exception {
  final String message;

  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

class SecurityManager {
  // Storage keys
  static const String _masterPasswordHashKey = 'master_password_hash';
  static const String _securitySetupCompleteKey = 'security_setup_complete';
  static const String _encryptionKeyInitializedKey =
      'encryption_key_initialized';
  static const String _databaseEncryptionKeyKey = 'database_encryption_key';

  // Security constants
  static const int _minimumPasswordLength = 8;
  static const int _maxFailedAttempts = 3;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  /// Security state
  static SecurityState _securityState = SecurityState();

  /// Initialize security system
  static Future<bool> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isSetupComplete =
        prefs.getBool(_securitySetupCompleteKey) ?? false;
    final keyInitialized =
        prefs.getBool(_encryptionKeyInitializedKey) ?? false;

    if (isSetupComplete && keyInitialized) {
      _securityState = _securityState.copyWith(
        isInitialized: true,
        requiresAuthentication: true,
      );
      return true;
    }

    return false;
  }

  /// Setup initial encryption key
  static Future<void> setupInitialEncryption() async {
    final prefs = await SharedPreferences.getInstance();

    // Generate initial encryption key
    final initialKey = await CryptoKeyManager.generateRandomKey();
    await prefs.setString(_databaseEncryptionKeyKey, initialKey);

    // Initialize database with encryption key
    await AppDatabase.setEncryptionKey(initialKey);

    // Mark setup as complete
    await prefs.setBool(_securitySetupCompleteKey, true);
    await prefs.setBool(_encryptionKeyInitializedKey, true);

    _securityState = _securityState.copyWith(
      isInitialized: true,
      requiresAuthentication: false,
    );
  }

  /// Authenticate user and set encryption key
  static Future<bool> authenticateAndSetKey(String password) async {
    if (_securityState.isAccountLocked) {
      throw SecurityException(
          'Account is locked. Please try again later.');
    }

    try {
      // Derive key from password
      final derivedKey =
          await CryptoKeyManager.deriveKeyFromPassword(password);

      // Validate key format
      if (!CryptoKeyManager.isValidKeyFormat(derivedKey)) {
        await _updateFailedAttempts();
        throw SecurityException('Invalid password format.');
      }

      // Set encryption key in database
      await AppDatabase.setEncryptionKey(derivedKey);

      // Store hash for verification
      final passwordHash = _hashPassword(password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_masterPasswordHashKey, passwordHash);

      // Reset failed attempts
      await _resetFailedAttempts();

      _securityState = _securityState.copyWith(
        isInitialized: true,
        requiresAuthentication: false,
        lastAuthTime: DateTime.now(),
        failedAttemptCount: 0,
      );

      return true;
    } catch (e) {
      await _updateFailedAttempts();
      rethrow;
    }
  }

  /// Validate current authentication
  static Future<bool> validateAuthentication(String password) async {
    if (_securityState.isAccountLocked) {
      throw SecurityException(
          'Account is locked due to too many failed attempts.');
    }

    try {
      // Derive key and compare with stored hash
      final derivedKey =
          await CryptoKeyManager.deriveKeyFromPassword(password);
      await AppDatabase.setEncryptionKey(derivedKey);

      // Verify password hash
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString(_masterPasswordHashKey);
      final currentHash = _hashPassword(password);

      if (storedHash == currentHash) {
        _securityState = _securityState.copyWith(
          lastAuthTime: DateTime.now(),
          failedAttemptCount: 0,
        );
        return true;
      }

      await _updateFailedAttempts();
      return false;
    } catch (e) {
      await _updateFailedAttempts();
      return false;
    }
  }

  /// Change encryption key
  static Future<void> changeEncryptionKey(
      String oldPassword, String newPassword) async {
    // Validate old password
    final isValid = await validateAuthentication(oldPassword);
    if (!isValid) {
      throw SecurityException('Current password is incorrect.');
    }

    // Derive new key and set it
    final newKey =
        await CryptoKeyManager.deriveKeyFromPassword(newPassword);
    await AppDatabase.setEncryptionKey(newKey);

    // Update password hash
    final newHash = _hashPassword(newPassword);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_masterPasswordHashKey, newHash);
  }

  /// Logout and clear encryption key
  static Future<void> logout() async {
    await AppDatabase.setEncryptionKey(null);
    _securityState = SecurityState();
    _securityState = _securityState.copyWith(
      isInitialized: false,
      requiresAuthentication: false,
      failedAttemptCount: 0,
      lastAuthTime: null,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_masterPasswordHashKey);
  }

  /// Get current security state
  static SecurityState getSecurityState() {
    return _securityState;
  }

  /// Check if security is initialized
  static bool get isSecurityInitialized =>
      _securityState.isInitialized;

  /// Check if authentication is required
  static bool get requiresAuthentication =>
      _securityState.requiresAuthentication;

  /// Validate password strength
  static bool isPasswordStrong(String password) {
    if (password.length < _minimumPasswordLength) {
      return false;
    }

    // Check for complexity (at least one uppercase, one lowercase, one number)
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));

    return hasUppercase && hasLowercase && hasNumber;
  }

  /// Hash password using SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Update failed attempt counter
  static Future<void> _updateFailedAttempts() async {
    final newCount = _securityState.failedAttemptCount + 1;

    if (newCount >= _maxFailedAttempts) {
      _securityState = _securityState.copyWith(
        isAccountLocked: true,
        failedAttemptCount: newCount,
      );
    } else {
      _securityState = _securityState.copyWith(
        failedAttemptCount: newCount,
      );
    }
  }

  /// Reset failed attempts
  static Future<void> _resetFailedAttempts() async {
    _securityState = _securityState.copyWith(
      failedAttemptCount: 0,
      isAccountLocked: false,
    );
  }

  /// Get lockout remaining time
  static Duration? getLockoutRemainingTime() {
    if (!_securityState.isAccountLocked) {
      return null;
    }

    return _lockoutDuration;
  }

  /// Check if database file is encrypted
  static Future<bool> isDatabaseEncrypted() async {
    final encryptedPath = AppDatabase.encryptedDatabasePath;
    if (!File(encryptedPath).existsSync()) {
      return false;
    }

    try {
      final file = File(encryptedPath);
      final bytes = await file.readAsBytes();
      return bytes.length > 100;
    } catch (e) {
      return false;
    }
  }

  /// Get encrypted database path
  static String get encryptedDatabasePath =>
      AppDatabase.encryptedDatabasePath;

  /// Get plaintext database path (for migration)
  static String get plaintextDatabasePath =>
      AppDatabase.plaintextDatabasePath;
}
