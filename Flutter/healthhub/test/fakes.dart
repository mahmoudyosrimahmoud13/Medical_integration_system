import 'package:healthhub/core/di.dart';
import 'package:healthhub/core/network/api_exception.dart';
import 'package:healthhub/core/storage/token_storage.dart';
import 'package:healthhub/features/admin/admin_repository.dart';
import 'package:healthhub/features/appointments/domain/appointments.dart';
import 'package:healthhub/features/auth/domain/auth.dart';
import 'package:healthhub/features/catalog/domain/catalog.dart';
import 'package:healthhub/features/chat/chat.dart';
import 'package:healthhub/features/doctor_portal/domain/doctor_portal.dart';
import 'package:healthhub/features/doctors/domain/doctors.dart';
import 'package:healthhub/features/hospital/domain/hospital.dart';
import 'package:healthhub/features/notifications/notifications.dart';
import 'package:healthhub/features/pharmacy/domain/pharmacy.dart';
import 'package:healthhub/features/records/domain/records.dart';

const fakePatient = User(id: 'u1', name: 'Sara Ali', email: 'sara@test.local', roles: ['Patient']);

const cardiology = Specialty(id: 's1', name: 'Cardiology');
const cairo = Governorate(id: 'g1', name: 'Cairo');
const maadi = Area(id: 'a1', name: 'Maadi', governorateId: 'g1');

// The demo doctor works tomorrow and the day after, never today, so slot tests don't depend on the clock.
String _dayName(int offset) => const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][
    (DateTime.now().add(Duration(days: offset)).weekday - 1) % 7];

final fakeDoctor = Doctor(
  id: 'd1',
  name: 'Ahmed Hassan',
  specialty: 'Cardiology',
  area: 'Maadi',
  governorate: 'Cairo',
  price: 300,
  ratingStars: 4.5,
  reviewCount: 12,
  college: 'Cairo University',
  schedule: [ScheduleDay(day: _dayName(1), from: '09:00 AM', to: '05:00 PM'), ScheduleDay(day: _dayName(2), from: '09:00 AM', to: '05:00 PM')],
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.sessionSaved = false});
  bool sessionSaved;
  int loginCalls = 0;

  @override
  bool get hasSession => sessionSaved;
  @override
  Future<User> login(String login, String password) async {
    loginCalls++;
    if (password != 'ok') throw const ApiException('Email Or Password Incorrect', statusCode: 401);
    sessionSaved = true;
    return fakePatient;
  }

  @override
  Future<User> me() async => fakePatient;
  @override
  Future<void> logout() async => sessionSaved = false;
  @override
  Future<void> register(RegisterData data) async {}
  @override
  Future<void> forgotPassword(String email) async {}
  @override
  Future<void> resetPassword(String code, String newPassword) async {}
  @override
  Future<User> changePhoto(List<int> bytes, String fileName) async => fakePatient;
  @override
  Future<void> useToken(String token) async {}
}

class FakeCatalog implements CatalogRepository {
  @override
  Future<List<Governorate>> governorates() async => const [cairo];
  @override
  Future<List<Area>> areas(String governorateId) async => const [maadi];
  @override
  Future<List<Specialty>> specialties() async => const [cardiology];
  @override
  Future<List<Drug>> searchDrugs(String query) async => const [Drug(id: 'DB00316', name: 'Acetaminophen')];
  @override
  Future<List<Product>> searchProducts(String query) async =>
      const [Product(id: 1, brand: 'Panadol', drugId: 'DB00316', activeIngredient: 'Acetaminophen', strength: '500 mg', price: 36)];
}

class FakeDoctors implements DoctorRepository {
  @override
  Future<DoctorPage> search(DoctorFilter filter, {int page = 0}) async => DoctorPage(items: [fakeDoctor], total: 1, page: 0);
  @override
  Future<Doctor> details(String id) async => fakeDoctor;
  @override
  Future<List<Review>> reviews(String doctorId) async => const [];
  @override
  Future<void> addReview(String doctorId, double rate, String message) async {}
}

class FakeAppointments implements AppointmentRepository {
  final booked = <Appointment>[];

  @override
  Future<Appointment> book({required String doctorId, required DateTime day, required String from}) async {
    final a = Appointment(id: 'ap${booked.length + 1}', day: day, dayName: 'Monday', from: from, to: from, status: 'booked');
    booked.add(a);
    return a;
  }

  @override
  Future<List<Appointment>> mine({bool upcomingOnly = true}) async => booked;
  @override
  Future<Appointment> reschedule(String id, {required DateTime day, required String from}) async => booked.first;
  @override
  Future<void> cancel(String id) async => booked.removeWhere((a) => a.id == id);
  @override
  Future<List<BookedSlot>> bookedSlots(String doctorId, DateTime day) async => const [];
}

