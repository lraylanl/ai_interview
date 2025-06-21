import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/ai_service.dart';
import 'services/chat_service.dart';
import 'model/chat_message.dart';
import 'feedback_dialog.dart';

class InterviewChatPage extends StatefulWidget {
  final int questionCount;
  final String prompt;
  final String chatRoomName;
  final int chatRoomId;
  final bool isExistingRoom;
  final bool viewOnly;

  const InterviewChatPage({
    super.key,
    required this.questionCount,
    required this.prompt,
    required this.chatRoomName,
    required this.chatRoomId,
    this.isExistingRoom = false,
    this.viewOnly = false,
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
  List<Map<String, String>> feedbackData = [];
  int currentQuestionIndex = 1;
  bool isLoading = false;
  bool isGeneratingQuestion = false;
  bool isInterviewCompleted = false;

  // 사용자 설정
  String userName = "사용자";
  String chatRoomName = "";
  String currentPrompt = "";
  double fontSize = 16.0;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    chatRoomName = widget.chatRoomName;
    currentPrompt = widget.prompt;

    if (widget.isExistingRoom) {
      _loadExistingChat();
    } else {
      _startInterview();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 기존 채팅 불러오기
  Future<void> _loadExistingChat() async {
    try {
      final chatRoom = await ChatService.getChatRoom(widget.chatRoomId);
      final chatMessages = await ChatService.getChatMessages(widget.chatRoomId);

      if (chatRoom != null) {
        setState(() {
          isInterviewCompleted = chatRoom.isCompleted;
          messages = chatMessages.map((msg) => ChatMessage(
            text: msg.content,
            isUser: msg.isUser,
            timestamp: msg.timestamp,
          )).toList();

          // 질문 수 계산
          currentQuestionIndex = messages.where((m) => !m.isUser).length;

          // 완료된 면접인 경우 피드백 데이터 준비
          if (chatRoom.isCompleted && chatRoom.feedback != null) {
            feedbackData = [{'feedback': chatRoom.feedback!}];
          }
        });
      }
    } catch (e) {
      print('기존 채팅 불러오기 오류: $e');
    }
  }

  void _startInterview() async {
    setState(() {
      isGeneratingQuestion = true;
    });

    try {
      String firstQuestion = await _generateAIQuestion();
      final message = ChatMessage(
        text: firstQuestion,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        messages.add(message);
        askedQuestions.add(firstQuestion);
        isGeneratingQuestion = false;
      });

      // 데이터베이스에 저장
      await ChatService.saveChatMessage(widget.chatRoomId, firstQuestion, false);

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
    if (_messageController.text.trim().isEmpty || isInterviewCompleted || widget.viewOnly) return;

    String userMessage = _messageController.text.trim();
    final message = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      messages.add(message);
      isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // 데이터베이스에 저장
    await ChatService.saveChatMessage(widget.chatRoomId, userMessage, true);

    // 현재 질문과 답변을 피드백 데이터에 저장
    if (askedQuestions.isNotEmpty) {
      feedbackData.add({
        'question': askedQuestions.last,
        'answer': userMessage,
        'feedback': '',
      });
    }

    // 다음 질문 생성 또는 면접 완료
    if (currentQuestionIndex < widget.questionCount) {
      currentQuestionIndex++;
      setState(() {
        isGeneratingQuestion = true;
      });

      try {
        String nextQuestion = await _generateAIQuestion();
        final aiMessage = ChatMessage(
          text: nextQuestion,
          isUser: false,
          timestamp: DateTime.now(),
        );

        setState(() {
          messages.add(aiMessage);
          askedQuestions.add(nextQuestion);
          isLoading = false;
          isGeneratingQuestion = false;
        });

        // 데이터베이스에 저장
        await ChatService.saveChatMessage(widget.chatRoomId, nextQuestion, false);

      } catch (e) {
        final errorMessage = ChatMessage(
          text: "면접 진행 중 오류가 발생했습니다. 다음 질문으로 넘어가겠습니다.",
          isUser: false,
          timestamp: DateTime.now(),
        );

        setState(() {
          messages.add(errorMessage);
          isLoading = false;
          isGeneratingQuestion = false;
        });

        await ChatService.saveChatMessage(widget.chatRoomId, errorMessage.text, false);
      }
    } else {
      // 면접 완료
      final completionMessage = ChatMessage(
        text: "면접이 완료되었습니다! 모든 질문에 성실히 답변해주셔서 감사합니다. 피드백을 생성하고 있습니다...",
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        isInterviewCompleted = true;
        messages.add(completionMessage);
        isLoading = false;
      });

      await ChatService.saveChatMessage(widget.chatRoomId, completionMessage.text, false);

      // 피드백 생성 및 면접 완료 처리
      await _generateAllFeedbackAndComplete();
    }
    _scrollToBottom();
  }

  // 모든 피드백 생성 후 면접 완료 처리
  Future<void> _generateAllFeedbackAndComplete() async {
    String overallFeedback = "";

    // AI API가 있는 경우에만 피드백 생성
    if (AIService.hasApiConnection) {
      for (int i = 0; i < feedbackData.length; i++) {
        try {
          String feedback = await AIService.generateFeedback(
            question: feedbackData[i]['question']!,
            answer: feedbackData[i]['answer']!,
            jobPosition: _extractJobPosition(),
          );
          feedbackData[i]['feedback'] = feedback;
        } catch (e) {
          print('피드백 생성 실패: $e');
          feedbackData[i]['feedback'] = '피드백 생성 중 오류가 발생했습니다.';
        }
      }

      // 종합 피드백 생성
      overallFeedback = feedbackData.map((f) => f['feedback']).join('\n\n');
    } else {
      // 데모 모드에서는 간단한 피드백 제공
      overallFeedback = '''✅ 좋은 점:
• 모든 질문에 성실히 답변해주셨습니다
• 기본적인 개념을 잘 이해하고 계십니다

🔄 개선점:
• 더 구체적인 예시나 경험을 포함하면 좋겠습니다
• 답변을 좀 더 체계적으로 구성해보세요

💡 조언:
• 실무 경험이나 프로젝트 사례를 더 추가하면 더욱 좋은 답변이 될 것 같습니다''';

      for (int i = 0; i < feedbackData.length; i++) {
        feedbackData[i]['feedback'] = overallFeedback;
      }
    }

    // 면접 완료 및 피드백 저장
    await ChatService.completeInterview(
      widget.chatRoomId,
      overallFeedback,
      feedbackData.length,
    );

    // 마지막 메시지 업데이트
    final finalMessage = ChatMessage(
      text: "면접이 완료되었습니다! 🎉\n피드백이 준비되었습니다. 아래 버튼을 클릭하여 확인해보세요.",
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      messages.last = finalMessage;
    });

    await ChatService.saveChatMessage(widget.chatRoomId, finalMessage.text, false);
    _scrollToBottom();

    // 잠시 후 피드백 다이얼로그 표시
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _showFeedbackDialog();
    }
  }

