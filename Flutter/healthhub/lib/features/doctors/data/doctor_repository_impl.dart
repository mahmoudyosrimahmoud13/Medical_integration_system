import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import '../domain/doctors.dart';
import '../../../core/i18n/i18n.dart';

ScheduleDay scheduleFromJson(Map<String, dynamic> j) =>
    ScheduleDay(day: str(j['day_name']), from: str(j['time_from']), to: str(j['time_to']));

DoctorSummary doctorSummaryFromJson(Map<String, dynamic> j) => DoctorSummary(
      id: str(j['id']),
      name: str(j['name']),
      specialty: str(map(j['specialty'])['name']),
      area: rememberPlace(j['area']),
      governorate: rememberPlace(j['governorate']),
      imageUrl: strOrNull(j['image_url']),
      phone: strOrNull(j['phone']),
      address: str(j['address_description']),
      price: number(j['price_session']),
      ratingStars: number(j['rating_stars']),
      reviewCount: integer(j['review_count']),
    );

Doctor doctorFromJson(Map<String, dynamic> j) {
  final s = doctorSummaryFromJson(j);
  return Doctor(
    id: s.id,
    name: s.name,
    specialty: s.specialty,
    area: s.area,
    governorate: s.governorate,
    imageUrl: s.imageUrl,
    phone: s.phone,
    address: s.address,
    price: s.price,
    ratingStars: s.ratingStars,
    reviewCount: s.reviewCount,
    userId: str(j['user_id']),
    email: str(j['email']),
    gender: str(j['gender'], 'male'),
    college: str(j['college_name']),
    summary: str(j['summary_career']),
    graduationYear: date(j['graduation_year']),
    schedule: list(j['schedule']).map(scheduleFromJson).toList(),
    certificates: (j['certificates'] as List? ?? const []).map((e) => e.toString()).toList(),
  );
}

Review reviewFromJson(Map<String, dynamic> j) => Review(
      id: str(j['id']),
      rate: number(j['rate']),
      message: str(j['message']),
      patientName: str(j['patient_name']),
      sentAt: date(j['sent_at']),
    );

class DoctorRepositoryImpl implements DoctorRepository {
  DoctorRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<DoctorPage> search(DoctorFilter f, {int page = 0}) async {
    final data = map(await _api.get('/doctors', query: {
      'specialty_id': f.specialtyId,
      'governorate_id': f.governorateId,
      'area_id': f.areaId,
      'name': (f.name?.trim().length ?? 0) >= 2 ? f.name!.trim() : null,
      'sort': f.sort.name,
      'page': page,
    }));
    return DoctorPage(
      items: list(data['items']).map(doctorSummaryFromJson).toList(),
      total: integer(data['total']),
      page: integer(data['page']),
    );
  }

  @override
  Future<Doctor> details(String id) async => doctorFromJson(map(await _api.get('/doctors/$id')));

  @override
  Future<List<Review>> reviews(String doctorId) async =>
      list(await _api.get('/doctors/$doctorId/reviews')).map(reviewFromJson).toList();

  @override
  Future<void> addReview(String doctorId, double rate, String message) =>
      _api.post('/doctors/$doctorId/reviews', body: {'rate': rate, 'message': message});
}
