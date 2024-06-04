class ResponseUSerModel {
  final String token;
  final String imgSrc;
  final String email;
  final List<String> roles;
  final String message;
  final bool isLogin;
  final bool error;
  final DateTime exToken;
  final String area;
  final String gov;

  ResponseUSerModel({
    required this.token,
    required this.imgSrc,
    required this.email,
    required this.roles,
    required this.message,
    required this.isLogin,
    required this.error,
    required this.exToken,
    required this.area,
    required this.gov,
  });
}
