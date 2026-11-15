import 'package:equatable/equatable.dart';

import '../../auth/domain/auth.dart';

class Prescription extends Equatable {
  const Prescription({
    required this.id,
    required this.drugId,
    required this.drugName,
    this.note,
    this.repeat,
    this.repeatCount = 1,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String drugId;
  final String drugName;
  final String? note;
  final String? repeat;
  final int repeatCount;
  final DateTime? startDate;
  final DateTime? endDate;

  bool isActiveOn(DateTime day) => endDate == null || !endDate!.isBefore(DateTime(day.year, day.month, day.day));

  @override
  List<Object?> get props => [id, drugId, endDate];
}

class SessionDoctor extends Equatable {
  const SessionDoctor({required this.id, required this.name, required this.specialty, this.email = '', this.phone, this.imageUrl});

  final String id;
  final String name;
  final String specialty;
  final String email;
  final String? phone;
  final String? imageUrl;

  @override
  List<Object?> get props => [id];
}

class MedicalSession extends Equatable {
  const MedicalSession({
    required this.id,
    required this.date,
    required this.diseaseName,
    required this.doctor,
    required this.prescriptions,
    this.notes,
  });

  final String id;
  final DateTime date;
  final String diseaseName;
  final String? notes;
  final SessionDoctor doctor;
  final List<Prescription> prescriptions;

  @override
  List<Object?> get props => [id];
}

class Disease extends Equatable {
  const Disease({required this.id, required this.name, this.persistent = false, this.cured = false, this.notes, this.doctor});

  final String id;
  final String name;
  final bool persistent;
  final bool cured;
  final String? notes;
  final String? doctor;

  @override
  List<Object?> get props => [id, cured];
}

class CtScan extends Equatable {
  const CtScan({required this.id, required this.url, this.result, this.uploadedAt});

  final String id;
  final String url;
  final String? result;
  final DateTime? uploadedAt;

  @override
  List<Object?> get props => [id];
}

class MedicalRecord extends Equatable {
  const MedicalRecord({
    required this.patient,
    this.diseases = const [],
    this.currentPrescriptions = const [],
    this.sessions = const [],
    this.ctScans = const [],
  });

  final User patient;
  final List<Disease> diseases;
  final List<Prescription> currentPrescriptions;
  final List<MedicalSession> sessions;
  final List<CtScan> ctScans;

  List<Disease> get chronic => diseases.where((d) => d.persistent && !d.cured).toList();

  @override
  List<Object?> get props => [patient, diseases, currentPrescriptions, sessions, ctScans];
}

class InteractionPair extends Equatable {
  const InteractionPair({required this.drugA, required this.drugB, required this.description, this.interacts});

  final String drugA;
  final String drugB;
  final bool? interacts; // null = the model could not answer
  final String description;

  @override
  List<Object?> get props => [drugA, drugB, interacts];
}

class InteractionReport extends Equatable {
  const InteractionReport({required this.available, required this.impact, required this.pairs});

  final bool available;
  final bool impact;
  final List<InteractionPair> pairs;

  @override
  List<Object?> get props => [available, impact, pairs];
}

class ShareCode extends Equatable {
  const ShareCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [code];
}

class NewPrescription {
  const NewPrescription({required this.drugId, required this.drugName, this.note, this.repeat, this.repeatCount = 1, this.startDate, this.endDate});

  final String drugId;
  final String drugName;
  final String? note;
  final String? repeat;
  final int repeatCount;
  final DateTime? startDate;
  final DateTime? endDate;
}

class NewSession {
  const NewSession({
    required this.patientEmail,
    required this.diseaseName,
    this.sessionNotes,
    this.diseaseNotes,
    this.persistent = false,
    this.cured = false,
    this.prescriptions = const [],
  });

  final String patientEmail;
  final String diseaseName;
  final String? sessionNotes;
  final String? diseaseNotes;
  final bool persistent;
  final bool cured;
  final List<NewPrescription> prescriptions;
}

abstract class RecordsRepository {
  Future<MedicalRecord> myRecord();
  Future<MedicalRecord> patientRecord(String email);
  Future<MedicalSession> writeSession(NewSession session);
  Future<InteractionReport> checkInteractions(String patientEmail, List<String> drugIds);
  Future<ShareCode> shareCode();
  Future<CtScan> uploadCt(List<int> bytes, String fileName);
}
