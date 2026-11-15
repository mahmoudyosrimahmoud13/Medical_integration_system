import 'package:equatable/equatable.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/json.dart';

class Contact extends Equatable {
  const Contact({required this.userId, required this.name, required this.role, required this.context, this.imageUrl});

  final String userId;
  final String name;
  final String role; // Doctor | Patient | Pharmacy | Hospital | Support
  final String context; // why you can talk to them
  final String? imageUrl;

  @override
  List<Object?> get props => [userId];
}

class ChatMessage extends Equatable {
  const ChatMessage({required this.id, required this.senderId, required this.senderName, required this.text, required this.sentAt, required this.mine, this.readAt});

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool mine;

  @override
  List<Object?> get props => [id, readAt];
}

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.otherId,
    required this.otherName,
    required this.otherRole,
    required this.subject,
    required this.unread,
    required this.lastMessageAt,
    this.otherImageUrl,
    this.lastMessage,
  });

  final String id;
  final String otherId;
  final String otherName;
  final String otherRole;
  final String? otherImageUrl;
  final String subject;
  final ChatMessage? lastMessage;
  final int unread;
  final DateTime lastMessageAt;

  @override
  List<Object?> get props => [id, unread, lastMessage];
}

abstract class ChatRepository {
  Future<List<Contact>> contacts();
  Future<List<Conversation>> conversations();
  Future<Conversation> start(String userId, {String subject = '', String? firstMessage});
  Future<List<ChatMessage>> messages(String conversationId, {DateTime? after});
  Future<ChatMessage> send(String conversationId, String text);
  Future<int> unreadCount();
}

ChatMessage messageFromJson(Map<String, dynamic> j) => ChatMessage(
      id: str(j['id']),
      senderId: str(j['sender_id']),
      senderName: str(j['sender_name']),
      text: str(j['text']),
      sentAt: date(j['sent_at']) ?? DateTime.now(),
      readAt: date(j['read_at']),
      mine: boolean(j['mine']),
    );

Conversation conversationFromJson(Map<String, dynamic> j) {
  final other = map(j['other']);
  return Conversation(
    id: str(j['id']),
    otherId: str(other['id']),
    otherName: str(other['name']),
    otherRole: str(j['other_role']),
    otherImageUrl: strOrNull(other['image_url']),
    subject: str(j['subject']),
    lastMessage: j['last_message'] == null ? null : messageFromJson(map(j['last_message'])),
    unread: integer(j['unread']),
    lastMessageAt: date(j['last_message_at']) ?? DateTime.now(),
  );
}

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<Contact>> contacts() async => list(await _api.get('/chat/contacts'))
      .map((j) => Contact(userId: str(j['user_id']), name: str(j['name']), role: str(j['role']), context: str(j['context']), imageUrl: strOrNull(j['image_url'])))
      .toList();

  @override
  Future<List<Conversation>> conversations() async => list(await _api.get('/chat/conversations')).map(conversationFromJson).toList();

  @override
  Future<Conversation> start(String userId, {String subject = '', String? firstMessage}) async =>
      conversationFromJson(map(await _api.post('/chat/conversations', body: {'user_id': userId, 'subject': subject, 'first_message': firstMessage})));

  @override
  Future<List<ChatMessage>> messages(String conversationId, {DateTime? after}) async =>
      list(await _api.get('/chat/conversations/$conversationId/messages', query: {'after': after?.toUtc().toIso8601String(), 'limit': 100}))
          .map(messageFromJson)
          .toList();

  @override
  Future<ChatMessage> send(String conversationId, String text) async =>
      messageFromJson(map(await _api.post('/chat/conversations/$conversationId/messages', body: {'text': text})));

  @override
  Future<int> unreadCount() async => integer(map(await _api.get('/chat/unread'))['unread']);
}
