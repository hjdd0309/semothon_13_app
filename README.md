# semoton_app

A new Flutter project.

페이지 간 토큰 정송 예시

```
import 'package:flutter/material.dart';
import '../services/project_service.dart';
import '../services/auth_service.dart';

class NewScreen extends StatefulWidget {
  final ProjectService projectService;
  final AuthService authService;

  const NewScreen({
    super.key,
    required this.projectService,
    required this.authService,
  });

  @override
  State<NewScreen> createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {

  late final ProjectService _projectService;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();

    _projectService = widget.projectService;
    _authService = widget.authService;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Screen'),
      ),

      body: Center(
        child: ElevatedButton(
          child: const Text('다음 화면 이동'),
          onPressed: () {

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnotherScreen(
                  projectService: _projectService,
                  authService: _authService,
                ),
              ),
            );

          },
        ),
      ),
    );
  }
}
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
=======

# semothon_13_app

세모톤 13조 앱 프론트 용입니다
