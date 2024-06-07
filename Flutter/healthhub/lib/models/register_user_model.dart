import 'dart:convert';
import 'dart:io';

class RegisterUserModel {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String birday;
  final String area;
  final String nationalID;
  final bool gender;
  final File? image;

  RegisterUserModel(
      {required this.image,
      required this.name,
      required this.email,
      required this.password,
      required this.phone,
      required this.birday,
      required this.area,
      required this.nationalID,
      required this.gender});

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'name': name});
    result.addAll({'email': email});
    result.addAll({'password': password});
    result.addAll({'phone': phone});
    result.addAll({'birday': birday});
    result.addAll({'area': area});
    result.addAll({'nationalID': nationalID});
    result.addAll({'gender': gender});

    return result;
  }
}
