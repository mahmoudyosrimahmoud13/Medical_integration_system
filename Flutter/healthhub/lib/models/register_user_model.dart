import 'dart:io';

final class RegisterUserModel {
  final String name;
  final String email;
  final String password;
  final String phone;
  final DateTime birday;
  final String area;
  final bool gender;

  RegisterUserModel(
      {required this.name,
      required this.email,
      required this.password,
      required this.phone,
      required this.birday,
      required this.area,
      required this.gender});
}
