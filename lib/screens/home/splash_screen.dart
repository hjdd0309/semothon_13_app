import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2F2),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '쿠옹',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7A0019),
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 28),

                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EDEE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 90,
                    color: Color(0xFF7A0019),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  '팀플, 이제 편하게 하자',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7A0019),
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  '어색한 첫 만남부터 완성까지,\n팀플을 설계하다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF6B6060),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // 나중에 로그인 화면 연결
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A0019),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '시작하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}