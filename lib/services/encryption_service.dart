import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

class EncryptionService {
  static final _key = encrypt.Key.fromSecureRandom(32);
  static final _iv = encrypt.IV.fromSecureRandom(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  // Encryption for personal data
  static String encryptPersonalData(String plainText) {
    try {
      if (plainText.isEmpty) return plainText;
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      if (kDebugMode) {
        print('Encryption error: $e');
      }
      return plainText; // Fallback to plain text in case of error
    }
  }

  // Decryption for personal data
  static String decryptPersonalData(String encryptedText) {
    try {
      if (encryptedText.isEmpty) return encryptedText;
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      if (kDebugMode) {
        print('Decryption error: $e');
      }
      return encryptedText; // Return as-is if decryption fails
    }
  }

  // Hash sensitive data for comparison
  static String hashSensitiveData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Encrypt location data
  static Map encryptLocationData(Map locationData) {
    final encrypted = {};
    locationData.forEach((key, value) {
      encrypted[key] = encryptPersonalData(value);
    });
    return encrypted;
  }

  // Decrypt location data
  static Map decryptLocationData(Map encryptedData) {
    final decrypted = {};
    encryptedData.forEach((key, value) {
      decrypted[key] = decryptPersonalData(value);
    });
    return decrypted;
  }

  // Encrypt financial data
  static String encryptFinancialData(double amount) {
    return encryptPersonalData(amount.toString());
  }

  // Decrypt financial data
  static double decryptFinancialData(String encryptedAmount) {
    final decrypted = decryptPersonalData(encryptedAmount);
    return double.tryParse(decrypted) ?? 0.0;
  }

  // Check if data is encrypted (basic check)
  static bool isEncrypted(String data) {
    try {
      // Try to decode as base64 - encrypted data should be base64
      base64.decode(data);
      return true;
    } catch (e) {
      return false;
    }
  }
} 