import 'package:equatable/equatable.dart';

class AppointmentDoctor extends Equatable {
  const AppointmentDoctor({required this.id, required this.name, required this.specialty, required this.area, required this.governorate, this.imageUrl, this.phone});

  final String id;
  final String name;
  final String specialty;
  final String area;
  final String governorate;
  final String? imageUrl;
  final String? phone;

  @override
  List<Object?> get props => [id];
}

class AppointmentPatient extends Equatable {
  const AppointmentPatient({required this.id, required this.name, required this.email, this.phone, this.gender = 'male', this.age, this.imageUrl});

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String gender;
  final int? age;
  final String? imageUrl;

  @override
  List<Object?> get props => [id];
}

class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.day,
    required this.dayName,
    required this.from,
    required this.to,
    required this.status,
    this.doctor,
    this.patient,
  });

  final String id;
  final DateTime day;
  final String dayName;
  final String from;
  final String to;
  final String status;
  final AppointmentDoctor? doctor;
  final AppointmentPatient? patient;

  @override
  List<Object?> get props => [id, day, from, status];
}

class BookedSlot extends Equatable {
  const BookedSlot({required this.day, required this.from});

  final DateTime day;
  final String from;

  @override
  List<Object?> get props => [day, from];
}

abstract class AppointmentRepository {
  Future<Appointment> book({required String doctorId, required DateTime day, required String from});
  Future<List<Appointment>> mine({bool upcomingOnly = true});
  Future<Appointment> reschedule(String id, {required DateTime day, required String from});
  Future<void> cancel(String id);
  Future<List<BookedSlot>> bookedSlots(String doctorId, DateTime day);
}