class FakeRecords implements RecordsRepository {
  @override
  Future<MedicalRecord> myRecord() async => const MedicalRecord(patient: fakePatient);
  @override
  Future<MedicalRecord> patientRecord(String email) async => const MedicalRecord(patient: fakePatient);
  @override
  Future<MedicalSession> writeSession(NewSession session) => throw UnimplementedError();
  @override
  Future<InteractionReport> checkInteractions(String patientEmail, List<String> drugIds) async =>
      const InteractionReport(available: true, impact: false, pairs: []);
  @override
  Future<ShareCode> shareCode() async => ShareCode(code: 'ABC123', expiresAt: DateTime.now().add(const Duration(minutes: 30)));
  @override
  Future<CtScan> uploadCt(List<int> bytes, String fileName) => throw UnimplementedError();
}

class FakeDoctorPortal implements DoctorPortalRepository {
  @override
  Future<ApplicationStatus> status() async => const ApplicationStatus(status: 'none');
  @override
  Future<ApplicationStatus> apply(DoctorApplication application) async => const ApplicationStatus(status: 'pending');
  @override
  Future<List<ScheduleDay>> schedule() async => const [];
  @override
  Future<List<ScheduleDay>> saveSchedule(List<ScheduleDay> days) async => days;
  @override
  Future<void> setPrice(double price) async {}
  @override
  Future<List<Appointment>> appointments({bool upcomingOnly = true}) async => const [];
  @override
  Future<void> cancelAppointment(String id) async {}
  @override
  Future<DoctorStats> stats() async => const DoctorStats();
}

class FakePharmacy implements PharmacyRepository {
  @override
  Future<(ApplicationStatus, Pharmacy?)> mine() async => (const ApplicationStatus(status: 'none'), null);
  @override
  Future<void> apply(FacilityApplication application) async {}
  @override
  Future<List<StockItem>> stock() async => const [];
  @override
  Future<StockItem> setStock(String drugId, int quantity, double price) async => StockItem(drugId: drugId, drugName: drugId, quantity: quantity, price: price);
  @override
  Future<void> removeStock(String drugId) async {}
  @override
  Future<SharedPrescriptions> prescriptionsByCode(String code) async => const SharedPrescriptions(patientName: 'Sara Ali', prescriptions: []);
  @override
  Future<List<Pharmacy>> find({String? drugId, String? governorateId, String? areaId}) async => const [];
}

class FakeHospital implements HospitalRepository {
  @override
  Future<(ApplicationStatus, Hospital?)> mine() async => (const ApplicationStatus(status: 'none'), null);
  @override
  Future<void> apply(FacilityApplication application) async {}
  @override
  Future<Hospital> addDoctor(String doctorEmail, String department) => throw UnimplementedError();
  @override
  Future<Hospital> removeDoctor(String doctorId) => throw UnimplementedError();
  @override
  Future<List<Appointment>> appointments() async => const [];
  @override
  Future<List<Hospital>> find({String? governorateId, String? areaId, String? name}) async => const [];
  @override
  Future<Hospital> details(String id) => throw UnimplementedError();
}

class FakeNotifications implements NotificationRepository {
  @override
  Future<List<AppNotification>> all() async => const [];
  @override
  Future<void> markRead(String id) async {}
}

class FakeAdmin implements AdminRepository {
  @override
  Future<List<PendingRequest>> pending(String kind) async => const [];
  @override
  Future<void> review(String kind, String id, {required bool accept}) async {}
}

class FakeChat implements ChatRepository {
  @override
  Future<List<Contact>> contacts() async => const [];
  @override
  Future<List<Conversation>> conversations() async => const [];
  @override
  Future<Conversation> start(String userId, {String subject = '', String? firstMessage}) => throw UnimplementedError();
  @override
  Future<List<ChatMessage>> messages(String conversationId, {DateTime? after}) async => const [];
  @override
  Future<ChatMessage> send(String conversationId, String text) => throw UnimplementedError();
  @override
  Future<int> unreadCount() async => 0;
}

Deps fakeDeps({TokenStorage? tokens, bool sessionSaved = false}) => Deps(
      tokens: tokens ?? TokenStorage.memory(),
      auth: FakeAuthRepository(sessionSaved: sessionSaved),
      catalog: FakeCatalog(),
      doctors: FakeDoctors(),
      appointments: FakeAppointments(),
      records: FakeRecords(),
      doctorPortal: FakeDoctorPortal(),
      pharmacy: FakePharmacy(),
      hospital: FakeHospital(),
      notifications: FakeNotifications(),
      admin: FakeAdmin(),
      chat: FakeChat(),
    );
