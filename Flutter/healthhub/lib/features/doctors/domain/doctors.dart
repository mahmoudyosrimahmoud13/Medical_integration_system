import 'package:equatable/equatable.dart';

class ScheduleDay extends Equatable {
  const ScheduleDay({required this.day, required this.from, required this.to});

  final String day; // Monday..Sunday
  final String from; // "09:00 AM"
  final String to;

  @override
  List<Object?> get props => [day, from, to];
}

class DoctorSummary extends Equatable {
  const DoctorSummary({
    required this.id,
    required this.name,
    required this.specialty,
    required this.area,
    required this.governorate,
    this.imageUrl,
    this.phone,
    this.address = '',
    this.price = 0,
    this.ratingStars = 0,
    this.reviewCount = 0,
  });

  final String id;
  final String name;
  final String specialty;
  final String area;
  final String governorate;
  final String? imageUrl;
  final String? phone;
  final String address;
  final double price;
  final double ratingStars;
  final int reviewCount;

  @override
  List<Object?> get props => [id, name, ratingStars, reviewCount];
}

class Doctor extends DoctorSummary {
  const Doctor({
    required super.id,
    required super.name,
    required super.specialty,
    required super.area,
    required super.governorate,
    super.imageUrl,
    super.phone,
    super.address,
    super.price,
    super.ratingStars,
    super.reviewCount,
    this.email = '',
    this.gender = 'male',
    this.college = '',
    this.summary = '',
    this.graduationYear,
    this.schedule = const [],
    this.certificates = const [],
    this.userId = '',
  });

  final String userId; // the doctor's account, used to start a chat
  final String email;
  final String gender;
  final String college;
  final String summary;
  final DateTime? graduationYear;
  final List<ScheduleDay> schedule;
  final List<String> certificates;
}

class Review extends Equatable {
  const Review({required this.id, required this.rate, required this.message, required this.patientName, this.sentAt});

  final String id;
  final double rate;
  final String message;
  final String patientName;
  final DateTime? sentAt;

  @override
  List<Object?> get props => [id, rate, message];
}

class DoctorPage extends Equatable {
  const DoctorPage({required this.items, required this.total, required this.page});

  final List<DoctorSummary> items;
  final int total;
  final int page;

  @override
  List<Object?> get props => [items, total, page];
}

enum DoctorSort { none, rate, join }

class DoctorFilter extends Equatable {
  const DoctorFilter({this.specialtyId, this.governorateId, this.areaId, this.name, this.sort = DoctorSort.none});

  final String? specialtyId;
  final String? governorateId;
  final String? areaId;
  final String? name;
  final DoctorSort sort;

  DoctorFilter copyWith({
    String? Function()? specialtyId,
    String? Function()? governorateId,
    String? Function()? areaId,
    String? Function()? name,
    DoctorSort? sort,
  }) =>
      DoctorFilter(
        specialtyId: specialtyId != null ? specialtyId() : this.specialtyId,
        governorateId: governorateId != null ? governorateId() : this.governorateId,
        areaId: areaId != null ? areaId() : this.areaId,
        name: name != null ? name() : this.name,
        sort: sort ?? this.sort,
      );

  @override
  List<Object?> get props => [specialtyId, governorateId, areaId, name, sort];
}

abstract class DoctorRepository {
  Future<DoctorPage> search(DoctorFilter filter, {int page = 0});
  Future<Doctor> details(String id);
  Future<List<Review>> reviews(String doctorId);
  Future<void> addReview(String doctorId, double rate, String message);
}
