import '../model/chat_room.dart';
import '../model/chat_message.dart';
import 'user_service.dart';
import 'database_service.dart'; // DatabaseService import

class ChatService {
  // DatabaseService 인스턴스 생성
  final DatabaseService _dbService = DatabaseService();
  final UserService _userService = UserService();

  // 새 채팅방 생성
  Future<int?> createChatRoom(String name, String prompt, int totalQuestions) async {
    try {
      final currentUser = await _userService.getCurrentUser();
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

      // DB 추가 로직을 DatabaseService에 위임
      return await _dbService.addChatRoom(chatRoom);
    } catch (e) {
      print('채팅방 생성 오류: $e');
      return null;
    }
  }

  // 채팅방 정보 가져오기
  Future<ChatRoom?> getChatRoom(int chatRoomId) async {
    return _dbService.getChatRoom(chatRoomId);
  }

  // 채팅 메시지 저장
  Future<void> saveChatMessage(int chatRoomId, String content, bool isUser) async {
    try {
      final message = ChatMessage(
        chatRoomId: chatRoomId,
        content: content,
        isUser: isUser,
        timestamp: DateTime.now(),
      );
      await _dbService.addChatMessage(message);
      await updateChatRoomUpdatedAt(chatRoomId);
    } catch (e) {
      print('채팅 메시지 저장 오류: $e');
    }
  }

  // 채팅방의 메시지 가져오기
  Future<List<ChatMessage>> getChatMessages(int chatRoomId) async {
    try {
      final messages = _dbService.getChatMessagesForRoom(chatRoomId);
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      print('채팅 메시지 조회 오류: $e');
      return [];
    }
  }

  // 채팅방 업데이트 시간 갱신
  Future<void> updateChatRoomUpdatedAt(int chatRoomId) async {
    try {
      final chatRoom = _dbService.getChatRoom(chatRoomId);
      if (chatRoom != null) {
        chatRoom.updatedAt = DateTime.now();
        await _dbService.updateChatRoom(chatRoom);
      }
    } catch (e) {
      print('채팅방 업데이트 시간 갱신 오류: $e');
    }
  }

  // 면접 완료 및 피드백 저장
  Future<void> completeInterview(int chatRoomId, String feedback, int answeredQuestions) async {
    try {
      final chatRoom = _dbService.getChatRoom(chatRoomId);
      if (chatRoom != null) {
        chatRoom.isCompleted = true;
        chatRoom.feedback = feedback;
        chatRoom.answeredQuestions = answeredQuestions;
        chatRoom.updatedAt = DateTime.now();
        await _dbService.updateChatRoom(chatRoom);
      }
    } catch (e) {
      print('면접 완료 처리 오류: $e');
    }
  }

  // 채팅방 삭제
  Future<void> deleteChatRoom(int chatRoomId) async {
    try {
      await _dbService.deleteChatRoom(chatRoomId);
    } catch (e) {
      print('채팅방 삭제 오류: $e');
    }
  }

  // 사용자의 채팅방 목록 가져오기 (공통 로직)
  Future<List<ChatRoom>> _getUserChatRooms(bool Function(ChatRoom) filter) async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) return [];

      final allRooms = _dbService.getAllChatRooms();
      final userRooms = allRooms.where((room) => room.userId == currentUser.id && filter(room)).toList();
      userRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return userRooms;
    } catch (e) {
      print('채팅방 목록 조회 오류: $e');
      return [];
    }
  }

  // 완료된 면접 목록 가져오기
  Future<List<ChatRoom>> getCompletedInterviews() async {
    return _getUserChatRooms((room) => room.isCompleted);
  }

  // 진행 중인 면접 목록 가져오기
  Future<List<ChatRoom>> getOngoingInterviews() async {
    return _getUserChatRooms((room) => !room.isCompleted);
  }
}