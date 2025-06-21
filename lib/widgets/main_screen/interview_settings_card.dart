import 'package:flutter/material.dart';

class InterviewSettingsCard extends StatelessWidget {
  final TextEditingController chatRoomNameController;
  final TextEditingController promptController;
  final int questionCount;
  final VoidCallback onStartInterview;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const InterviewSettingsCard({
    Key? key,
    required this.chatRoomNameController,
    required this.promptController,
    required this.questionCount,
    required this.onStartInterview,
    required this.onIncrement,
    required this.onDecrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
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
            TextField(
              controller: chatRoomNameController,
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
            TextField(
              controller: promptController,
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
                        onPressed: onDecrement,
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
                        onPressed: onIncrement,
                        icon: const Icon(Icons.add),
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onStartInterview,
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
    );
  }
}