import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 앱 전체 테마를 통일하면 유지/관리하기 편해집니다.
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
      // 전체 배경에 그라데이션 처리
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
              // ==========================
              // 1. 상단 헤더 영역
              // ==========================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 햄버거 메뉴 아이콘 + 테두리
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.indigo, width: 1.25), // 테두리 색
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu, size: 24, color: Colors.indigo),
                        onPressed: () {},
                        splashRadius: 24,
                      ),
                    ),

                    // 로그인/회원가입 버튼 + 테두리
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.indigo), // 테두리 색
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

              // ==========================
              // 2. 중앙 카드 컨테이너
              // ==========================
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 화면 폭의 70%를 기본으로 사용하되, 최소 300, 최대 600 제한
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
                              // 아이콘 + 레이블
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
                                width: cardWidth * 0.9, // 카드 폭의 90%만큼만 버튼 폭 설정
                                child: ElevatedButton(
                                  onPressed: () {
                                    // TODO: 면접 시작 로직 이동
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
}
