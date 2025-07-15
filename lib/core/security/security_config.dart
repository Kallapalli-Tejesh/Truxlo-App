class SecurityConfig {
  // Password requirements
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const bool requireUppercase = true;
  static const bool requireLowercase = true;
  static const bool requireNumbers = true;
  static const bool requireSpecialChars = true;

  // File upload limits
  static const int maxImageSizeMB = 5;
  static const int maxDocumentSizeMB = 10;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];

  // Input validation limits
  static const int maxJobTitleLength = 100;
  static const int maxJobDescriptionLength = 500;
  static const int maxLocationLength = 100;
  static const int maxNameLength = 50;
  static const double maxPrice = 1000000.0;
  static const double maxWeight = 50000.0;

  // Rate limiting
  static const int maxRequestsPerMinute = 60;
  static const int maxLoginAttemptsPerHour = 5;
  static const Duration sessionTimeout = Duration(hours: 24);

  // Security headers
  static const Map<String, String> securityHeaders = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  };
} 