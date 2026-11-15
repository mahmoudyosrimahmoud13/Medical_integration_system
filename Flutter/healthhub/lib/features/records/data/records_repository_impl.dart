import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import '../../auth/data/auth_repository_impl.dart';
import '../domain/records.dart';

Prescription prescriptionFromJson(Map<String, dynamic> j) => Prescription(
      id: str(j['id']),
      drugId: str(j['drug_id']),
      drugName: str(j['drug_name']),
      note: strOrNull(j['note']),
      repeat: strOrNull(j['repeat']),
      repeatCount: integer(j['repeat_count'], 1),
      startDate: date(j['start_date']),
      endDate: date(j['end_date']),
    );

MedicalSession sessionFromJson(Map<String, dynamic> j) {
  final d = map(j['doctor']);
  return MedicalSession(
    id: str(j['id']),
    date: date(j['session_date']) ?? DateTime.now(),
    diseaseName: str(j['disease_name']),
    notes: strOrNull(j['notes']),
    doctor: SessionDoctor(
      id: str(d['id']),
      name: str(d['name']),
      specialty: str(d['specialty']),
      email: str(d['email']),
      phone: strOrNull(d['phone']),
      imageUrl: strOrNull(d['image_url']),
    ),
    prescriptions: list(j['prescriptions']).map(prescriptionFromJson).toList(),
  );
}

MedicalRecord recordFromJson(Map<String, dynamic> j) => MedicalRecord(
      patient: userFromJson(map(j['patient'])),
      diseases: list(j['diseases'])
          .map((d) => Disease(
                id: str(d['id']),
                name: str(d['name']),
                persistent: boolean(d['persistent']),
                cured: boolean(d['cured']),
                notes: strOrNull(d['notes']),
                doctor: strOrNull(d['responsible_doctor']),
              ))
          .toList(),
      currentPrescriptions: list(j['current_prescriptions']).map(prescriptionFromJson).toList(),
      sessions: list(j['sessions']).map(sessionFromJson).toList(),
      ctScans: list(j['ct_scans']).map(ctFromJson).toList(),
    );

CtScan ctFromJson(Map<String, dynamic> j) =>
    CtScan(id: str(j['id']), url: str(j['url']), result: strOrNull(j['result']), uploadedAt: date(j['uploaded_at']));

class RecordsRepositoryImpl implements RecordsRepository {
  RecordsRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<MedicalRecord> myRecord() async => recordFromJson(map(await _api.get('/medical/record')));

  @override
  Future<MedicalRecord> patientRecord(String email) async =>
      recordFromJson(map(await _api.get('/medical/patients/${Uri.encodeComponent(email.trim())}/record')));

  @override
  Future<MedicalSession> writeSession(NewSession s) async => sessionFromJson(map(await _api.post('/medical/sessions', body: {
        'patient_email': s.patientEmail.trim(),
        'disease_name': s.diseaseName.trim(),
        'session_notes': s.sessionNotes,
        'disease_notes': s.diseaseNotes,
        'persistent': s.persistent,
        'cured': s.cured,
        'prescriptions': [
          for (final p in s.prescriptions)
            {
              'drug_id': p.drugId,
              'note': p.note,
              'repeat': p.repeat,
              'repeat_count': p.repeatCount,
              'start_date': p.startDate == null ? null : isoDay(p.startDate!),
              'end_date': p.endDate == null ? null : isoDay(p.endDate!),
            }
        ],
      })));

  @override
  Future<InteractionReport> checkInteractions(String patientEmail, List<String> drugIds) async {
    final j = map(await _api.post('/medical/interactions/check', body: {'patient_email': patientEmail.trim(), 'drug_ids': drugIds}));
    return InteractionReport(
      available: boolean(j['available']),
      impact: boolean(j['impact']),
      pairs: list(j['results'])
          .map((r) => InteractionPair(
                drugA: str(r['drugA']),
                drugB: str(r['drugB']),
                interacts: r['interacts'] == null ? null : boolean(r['interacts']),
                description: str(r['description']),
              ))
          .toList(),
    );
  }

  @override
  Future<ShareCode> shareCode() async {
    final j = map(await _api.post('/medical/share-code'));
    return ShareCode(code: str(j['code']), expiresAt: date(j['expires_at']) ?? DateTime.now().add(const Duration(minutes: 30)));
  }

  @override
  Future<CtScan> uploadCt(List<int> bytes, String fileName) async => ctFromJson(map(await _api.upload('/medical/ct-scans',
      files: {'file': [UploadFile(bytes: Uint8List.fromList(bytes), name: fileName)]})));
}
