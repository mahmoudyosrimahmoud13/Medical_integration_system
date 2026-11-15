import 'package:equatable/equatable.dart';

import '../../appointments/domain/appointments.dart';
import '../../doctor_portal/domain/doctor_portal.dart';
import '../../doctors/domain/doctors.dart';
import '../../pharmacy/domain/pharmacy.dart';

class HospitalDoctor extends Equatable {
  const HospitalDoctor({required this.doctor, required this.department});

  final DoctorSummary doctor;
  final String department;

  @override
  List<Object?> get props => [doctor, department];
}

class Hospital extends Equatable {
  const Hospital({
    required this.id,
    required this.name,
    required this.area,
    required this.governorate,
    this.description = '',
    this.address = '',
    this.phone,
    this.status = 'accepted',
    this.doctors = const [],
  });

  final String id;
  final String name;
  final String area;
  final String governorate;
  final String description;
  final String address;
  final String? phone;
  final String status;
  final List<HospitalDoctor> doctors;

  /// Department name -> doctors in it.
  Map<String, List<DoctorSummary>> get departments {
    final out = <String, List<DoctorSummary>>{};
    for (final d in doctors) {
      out.putIfAbsent(d.department.isEmpty ? 'General' : d.department, () => []).add(d.doctor);
    }
    return out;
  }

  @override
  List<Object?> get props => [id, status, doctors];
}

abstract class HospitalRepository {
  Future<(ApplicationStatus, Hospital?)> mine();
  Future<void> apply(FacilityApplication application);
  Future<Hospital> addDoctor(String doctorEmail, String department);
  Future<Hospital> removeDoctor(String doctorId);
  Future<List<Appointment>> appointments();
  Future<List<Hospital>> find({String? governorateId, String? areaId, String? name});
  Future<Hospital> details(String id);
}
