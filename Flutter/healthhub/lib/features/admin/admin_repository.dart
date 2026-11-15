import 'package:equatable/equatable.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/json.dart';

/// One request waiting for an admin: a doctor, pharmacy or hospital.
class PendingRequest extends Equatable {
  const PendingRequest({required this.id, required this.kind, required this.title, required this.subtitle, this.details = const [], this.files = const []});

  final String id;
  final String kind; // doctor | pharmacy | hospital
  final String title;
  final String subtitle;
  final List<String> details;
  final List<String> files;

  @override
  List<Object?> get props => [id, kind];
}

abstract class AdminRepository {
  Future<List<PendingRequest>> pending(String kind);
  Future<void> review(String kind, String id, {required bool accept});
}

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<PendingRequest>> pending(String kind) async {
    switch (kind) {
      case 'doctor':
        final data = map(await _api.get('/admin/doctor-requests'));
        return list(data['items'])
            .map((j) => PendingRequest(
                  id: str(j['id']),
                  kind: kind,
                  title: 'Dr. ${str(j['name'])}',
                  subtitle: '${str(map(j['specialty'])['name'])} · ${str(map(j['area'])['key'])}',
                  details: [str(j['email']), str(j['college_name']), str(j['summary_career'])].where((s) => s.isNotEmpty).toList(),
                  files: (j['certificates'] as List? ?? const []).map((e) => e.toString()).toList(),
                ))
            .toList();
      case 'pharmacy':
      case 'hospital':
        return list(await _api.get('/admin/$kind-requests'))
            .map((j) => PendingRequest(
                  id: str(j['id']),
                  kind: kind,
                  title: str(j['name']),
                  subtitle: '${str(map(j['area'])['key'])}, ${str(map(j['governorate'])['key'])}',
                  details: [str(j['address_description']), str(j['phone']), str(j['description'])].where((s) => s.isNotEmpty).toList(),
                ))
            .toList();
      default:
        return const [];
    }
  }

  @override
  Future<void> review(String kind, String id, {required bool accept}) =>
      _api.post('/admin/$kind-requests/$id/${accept ? 'accept' : 'reject'}');
}
