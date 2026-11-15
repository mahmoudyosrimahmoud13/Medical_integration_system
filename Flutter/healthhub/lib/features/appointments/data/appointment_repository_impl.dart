import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import '../domain/appointments.dart';
import '../../../core/i18n/i18n.dart';

Appointment appointmentFromJson(Map<String, dynamic> j) {
  final d = j['doctor'] == null ? null : map(j['doctor']);
  final p = j['patient'] == null ? null : map(j['patient']);
  return Appointment(
    id: str(j['id']),
    day: date(j['day']) ?? DateTime.now(),
    dayName: str(j['day_name']),
    from: str(j['time_from']),
    to: str(j['time_to']),
    status: str(j['status'], 'booked'),
    doctor: d == null
        ? null
        : AppointmentDoctor(
            id: str(d['id']),
            name: str(d['name']),
            specialty: str(d['specialty']),
            area: rememberPlace({'key': d['area'], 'name_ar': d['area_ar']}),
            governorate: rememberPlace({'key': d['governorate'], 'name_ar': d['governorate_ar']}),
            imageUrl: strOrNull(d['image_url']),
            phone: strOrNull(d['phone']),
          ),
    patient: p == null
        ? null
        : AppointmentPatient(
            id: str(p['id']),
            name: str(p['name']),
            email: str(p['email']),
            phone: strOrNull(p['phone']),
            gender: str(p['gender'], 'male'),
            age: p['age'] == null ? null : integer(p['age']),
            imageUrl: strOrNull(p['image_url']),
          ),
  );
}

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<Appointment> book({required String doctorId, required DateTime day, required String from}) async =>
      appointmentFromJson(map(await _api.post('/appointments', body: {'doctor_id': doctorId, 'day': isoDay(day), 'time_from': from})));

  @override
  Future<List<Appointment>> mine({bool upcomingOnly = true}) async =>
      list(await _api.get('/appointments', query: {'upcoming_only': upcomingOnly})).map(appointmentFromJson).toList();

  @override
  Future<Appointment> reschedule(String id, {required DateTime day, required String from}) async =>
      appointmentFromJson(map(await _api.put('/appointments/$id', body: {'day': isoDay(day), 'time_from': from})));

  @override
  Future<void> cancel(String id) => _api.delete('/appointments/$id');

  @override
  Future<List<BookedSlot>> bookedSlots(String doctorId, DateTime day) async =>
      list(await _api.get('/doctors/$doctorId/booked-slots', query: {'day': isoDay(day)}))
          .map((j) => BookedSlot(day: date(j['day']) ?? day, from: str(j['time_from'])))
          .toList();
}
