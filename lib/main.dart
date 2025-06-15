import 'package:flutter/material.dart';
import 'inverview_chat_page.dart';

void main() {
  runApp(
    MaterialApp(
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
            backgroundColor: Colors.indigo[700],
            shadowColor: Colors.indigoAccent.withOpacity(0.2),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
      home: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
              // 상단 헤더 영역
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.indigo),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.person_outline, size: 18, color: Colors.indigo),
                        label: const Text(
                          "로그인 / 회원가입",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.indigo),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
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

  void _showInterviewSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const InterviewSettingsDialog();
      },
    );
  }
}

class InterviewSettingsDialog extends StatefulWidget {
  const InterviewSettingsDialog({super.key});

  @override
  State<InterviewSettingsDialog> createState() => _InterviewSettingsDialogState();
}

class _InterviewSettingsDialogState extends State<InterviewSettingsDialog> {
  int questionCount = 5;
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _chatRoomNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 기본 채팅방 이름 설정
    _chatRoomNameController.text = "AI 면접 ${DateTime.now().month}/${DateTime.now().day}";
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 700,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "면접 설정",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                  ),
                ],
              ),

              const SizedBox(height: 24),

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
                          onPressed: _decrementQuestionCount,
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
                          onPressed: _incrementQuestionCount,
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
                "면접 프롬프트",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "원하는 직무나 분야를 입력해주세요 (선택사항)",
                style: TextStyle(
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
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "예: 프론트엔드 개발자, React 전문가\n백엔드 개발자, Spring Boot 경험자\n데이터 분석가, Python 활용",
                    hintStyle: TextStyle(color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
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
            ],
          ),
        ),
      ),
    );
  }
}