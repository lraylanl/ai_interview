import 'package:hive_flutter/hive_flutter.dart';
import '../model/user.dart';
import '../model/chat_room.dart';
import '../model/chat_message.dart';

class DatabaseHelper {
  static const String _usersBox = 'users';
  static const String _chatRoomsBox = 'chat_rooms';
  static const String _chatMessagesBox = 'chat_messages';

  static Future<void> initHive() async {
    await Hive.initFlutter();

    // 박스 열기
    await Hive.openBox<Map>(_usersBox);
    await Hive.openBox<Map>(_chatRoomsBox);
    await Hive.openBox<Map>(_chatMessagesBox);
  }

  // User operations
  static Future<int> insertUser(User user) async {
    final box = Hive.box<Map>(_usersBox);
    final id = DateTime.now().millisecondsSinceEpoch;
    final userMap = user.toMap();
    userMap['id'] = id;
    await box.put(id, userMap);
    return id;
  }

  static Future<User?> getUserByUsername(String username) async {
    final box = Hive.box<Map>(_usersBox);

    for (var key in box.keys) {
      final userMap = box.get(key);
      if (userMap != null && userMap['username'] == username) {
        return User.fromMap(Map<String, dynamic>.from(userMap));
      }
    }
    return null;
  }

  static Future<User?> getUserById(int id) async {
    final box = Hive.box<Map>(_usersBox);
    final userMap = box.get(id);
    if (userMap != null) {
      return User.fromMap(Map<String, dynamic>.from(userMap));
    }
    return null;
  }

  // Chat room operations
  static Future<int> insertChatRoom(ChatRoom chatRoom) async {
    final box = Hive.box<Map>(_chatRoomsBox);
    final id = DateTime.now().millisecondsSinceEpoch;
    final chatRoomMap = chatRoom.toMap();
    chatRoomMap['id'] = id;
    await box.put(id, chatRoomMap);
    return id;
  }

  static Future<List<ChatRoom>> getChatRoomsByUserId(int userId) async {
    final box = Hive.box<Map>(_chatRoomsBox);
    final chatRooms = <ChatRoom>[];

    for (var key in box.keys) {
      final chatRoomMap = box.get(key);
      if (chatRoomMap != null && chatRoomMap['user_id'] == userId) {
        chatRooms.add(ChatRoom.fromMap(Map<String, dynamic>.from(chatRoomMap)));
      }
    }

    // 최신순으로 정렬
    chatRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return chatRooms;
  }

  static Future<ChatRoom?> getChatRoomById(int id) async {
    final box = Hive.box<Map>(_chatRoomsBox);
    final chatRoomMap = box.get(id);
    if (chatRoomMap != null) {
      return ChatRoom.fromMap(Map<String, dynamic>.from(chatRoomMap));
    }
    return null;
  }

  static Future<void> updateChatRoom(ChatRoom chatRoom) async {
    final box = Hive.box<Map>(_chatRoomsBox);
    await box.put(chatRoom.id!, chatRoom.toMap());
  }

  static Future<void> deleteChatRoom(int id) async {
    final box = Hive.box<Map>(_chatRoomsBox);
    await box.delete(id);

    // 관련 메시지도 삭제
    final messagesBox = Hive.box<Map>(_chatMessagesBox);
    final keysToDelete = <dynamic>[];

    for (var key in messagesBox.keys) {
      final messageMap = messagesBox.get(key);
      if (messageMap != null && messageMap['chat_room_id'] == id) {
        keysToDelete.add(key);
      }
    }

    for (var key in keysToDelete) {
      await messagesBox.delete(key);
    }
  }

  // Chat message operations
  static Future<int> insertChatMessage(ChatMessage message, int chatRoomId) async {
    final box = Hive.box<Map>(_chatMessagesBox);
    final id = DateTime.now().millisecondsSinceEpoch;
    final messageMap = message.toMap();
    messageMap['id'] = id;
    messageMap['chat_room_id'] = chatRoomId;
    await box.put(id, messageMap);
    return id;
  }

  static Future<List<ChatMessage>> getChatMessagesByChatRoomId(int chatRoomId) async {
    final box = Hive.box<Map>(_chatMessagesBox);
    final messages = <ChatMessage>[];

    for (var key in box.keys) {
      final messageMap = box.get(key);
      if (messageMap != null && messageMap['chat_room_id'] == chatRoomId) {
        messages.add(ChatMessage.fromMap(Map<String, dynamic>.from(messageMap)));
      }
    }

    // 시간순으로 정렬
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }
}