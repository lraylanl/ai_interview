import 'package:hive_flutter/hive_flutter.dart';
import '../model/chat_room.dart';
import '../model/chat_message.dart';
import 'user_service.dart';

class ChatService {
  static Box<ChatRoom> get _chatRoomBox => Hive.box<ChatRoom>('chatRooms');
  static Box<ChatMessage> get _chatMessageBox => Hive.box<ChatMessage>('chatMessages');

  // 새 채팅방 생성
  static Future<int?> createChatRoom(String name, String prompt, int totalQuestions) async {
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) return null;

      final chatRoom = ChatRoom(
        name: name,
        prompt: prompt,
        userId: currentUser.id!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalQuestions: totalQuestions,
        answeredQuestions: 0,
      );

      // Hive에 저장하고 생성된 키를 ID로 사용
      final key = await _chatRoomBox.add(chatRoom);
      chatRoom.id = key;
      await chatRoom.save(); // ID 업데이트

      return key;
    } catch (e) {
      print('채팅방 생성 오류: $e');
      return null;
    }
  }

  // 사용자의 채팅방 목록 가져오기
  static Future<List<ChatRoom>> getUserChatRooms() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) return [];

      final chatRooms = _chatRoomBox.values
          .where((room) => room.userId == currentUser.id)
          .toList();

      // 최신 순으로 정렬
      chatRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return chatRooms;
    } catch (e) {
      print('채팅방 목록 조회 오류: $e');
      return [];
    }
  }

  // 채팅방 정보 가져오기
  static Future<ChatRoom?> getChatRoom(int chatRoomId) async {
    try {
      return _chatRoomBox.get(chatRoomId);
    } catch (e) {
      print('채팅방 조회 오류: $e');
      return null;
    }
  }

  // 채팅 메시지 저장
  static Future<void> saveChatMessage(
      int chatRoomId,
      String content,
      bool isUser,
      ) async {
    try {
      final message = ChatMessage(
        chatRoomId: chatRoomId,
        content: content,
        isUser: isUser,
        timestamp: DateTime.now(),
      );

      // 메시지 저장
      final key = await _chatMessageBox.add(message);
      message.id = key;
      await message.save();

      // 채팅방 업데이트 시간 갱신
      await updateChatRoomUpdatedAt(chatRoomId);
    } catch (e) {
      print('채팅 메시지 저장 오류: $e');
    }
  }

  // 채팅방의 메시지 가져오기
  static Future<List<ChatMessage>> getChatMessages(int chatRoomId) async {
    try {
      final messages = _chatMessageBox.values
          .where((message) => message.chatRoomId == chatRoomId)
          .toList();

      // 시간순으로 정렬
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return messages;
    } catch (e) {
      print('채팅 메시지 조회 오류: $e');
      return [];
    }
  }

  // 채팅방 업데이트 시간 갱신
  static Future<void> updateChatRoomUpdatedAt(int chatRoomId) async {
    try {
      final chatRoom = _chatRoomBox.get(chatRoomId);
      if (chatRoom != null) {
        chatRoom.updatedAt = DateTime.now();
        await chatRoom.save();
      }
    } catch (e) {
      print('채팅방 업데이트 시간 갱신 오류: $e');
    }
  }

  // 면접 완료 및 피드백 저장
  static Future<void> completeInterview(
      int chatRoomId,
      String feedback,
      int answeredQuestions,
      ) async {
    try {
      final chatRoom = _chatRoomBox.get(chatRoomId);
      if (chatRoom != null) {
        chatRoom.isCompleted = true;
        chatRoom.feedback = feedback;
        chatRoom.answeredQuestions = answeredQuestions;
        chatRoom.updatedAt = DateTime.now();
        await chatRoom.save();
      }
    } catch (e) {
      print('면접 완료 처리 오류: $e');
    }
  }

  // 채팅방 삭제
  static Future<void> deleteChatRoom(int chatRoomId) async {
    try {
      // 관련 메시지들 먼저 삭제
      final messages = _chatMessageBox.values
          .where((message) => message.chatRoomId == chatRoomId)
          .toList();

      for (final message in messages) {
        await message.delete();
      }

      // 채팅방 삭제
      final chatRoom = _chatRoomBox.get(chatRoomId);
      if (chatRoom != null) {
        await chatRoom.delete();
      }
    } catch (e) {
      print('채팅방 삭제 오류: $e');
    }
  }

  // 완료된 면접 목록 가져오기
  static Future<List<ChatRoom>> getCompletedInterviews() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) return [];

      final completedRooms = _chatRoomBox.values
          .where((room) => room.userId == currentUser.id && room.isCompleted)
          .toList();

      // 최신 순으로 정렬
      completedRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return completedRooms;
    } catch (e) {
      print('완료된 면접 조회 오류: $e');
      return [];
    }
  }

  // 진행 중인 면접 목록 가져오기
  static Future<List<ChatRoom>> getOngoingInterviews() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) return [];

      final ongoingRooms = _chatRoomBox.values
          .where((room) => room.userId == currentUser.id && !room.isCompleted)
          .toList();

      // 최신 순으로 정렬
      ongoingRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return ongoingRooms;
    } catch (e) {
      print('진행 중인 면접 조회 오류: $e');
      return [];
    }
  }
}