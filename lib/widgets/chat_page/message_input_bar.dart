import 'package:flutter/material.dart';

class MessageInputBar extends StatelessWidget {
  final TextEditingController messageController;
  final VoidCallback onSendMessage;
  final bool isInterviewCompleted;
  final bool isLoading;

  const MessageInputBar({
    Key? key,
    required this.messageController,
    required this.onSendMessage,
    required this.isInterviewCompleted,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isInterviewCompleted ? Colors.grey[100] : const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isInterviewCompleted ? Colors.grey[300]! : Colors.indigo.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: messageController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                enabled: !isInterviewCompleted,
                decoration: InputDecoration(
                  hintText: isInterviewCompleted ? "면접이 완료되었습니다" : "답변을 입력해주세요...",
                  hintStyle: TextStyle(color: isInterviewCompleted ? Colors.grey[500] : Colors.black38),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => onSendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: isInterviewCompleted || isLoading ? Colors.grey[400] : Colors.indigo[700],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: (isLoading || isInterviewCompleted) ? null : onSendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
              splashRadius: 24,
            ),
          ),
        ],
      ),
    );
  }
}