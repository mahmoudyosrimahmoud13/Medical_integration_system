import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import '../../appointments/data/appointment_repository_impl.dart';
import '../../appointments/domain/appointments.dart';
import '../../doctor_portal/data/doctor_portal_repository_impl.dart';
import '../../doctor_portal/domain/doctor_portal.dart';
import '../../doctors/data/doctor_repository_impl.dart';
import '../../pharmacy/domain/pharmacy.dart';
import '../domain/hospital.dart';
import '../../../core/i18n/i18n.dart';

Hospital hospitalFromJson(Map<String, dynamic> j) => Hospital(
      id: str(j['id']),
      name: str(j['name']),
      area: rememberPlace(j['area']),
      governorate: rememberPlace(j['governorate']),
      description: str(j['description']),
      address: str(j['address_description']),
      phone: strOrNull(j['phone']),
      status: str(j['status'], 'accepted'),
      ownerId: str(j['owner_id']),
      doctors: list(j['doctors'])
          .map((d) => HospitalDoctor(doctor: doctorSummaryFromJson(map(d['doctor'])), department: str(d['department'])))
          .toList(),
    );

class HospitalRepositoryImpl implements HospitalRepository {
  HospitalRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<(ApplicationStatus, Hospital?)> mine() async {
    final j = map(await _api.get('/hospitals/me'));
    return (statusFromJson(j), j['hospital'] == null ? null : hospitalFromJson(map(j['hospital'])));
  }

  @override
  Future<void> apply(FacilityApplication a) => _api.post('/hospitals/apply', body: a.toJson());

  @override
  Future<Hospital> addDoctor(String doctorEmail, String department) async => hospitalFromJson(
      map(await _api.post('/hospitals/me/doctors', body: {'doctor_email': doctorEmail.trim(), 'department': department.trim()})));

  @override
  Future<Hospital> removeDoctor(String doctorId) async => hospitalFromJson(map(await _api.delete('/hospitals/me/doctors/$doctorId')));

  @override
  Future<List<Appointment>> appointments() async =>
      list(await _api.get('/hospitals/me/appointments')).map(appointmentFromJson).toList();

  @override
  Future<List<Hospital>> find({String? governorateId, String? areaId, String? name}) async =>
      list(await _api.get('/hospitals', query: {'governorate_id': governorateId, 'area_id': areaId, 'name': name}))
          .map(hospitalFromJson)
          .toList();

  @override
  Future<Hospital> details(String id) async => hospitalFromJson(map(await _api.get('/hospitals/$id')));
}
