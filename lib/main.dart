import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'inverview_chat_page.dart';
import 'auth_page.dart';
import 'services/user_service.dart';
import 'services/chat_service.dart';
import 'model/user.dart';
import 'model/chat_room.dart';
import 'model/chat_message.dart';
import 'feedback_dialog.dart';
import 'widgets/main_screen/main_header_card.dart';
import 'widgets/main_screen/statistics_card.dart';
import 'widgets/main_screen/interview_settings_card.dart';
import 'widgets/main_screen/chat_history_drawer.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 초기화
  await Hive.initFlutter();

  // 어댑터 등록
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(ChatRoomAdapter());
  Hive.registerAdapter(ChatMessageAdapter());

  // 박스 열기
  await Hive.openBox<User>('users');
  await Hive.openBox<ChatRoom>('chatRooms');
  await Hive.openBox<ChatMessage>('chatMessages');
  await Hive.openBox('settings');

  // 디버깅 코드
  _printHiveData();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('⚠️ .env 파일을 찾을 수 없습니다. 데모 모드로 실행됩니다.');
  }

  runApp(const MyApp());
}

/// Hive 데이터를 콘솔에 출력하는 디버깅용 함수
void _printHiveData() {
  print('--- [Hive DB] Users ---');
  final userBox = Hive.box<User>('users');
  if (userBox.isEmpty) {
    print('No users found.');
  } else {
    userBox.values.forEach((user) {
      print('Key: ${user.key}, ID: ${user.id}, Username: ${user.username}, Name: ${user.name}');
    });
  }

  print('--- [Hive DB] ChatRooms ---');
  final chatRoomBox = Hive.box<ChatRoom>('chatRooms');
  if (chatRoomBox.isEmpty) {
    print('No chat rooms found.');
  } else {
    chatRoomBox.values.forEach((room) {
      print('Key: ${room.key}, ID: ${room.id}, Name: ${room.name}, UserID: ${room.userId}, Completed: ${room.isCompleted}');
    });
  }


  print('--- [Hive DB] ChatMessages ---');
  final messageBox = Hive.box<ChatMessage>('chatMessages');
  if (messageBox.isEmpty) {
    print('No chat messages found.');
  } else {
    messageBox.values.forEach((msg) {
      // 메시지 내용이 길 수 있으므로 일부만 출력
      final contentPreview = msg.content.length > 30 ? '${msg.content.substring(0, 30)}...' : msg.content;
      print('Key: ${msg.key}, RoomID: ${msg.chatRoomId}, IsUser: ${msg.isUser}, Content: "$contentPreview"');
    });
  }

  print('-------------------------');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        cardColor: const Color(0xFFF5F3FF),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
          titleMedium: TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _chatRoomNameController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();

  int questionCount = 5;
  User? currentUser;
  List<ChatRoom> ongoingRooms = [];
  List<ChatRoom> completedRooms = [];

  @override
  void initState() {
    super.initState();
    _promptController.text = "";
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _userService.getCurrentUser();


    List<ChatRoom> ongoing = [];
    List<ChatRoom> completed = [];

    if (user != null) {
      ongoing = await _chatService.getOngoingInterviews();
      completed = await _chatService.getCompletedInterviews();
    }


    if (mounted) {
      setState(() {
        currentUser = user;
        ongoingRooms = ongoing;
        completedRooms = completed;
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _chatRoomNameController.dispose();
    super.dispose();
  }

  void _incrementQuestionCount() {
    if (questionCount < 12) {
      setState(() {
        questionCount++;
      });
    }
  }

  void _decrementQuestionCount() {
    if (questionCount > 1) {
      setState(() {
        questionCount--;
      });
    }
  }

  void _startInterview() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('면접을 시작하려면 로그인이 필요합니다.')),
      );
      await Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthPage()));
      _loadUserData();
      return;
    }

    String prompt = _promptController.text.trim();
    String chatRoomName = _chatRoomNameController.text.trim();

    if (chatRoomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('채팅방 이름을 입력해주세요.')),
      );
      return;
    }

    if (prompt.isEmpty) {
      prompt = "일반 개발자 면접";
    }

    final chatRoomId = await _chatService.createChatRoom(chatRoomName, prompt, questionCount);

    if (chatRoomId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InterviewChatPage(
            questionCount: questionCount,
            prompt: prompt,
            chatRoomName: chatRoomName,
            chatRoomId: chatRoomId,
          ),
        ),
      ).then((_) {
        _loadUserData();
      });
    }
  }

  void _openChatRoom(ChatRoom chatRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterviewChatPage(
          questionCount: chatRoom.totalQuestions ?? 5,
          prompt: chatRoom.prompt,
          chatRoomName: chatRoom.name,
          chatRoomId: chatRoom.id!,
          isExistingRoom: true,
          // 완료된 면접이면 viewOnly 모드로 설정
          viewOnly: chatRoom.isCompleted,
        ),
      ),
    ).then((_) {
      _loadUserData();
    });
  }

  void _deleteChatRoom(ChatRoom chatRoom) async {
    await _chatService.deleteChatRoom(chatRoom.id!);
    _loadUserData();
  }

  void _logout() async {
    await _userService.logout();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],

      // 사이드바 메뉴
      drawer: ChatHistoryDrawer(
        currentUser: currentUser,
        ongoingRooms: ongoingRooms,
        completedRooms: completedRooms,
        onOpenChatRoom: _openChatRoom,
        onDeleteChatRoom: _deleteChatRoom,
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.indigo),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'AI 면접',
          style: TextStyle(
            color: Colors.indigo,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (currentUser != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  '${currentUser!.name}님',
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.indigo),
              onPressed: _logout,
            ),
          ] else ...[
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                );
                _loadUserData();
              },
              child: const Text(
                '로그인',
                style: TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ]
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 분리된 헤더 카드 위젯 사용
              const MainHeaderCard(),

              const SizedBox(height: 32),

              // 분리된 통계 카드 위젯 사용
              StatisticsCard(
                completedRooms: completedRooms,
                ongoingRooms: ongoingRooms,
              ),

              // 분리된 설정 카드 위젯 사용
              InterviewSettingsCard(
                chatRoomNameController: _chatRoomNameController,
                promptController: _promptController,
                questionCount: questionCount,
                onStartInterview: _startInterview,
                onIncrement: _incrementQuestionCount,
                onDecrement: _decrementQuestionCount,
              ),

            ],
          ),
        ),
      ),
    );
  }
}