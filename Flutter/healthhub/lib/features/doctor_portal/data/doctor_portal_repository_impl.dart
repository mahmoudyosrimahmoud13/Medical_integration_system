import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import '../../appointments/data/appointment_repository_impl.dart';
import '../../appointments/domain/appointments.dart';
import '../../doctors/data/doctor_repository_impl.dart';
import '../../doctors/domain/doctors.dart';
import '../domain/doctor_portal.dart';

ApplicationStatus statusFromJson(Map<String, dynamic> j) =>
    ApplicationStatus(status: str(j['status'], 'none'), accessToken: strOrNull(j['access_token']));

class DoctorPortalRepositoryImpl implements DoctorPortalRepository {
  DoctorPortalRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<ApplicationStatus> status() async => statusFromJson(map(await _api.get('/doctors/me/status')));

  @override
  Future<ApplicationStatus> apply(DoctorApplication a) async => statusFromJson(map(await _api.upload(
        '/doctors/apply',
        fields: {
          'specialty_id': a.specialtyId,
          'area_id': a.areaId,
          'college_name': a.college,
          'graduation_year': a.graduationYear == null ? null : isoDay(a.graduationYear!),
          'summary_career': a.summary,
          'address_description': a.address,
        },
        files: {
          'certificates': [for (final c in a.certificates) UploadFile(bytes: Uint8List.fromList(c.bytes), name: c.name)],
        },
      )));

  @override
  Future<List<ScheduleDay>> schedule() async => list(await _api.get('/doctors/me/schedule')).map(scheduleFromJson).toList();

  @override
  Future<List<ScheduleDay>> saveSchedule(List<ScheduleDay> days) async => list(await _api.put('/doctors/me/schedule',
          body: [for (final d in days) {'day_name': d.day, 'time_from': d.from, 'time_to': d.to}]))
      .map(scheduleFromJson)
      .toList();

  @override
  Future<void> setPrice(double price) => _api.put('/doctors/me/price', body: {'price': price});

  @override
  Future<List<Appointment>> appointments({bool upcomingOnly = true}) async =>
      list(await _api.get('/doctors/me/appointments', query: {'upcoming_only': upcomingOnly})).map(appointmentFromJson).toList();

  @override
  Future<void> cancelAppointment(String id) => _api.delete('/doctors/me/appointments/$id');

  @override
  Future<DoctorStats> stats() async {
    final j = map(await _api.get('/doctors/me/stats'));
    return DoctorStats(
      total: integer(j['total']),
      male: integer(j['male']),
      female: integer(j['female']),
      upcoming: integer(j['upcoming_appointments']),
    );
  }
}
