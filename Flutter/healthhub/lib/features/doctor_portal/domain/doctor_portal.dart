import 'package:equatable/equatable.dart';

import '../../appointments/domain/appointments.dart';
import '../../doctors/domain/doctors.dart';

/// none | pending | rejected | accepted
class ApplicationStatus extends Equatable {
  const ApplicationStatus({required this.status, this.accessToken});

  final String status;
  final String? accessToken;

  bool get isNone => status == 'none';
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  @override
  List<Object?> get props => [status];
}

class DoctorStats extends Equatable {
  const DoctorStats({this.total = 0, this.male = 0, this.female = 0, this.upcoming = 0});

  final int total;
  final int male;
  final int female;
  final int upcoming;

  @override
  List<Object?> get props => [total, male, female, upcoming];
}

class DoctorApplication {
  const DoctorApplication({
    required this.specialtyId,
    required this.areaId,
    required this.college,
    this.graduationYear,
    this.summary = '',
    this.address = '',
    this.certificates = const [],
  });

  final String specialtyId;
  final String areaId;
  final String college;
  final DateTime? graduationYear;
  final String summary;
  final String address;
  final List<({List<int> bytes, String name})> certificates;
}

abstract class DoctorPortalRepository {
  Future<ApplicationStatus> status();
  Future<ApplicationStatus> apply(DoctorApplication application);
  Future<List<ScheduleDay>> schedule();
  Future<List<ScheduleDay>> saveSchedule(List<ScheduleDay> days);
  Future<void> setPrice(double price);
  Future<List<Appointment>> appointments({bool upcomingOnly = true});
  Future<void> cancelAppointment(String id);
  Future<DoctorStats> stats();
}
