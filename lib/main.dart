import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'inverview_chat_page.dart';
import 'auth_page.dart';
import 'services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드 (오류가 있어도 앱은 계속 실행)
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
  int questionCount = 5;
  String? currentUserName;

  @override
  void initState() {
    super.initState();
    _promptController.text = "프론트엔드 개발자, Flutter 전문";
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await UserService.getCurrentUser();
    setState(() {
      currentUserName = user?['name'];
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

  void _startInterview() {
    String prompt = _promptController.text.trim();
    String chatRoomName = _chatRoomNameController.text.trim();

    if (chatRoomName.isEmpty) {
      chatRoomName = "AI 면접 ${DateTime.now().month}/${DateTime.now().day}";
    }

    if (prompt.isEmpty) {
      prompt = "일반 개발자";
    }

    Navigator.of(context).pop(); // 다이얼로그 닫기

    // 대화 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterviewChatPage(
          questionCount: questionCount,
          prompt: prompt,
          chatRoomName: chatRoomName,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await UserService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 헤더
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.indigo, width: 1.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu, size: 24, color: Colors.indigo),
                        onPressed: () {},
                        splashRadius: 24,
                      ),
                    ),
                    // 사용자 정보 및 로그아웃
                    if (currentUserName != null)
                      Row(
                        children: [
                          Text(
                            '$currentUserName님',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.indigo, width: 1.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.logout, size: 24, color: Colors.indigo),
                              onPressed: _logout,
                              splashRadius: 24,
                            ),
                          ),
                        ],
                      ),
                    // API 모드 표시
                    _buildModeIndicator(),
                  ],
                ),
              ),

              const Spacer(),

              // 중앙 카드 컨테이너
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double cardWidth = constraints.maxWidth * 0.7;
                    if (cardWidth < 300) cardWidth = constraints.maxWidth * 0.9;
                    cardWidth = cardWidth.clamp(300.0, 600.0);

                    return SizedBox(
                      width: cardWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              spreadRadius: -2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.indigoAccent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mic_external_on,
                                  size: 60,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "AI 면접",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                "AI 면접을 시작해보세요",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "간단한 직무 선택으로 모의 면접을 빠르게 경험해보세요.",
                                style: TextStyle(fontSize: 16, color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: cardWidth * 0.9,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _showInterviewSettingsDialog(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo[700],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    elevation: 4,
                                  ),
                                  child: const Text(
                                    "면접 시작하기",
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeIndicator() {
    final bool hasApiKey = dotenv.env['GROQ_API_KEY']?.isNotEmpty ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasApiKey ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasApiKey ? Colors.green[300]! : Colors.orange[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasApiKey ? Icons.smart_toy : Icons.play_circle_outline,
            size: 16,
            color: hasApiKey ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            hasApiKey ? 'AI 모드' : '데모 모드',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasApiKey ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showInterviewSettingsDialog(BuildContext context) {
    final bool hasApiKey = dotenv.env['GROQ_API_KEY']?.isNotEmpty ?? false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.85, // 화면 높이의 85%로 제한
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 고정 헤더
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "면접 설정",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  // 스크롤 가능한 콘텐츠
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // API 모드 정보 표시
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: hasApiKey ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hasApiKey ? Colors.green[200]! : Colors.orange[200]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  hasApiKey ? Icons.check_circle : Icons.info,
                                  color: hasApiKey ? Colors.green[700] : Colors.orange[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hasApiKey
                                        ? '🤖 AI 모드: 실시간 질문 생성 및 피드백'
                                        : '📱 데모 모드: 사전 준비된 질문 사용',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: hasApiKey ? Colors.green[700] : Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 채팅방 이름 설정
                          const Text(
                            "채팅방 이름",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                            ),
                            child: TextField(
                              controller: _chatRoomNameController,
                              decoration: const InputDecoration(
                                hintText: "채팅방 이름을 입력해주세요",
                                hintStyle: TextStyle(color: Colors.black38),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 질문 개수 설정
                          const Text(
                            "면접 질문 개수",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "질문 개수",
                                  style: TextStyle(fontSize: 16, color: Colors.black54),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (questionCount > 1) questionCount--;
                                        });
                                      },
                                      icon: const Icon(Icons.remove_circle_outline),
                                      color: questionCount > 1 ? Colors.indigo : Colors.grey,
                                      splashRadius: 20,
                                    ),
                                    Container(
                                      width: 50,
                                      alignment: Alignment.center,
                                      child: Text(
                                        "$questionCount",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (questionCount < 12) questionCount++;
                                        });
                                      },
                                      icon: const Icon(Icons.add_circle_outline),
                                      color: questionCount < 12 ? Colors.indigo : Colors.grey,
                                      splashRadius: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 프롬프트 입력
                          const Text(
                            "면접 직무/분야",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasApiKey
                                ? "AI가 이 정보를 바탕으로 맞춤형 질문을 생성합니다"
                                : "직무별 질문 풀을 선택하는데 사용됩니다",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                            ),
                            child: TextField(
                              controller: _promptController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: "예: 프론트엔드 개발자, React 전문가\n백엔드 개발자, Spring Boot\n모바일 개발자, Flutter",
                                hintStyle: TextStyle(color: Colors.black38),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // 고정 하단 버튼
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startInterview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                        ),
                        child: const Text(
                          "면접 시작하기",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}