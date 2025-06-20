import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1';

  // API 키 접근자
  static String? get _groqApiKey => dotenv.env['GROQ_API_KEY'];
  static bool get isGroqAvailable => _groqApiKey != null && _groqApiKey!.isNotEmpty;

  // Groq API 사용
  static Future<String> generateQuestionWithGroq({
    required String prompt,
    required String jobPosition,
    required int questionNumber,
    required List<String> previousQuestions,
  }) async {
    if (!isGroqAvailable) {
      throw Exception('Groq API key not found');
    }

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

  // Groq로 피드백 생성
  static Future<String> generateFeedbackWithGroq({
    required String question,
    required String answer,
    required String jobPosition,
  }) async {
    if (!isGroqAvailable) {
      throw Exception('Groq API key not found');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_groqApiKey',
    };

    final systemPrompt = '''
당신은 경험이 풍부한 면접관입니다.
직무: $jobPosition

면접자의 답변에 대해 건설적이고 구체적인 피드백을 제공해주세요.

피드백 구조:
✅ 좋은 점 (2-3개)
🔄 개선점 (1-2개)  
💡 조언 (구체적인 팁)

질문: $question
답변: $answer

친근하면서도 전문적인 톤으로 답변해주세요.
''';

    final body = {
      'model': 'llama3-8b-8192',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': '이 답변에 대한 피드백을 제공해주세요.'}
      ],
      'max_tokens': 400,
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

  // 데모용 질문 풀 (폴백용)
  static final List<Map<String, List<String>>> _demoQuestions = [
    {
      'general': [
        '자기소개를 간단히 해주세요.',
        '이 직무에 지원한 이유는 무엇인가요?',
        '본인의 장점과 단점은 무엇인가요?',
        '팀워크 경험에 대해 말씀해주세요.',
        '가장 큰 성취는 무엇이라고 생각하시나요?',
        '어려운 상황을 극복한 경험이 있나요?',
        '5년 후 본인의 모습은 어떨 것 같나요?',
        '스트레스를 어떻게 관리하시나요?',
        '새로운 기술을 학습하는 방법은 무엇인가요?',
        '우리 회사에 대해 알고 있는 것이 있나요?',
      ]
    },
    {
      'frontend': [
        'React와 Vue.js의 차이점에 대해 설명해주세요.',
        'CSS의 box model에 대해 설명해주세요.',
        '웹 접근성(Web Accessibility)이 왜 중요한가요?',
        'SPA(Single Page Application)의 장단점은?',
        '브라우저의 렌더링 과정에 대해 설명해주세요.',
        'TypeScript를 사용하는 이유는 무엇인가요?',
        '웹 성능 최적화 방법에는 어떤 것들이 있나요?',
        'JavaScript의 호이스팅에 대해 설명해주세요.',
        'Virtual DOM이 무엇인지 설명해주세요.',
      ]
    },
    {
      'backend': [
        'RESTful API 설계 원칙에 대해 설명해주세요.',
        'SQL과 NoSQL의 차이점은 무엇인가요?',
        '마이크로서비스 아키텍처의 장단점은?',
        '데이터베이스 인덱스가 무엇이고 왜 사용하나요?',
        'HTTP 상태 코드 중 자주 사용되는 것들을 설명해주세요.',
        '캐싱 전략에는 어떤 것들이 있나요?',
        'JWT 토큰의 장단점에 대해 설명해주세요.',
        '데이터베이스 트랜잭션이란 무엇인가요?',
      ]
    },
    {
      'mobile': [
        'Flutter와 React Native의 차이점은?',
        '모바일 앱의 생명주기에 대해 설명해주세요.',
        'State Management가 왜 중요한가요?',
        '크로스플랫폼 개발의 장단점은?',
        '앱 성능 최적화 방법에는 어떤 것들이 있나요?',
        'Flutter의 위젯 트리에 대해 설명해주세요.',
        'Provider와 Bloc의 차이점은 무엇인가요?',
        '모바일 앱의 메모리 관리는 어떻게 하나요?',
      ]
    },
  ];

  static final List<String> _demoFeedbacks = [
    '''✅ 좋은 점:
• 질문을 잘 이해하고 체계적으로 답변하셨습니다
• 구체적인 예시를 들어 설명해주셨네요
• 자신감 있는 태도가 인상적입니다

🔄 개선점:
• 조금 더 간결하게 요점을 정리하면 좋겠습니다

💡 조언:
• 실무 경험이나 프로젝트 사례를 더 추가하면 더욱 좋은 답변이 될 것 같습니다''',

    '''✅ 좋은 점:
• 논리적인 사고 과정이 잘 드러났습니다
• 기술적 이해도가 높아 보입니다
• 질문의 핵심을 잘 파악하셨네요

🔄 개선점:
• 실제 적용 사례를 더 구체적으로 말씀해주시면 좋겠습니다

💡 조언:
• 이론뿐만 아니라 실무에서의 경험담을 함께 얘기하면 더 설득력이 있을 것입니다''',

    '''✅ 좋은 점:
• 차분하고 신중한 답변 태도가 좋습니다
• 다양한 관점에서 접근하려는 모습이 인상적입니다
• 성실함이 잘 드러나는 답변이었습니다

🔄 개선점:
• 조금 더 자신감 있게 답변하시면 좋겠습니다

💡 조언:
• 본인의 강점을 더 적극적으로 어필해보세요''',

    '''✅ 좋은 점:
• 문제 해결 능력이 돋보이는 답변입니다
• 창의적인 접근 방식이 인상적입니다
• 학습 의욕이 높아 보입니다

🔄 개선점:
• 답변을 조금 더 구조화하면 좋겠습니다

💡 조언:
• STAR 기법(상황-과제-행동-결과)을 활용해 답변해보세요''',

    '''✅ 좋은 점:
• 실무 경험이 잘 녹아있는 답변입니다
• 협업 능력이 뛰어나 보입니다
• 책임감 있는 태도가 느껴집니다

🔄 개선점:
• 구체적인 수치나 결과를 더 포함하면 좋겠습니다

💡 조언:
• 성과를 정량적으로 표현할 수 있는 방법을 생각해보세요'''
  ];

  // 데모 질문 생성 (폴백용)
  static String _generateDemoQuestion({
    required String jobPosition,
    required List<String> previousQuestions,
  }) {
    String category = 'general';

    // 직무에 따른 카테고리 선택
    if (jobPosition.toLowerCase().contains('프론트엔드') ||
        jobPosition.toLowerCase().contains('frontend') ||
        jobPosition.toLowerCase().contains('react') ||
        jobPosition.toLowerCase().contains('vue') ||
        jobPosition.toLowerCase().contains('웹')) {
      category = 'frontend';
    } else if (jobPosition.toLowerCase().contains('백엔드') ||
        jobPosition.toLowerCase().contains('backend') ||
        jobPosition.toLowerCase().contains('서버') ||
        jobPosition.toLowerCase().contains('server') ||
        jobPosition.toLowerCase().contains('api')) {
      category = 'backend';
    } else if (jobPosition.toLowerCase().contains('모바일') ||
        jobPosition.toLowerCase().contains('flutter') ||
        jobPosition.toLowerCase().contains('앱') ||
        jobPosition.toLowerCase().contains('mobile') ||
        jobPosition.toLowerCase().contains('android') ||
        jobPosition.toLowerCase().contains('ios')) {
      category = 'mobile';
    }

    // 해당 카테고리의 질문들 가져오기
    List<String> questions = _demoQuestions
        .firstWhere((map) => map.containsKey(category), orElse: () => _demoQuestions.first)
    [category]!;

    // 일반 질문도 섞어서 추가
    questions.addAll(_demoQuestions.first['general']!);

    // 이미 사용된 질문 제외
    List<String> availableQuestions = questions
        .where((q) => !previousQuestions.any((prev) => prev.contains(q.split('.').first)))
        .toList();

    if (availableQuestions.isEmpty) {
      return '마지막 질문입니다. 우리 회사에 궁금한 점이 있다면 자유롭게 질문해주세요.';
    }

    // 랜덤하게 질문 선택
    final random = Random();
    return availableQuestions[random.nextInt(availableQuestions.length)];
  }

  // 메인 질문 생성 메서드 (Groq 우선, 폴백 포함)
  static Future<String> generateQuestion({
    required String prompt,
    required String jobPosition,
    required int questionNumber,
    required List<String> previousQuestions,
  }) async {
    // Groq API 사용 시도
    if (isGroqAvailable) {
      try {
        print('Groq AI로 질문 생성 중...');
        return await generateQuestionWithGroq(
          prompt: prompt,
          jobPosition: jobPosition,
          questionNumber: questionNumber,
          previousQuestions: previousQuestions,
        );
      } catch (e) {
        print('⚠️ Groq API 실패, 데모 모드로 전환: $e');
      }
    } else {
      print('📱 API 키가 없어 데모 모드로 실행 중...');
    }

    // 폴백: 데모 질문 사용
    print('📱 데모 질문을 생성 중...');
    return _generateDemoQuestion(
      jobPosition: jobPosition,
      previousQuestions: previousQuestions,
    );
  }

  // 피드백 생성 메서드 (Groq 우선, 폴백 포함)
  static Future<String> generateFeedback({
    required String question,
    required String answer,
    required String jobPosition,
  }) async {
    // Groq API 사용 시도
    if (isGroqAvailable) {
      try {
        print('피드백 생성 중...');
        return await generateFeedbackWithGroq(
          question: question,
          answer: answer,
          jobPosition: jobPosition,
        );
      } catch (e) {
        print('⚠️ Groq 피드백 실패, 데모 피드백 사용: $e');
      }
    }

    // 폴백: 랜덤 데모 피드백
    final random = Random();
    return _demoFeedbacks[random.nextInt(_demoFeedbacks.length)];
  }

  // 현재 모드 확인
  static String getCurrentMode() {
    return isGroqAvailable ? 'AI 모드 (Groq)' : '데모 모드';
  }

  // API 상태 확인
  static bool get hasApiConnection => isGroqAvailable;

  // 사용 가능한 모델 목록
  static List<String> get availableModels => [
    'llama3-70b-8192'

  ];
}