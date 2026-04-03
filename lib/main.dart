import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home/home_screen.dart';
import 'screens/services/auth_service.dart';
import 'screens/services/project_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  final authService = AuthService();
  final projectService = ProjectService(
    baseUrl: 'https://semothon13app-production.up.railway.app',
  );

  final savedToken = await authService.getSavedToken();
  if (savedToken != null) {
    projectService.setAccessToken(savedToken);
  }

  runApp(
    AicoApp(
      authService: authService,
      projectService: projectService,
    ),
  );
}

class AicoApp extends StatelessWidget {
  final AuthService authService;
  final ProjectService projectService;

  const AicoApp({
    super.key,
    required this.authService,
    required this.projectService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '에코 (ai-coach)',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F1F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA31621),
        ),
      ),
      home: HomeScreen(
        authService: authService,
        projectService: projectService,
      ),
    );
  }
}