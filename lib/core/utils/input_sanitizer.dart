import 'package:flutter/foundation.dart';

/// Utility class for sanitizing user inputs to prevent XSS and injection attacks
class InputSanitizer {
  /// Sanitize text input by removing potentially dangerous characters
  static String sanitizeText(String input) {
    if (input.isEmpty) return input;
    
    // Remove HTML tags and scripts
    String sanitized = input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '') // Remove javascript: protocol
        .replaceAll(RegExp(r'data:', caseSensitive: false), '') // Remove data: protocol
        .replaceAll(RegExp(r'vbscript:', caseSensitive: false), ''); // Remove vbscript: protocol
    
    // Remove control characters except newlines and tabs
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    // Trim whitespace
    sanitized = sanitized.trim();
    
    if (kDebugMode && sanitized != input) {
      debugPrint('InputSanitizer: Sanitized input from "${input.length}" to "${sanitized.length}" characters');
    }
    
    return sanitized;
  }

  /// Sanitize email input
  static String sanitizeEmail(String email) {
    if (email.isEmpty) return email;
    
    // Basic email validation and sanitization
    String sanitized = email.trim().toLowerCase();
    
    // Remove any HTML or script content
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Remove control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    return sanitized;
  }

  /// Sanitize phone number input
  static String sanitizePhone(String phone) {
    if (phone.isEmpty) return phone;
    
    // Remove all non-digit characters except +, -, (, ), and space
    String sanitized = phone.replaceAll(RegExp(r'[^\d\+\-\(\)\s]'), '');
    
    // Remove control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    return sanitized.trim();
  }

  /// Sanitize address input
  static String sanitizeAddress(String address) {
    if (address.isEmpty) return address;
    
    // Remove HTML tags and scripts
    String sanitized = address
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'data:', caseSensitive: false), '');
    
    // Remove control characters except newlines
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    return sanitized.trim();
  }

  /// Sanitize numeric input
  static String sanitizeNumeric(String input) {
    if (input.isEmpty) return input;
    
    // Remove all non-digit characters except decimal point
    String sanitized = input.replaceAll(RegExp(r'[^\d\.]'), '');
    
    // Ensure only one decimal point
    final parts = sanitized.split('.');
    if (parts.length > 2) {
      sanitized = '${parts[0]}.${parts[1]}';
    }
    
    return sanitized;
  }

  /// Validate and sanitize password (basic validation)
  static String sanitizePassword(String password) {
    if (password.isEmpty) return password;
    
    // Remove control characters
    String sanitized = password.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    return sanitized;
  }

  /// Check if input contains potentially dangerous content
  static bool containsDangerousContent(String input) {
    if (input.isEmpty) return false;
    
    final dangerousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'data:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // Event handlers
      RegExp(r'<iframe', caseSensitive: false),
      RegExp(r'<object', caseSensitive: false),
      RegExp(r'<embed', caseSensitive: false),
    ];
    
    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(input)) {
        if (kDebugMode) {
          debugPrint('InputSanitizer: Dangerous content detected: ${pattern.pattern}');
        }
        return true;
      }
    }
    
    return false;
  }

  /// Get validation error message for dangerous content
  static String? getValidationError(String input) {
    if (containsDangerousContent(input)) {
      return 'Input contains invalid characters or content';
    }
    return null;
  }
} 