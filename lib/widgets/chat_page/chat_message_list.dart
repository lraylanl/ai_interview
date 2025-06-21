import 'package:flutter/material.dart';
import '../../model/chat_message.dart' as model;

class ChatMessageList extends StatelessWidget {
  final ScrollController scrollController;
  final List<model.ChatMessage> messages;
  final bool isGeneratingQuestion;
  final double fontSize;

  const ChatMessageList({
    Key? key,
    required this.scrollController,
    required this.messages,
    required this.isGeneratingQuestion,
    this.fontSize = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length + (isGeneratingQuestion ? 1 : 0),
        itemBuilder: (context, index) {
          if (isGeneratingQuestion && index == messages.length) {
            return _buildLoadingMessage();
          }
          return _buildMessageBubble(messages[index]);
        },
      ),
    );
  }

  Widget _buildMessageBubble(model.ChatMessage message) {
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
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.indigo),
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
                message.content,
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
              child: const Icon(Icons.person, size: 18, color: Colors.white),
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
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.indigo),
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
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}