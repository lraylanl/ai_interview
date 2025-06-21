import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'inverview_chat_page.dart';
import 'auth_page.dart';
import 'services/user_service.dart';
import 'services/chat_service.dart';
import 'model/user.dart';
import 'model/chat_room.dart';
import 'feedback_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('⚠️ .env 파일을 찾을 수 없습니다. 데모 모드로 실행됩니다.');
  }

  runApp(const MyApp());
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
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          return const MainScreen();
        } else {
          return const AuthPage();
        }
      },
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

  int questionCount = 5;
  User? currentUser;
  List<ChatRoom> ongoingRooms = [];
  List<ChatRoom> completedRooms = [];

  @override
  void initState() {
    super.initState();
    _promptController.text = "프론트엔드 개발자, Flutter 전문";
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await UserService.getCurrentUser();
    final ongoing = await ChatService.getOngoingInterviews();
    final completed = await ChatService.getCompletedInterviews();

    setState(() {
      currentUser = user;
      ongoingRooms = ongoing;
      completedRooms = completed;
    });
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

    // 새 채팅방 생성
    final chatRoomId = await ChatService.createChatRoom(chatRoomName, prompt, questionCount);

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
        // 채팅방 목록 새로고침
        _loadUserData();
      });
    }
  }

  void _openChatRoom(ChatRoom chatRoom) {
    if (chatRoom.isCompleted) {
      // 완료된 면접인 경우 피드백 다이얼로그 표시
      _showFeedbackDialog(chatRoom);
    } else {
      // 진행 중인 면접인 경우 채팅방으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InterviewChatPage(
            questionCount: chatRoom.totalQuestions ?? 5,
            prompt: chatRoom.prompt,
            chatRoomName: chatRoom.name,
            chatRoomId: chatRoom.id!,
            isExistingRoom: true,
          ),
        ),
      ).then((_) {
        _loadUserData();
      });
    }
  }

  void _showFeedbackDialog(ChatRoom chatRoom) {
    showDialog(
      context: context,
      builder: (context) => InterviewFeedbackDialog(
        chatRoom: chatRoom,
        onViewMessages: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InterviewChatPage(
                questionCount: chatRoom.totalQuestions ?? 5,
                prompt: chatRoom.prompt,
                chatRoomName: chatRoom.name,
                chatRoomId: chatRoom.id!,
                isExistingRoom: true,
                viewOnly: true,
              ),
            ),
          );
        },
      ),
    );
  }

  void _logout() async {
    await UserService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.blue],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '면접 기록',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${currentUser?.name}님',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.indigo,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.indigo,
                      tabs: [
                        Tab(text: '진행 중'),
                        Tab(text: '완료'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // 진행 중인 면접
                          _buildChatRoomList(ongoingRooms, false),
                          // 완료된 면접
                          _buildChatRoomList(completedRooms, true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          ],
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
              // 헤더
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.indigo, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mic_external_on,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI 면접 시작',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '전문적인 면접 경험을 시작해보세요',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 통계 카드
              if (completedRooms.isNotEmpty || ongoingRooms.isNotEmpty)
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '면접 통계',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                '완료된 면접',
                                completedRooms.length.toString(),
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                '진행 중',
                                ongoingRooms.length.toString(),
                                Icons.play_circle,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // 설정 카드
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '새 면접 설정',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 채팅방 이름
                      TextField(
                        controller: _chatRoomNameController,
                        decoration: InputDecoration(
                          labelText: '면접 제목',
                          hintText: '예: 프론트엔드 개발자 면접',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 면접 직무/프롬프트
                      TextField(
                        controller: _promptController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: '면접 직무 및 상세 정보',
                          hintText: '예: 프론트엔드 개발자, React 전문, 3년 경력',
                          prefixIcon: const Icon(Icons.work_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 질문 개수
                      Row(
                        children: [
                          const Icon(Icons.quiz_outlined, color: Colors.indigo),
                          const SizedBox(width: 8),
                          const Text(
                            '질문 개수:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _decrementQuestionCount,
                                  icon: const Icon(Icons.remove),
                                  color: Colors.indigo,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    '$questionCount',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _incrementQuestionCount,
                                  icon: const Icon(Icons.add),
                                  color: Colors.indigo,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 시작 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _startInterview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow),
                              SizedBox(width: 8),
                              Text(
                                '면접 시작',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomList(List<ChatRoom> rooms, bool isCompleted) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.history : Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted ? '완료된 면접이 없습니다' : '진행 중인 면접이 없습니다',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted ? '면접을 완료하면 여기에 표시됩니다' : '새로운 면접을 시작해보세요!',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final chatRoom = rooms[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.chat,
                color: isCompleted ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(
              chatRoom.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatRoom.prompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (isCompleted)
                  Text(
                    '${chatRoom.answeredQuestions}/${chatRoom.totalQuestions} 질문 완료',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    '${chatRoom.totalQuestions} 질문',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                if (isCompleted)
                  const PopupMenuItem(
                    value: 'feedback',
                    child: Row(
                      children: [
                        Icon(Icons.assessment, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('피드백 보기'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'delete') {
                  await ChatService.deleteChatRoom(chatRoom.id!);
                  _loadUserData();
                } else if (value == 'feedback') {
                  _showFeedbackDialog(chatRoom);
                }
              },
            ),
            onTap: () {
              Navigator.pop(context);
              _openChatRoom(chatRoom);
            },
          ),
        );
      },
    );
  }
}