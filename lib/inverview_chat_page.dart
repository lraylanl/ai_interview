import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/ai_service.dart';

class InterviewChatPage extends StatefulWidget {
  final int questionCount;
  final String prompt;
  final String chatRoomName;

  const InterviewChatPage({
    super.key,
    required this.questionCount,
    required this.prompt,
    required this.chatRoomName,
  });

  @override
  State<InterviewChatPage> createState() => _InterviewChatPageState();
}

class _InterviewChatPageState extends State<InterviewChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ChatMessage> messages = [];
  List<String> askedQuestions = [];
  int currentQuestionIndex = 1;
  bool isLoading = false;
  bool isGeneratingQuestion = false;

  // 사용자 설정
  String userName = "lraylanl";
  String chatRoomName = "";
  String currentPrompt = "";
  double fontSize = 16.0;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    chatRoomName = widget.chatRoomName;
    currentPrompt = widget.prompt;
    _startInterview();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startInterview() async {
    setState(() {
      isGeneratingQuestion = true;
    });

    try {
      String firstQuestion = await _generateAIQuestion();
      setState(() {
        messages.add(ChatMessage(
          text: firstQuestion,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        askedQuestions.add(firstQuestion);
        isGeneratingQuestion = false;
      });
    } catch (e) {
      print('면접 시작 오류: $e');
      setState(() {
        isGeneratingQuestion = false;
      });
    }
  }

  Future<String> _generateAIQuestion() async {
    try {
      return await AIService.generateQuestion(
        prompt: currentPrompt,
        jobPosition: _extractJobPosition(),
        questionNumber: currentQuestionIndex,
        previousQuestions: askedQuestions,
      );
    } catch (e) {
      print('AI 질문 생성 실패: $e');
      rethrow;
    }
  }

  String _extractJobPosition() {
    // 프롬프트에서 직무 추출 (간단한 예시)
    final prompt = currentPrompt.toLowerCase();
    if (prompt.contains('프론트엔드') || prompt.contains('frontend') || prompt.contains('react') || prompt.contains('vue')) {
      return '프론트엔드 개발자';
    }
    if (prompt.contains('백엔드') || prompt.contains('backend') || prompt.contains('서버') || prompt.contains('server')) {
      return '백엔드 개발자';
    }
    if (prompt.contains('풀스택') || prompt.contains('fullstack')) {
      return '풀스택 개발자';
    }
    if (prompt.contains('모바일') || prompt.contains('flutter') || prompt.contains('앱') || prompt.contains('mobile')) {
      return '모바일 개발자';
    }
    if (prompt.contains('데이터') || prompt.contains('분석') || prompt.contains('python')) {
      return '데이터 분석가';
    }
    if (prompt.contains('디자인') || prompt.contains('ui') || prompt.contains('ux')) {
      return 'UX/UI 디자이너';
    }
    return currentPrompt.isNotEmpty ? currentPrompt : '개발자';
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String userMessage = _messageController.text.trim();
    setState(() {
      messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // 선택적: 답변에 대한 피드백 생성
    if (AIService.hasApiConnection && askedQuestions.isNotEmpty) {
      try {
        String feedback = await AIService.generateFeedback(
          question: askedQuestions.last,
          answer: userMessage,
          jobPosition: _extractJobPosition(),
        );

        setState(() {
          messages.add(ChatMessage(
            text: feedback,
            isUser: false,
            timestamp: DateTime.now(),
            isFeedback: true,
          ));
        });
        _scrollToBottom();
      } catch (e) {
        print('피드백 생성 실패: $e');
      }
    }

    // 다음 질문 생성
    if (currentQuestionIndex < widget.questionCount) {
      currentQuestionIndex++;
      setState(() {
        isGeneratingQuestion = true;
      });

      try {
        String nextQuestion = await _generateAIQuestion();
        setState(() {
          messages.add(ChatMessage(
            text: nextQuestion,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          askedQuestions.add(nextQuestion);
          isLoading = false;
          isGeneratingQuestion = false;
        });
      } catch (e) {
        setState(() {
          messages.add(ChatMessage(
            text: "면접 진행 중 오류가 발생했습니다. 다음 질문으로 넘어가겠습니다.",
            isUser: false,
            timestamp: DateTime.now(),
          ));
          isLoading = false;
          isGeneratingQuestion = false;
        });
      }
    } else {
      setState(() {
        messages.add(ChatMessage(
          text: "면접이 완료되었습니다! 모든 질문에 성실히 답변해주셔서 감사합니다. 오늘 면접에서 보여주신 열정과 역량이 인상적이었습니다. 좋은 결과가 있기를 바랍니다! 🎉",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showUserEditDialog() {
    final TextEditingController userNameController = TextEditingController(text: userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("사용자 이름 수정"),
        content: TextField(
          controller: userNameController,
          decoration: const InputDecoration(
            labelText: "사용자 이름",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                userName = userNameController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  void _showChatRoomEditDialog() {
    final TextEditingController chatRoomController = TextEditingController(text: chatRoomName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("채팅방 이름 수정"),
        content: TextField(
          controller: chatRoomController,
          decoration: const InputDecoration(
            labelText: "채팅방 이름",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                chatRoomName = chatRoomController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  void _showPromptEditDialog() {
    final TextEditingController promptController = TextEditingController(text: currentPrompt);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("프롬프트 수정"),
        content: TextField(
          controller: promptController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "면접 프롬프트",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                currentPrompt = promptController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  void _showAppSettings() {
    final bool hasApiKey = dotenv.env['GROQ_API_KEY']?.isNotEmpty ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("앱 설정"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // API 모드 상태 표시
            Container(
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
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasApiKey ? '🤖 AI 모드 활성화' : '📱 데모 모드',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasApiKey ? Colors.green[700] : Colors.orange[700],
                          ),
                        ),
                        Text(
                          hasApiKey
                              ? '실시간 AI 질문 생성 및 피드백'
                              : '사전 준비된 질문 및 피드백 사용',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasApiKey ? Colors.green[600] : Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("다크 모드"),
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
                Navigator.pop(context);
              },
            ),
            const ListTile(
              title: Text("알림 설정"),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("닫기"),
          ),
        ],
      ),
    );
  }

  void _showChatSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("대화 설정"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("폰트 크기"),
                subtitle: Column(
                  children: [
                    Slider(
                      value: fontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 6,
                      label: fontSize.round().toString(),
                      onChanged: (value) {
                        setDialogState(() {
                          fontSize = value;
                        });
                        setState(() {
                          fontSize = value;
                        });
                      },
                    ),
                    Text("현재 크기: ${fontSize.round()}px"),
                  ],
                ),
              ),
              const ListTile(
                title: Text("메시지 알림음"),
                trailing: Icon(Icons.chevron_right),
              ),
              const ListTile(
                title: Text("자동 저장"),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("닫기"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.indigo[700],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: Colors.indigo),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      chatRoomName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.indigo),
                title: const Text("사용자 이름 수정"),
                onTap: () {
                  Navigator.pop(context);
                  _showUserEditDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: Colors.indigo),
                title: const Text("채팅방 이름 수정"),
                onTap: () {
                  Navigator.pop(context);
                  _showChatRoomEditDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note, color: Colors.indigo),
                title: const Text("프롬프트 수정"),
                onTap: () {
                  Navigator.pop(context);
                  _showPromptEditDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.indigo),
                title: const Text("앱 설정"),
                onTap: () {
                  Navigator.pop(context);
                  _showAppSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble, color: Colors.indigo),
                title: const Text("대화 설정"),
                onTap: () {
                  Navigator.pop(context);
                  _showChatSettings();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.indigo),
                title: const Text("면접 정보"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("질문 ${currentQuestionIndex}/${widget.questionCount}"),
                    Text("모드: ${AIService.getCurrentMode()}"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.indigo, width: 1.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu, size: 24, color: Colors.indigo),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        splashRadius: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chatRoomName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "질문 ${currentQuestionIndex}/${widget.questionCount} • ${AIService.getCurrentMode()}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.indigo, width: 1.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 24, color: Colors.indigo),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // 채팅 영역
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 메시지 리스트
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length + (isGeneratingQuestion ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (isGeneratingQuestion && index == messages.length) {
                              return _buildLoadingMessage();
                            }
                            return _buildMessageBubble(messages[index]);
                          },
                        ),
                      ),

                      // 로딩 표시
                      if (isLoading && !isGeneratingQuestion)
                        const LinearProgressIndicator(color: Colors.indigo),

                      // 입력 영역
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.black12, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  decoration: const InputDecoration(
                                    hintText: "답변을 입력해주세요...",
                                    hintStyle: TextStyle(color: Colors.black38),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.indigo[700],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.indigoAccent.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: isLoading ? null : _sendMessage,
                                icon: const Icon(Icons.send, color: Colors.white),
                                splashRadius: 24,
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: message.isFeedback
                    ? Colors.green.withOpacity(0.1)
                    : Colors.indigo.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.isFeedback ? Icons.feedback : Icons.smart_toy,
                size: 18,
                color: message.isFeedback ? Colors.green : Colors.indigo,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.indigo[700]
                    : message.isFeedback
                    ? Colors.green[50]
                    : const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(18),
                border: message.isUser
                    ? null
                    : Border.all(
                    color: message.isFeedback
                        ? Colors.green.withOpacity(0.2)
                        : Colors.indigo.withOpacity(0.2)
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: fontSize,
                  color: message.isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.indigo[700],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 18,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.indigo.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "AI가 질문을 생성하고 있습니다...",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isFeedback;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isFeedback = false,
  });
}