import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/json.dart';
import '../../catalog/data/catalog_repository_impl.dart';
import '../domain/auth.dart';

User userFromJson(Map<String, dynamic> j) => User(
      id: str(j['id']),
      name: str(j['name']),
      email: str(j['email']),
      roles: (j['roles'] as List? ?? const []).map((e) => e.toString()).toList(),
      phone: strOrNull(j['phone']),
      gender: str(j['gender'], 'male'),
      birthDate: date(j['birth_date']),
      age: j['age'] == null ? null : integer(j['age']),
      imageUrl: strOrNull(j['image_url']),
      area: j['area'] == null ? null : areaFromJson(map(j['area'])),
      governorate: j['governorate'] == null ? null : governorateFromJson(map(j['governorate'])),
    );

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  @override
  bool get hasSession => _tokens.token != null;

  @override
  Future<User> login(String login, String password) async {
    final data = map(await _api.post('/auth/login', body: {'login': login.trim(), 'password': password}));
    await _tokens.save(str(data['access_token']));
    return userFromJson(map(data['user']));
  }

  @override
  Future<void> register(RegisterData d) async {
    await _api.post('/auth/register', body: {
      'name': d.name.trim(),
      'email': d.email.trim(),
      'password': d.password,
      'phone': d.phone.trim(),
      'birth_date': isoDay(d.birthDate),
      'national_id': d.nationalId.trim(),
      'gender': d.gender,
      'area_id': d.areaId,
    });
  }

  @override
  Future<User> me() async => userFromJson(map(await _api.get('/users/me')));

  @override
  Future<void> logout() => _tokens.clear();

  @override
  Future<void> forgotPassword(String email) => _api.post('/auth/forgot-password', body: {'email': email.trim()});

  @override
  Future<void> resetPassword(String code, String newPassword) =>
      _api.post('/auth/reset-password', body: {'token': code.trim(), 'new_password': newPassword});

  @override
  Future<User> changePhoto(List<int> bytes, String fileName) async {
    final data = await _api.upload('/users/me/photo',
        method: 'PUT', files: {'image': [UploadFile(bytes: Uint8List.fromList(bytes), name: fileName)]});
    return userFromJson(map(data));
  }

  @override
  Future<void> useToken(String token) => _tokens.save(token);
}
