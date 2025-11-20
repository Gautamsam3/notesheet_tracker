// lib/utils/validators.dart

class Validators {
  // Email validation regex (basic)
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates an email address.
  /// Returns null if valid, otherwise an error message.
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email cannot be empty.';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null; // Valid
  }

  /// Validates a password.
  /// Returns null if valid, otherwise an error message.
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password cannot be empty.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    // Add more complex rules if needed (e.g., requires uppercase, number, special char)
    // if (!password.contains(RegExp(r'[A-Z]'))) {
    //   return 'Password must contain at least one uppercase letter.';
    // }
    // if (!password.contains(RegExp(r'[0-9]'))) {
    //   return 'Password must contain at least one number.';
    // }
    return null; // Valid
  }

  /// Validates a non-empty string.
  /// Returns null if valid, otherwise an error message.
  static String? validateNonEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty.';
    }
    return null; // Valid
  }

  /// Validates a numeric input.
  /// Returns null if valid, otherwise an error message.
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName cannot be empty.';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number for $fieldName.';
    }
    return null; // Valid
  }

  /// Validates an integer input.
  /// Returns null if valid, otherwise an error message.
  static String? validateInteger(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName cannot be empty.';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid integer for $fieldName.';
    }
    return null; // Valid
  }

  /// Validates a date input (assuming a specific format, e.g., 'YYYY-MM-DD').
  /// For date pickers, this might not be strictly necessary as they return DateTime objects.
  /// This is more for manual text input fields.
  static String? validateDate(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName cannot be empty.';
    }
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date for $fieldName (e.g., YYYY-MM-DD).';
    }
  }

  /// Validates that a string is within a specified length range.
  static String? validateLength(
    String? value,
    String fieldName,
    int minLength, {
    int? maxLength,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName cannot be empty.';
    }
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters.';
    }
    if (maxLength != null && value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters.';
    }
    return null; // Valid
  }
}
