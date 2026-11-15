import 'package:equatable/equatable.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/json.dart';

class AppNotification extends Equatable {
  const AppNotification({required this.id, required this.type, required this.message, required this.isRead, this.createdAt});

  final String id;
  final String type;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, isRead];
}

abstract class NotificationRepository {
  Future<List<AppNotification>> all();
  Future<void> markRead(String id);
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<AppNotification>> all() async => list(await _api.get('/notifications'))
      .map((j) => AppNotification(
            id: str(j['id']),
            type: str(j['type']),
            message: str(j['message']),
            isRead: boolean(j['is_read']),
            createdAt: date(j['created_at']),
          ))
      .toList();

  @override
  Future<void> markRead(String id) => _api.post('/notifications/$id/read');
}
