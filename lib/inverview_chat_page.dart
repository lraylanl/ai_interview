import 'package:flutter/material.dart';

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
  int currentQuestionIndex = 1;
  bool isLoading = false;

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

  void _startInterview() {
    String firstQuestion = _generateQuestion();
    setState(() {
      messages.add(ChatMessage(
        text: firstQuestion,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  String _generateQuestion() {
    List<String> sampleQuestions = [
      "자기소개를 간단히 해주세요.",
      "이 직무에 지원한 이유는 무엇인가요?",
      "가장 큰 성취는 무엇이라고 생각하시나요?",
      "팀워크 경험에 대해 말씀해주세요.",
      "어려운 문제를 해결했던 경험이 있다면 공유해주세요.",
      "본인의 장점과 단점은 무엇인가요?",
      "5년 후 본인의 모습은 어떨 것 같나요?",
      "스트레스를 어떻게 관리하시나요?",
      "새로운 기술을 학습하는 방법은 무엇인가요?",
      "우리 회사에 대해 알고 있는 것이 있나요?",
      "마지막으로 질문이 있으시다면 해주세요.",
      "면접이 끝났습니다. 수고하셨습니다!",
    ];

    if (currentQuestionIndex <= widget.questionCount && currentQuestionIndex <= sampleQuestions.length) {
      return "질문 ${currentQuestionIndex}/${widget.questionCount}: ${sampleQuestions[currentQuestionIndex - 1]}";
    }

    return "면접이 완료되었습니다. 수고하셨습니다!";
  }

  void _sendMessage() {
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

    Future.delayed(const Duration(seconds: 2), () {
      if (currentQuestionIndex < widget.questionCount) {
        currentQuestionIndex++;
        String nextQuestion = _generateQuestion();

        setState(() {
          messages.add(ChatMessage(
            text: nextQuestion,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          isLoading = false;
        });
      } else {
        setState(() {
          messages.add(ChatMessage(
            text: "면접이 완료되었습니다. 모든 질문에 답변해주셔서 감사합니다!",
            isUser: false,
            timestamp: DateTime.now(),
          ));
          isLoading = false;
        });
      }
      _scrollToBottom();
    });
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("앱 설정"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const ListTile(
              title: Text("데이터 사용량"),
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
                title: const Text("정보"),
                subtitle: Text("질문 ${currentQuestionIndex}/${widget.questionCount}"),
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
                            "질문 ${currentQuestionIndex}/${widget.questionCount}",
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
                          itemCount: messages.length + (isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length && isLoading) {
                              return _buildLoadingMessage();
                            }
                            return _buildMessageBubble(messages[index]);
                          },
                        ),
                      ),

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
                                onPressed: _sendMessage,
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
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.indigo[700] : const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(18),
                border: message.isUser ? null : Border.all(color: Colors.indigo.withOpacity(0.2)),
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
                  "답변을 분석중...",
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

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}