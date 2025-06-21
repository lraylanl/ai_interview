import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/ai_service.dart';
import 'services/chat_service.dart';
import 'model/chat_message.dart' as model;
import 'feedback_dialog.dart';
import 'widgets/chat_page/chat_app_bar.dart';
import 'widgets/chat_page/chat_message_list.dart';
import 'widgets/chat_page/message_input_bar.dart';

enum ChatPageState {
  loading,
  waitingForAnswer,
  generatingQuestion,
  processingAnswer,
  completed
}

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

  final ChatService _chatService = ChatService();

  List<model.ChatMessage> messages = [];
  List<String> askedQuestions = [];
  List<Map<String, String>> feedbackData = [];
  int currentQuestionIndex = 1;

  ChatPageState _pageState = ChatPageState.loading;

  String chatRoomName = "";
  String currentPrompt = "";
  double fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    chatRoomName = widget.chatRoomName;
    currentPrompt = widget.prompt;

    if (widget.viewOnly) {
      _pageState = ChatPageState.completed;
    }

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

  Future<void> _loadExistingChat() async {
    setState(() => _pageState = ChatPageState.loading);
    try {
      final chatRoom = await _chatService.getChatRoom(widget.chatRoomId);
      final chatMessages = await _chatService.getChatMessages(widget.chatRoomId);

      if (chatRoom != null && mounted) {
        askedQuestions = chatMessages.where((m) => !m.isUser).map((m) => m.content).toList();

        setState(() {
          messages = chatMessages;
          currentQuestionIndex = askedQuestions.isNotEmpty ? askedQuestions.length : 1;

          if (chatRoom.isCompleted) {
            _pageState = ChatPageState.completed;
          } else {
            _pageState = ChatPageState.waitingForAnswer;
          }
        });
      }
    } catch (e) {
      print('기존 채팅 불러오기 오류: $e');
      if (mounted) setState(() => _pageState = ChatPageState.waitingForAnswer);
    }
  }

  void _startInterview() async {
    setState(() => _pageState = ChatPageState.generatingQuestion);
    try {
      String firstQuestion = await _generateAIQuestion();
      final message = model.ChatMessage(
        chatRoomId: widget.chatRoomId,
        content: firstQuestion,
        isUser: false,
        timestamp: DateTime.now(),
      );

      await _chatService.saveChatMessage(widget.chatRoomId, firstQuestion, false);

      if (mounted) {
        setState(() {
          messages.add(message);
          askedQuestions.add(firstQuestion);
          currentQuestionIndex = 1;
          _pageState = ChatPageState.waitingForAnswer;
        });
      }
    } catch (e) {
      print('면접 시작 오류: $e');
      if (mounted) setState(() => _pageState = ChatPageState.waitingForAnswer);
    }
  }

  Future<String> _generateAIQuestion() async {
    return AIService.generateQuestion(
      prompt: currentPrompt,
      jobPosition: _extractJobPosition(),
      questionNumber: currentQuestionIndex,
      previousQuestions: askedQuestions,
    );
  }

  String _extractJobPosition() {
    final prompt = currentPrompt.toLowerCase();
    if (prompt.contains('프론트엔드') || prompt.contains('frontend')) return '프론트엔드 개발자';
    if (prompt.contains('백엔드') || prompt.contains('backend')) return '백엔드 개발자';
    if (prompt.contains('모바일') || prompt.contains('flutter')) return '모바일 개발자';
    return currentPrompt.isNotEmpty ? currentPrompt : '개발자';
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _pageState != ChatPageState.waitingForAnswer) return;

    String userMessage = _messageController.text.trim();
    final message = model.ChatMessage(
      chatRoomId: widget.chatRoomId,
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      messages.add(message);
      _pageState = ChatPageState.processingAnswer;
    });
    _messageController.clear();
    _scrollToBottom();

    await _chatService.saveChatMessage(widget.chatRoomId, userMessage, true);
    if (askedQuestions.isNotEmpty) {
      feedbackData.add({'question': askedQuestions.last, 'answer': userMessage});
    }

    if (currentQuestionIndex < widget.questionCount) {
      await _generateNextQuestion();
    } else {
      await _finalizeInterview();
    }
  }

  Future<void> _generateNextQuestion() async {
    setState(() {
      currentQuestionIndex++;
      _pageState = ChatPageState.generatingQuestion;
    });

    try {
      String nextQuestion = await _generateAIQuestion();
      final aiMessage = model.ChatMessage(
        chatRoomId: widget.chatRoomId,
        content: nextQuestion,
        isUser: false,
        timestamp: DateTime.now(),
      );

      await _chatService.saveChatMessage(widget.chatRoomId, nextQuestion, false);

      if (mounted) {
        setState(() {
          messages.add(aiMessage);
          askedQuestions.add(nextQuestion);
          _pageState = ChatPageState.waitingForAnswer;
        });
      }
    } catch (e) {
      print('다음 질문 생성 오류: $e');
      if (mounted) setState(() => _pageState = ChatPageState.waitingForAnswer);
    }
    _scrollToBottom();
  }

  Future<void> _finalizeInterview() async {
    setState(() => _pageState = ChatPageState.processingAnswer);

    final completionMessageContent = "면접이 완료되었습니다! 모든 질문에 성실히 답변해주셔서 감사합니다. 피드백을 생성하고 있습니다...";
    final completionMessage = model.ChatMessage(
      chatRoomId: widget.chatRoomId,
      content: completionMessageContent,
      isUser: false,
      timestamp: DateTime.now(),
    );
    setState(() => messages.add(completionMessage));
    _scrollToBottom();
    await _chatService.saveChatMessage(widget.chatRoomId, completionMessageContent, false);

    await _generateAllFeedbackAndComplete();
  }

  Future<void> _generateAllFeedbackAndComplete() async {
    String overallFeedback = "";
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
    overallFeedback = feedbackData.map((f) => f['feedback']).join('\n\n');

    await _chatService.completeInterview(widget.chatRoomId, overallFeedback, feedbackData.length);

    final finalMessageContent = "피드백이 준비되었습니다.🎉 우측 상단 버튼을 클릭하여 확인해보세요.";
    final finalMessage = model.ChatMessage(
      chatRoomId: widget.chatRoomId,
      content: finalMessageContent,
      isUser: false,
      timestamp: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        messages.last = finalMessage;
        _pageState = ChatPageState.completed;
      });
    }
    await _chatService.saveChatMessage(widget.chatRoomId, finalMessageContent, false);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _showFeedbackDialog();
  }

  void _showFeedbackDialog() {
    final chatRoom = _chatService.getChatRoom(widget.chatRoomId);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FutureBuilder(
        future: chatRoom,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return InterviewFeedbackDialog(
              chatRoom: snapshot.data!,
              onViewMessages: () => Navigator.pop(context),
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
    final bool isCompleted = _pageState == ChatPageState.completed;
    final bool isGenerating = _pageState == ChatPageState.generatingQuestion;
    final bool isProcessing = _pageState == ChatPageState.processingAnswer;
    final bool canSendMessage = _pageState == ChatPageState.waitingForAnswer;

    return Scaffold(
      appBar: ChatAppBar(
        chatRoomName: chatRoomName,
        viewOnly: widget.viewOnly,
        currentQuestionIndex: currentQuestionIndex,
        questionCount: widget.questionCount,
        isInterviewCompleted: isCompleted,
        onShowFeedback: _showFeedbackDialog,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          ),
        ),
        child: Column(
          children: [
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
                    ChatMessageList(
                      scrollController: _scrollController,
                      messages: messages,
                      isGeneratingQuestion: isGenerating,
                      fontSize: fontSize,
                    ),
                    if (isProcessing)
                      const LinearProgressIndicator(color: Colors.indigo),
                  ],
                ),
              ),
            ),
            if (!widget.viewOnly)
              MessageInputBar(
                messageController: _messageController,
                onSendMessage: _sendMessage,
                isInterviewCompleted: isCompleted,
                isLoading: !canSendMessage,
              ),
          ],
        ),
      ),
    );
  }
}