  // 피드백 다이얼로그 표시
  void _showFeedbackDialog() {
    final chatRoom = ChatService.getChatRoom(widget.chatRoomId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FutureBuilder(
        future: chatRoom,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return InterviewFeedbackDialog(
              chatRoom: snapshot.data!,
              onViewMessages: () {
                Navigator.pop(context);
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.indigo),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
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
                          Row(
                            children: [
                              Text(
                                widget.viewOnly
                                    ? "대화 기록 보기"
                                    : "질문 ${currentQuestionIndex}/${widget.questionCount}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              if (isInterviewCompleted) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "완료",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isInterviewCompleted && !widget.viewOnly)
                      IconButton(
                        icon: const Icon(Icons.assessment, color: Colors.green),
                        onPressed: _showFeedbackDialog,
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

                      // 입력 영역 (면접 완료 시 또는 viewOnly 시 비활성화)
                      if (!widget.viewOnly)
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
                                    color: isInterviewCompleted
                                        ? Colors.grey[100]
                                        : const Color(0xFFF5F3FF),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: isInterviewCompleted
                                            ? Colors.grey[300]!
                                            : Colors.indigo.withOpacity(0.2)
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _messageController,
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    enabled: !isInterviewCompleted,
                                    decoration: InputDecoration(
                                      hintText: isInterviewCompleted
                                          ? "면접이 완료되었습니다"
                                          : "답변을 입력해주세요...",
                                      hintStyle: TextStyle(
                                          color: isInterviewCompleted
                                              ? Colors.grey[500]
                                              : Colors.black38
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12
                                      ),
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: isInterviewCompleted || isLoading
                                      ? Colors.grey[400]
                                      : Colors.indigo[700],
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: (isLoading || isInterviewCompleted) ? null : _sendMessage,
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
                color: message.isUser
                    ? Colors.indigo[700]
                    : const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(18),
                border: message.isUser
                    ? null
                    : Border.all(color: Colors.indigo.withOpacity(0.2)),
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

// ChatMessage 클래스
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