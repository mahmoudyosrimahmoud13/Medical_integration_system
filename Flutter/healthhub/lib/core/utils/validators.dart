/// Form validators. They mirror the server rules so users see problems before sending.
/// Each returns null when the value is fine, or a short message.
class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _password = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[_#$^+=!*()@%&]).{8,}$');
  static final _phone = RegExp(r'^(?:\+20|0)?1[0125]\d{8}$');
  static final _nationalId = RegExp(r'^[23]\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{7}$');

  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    return _email.hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';
    return _password.hasMatch(v) ? null : 'Use upper and lower case letters, a number and a symbol';
  }

  static String? loginPassword(String? v) => (v == null || v.isEmpty) ? 'Password is required' : null;

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone is required';
    return _phone.hasMatch(v.trim()) ? null : 'Use an Egyptian mobile number, like 01012345678';
  }

  static String? nationalId(String? v) {
    if (v == null || v.trim().isEmpty) return 'National ID is required';
    return _nationalId.hasMatch(v.trim()) ? null : 'National ID must be 14 valid digits';
  }

  static String? name(String? v) {
    if (v == null || v.trim().length < 3) return 'Enter your full name';
    return null;
  }

  static String? Function(String?) match(String Function() other, [String message = "Passwords don't match"]) =>
      (v) => v == other() ? null : message;
}
