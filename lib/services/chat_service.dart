import '../database/database_helper.dart';
import '../model/chat_room.dart';
import '../model/chat_message.dart';
import 'user_service.dart';

class ChatService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

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

      return await _dbHelper.insertChatRoom(chatRoom);
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

      return await _dbHelper.getChatRoomsByUserId(currentUser.id!);
    } catch (e) {
      print('채팅방 목록 조회 오류: $e');
      return [];
    }
  }

  // 채팅방 정보 가져오기
  static Future<ChatRoom?> getChatRoom(int chatRoomId) async {
    try {
      return await _dbHelper.getChatRoomById(chatRoomId);
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

      await _dbHelper.insertChatMessage(message);
      await _dbHelper.updateChatRoomUpdatedAt(chatRoomId);
    } catch (e) {
      print('채팅 메시지 저장 오류: $e');
    }
  }

  // 채팅방의 메시지 가져오기
  static Future<List<ChatMessage>> getChatMessages(int chatRoomId) async {
    try {
      return await _dbHelper.getChatMessagesByRoomId(chatRoomId);
    } catch (e) {
      print('채팅 메시지 조회 오류: $e');
      return [];
    }
  }

  // 면접 완료 및 피드백 저장
  static Future<void> completeInterview(
      int chatRoomId,
      String feedback,
      int answeredQuestions,
      ) async {
    try {
      final chatRoom = await _dbHelper.getChatRoomById(chatRoomId);
      if (chatRoom != null) {
        await _dbHelper.completeChatRoom(
          chatRoomId,
          feedback,
          chatRoom.totalQuestions ?? 0,
          answeredQuestions,
        );
      }
    } catch (e) {
      print('면접 완료 처리 오류: $e');
    }
  }

  // 채팅방 삭제
  static Future<void> deleteChatRoom(int chatRoomId) async {
    try {
      await _dbHelper.deleteChatRoom(chatRoomId);
    } catch (e) {
      print('채팅방 삭제 오류: $e');
    }
  }

  // 완료된 면접 목록 가져오기
  static Future<List<ChatRoom>> getCompletedInterviews() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) return [];

      final allRooms = await _dbHelper.getChatRoomsByUserId(currentUser.id!);
      return allRooms.where((room) => room.isCompleted).toList();
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

      final allRooms = await _dbHelper.getChatRoomsByUserId(currentUser.id!);
      return allRooms.where((room) => !room.isCompleted).toList();
    } catch (e) {
      print('진행 중인 면접 조회 오류: $e');
      return [];
    }
  }
}