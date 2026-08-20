class Validators {
  Validators._();

  static bool isEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
  }

  static String passwordError(String value) {
    if (value.length < 8) {
      return 'Password must contain at least 8 characters.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value) || !RegExp(r'\d').hasMatch(value)) {
      return 'Password must include a letter and a number.';
    }
    return '';
  }

  static String usernameError(String value) {
    final clean = value.trim();
    if (clean.length < 3) {
      return 'Username must contain at least 3 characters.';
    }
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(clean)) {
      return 'Use only letters, numbers, dots, and underscores.';
    }
    return '';
  }

  static String requiredTextError(String value, String label, {int minimum = 2}) {
    if (value.trim().length < minimum) {
      return '$label must contain at least $minimum characters.';
    }
    return '';
  }
}
