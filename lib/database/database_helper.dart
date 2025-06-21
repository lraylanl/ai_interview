import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/user.dart';
import '../model/chat_room.dart';
import '../model/chat_message.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_interview.db');

    return await openDatabase(
      path,
      version: 2, // 버전 업데이트
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Chat rooms table (업데이트된 스키마)
    await db.execute('''
      CREATE TABLE chat_rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        prompt TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        feedback TEXT,
        total_questions INTEGER,
        answered_questions INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Chat messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chat_room_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (chat_room_id) REFERENCES chat_rooms (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 기존 테이블에 새 컬럼 추가
      await db.execute('ALTER TABLE chat_rooms ADD COLUMN is_completed INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE chat_rooms ADD COLUMN feedback TEXT');
      await db.execute('ALTER TABLE chat_rooms ADD COLUMN total_questions INTEGER');
      await db.execute('ALTER TABLE chat_rooms ADD COLUMN answered_questions INTEGER');
    }
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // Chat room operations
  Future<int> insertChatRoom(ChatRoom chatRoom) async {
    final db = await database;
    return await db.insert('chat_rooms', chatRoom.toMap());
  }

  Future<List<ChatRoom>> getChatRoomsByUserId(int userId) async {
    final db = await database;
    final result = await db.query(
      'chat_rooms',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return result.map((map) => ChatRoom.fromMap(map)).toList();
  }

  Future<void> updateChatRoomUpdatedAt(int chatRoomId) async {
    final db = await database;
    await db.update(
      'chat_rooms',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [chatRoomId],
    );
  }

  Future<void> completeChatRoom(int chatRoomId, String feedback, int totalQuestions, int answeredQuestions) async {
    final db = await database;
    await db.update(
      'chat_rooms',
      {
        'is_completed': 1,
        'feedback': feedback,
        'total_questions': totalQuestions,
        'answered_questions': answeredQuestions,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [chatRoomId],
    );
  }

  Future<ChatRoom?> getChatRoomById(int chatRoomId) async {
    final db = await database;
    final result = await db.query(
      'chat_rooms',
      where: 'id = ?',
      whereArgs: [chatRoomId],
    );

    if (result.isNotEmpty) {
      return ChatRoom.fromMap(result.first);
    }
    return null;
  }

  Future<void> deleteChatRoom(int chatRoomId) async {
    final db = await database;
    await db.delete('chat_messages', where: 'chat_room_id = ?', whereArgs: [chatRoomId]);
    await db.delete('chat_rooms', where: 'id = ?', whereArgs: [chatRoomId]);
  }

  // Chat message operations
  Future<int> insertChatMessage(ChatMessage message) async {
    final db = await database;
    return await db.insert('chat_messages', message.toMap());
  }

  Future<List<ChatMessage>> getChatMessagesByRoomId(int chatRoomId) async {
    final db = await database;
    final result = await db.query(
      'chat_messages',
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'timestamp ASC',
    );

    return result.map((map) => ChatMessage.fromMap(map)).toList();
  }
}