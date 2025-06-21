import 'package:hive_flutter/hive_flutter.dart';
import '../model/user.dart';
import '../model/chat_room.dart';
import '../model/chat_message.dart';

/// 모든 Hive 데이터베이스 관련 작업을 중앙에서 관리하는 서비스 클래스
class DatabaseService {
  // Hive Box 인스턴스
  Box<User> get _userBox => Hive.box<User>('users');
  Box<ChatRoom> get _chatRoomBox => Hive.box<ChatRoom>('chatRooms');
  Box<ChatMessage> get _chatMessageBox => Hive.box<ChatMessage>('chatMessages');

  // --- User 관련 메서드 ---

  Future<int> addUser(User user) async {
    final key = await _userBox.add(user);
    user.id = key;
    await user.save();
    return key;
  }

  User? getUserByUsername(String username) {
    try {
      return _userBox.values.firstWhere((user) => user.username == username);
    } catch (e) {
      return null; // 사용자를 찾지 못한 경우
    }
  }

  User? getUser(int key) {
    return _userBox.get(key);
  }

  // --- ChatRoom 관련 메서드 ---

  Future<int> addChatRoom(ChatRoom room) async {
    final key = await _chatRoomBox.add(room);
    room.id = key;
    await room.save();
    return key;
  }

  ChatRoom? getChatRoom(int key) {
    return _chatRoomBox.get(key);
  }

  Future<void> updateChatRoom(ChatRoom room) async {
    await room.save();
  }

  List<ChatRoom> getAllChatRooms() {
    return _chatRoomBox.values.toList();
  }

  Future<void> deleteChatRoom(int key) async {
    // 1. 관련 메시지들 삭제
    final messagesToDelete = _chatMessageBox.values.where((msg) => msg.chatRoomId == key);
    for (final message in messagesToDelete) {
      await message.delete();
    }
    // 2. 채팅방 삭제
    await _chatRoomBox.delete(key);
  }

  // --- ChatMessage 관련 메서드 ---

  Future<void> addChatMessage(ChatMessage message) async {
    final key = await _chatMessageBox.add(message);
    message.id = key;
    await message.save();
  }

  List<ChatMessage> getChatMessagesForRoom(int chatRoomId) {
    return _chatMessageBox.values
        .where((message) => message.chatRoomId == chatRoomId)
        .toList();
  }
}