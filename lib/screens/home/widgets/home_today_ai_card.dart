import 'package:flutter/material.dart';

class HomeTodayAiCard extends StatelessWidget {
  const HomeTodayAiCard({super.key});

  static const primaryColor = Color(0xFFA31621);
  static const titleColor = Color(0xFF3A2A2A);
  static const subtitleColor = Color(0xFF7D6666);
  static const borderColor = Color(0xFFEAE1E1);

  static const softPink = Color(0xFFF9F1F1);
  static const softCardColor = Color(0xFFFCFBFB);

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 데이터로 교체
    final rawTasks = <String>[
      '소프트웨어공학 자료조사 마감',
      '오후 7시 팀 회의',
      'PPT 초안 검토',
    ];

    final analysis = _analyzeToday(rawTasks);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
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
          // 가운데 쿠옹이
          Center(
            child: Image.asset(
              'assets/images/hikhuong-nk.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),

          // 브리핑만 남김
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: softCardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _aiBadge(),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '쿠옹이 AI 브리핑',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // summary: 1문장
                Text(
                  analysis.summary,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),

                const SizedBox(height: 10),

                // 태그(짧게)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip(
                      '마감 ${analysis.deadlineCount}개',
                      const Color(0xFFFDE8EA),
                    ),
                    _chip(
                      '회의 ${analysis.meetingCount}개',
                      const Color(0xFFF6F1F1),
                    ),
                    _chip(
                      '오늘 우선 집중',
                      const Color(0xFFFFF4F1),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: borderColor, height: 1),
                const SizedBox(height: 12),

                // briefingMessage: 불릿 2~3개 (최대 3줄)
                Text(
                  analysis.briefingMessage,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF5F4747),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                // coachingLine: 1문장
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: softPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    analysis.coachingLine,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: subtitleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _aiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8EA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF3C9CE)),
      ),
      child: const Text(
        'AI',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: primaryColor,
        ),
      ),
    );
  }

  static Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: titleColor,
        ),
      ),
    );
  }

  // ---- 분석(짧게) ----
  _TodayAnalysis _analyzeToday(List<String> rawTasks) {
    final items = rawTasks.map(_toAiItem).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final deadlineCount =
        items.where((e) => e.type == _TaskType.deadline).length;
    final meetingCount =
        items.where((e) => e.type == _TaskType.meeting).length;

    // 1) summary: 1문장
    final summary = (deadlineCount > 0 && meetingCount > 0)
        ? '오늘은 마감+회의가 같이 있어요. 우선순위만 잘 잡으면 돼요.'
        : (deadlineCount > 0)
            ? '오늘은 “마감”이 최우선이에요.'
            : (meetingCount > 0)
                ? '오늘은 “회의 준비”가 핵심이에요.'
                : '오늘은 정리/검토로 흐름 정리하기 좋아요.';

    // 2) briefingMessage: 불릿 2~3개
    String bullet(String s) => '• $s';

    final top = items.take(3).toList();
    final bullets = <String>[];

    if (top.isNotEmpty) bullets.add(bullet('1순위: ${top[0].title}'));
    if (top.length >= 2) bullets.add(bullet('2순위: ${top[1].title}'));

    if (meetingCount > 0) {
      bullets.add(bullet('회의 전: 결론/질문 3개만 메모'));
    } else if (deadlineCount > 0) {
      bullets.add(bullet('마감은 “제출 가능 상태”까지 먼저 만들기'));
    } else {
      bullets.add(bullet('짧은 것부터 처리해서 추진력 만들기'));
    }

    final briefingMessage = bullets.take(3).join('\n');

    // 3) coachingLine: 1문장
    final coachingLine = meetingCount > 0
        ? '회의 10분 전 체크리스트만 만들면 팀플이 훨씬 매끄러워져요.'
        : '오늘은 한 가지를 끝내고 다음으로 넘어가면 집중이 덜 깨져요.';

    return _TodayAnalysis(
      summary: summary,
      briefingMessage: briefingMessage,
      coachingLine: coachingLine,
      deadlineCount: deadlineCount,
      meetingCount: meetingCount,
    );
  }

  _AiTaskItem _toAiItem(String text) {
    bool has(List<String> keys) => keys.any((k) => text.contains(k));

    _TaskType type = _TaskType.normal;
    int score = 10;

    if (has(['마감', '제출'])) {
      type = _TaskType.deadline;
      score += 60;
    }
    if (has(['회의', '미팅'])) {
      type = _TaskType.meeting;
      score += 40;
    }
    if (has(['자료조사', '조사', '리서치'])) score += 25;
    if (has(['초안', '작성', '정리'])) score += 20;
    if (has(['검토', '리뷰'])) score += 15;

    if (RegExp(r'\d{1,2}:\d{2}').hasMatch(text) ||
        text.contains('오후') ||
        text.contains('오전')) {
      score += 10;
    }

    return _AiTaskItem(title: text, type: type, score: score);
  }
}

enum _TaskType { deadline, meeting, normal }

class _AiTaskItem {
  final String title;
  final _TaskType type;
  final int score;
  _AiTaskItem({
    required this.title,
    required this.type,
    required this.score,
  });
}

class _TodayAnalysis {
  final String summary; // 1문장
  final String briefingMessage; // 불릿 2~3개
  final String coachingLine; // 1문장
  final int deadlineCount;
  final int meetingCount;

  _TodayAnalysis({
    required this.summary,
    required this.briefingMessage,
    required this.coachingLine,
    required this.deadlineCount,
    required this.meetingCount,
  });
}