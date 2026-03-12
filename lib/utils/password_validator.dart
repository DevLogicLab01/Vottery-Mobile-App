class PasswordValidator {
  static const int minLength = 12;
  static const int maxLength = 128;

  static final List<String> commonPasswords = [
    'password', '12345678', 'qwerty123', 'password1', 'abc12345',
    'letmein1', 'welcome1', 'monkey12', 'dragon12', 'master12',
    'password123!', 'admin123!', 'welcome123!',
    'qwerty123!', '123456789!', 'password1!',
  ];

  static Map<String, dynamic> validate(String password) {
    final errors = <String>[];
    
    if (password.length < minLength) {
      errors.add('Must be at least $minLength characters');
    }
    if (password.length > maxLength) {
      errors.add('Must be less than $maxLength characters');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('Must contain at least one uppercase letter');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('Must contain at least one lowercase letter');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('Must contain at least one number');
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      errors.add('Must contain at least one special character');
    }
    if (commonPasswords.contains(password.toLowerCase())) {
      errors.add('This password is too common');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'strength': _calculateStrength(password),
    };
  }

  static String? validateJoined(String password) {
    final result = validate(password);
    final errors = result['errors'] as List<String>;
    if (errors.isEmpty) return null;
    return errors.join('. ');
  }

  static String _calculateStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    if (score <= 2) return 'weak';
    if (score <= 4) return 'medium';
    return 'strong';
  }
}
