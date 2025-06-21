import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1';

  // API 키 접근자
  static String? get _groqApiKey => dotenv.env['GROQ_API_KEY'];
  static bool get isGroqAvailable => _groqApiKey != null && _groqApiKey!.isNotEmpty;

  // 메인 질문 생성 메서드
  static Future<String> generateQuestion({
    required String prompt,
    required String jobPosition,
    required int questionNumber,
    required List<String> previousQuestions,
  }) async {
    if (!isGroqAvailable) {
      throw Exception('Groq API key not found in .env file');
    }

    print('Groq AI로 질문 생성 중...');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_groqApiKey',
    };

    final systemPrompt = '''
당신은 전문적인 면접관입니다. 
직무: $jobPosition
면접자의 추가 정보: $prompt

이전 질문들: ${previousQuestions.join(', ')}

다음 규칙을 따라 질문을 생성해주세요:
1. 이전 질문과 중복되지 않도록 해주세요
2. 해당 직무에 적합한 전문적인 질문을 해주세요
3. 질문만 답변해주세요 (번호나 추가 설명 없이)
4. 한국어로 답변해주세요
5. 질문은 구체적이고 실무중심적이어야 합니다
''';

    final body = {
      'model': 'llama3-70b-8192',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': '다음 면접 질문을 생성해주세요.'}
      ],
      'max_tokens': 200,
      'temperature': 0.7,
    };

    try {
      final response = await http.post(
        Uri.parse('$_groqBaseUrl/chat/completions'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        print('Groq API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Groq API 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Groq AI 질문 생성 실패: $e');
    }
  }

  // 피드백 생성 메서드
  static Future<String> generateFeedback({
    required String question,
    required String answer,
    required String jobPosition,
  }) async {
    if (!isGroqAvailable) {
      throw Exception('Groq API key not found in .env file');
    }

    print('Groq AI로 피드백 생성 중...');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_groqApiKey',
    };

    final systemPrompt = '''
당신은 한국어로 답변하는, 경험이 풍부한 IT 면접관입니다.
직무: $jobPosition

면접자의 질문과 답변을 보고, 다음 규칙에 따라 상세한 피드백을 생성해주세요.

[피드백 규칙]
1. 반드시 한국어로만 작성해야 합니다.
2. 면접자의 답변에 대해 건설적이고 구체적인 피드백을 제공해야 합니다.
3. 아래 제공된 '피드백 구조'를 정확히 따라야 합니다.
4. 친근하면서도 전문적인 톤을 유지해야 합니다.

[피드백 구조]
✅ 좋은 점: (2~3개 항목으로 구체적으로 작성)
🔄 개선점: (1~2개 항목으로 구체적으로 작성)  
💡 조언: (실질적인 팁 제공)

[면접 내용]
- 질문: $question
- 답변: $answer
''';

    final body = {
      'model': 'llama3-70b-8192',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': '이 답변에 대한 피드백을 제공해주세요.'}
      ],
      'max_tokens': 500,
      'temperature': 0.6,
    };

    try {
      final response = await http.post(
        Uri.parse('$_groqBaseUrl/chat/completions'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        throw Exception('Groq 피드백 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Groq 피드백 생성 실패: $e');
    }
  }
}