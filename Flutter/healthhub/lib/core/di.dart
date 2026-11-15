import '../features/admin/admin_repository.dart';
import '../features/appointments/data/appointment_repository_impl.dart';
import '../features/appointments/domain/appointments.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/auth.dart';
import '../features/catalog/data/catalog_repository_impl.dart';
import '../features/catalog/domain/catalog.dart';
import '../features/doctor_portal/data/doctor_portal_repository_impl.dart';
import '../features/doctor_portal/domain/doctor_portal.dart';
import '../features/doctors/data/doctor_repository_impl.dart';
import '../features/doctors/domain/doctors.dart';
import '../features/hospital/data/hospital_repository_impl.dart';
import '../features/hospital/domain/hospital.dart';
import '../features/notifications/notifications.dart';
import '../features/pharmacy/data/pharmacy_repository_impl.dart';
import '../features/pharmacy/domain/pharmacy.dart';
import '../features/records/data/records_repository_impl.dart';
import '../features/records/domain/records.dart';
import 'network/api_client.dart';
import 'storage/token_storage.dart';

/// Holds every repository. Screens read it with `context.read<Deps>()`.
/// Tests build it with fakes through the named constructor.
class Deps {
  Deps({
    required this.tokens,
    required this.auth,
    required this.catalog,
    required this.doctors,
    required this.appointments,
    required this.records,
    required this.doctorPortal,
    required this.pharmacy,
    required this.hospital,
    required this.notifications,
    required this.admin,
  });

  factory Deps.fromApi(ApiClient api, TokenStorage tokens) => Deps(
        tokens: tokens,
        auth: AuthRepositoryImpl(api, tokens),
        catalog: CatalogRepositoryImpl(api),
        doctors: DoctorRepositoryImpl(api),
        appointments: AppointmentRepositoryImpl(api),
        records: RecordsRepositoryImpl(api),
        doctorPortal: DoctorPortalRepositoryImpl(api),
        pharmacy: PharmacyRepositoryImpl(api),
        hospital: HospitalRepositoryImpl(api),
        notifications: NotificationRepositoryImpl(api),
        admin: AdminRepositoryImpl(api),
      );

  final TokenStorage tokens;
  final AuthRepository auth;
  final CatalogRepository catalog;
  final DoctorRepository doctors;
  final AppointmentRepository appointments;
  final RecordsRepository records;
  final DoctorPortalRepository doctorPortal;
  final PharmacyRepository pharmacy;
  final HospitalRepository hospital;
  final NotificationRepository notifications;
  final AdminRepository admin;
}
