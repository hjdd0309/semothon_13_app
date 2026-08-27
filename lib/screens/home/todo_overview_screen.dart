import 'package:flutter/material.dart';

class TodoOverviewScreen extends StatefulWidget {
  const TodoOverviewScreen({super.key});

  @override
  State<TodoOverviewScreen> createState() => _TodoOverviewScreenState();
}

class _TodoOverviewScreenState extends State<TodoOverviewScreen> {
  static const Color kBg = Color(0xFFF8F5F3);
  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE9DEDA);
  static const Color kText = Color(0xFF231A1C);
  static const Color kSub = Color(0xFF8C7E7F);
  static const Color kWine = Color(0xFFA31621);
  static const Color kGreen = Color(0xFF18A957);

  final List<_MemberTodo> members = [
    _MemberTodo(
      name: 'user_1',
      role: '자료조사',
      todos: [
        _Todo(title: '유사 서비스 5개 조사하기'),
        _Todo(title: '경쟁 서비스 장단점 정리'),
        _Todo(title: '핵심 인사이트 도출'),
      ],
    ),
    _MemberTodo(
      name: 'user_2',
      role: 'PPT 만들기',
      todos: [
        _Todo(title: 'PPT 목차 구성'),
        _Todo(title: '디자인 템플릿 제작'),
        _Todo(title: '최종 발표 슬라이드 정리'),
      ],
    ),
    _MemberTodo(
      name: 'user_3',
      role: '논문 자료 분석',
      todos: [
        _Todo(title: '논문 3편 요약'),
        _Todo(title: '핵심 근거 정리'),
        _Todo(title: '적용 포인트 정리'),
      ],
    ),
    _MemberTodo(
      name: '표지훈',
      role: '발표자',
      todos: [
        _Todo(title: '발표 대본 작성'),
        _Todo(title: '리허설 진행'),
        _Todo(title: 'Q&A 준비'),
      ],
    ),
  ];

  int selectedIndex = 0;

  _MemberTodo get selectedMember => members[selectedIndex];

  void toggleTodo(int memberIndex, int todoIndex) {
    setState(() {
      final todo = members[memberIndex].todos[todoIndex];
      members[memberIndex].todos[todoIndex] =
          todo.copyWith(isDone: !todo.isDone);
    });
  }

  double get progress {
    final done = selectedMember.todos.where((e) => e.isDone).length;
    return done / selectedMember.todos.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: const Text(
          'To Do Overview',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMemberSelector(),
                const SizedBox(height: 16),
                _buildTodoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberSelector() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? kWine : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: Center(
                child: Text(
                  members[index].name,
                  style: TextStyle(
                    color: selected ? Colors.white : kText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${selectedMember.name} - ${selectedMember.role}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),

          /// progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: const Color(0xFFEDE7E4),
              valueColor: const AlwaysStoppedAnimation(kWine),
            ),
          ),

          const SizedBox(height: 16),

          /// todo list
          ...List.generate(
            selectedMember.todos.length,
            (index) {
              final todo = selectedMember.todos[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFAFA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration:
                                todo.isDone ? TextDecoration.lineThrough : null,
                            color: todo.isDone ? kSub : kText,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => toggleTodo(selectedIndex, index),
                        child: Icon(
                          todo.isDone
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: todo.isDone ? kGreen : kWine,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// model
class _MemberTodo {
  final String name;
  final String role;
  final List<_Todo> todos;

  _MemberTodo({
    required this.name,
    required this.role,
    required this.todos,
  });
}

class _Todo {
  final String title;
  final bool isDone;

  _Todo({required this.title, this.isDone = false});

  _Todo copyWith({String? title, bool? isDone}) {
    return _Todo(
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}
