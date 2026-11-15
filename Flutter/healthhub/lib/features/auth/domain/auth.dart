import 'package:equatable/equatable.dart';

import '../../catalog/domain/catalog.dart';

/// The parts of the app a user can work in. Everyone is a patient;
/// accepted doctors, pharmacies, hospitals and admins get extra workspaces.
enum Workspace {
  patient('Patient'),
  doctor('Doctor'),
  pharmacy('Pharmacy'),
  hospital('Hospital'),
  admin('Admin');

  const Workspace(this.label);
  final String label;

  static Workspace? byName(String? name) {
    for (final w in Workspace.values) {
      if (w.name == name) return w;
    }
    return null;
  }
}

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    this.phone,
    this.gender = 'male',
    this.birthDate,
    this.age,
    this.imageUrl,
    this.area,
    this.governorate,
  });

  final String id;
  final String name;
  final String email;
  final List<String> roles;
  final String? phone;
  final String gender;
  final DateTime? birthDate;
  final int? age;
  final String? imageUrl;
  final Area? area;
  final Governorate? governorate;

  String get firstName => name.split(' ').first;

  bool hasRole(String role) => roles.contains(role);

  List<Workspace> get workspaces => [
        Workspace.patient,
        if (hasRole('Doctor')) Workspace.doctor,
        if (hasRole('Pharmacy')) Workspace.pharmacy,
        if (hasRole('Hospital')) Workspace.hospital,
        if (hasRole('Admin') || hasRole('CustomerService')) Workspace.admin,
      ];

  @override
  List<Object?> get props => [id, name, email, roles, phone, imageUrl, area];
}

class RegisterData {
  const RegisterData({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.birthDate,
    required this.nationalId,
    required this.gender,
    required this.areaId,
  });

  final String name;
  final String email;
  final String password;
  final String phone;
  final DateTime birthDate;
  final String nationalId;
  final String gender; // male | female
  final String areaId;
}

abstract class AuthRepository {
  /// True when a saved token exists (the user logged in before).
  bool get hasSession;

  Future<User> login(String login, String password);
  Future<void> register(RegisterData data);
  Future<User> me();
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String code, String newPassword);
  Future<User> changePhoto(List<int> bytes, String fileName);

  /// Replaces the saved token, e.g. after a role was granted.
  Future<void> useToken(String token);
}
