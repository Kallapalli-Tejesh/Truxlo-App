import 'dart:io';
import 'package:flutter/foundation.dart';

class ValidationService {
  // Input sanitization patterns
  static final RegExp _htmlPattern = RegExp(r'<[^>]*>');
  static final RegExp _scriptPattern = RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false);
  static final RegExp _phonePattern = RegExp(r'^[+]?[0-9]{10,15}$');
  static final RegExp _emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp _alphanumericPattern = RegExp(r'^[a-zA-Z0-9\s\-_.]+$');

  // Job-related validation
  static String? validateJobTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Job title is required';
    }
    
    final sanitized = _sanitizeInput(value);
    if (sanitized.length < 3 || sanitized.length > 100) {
      return 'Job title must be between 3 and 100 characters';
    }
    
    if (!_alphanumericPattern.hasMatch(sanitized)) {
      return 'Job title contains invalid characters';
    }
    
    return null;
  }

  static String? validateJobDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Job description is required';
    }
    
    final sanitized = _sanitizeInput(value);
    if (sanitized.length < 10 || sanitized.length > 500) {
      return 'Description must be between 10 and 500 characters';
    }
    
    return null;
  }

  static String? validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Location is required';
    }
    
    final sanitized = _sanitizeInput(value);
    if (sanitized.length < 3 || sanitized.length > 100) {
      return 'Location must be between 3 and 100 characters';
    }
    
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Please enter a valid price';
    }
    
    if (price > 1000000) {
      return 'Price cannot exceed ₹10,00,000';
    }
    
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Weight is required';
    }
    
    final weight = double.tryParse(value);
    if (weight == null || weight <= 0) {
      return 'Please enter a valid weight';
    }
    
    if (weight > 50000) {
      return 'Weight cannot exceed 50,000 kg';
    }
    
    return null;
  }

  // User profile validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    final sanitized = _sanitizeInput(value);
    if (sanitized.length < 2 || sanitized.length > 50) {
      return 'Name must be between 2 and 50 characters';
    }
    
    final namePattern = RegExp(r'^[a-zA-Z\s]+$');
    if (!namePattern.hasMatch(sanitized)) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    // Only trim and lowercase for email validation
    final trimmedEmail = value.trim().toLowerCase();
    if (!_emailPattern.hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    final sanitized = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (!_phonePattern.hasMatch(sanitized)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (value.length > 128) {
      return 'Password cannot exceed 128 characters';
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  // File validation
  static String? validateImageFile(File? file) {
    if (file == null) {
      return 'Please select an image';
    }
    
    // Check file size (max 5MB)
    final fileSizeInBytes = file.lengthSync();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    if (fileSizeInMB > 5) {
      return 'Image size cannot exceed 5MB';
    }
    
    // Check file extension
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
    final fileExtension = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(fileExtension)) {
      return 'Only JPG, JPEG, PNG, and GIF files are allowed';
    }
    
    return null;
  }

  static String? validateDocumentFile(File? file) {
    if (file == null) {
      return 'Please select a document';
    }
    
    // Check file size (max 10MB)
    final fileSizeInBytes = file.lengthSync();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    if (fileSizeInMB > 10) {
      return 'Document size cannot exceed 10MB';
    }
    
    // Check file extension
    final allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];
    final fileExtension = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(fileExtension)) {
      return 'Only PDF, DOC, DOCX, JPG, JPEG, and PNG files are allowed';
    }
    
    return null;
  }

  // Input sanitization
  static String _sanitizeInput(String input) {
    // Remove HTML tags
    String sanitized = input.replaceAll(_htmlPattern, '');
    
    // Remove script tags
    sanitized = sanitized.replaceAll(_scriptPattern, '');
    
    // Remove null bytes
    sanitized = sanitized.replaceAll('\x00', '');
    
    // Trim whitespace
    sanitized = sanitized.trim();
    
    return sanitized;
  }

  // Batch validation for forms
  static Map<String, String?> validateJobForm({
    required String? title,
    required String? description,
    required String? pickupLocation,
    required String? destinationLocation,
    required String? price,
    required String? weight,
  }) {
    return {
      'title': validateJobTitle(title),
      'description': validateJobDescription(description),
      'pickupLocation': validateLocation(pickupLocation),
      'destinationLocation': validateLocation(destinationLocation),
      'price': validatePrice(price),
      'weight': validateWeight(weight),
    };
  }

  static Map<String, String?> validateUserProfile({
    required String? name,
    required String? email,
    required String? phone,
  }) {
    return {
      'name': validateName(name),
      'email': validateEmail(email),
      'phone': validatePhone(phone),
    };
  }

  // Security utilities
  static bool isValidInput(String input) {
    // Check for common injection patterns
    final dangerousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'union\s+select', caseSensitive: false),
      RegExp(r'drop\s+table', caseSensitive: false),
    ];
    
    return !dangerousPatterns.any((pattern) => pattern.hasMatch(input));
  }

  static String sanitizeForDisplay(String input) {
    return _sanitizeInput(input);
  }

  static String sanitizeForDatabase(String input, {bool isEmail = false}) {
    if (isEmail) {
      // For emails, only trim and convert to lowercase
      return input.trim().toLowerCase();
    }
    // Additional sanitization for other fields
    String sanitized = _sanitizeInput(input);
    sanitized = sanitized.replaceAll("'", "''");
    return sanitized;
  }

  // Standard email normalization utility
  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }
}
