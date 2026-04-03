import 'package:flutter/material.dart';
import 'signup_screen.dart';
import '../home/home_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/project_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final ProjectService projectService;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.projectService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  static const Color primaryColor = Color(0xFFA31621);
  static const Color bgColor = Color(0xFFF6F1F1);
  static const Color cardColor = Colors.white;
  static const Color subtitleColor = Color(0xFF7D6666);
  static const Color inputFillColor = Color(0xFFF9F1F1);
  static const Color featureCardColor = Color(0xFFF7EFEF);

  AuthService get _authService => widget.authService;
  ProjectService get _projectService => widget.projectService;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> onLoginPressed() async {
    final username = emailController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요.')),
      );
      return;
    }

    try {
      final token = await _authService.login(
        username: username,
        password: password,
      );

      _projectService.setAccessToken(token);

      String realName = '사용자';

      try {
        final profileResponse = await http.get(
          Uri.parse(
            'https://semothon13app-production.up.railway.app/profile/me',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);

          realName =
              profileData['name']?.toString() ??
                  profileData['real_name']?.toString() ??
                  profileData['display_name']?.toString() ??
                  '사용자';

          if (realName.trim().isEmpty) {
            realName = '사용자';
          }
        }
      } catch (_) {}

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName: realName,
            authService: _authService,
            projectService: _projectService,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void onSignupPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SignupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, 0),
                              child: Image.asset(
                                'assets/images/mainlogo.png',
                                width: 290,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Transform.translate(
  offset: const Offset(0, -10),
  child: const Column(
    children: [
      Text(
        '에코 (ai-coach)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFB11226),
          letterSpacing: -0.2,
          height: 1.3,
        ),
      ),
      SizedBox(height: 8),
      Text(
        '첫 만남의 어색함부터 프로젝트 완성까지\n팀플의 흐름을 함께 설계하는 AI 코치',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF8A7A7A),
          height: 1.5,
          letterSpacing: -0.1,
        ),
      ),
    ],
  ),
),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCFBFB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFEAE1E1),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '이메일',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5F4747),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: '이메일을 입력하세요',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFA58787),
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: inputFillColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE7C9C9),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: primaryColor,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                '비밀번호',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5F4747),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFA58787),
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: inputFillColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE7C9C9),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: primaryColor,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: onLoginPressed,
                                  icon: const Icon(
                                    Icons.people_outline,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    '로그인',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: GestureDetector(
                                  onTap: onSignupPressed,
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: subtitleColor,
                                      ),
                                      children: [
                                        TextSpan(text: '아직 계정이 없으신가요? '),
                                        TextSpan(
                                          text: '회원가입',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 72,
                                decoration: BoxDecoration(
                                  color: featureCardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_outlined,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'AI 팀장 쿠옹',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF4B3A3A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 72,
                                decoration: BoxDecoration(
                                  color: featureCardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.groups_2_outlined,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '스마트 협업',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF4B3A3A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}