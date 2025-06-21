import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 2)
class ChatMessage extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  int chatRoomId;

  @HiveField(2)
  String content;

  @HiveField(3)
  bool isUser;

  @HiveField(4)
  DateTime timestamp;

  ChatMessage({
    this.id,
    required this.chatRoomId,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'content': content,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static ChatMessage fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      chatRoomId: map['chat_room_id'],
      content: map['content'],
      isUser: map['is_user'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}