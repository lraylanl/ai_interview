class ChatRoom {
  final int? id;
  final String name;
  final String prompt;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final String? feedback;
  final int? totalQuestions;
  final int? answeredQuestions;

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

  ChatRoom copyWith({
    int? id,
    String? name,
    String? prompt,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    String? feedback,
    int? totalQuestions,
    int? answeredQuestions,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      prompt: prompt ?? this.prompt,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      feedback: feedback ?? this.feedback,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      answeredQuestions: answeredQuestions ?? this.answeredQuestions,
    );
  }
}