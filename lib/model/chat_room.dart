import 'package:hive/hive.dart';

part 'chat_room.g.dart';

@HiveType(typeId: 1)
class ChatRoom extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String prompt;

  @HiveField(3)
  int userId;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  String? feedback;

  @HiveField(8)
  int? totalQuestions;

  @HiveField(9)
  int? answeredQuestions;

  ChatRoom({
    this.id,
    required this.name,
    required this.prompt,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.feedback,
    this.totalQuestions,
    this.answeredQuestions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'prompt': prompt,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'feedback': feedback,
      'total_questions': totalQuestions,
      'answered_questions': answeredQuestions,
    };
  }

  static ChatRoom fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'],
      name: map['name'],
      prompt: map['prompt'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isCompleted: map['is_completed'] == 1,
      feedback: map['feedback'],
      totalQuestions: map['total_questions'],
      answeredQuestions: map['answered_questions'],
    );
  }
}