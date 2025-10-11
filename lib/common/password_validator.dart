class PasswordValidator {
  /// Validates password according to signup requirements
  static String? validatePassword(String? password) {
    if (password == null || password.trim().isEmpty) {
      return "Password is required";
    }

    if (password.length < 8) {
      return "Password must be at least 8 characters long";
    }

    // Check for uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password must contain at least one uppercase letter";
    }

    // Check for lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Password must contain at least one lowercase letter";
    }

    // Check for number
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password must contain at least one number";
    }

    // Check for special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return "Password must contain at least one special character";
    }

    return null;
  }

  /// Validates confirm password matches the new password
  static String? validateConfirmPassword(
      String? confirmPassword, String? newPassword) {
    if (confirmPassword == null || confirmPassword.trim().isEmpty) {
      return "Confirm password is required";
    }

    if (confirmPassword != newPassword) {
      return "Passwords do not match";
    }

    return null;
  }
}
