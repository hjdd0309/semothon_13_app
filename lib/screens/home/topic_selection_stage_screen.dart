import 'package:flutter/material.dart';
import 'role_assignment_stage_screen.dart';
import 'project_detail_screen.dart';
import '../models/project_detail_model.dart';
import '../services/project_service.dart';

// --- 1. 데이터 모델 및 모든 과목 질문 데이터 ---
enum QuestionType { singleChoice, multipleChoice, text, multipleChoiceWithOther }

class Question {
  final String title;
  final QuestionType type;
  final List<String> options;
  final int maxSelect;

  Question({
    required this.title,
    required this.type,
    this.options = const [],
    this.maxSelect = 0,
  });
}

final Map<String, List<Question>> subjectQuestions = {
  '세계와 시민': [
    Question(
      title: '우리 조가 다뤄봤으면 하는 사회문제 분야는 무엇인가요? (1~2개 선택)',
      type: QuestionType.multipleChoiceWithOther,
      options: ['환경/생태', '인권/복지', '생활/안전', '교육/문화', '기술/과학'],
      maxSelect: 2,
    ),
    Question(
      title: '최근 일상생활에서 불편을 느끼거나 문제라고 생각했던 경험이 있다면 무엇인가요?',
      type: QuestionType.text,
    ),
    Question(
      title: '해결하는 사회문제의 범위는 어디까지인가요?',
      type: QuestionType.singleChoice,
      options: ['캠퍼스', '지역사회', '대한민국/국가 및 글로벌'],
    ),
    Question(
      title: '이번 활동에서 대변하거나 돕고싶은 구체적 대상은 누구인가요?',
      type: QuestionType.text,
    ),
    Question(
      title: '도전해보고 싶은 해결 방식은 무엇인가요? (1~2개 선택)',
      type: QuestionType.multipleChoiceWithOther,
      options: ['숏폼 영상 제작', '오프라인 캠페인', '카드뉴스 제작', 'SNS 운영', '제도 제안'],
      maxSelect: 2,
    ),
  ],
  '디자인적 사고': [
    Question(
      title: '최근 흥미로웠던 개발 주제가 있으신가요? (중복 가능)',
      type: QuestionType.multipleChoice,
      options: ['사회 문제 해결', '재미있는 서비스', '기술적으로 도전적인', '창업 아이디어', '생활 편의 서비스'],
    ),
    Question(
      title: '어떤 개발 경험이 있으신가요? (중복 가능)',
      type: QuestionType.multipleChoice,
      options: ['디자인 (UI/UX)', '게임 개발', '웹 프로그래밍', '앱 프로그래밍', 'AI / 머신러닝', '시스템 프로그래밍', '데이터 분석'],
    ),
    Question(
      title: '이건 정말 창의적이다라고 생각되시는 아이디어가 있나요?',
      type: QuestionType.text,
    ),
    Question(
      title: '관심있는 문제 영역이 있나요?',
      type: QuestionType.multipleChoice,
      options: ['교육', '환경', '건강', '교통', '커뮤니티', '게임 / 엔터테인먼트', '생산성'],
    ),
    Question(
      title: '프로젝트 결과물이 어디까지 나오면 좋겠나요?',
      type: QuestionType.singleChoice,
      options: ['아이디어 기획 중심', '간단한 프로토타입', '핵심 기능 구현', '대부분 기능 구현', '실제 배포 가능 수준'],
    ),
  ],
  '데이터분석캡스톤디자인': [
    Question(
      title: '우리 조가 다뤄봤으면 하는 사회문제 분야는 무엇인가요? (1~2개 선택)',
      type: QuestionType.multipleChoiceWithOther,
      options: ['환경/생태', '인권/복지', '생활/안전', '교육/문화', '기술/과학'],
      maxSelect: 2,
    ),
    Question(
      title: '최근 일상생활에서 불편을 느끼거나 문제라고 생각했던 경험이 있다면 무엇인가요?',
      type: QuestionType.text,
    ),
    Question(
      title: '해결하는 사회문제의 범위는 어디까지인가요?',
      type: QuestionType.singleChoice,
      options: ['캠퍼스', '지역사회', '대한민국/국가 및 글로벌'],
    ),
    Question(
      title: '이번 활동에서 대변하거나 돕고싶은 구체적 대상은 누구인가요?',
      type: QuestionType.text,
    ),
    Question(
      title: '도전해보고 싶은 해결 방식은 무엇인가요? (1~2개 선택)',
      type: QuestionType.multipleChoiceWithOther,
      options: ['숏폼 영상 제작', '오프라인 캠페인', '카드뉴스 제작', 'SNS 운영', '제도 제안'],
      maxSelect: 2,
    ),
  ],
  '데이터분석캡스톤디자인': [
    Question(
      title: '가장 흥미를 느끼는 산업/도메인은 무엇인가요? (최대 3개)',
      type: QuestionType.multipleChoiceWithOther,
      options: ['스마트시티 / 교통', '헬스케어 / 스포츠', '엔터테인먼트 / 미디어', '금융 / 경제', '소셜 / 커뮤니티'],
      maxSelect: 3,
    ),
    Question(
      title: '메인으로 다뤄보고 싶은 데이터의 종류는 무엇인가요? (1~2개)',
      type: QuestionType.multipleChoice,
      options: ['이미지 / 영상 데이터', '텍스트 데이터', '정형 데이터', '시계열 데이터'],
      maxSelect: 2,
    ),
    Question(
      title: '우리 팀의 최종 결과물은 어떤 형태였으면 좋겠나요?',
      type: QuestionType.singleChoice,
      options: ['웹/앱 서비스', '온디바이스 AI 어플리케이션', '대시보드', '리포트/논문'],
    ),
    Question(
      title: '활용해 보고 싶은 기술 스택이 있나요?',
      type: QuestionType.text,
    ),
    Question(
      title: '데이터로 해결하고 싶은 불편함이 있다면?',
      type: QuestionType.text,
    ),
  ],
};

// --- 2. 주제 선정 화면 ---
class TopicSelectionStageScreen extends StatefulWidget {
  final ProjectDetailModel? project;
  final ProjectService? service;

  const TopicSelectionStageScreen({
    super.key,
    this.project,
    this.service,
  });

  @override
  State<TopicSelectionStageScreen> createState() =>
      _TopicSelectionStageScreenState();
}

class _TopicSelectionStageScreenState extends State<TopicSelectionStageScreen> {
  static const Color kCream = Color(0xFFFCFAF7);
  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFEBE2DE);
  static const Color kText = Color(0xFF231A1C);
  static const Color kSub = Color(0xFF8C7E7F);
  static const Color kWine = Color(0xFFA31621);

  bool hasStarted = false;
  int currentQuestionIndex = 0;
  String selectedSubject = '세계와 시민';
  Map<int, dynamic> answers = {};

  // 텍스트 입력용 컨트롤러 (질문 이동 시 값 유지)
  final Map<int, TextEditingController> _textControllers = {};

  // "기타" 직접입력용 상태
  final Map<int, bool> _otherSelected = {};
  final Map<int, TextEditingController> _otherControllers = {};

  final List<Map<String, dynamic>> participants = [
    {'name': '현정', 'ready': true},
    {'name': '서연', 'ready': true},
    {'name': '유나', 'ready': true},
    {'name': '민지', 'ready': true},
  ];

  final List<Color> cardColors = [
    const Color(0xFFFFF4F4),
    const Color(0xFFFDF7F2),
    const Color(0xFFF8F6FF),
    const Color(0xFFF4FAF6),
    const Color(0xFFFFF4F4),
    const Color(0xFFFDF7F2),
    const Color(0xFFF8F6FF),
  ];

  bool get isAllReady =>
      participants.every((member) => member['ready'] == true);

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    for (final c in _otherControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getTextController(int index) {
    if (!_textControllers.containsKey(index)) {
      _textControllers[index] = TextEditingController(
        text: (answers[index] is String) ? answers[index] : '',
      );
    }
    return _textControllers[index]!;
  }

  TextEditingController _getOtherController(int index) {
    if (!_otherControllers.containsKey(index)) {
      _otherControllers[index] = TextEditingController();
    }
    return _otherControllers[index]!;
  }

  void _startSession() {
    if (!isAllReady) return;
    setState(() {
      hasStarted = true;
      currentQuestionIndex = 0;
      answers.clear();
      _textControllers.forEach((_, c) => c.dispose());
      _textControllers.clear();
      _otherControllers.forEach((_, c) => c.dispose());
      _otherControllers.clear();
      _otherSelected.clear();
    });
  }

  void _goNext() {
    final questions = subjectQuestions[selectedSubject]!;

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      _submitSurveyFake();
    }
  }

  void _goPrevious() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  bool _isCurrentQuestionAnswered() {
    final ans = answers[currentQuestionIndex];
    if (ans == null) return false;
    if (ans is String && ans.trim().isEmpty) return false;
    if (ans is List && ans.isEmpty) return false;
    return true;
  }

  void _submitSurveyFake() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kWine),
              SizedBox(height: 20),
              Text(
                'AI가 주제를 분석 중이에요...',
                style: TextStyle(
                  color: kText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pop(context);

    List<Map<String, String>> dummyTopics = [
      {
        'topic_name': '지역 주민 참여형 도시 안전 모니터링 플랫폼',
        'reason':
        '우리 팀원들 중에 안전 문제에 관심 있는 친구들이 많아서 골랐어요! 실제로 앱으로 만들기도 쉽고, 지역 사회에 도움이 될 것 같아서 추천했어요.',
        'expected_effect':
        '주민들이 직접 참여하면서 안전한 동네 만들기에 동참할 수 있을 거예요. 앱 개발 실전 경험도 쌓고, 지역 공동체도 더 단단해질 것 같아요!',
      },
      {
        'topic_name': '다문화 가정 자녀 교육 지원 커뮤니티 서비스',
        'reason':
        '교육 분야에 관심 있는 팀원들이 많았고, 특히 다문화 학생들을 도와주는 게 의미 있을 것 같아서 골랐어요. 우리 주변에서도 이런 도움이 필요할 때가 많더라고요.',
        'expected_effect':
        '아이들이 언어 때문에 힘들어하지 않도록 도와줄 수 있을 거예요. 지역 사회 사람들도 함께 참여하면서 서로 더 잘 이해하게 될 것 같아요!',
      },
      {
        'topic_name': '청년 사회참여를 위한 온라인 정책 제안 캠페인',
        'reason':
        '청년들이 사회 문제에 관심이 많다는 걸 보고 골랐어요. 정책 참여가 어렵게 느껴지는 친구들에게 쉽게 다가갈 수 있는 방법이 필요할 것 같아서 추천했어요.',
        'expected_effect':
        '청년들의 목소리가 정책에 반영될 수 있도록 도와줄 거예요. 온라인으로 쉽게 참여할 수 있게 하면 더 많은 친구들이 관심 가져줄 것 같아요!',
      },
    ];

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationResultScreen(
          topics: dummyTopics,
          project: widget.project,
          service: widget.service,
        ),
      ),
    );
  }

  // ──────────────────── 시작 화면 ────────────────────
  Widget _buildStartScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 과목 선택 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '주제선정',
                  style: TextStyle(
                      color: kText, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  '어떤 과목의 주제를 정할지 선택해주세요.\n팀원들이 모두 방에 모이면 시작할 수 있어요.',
                  style: TextStyle(
                      color: kSub,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF0D9D9)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSubject,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: kWine),
                      items: subjectQuestions.keys.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: const TextStyle(
                                  color: kText, fontWeight: FontWeight.w700)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedSubject = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 참여 팀원 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '참여 중인 팀원',
                  style: TextStyle(
                      color: kText, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                ...participants.map(
                      (member) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFAFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEBE2DE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                                color: Color(0xFFF3E7E4),
                                shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                member['name'].toString().substring(0, 1),
                                style: const TextStyle(
                                    color: kWine, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(member['name'],
                                style: const TextStyle(
                                    color: kText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEFF8F1),
                                borderRadius: BorderRadius.circular(999)),
                            child: const Text('입장 완료',
                                style: TextStyle(
                                    color: Color(0xFF1D8F49),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 시작 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isAllReady ? _startSession : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kWine,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFE7DEDA),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('시작하기',
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────── 질문 화면 ────────────────────
  Widget _buildQuestionScreen() {
    final questions = subjectQuestions[selectedSubject]!;
    final currentQuestion = questions[currentQuestionIndex];
    final double progress = (currentQuestionIndex + 1) / questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 진행률 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '질문 ${currentQuestionIndex + 1} / ${questions.length}',
                  style: const TextStyle(
                      color: kWine, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: progress,
                    backgroundColor: const Color(0xFFF2ECE8),
                    valueColor: const AlwaysStoppedAnimation(kWine),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 질문 제목 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: kBorder),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF1D9D9)),
                  ),
                  child:
                  const Icon(Icons.edit_document, color: kWine, size: 28),
                ),
                const SizedBox(height: 18),
                Text(
                  currentQuestion.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: kText,
                      fontSize: 21,
                      height: 1.4,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 답변 입력 영역
          _buildQuestionInput(currentQuestion, currentQuestionIndex),
          const SizedBox(height: 16),

          // 응답 현황
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.groups_2_outlined, color: kWine, size: 20),
                SizedBox(width: 8),
                Text('응답 현황 4 / 4',
                    style: TextStyle(
                        color: kText,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 이전 / 다음 버튼
          Row(
            children: [
              if (currentQuestionIndex > 0) ...[
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _goPrevious,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kWine,
                      side: const BorderSide(color: kWine, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                    _isCurrentQuestionAnswered() ? _goNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kWine,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: const Color(0xFFE7DEDA),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      currentQuestionIndex == questions.length - 1
                          ? 'AI에게 주제 추천받기'
                          : '다음 질문',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ──────────────────── 답변 입력 위젯 ────────────────────
  Widget _buildQuestionInput(Question q, int index) {
    // 주관식
    if (q.type == QuestionType.text) {
      final controller = _getTextController(index);
      return TextField(
        controller: controller,
        cursorColor: kWine,
        decoration: InputDecoration(
          hintText: '자유롭게 적어주세요.',
          hintStyle: const TextStyle(color: kSub, fontSize: 15),
          filled: true,
          fillColor: kCard,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: kWine, width: 1.5)),
          contentPadding: const EdgeInsets.all(20),
        ),
        maxLines: 4,
        style: const TextStyle(
            color: kText, fontWeight: FontWeight.w600, fontSize: 16),
        onChanged: (value) => setState(() => answers[index] = value),
      );
    }

    // 객관식 (single / multiple / multipleWithOther)
    final bool isMultiple = q.type == QuestionType.multipleChoice ||
        q.type == QuestionType.multipleChoiceWithOther;
    final bool hasOther = q.type == QuestionType.multipleChoiceWithOther;

    // 옵션 목록 + (기타) 항목
    final int totalCount = q.options.length + (hasOther ? 1 : 0);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        // "기타 (직접 입력)" 항목
        if (hasOther && i == q.options.length) {
          final bool otherOn = _otherSelected[index] ?? false;
          final otherCtrl = _getOtherController(index);

          return Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _otherSelected[index] = !otherOn;

                    if (isMultiple) {
                      answers[index] ??= <String>[];
                      final list = answers[index] as List<String>;
                      if (!otherOn) {
                        // 선택 제한 체크
                        if (q.maxSelect > 0 && list.length >= q.maxSelect) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                Text('최대 ${q.maxSelect}개까지만 선택 가능합니다.')),
                          );
                          _otherSelected[index] = false;
                          return;
                        }
                      } else {
                        // 기타 해제 시 기타 텍스트 제거
                        list.removeWhere(
                                (e) => !q.options.contains(e));
                        otherCtrl.clear();
                      }
                    } else {
                      if (!otherOn) {
                        answers[index] = '';
                      } else {
                        answers[index] = null;
                        otherCtrl.clear();
                      }
                    }
                  });
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFAF5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: otherOn ? kWine : kBorder,
                        width: otherOn ? 2 : 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: otherOn ? kWine : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                              otherOn ? kWine : const Color(0xFFE3D8D4)),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + i),
                            style: TextStyle(
                                color: otherOn ? Colors.white : kText,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('기타 (직접 입력)',
                            style: TextStyle(
                                color: kText,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
              if (otherOn) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: otherCtrl,
                  cursorColor: kWine,
                  decoration: InputDecoration(
                    hintText: '직접 입력해주세요.',
                    hintStyle: const TextStyle(color: kSub, fontSize: 14),
                    filled: true,
                    fillColor: kCard,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                        const BorderSide(color: kWine, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(
                      color: kText, fontWeight: FontWeight.w600, fontSize: 15),
                  onChanged: (value) {
                    setState(() {
                      if (isMultiple) {
                        final list = (answers[index] as List<String>);
                        list.removeWhere((e) => !q.options.contains(e));
                        if (value.trim().isNotEmpty) {
                          list.add(value.trim());
                        }
                      } else {
                        answers[index] = value;
                      }
                    });
                  },
                ),
              ],
            ],
          );
        }

        // 일반 옵션
        final option = q.options[i];
        final bgColor = cardColors[i % cardColors.length];

        bool isSelected = false;
        if (!isMultiple) {
          isSelected =
              answers[index] == option && !(_otherSelected[index] ?? false);
        } else {
          answers[index] ??= <String>[];
          isSelected = (answers[index] as List).contains(option);
        }

        return InkWell(
          onTap: () {
            setState(() {
              if (!isMultiple) {
                // 단일 선택
                answers[index] = option;
                _otherSelected[index] = false;
                _getOtherController(index).clear();
              } else {
                List<String> currentAnswers =
                (answers[index] as List).cast<String>();
                if (isSelected) {
                  currentAnswers.remove(option);
                } else {
                  if (q.maxSelect == 0 ||
                      currentAnswers.length < q.maxSelect) {
                    currentAnswers.add(option);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                        Text('최대 ${q.maxSelect}개까지만 선택 가능합니다.')));
                  }
                }
              }
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isSelected ? kWine : kBorder,
                  width: isSelected ? 2 : 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected ? kWine : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color:
                        isSelected ? kWine : const Color(0xFFE3D8D4)),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: TextStyle(
                          color: isSelected ? Colors.white : kText,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(option,
                      style: const TextStyle(
                          color: kText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kText,
        title:
        const Text('주제선정', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: !hasStarted ? _buildStartScreen() : _buildQuestionScreen(),
    );
  }
}

// --- 3. 추천 결과 화면 ---
class RecommendationResultScreen extends StatelessWidget {
  final List<dynamic> topics;
  final ProjectDetailModel? project;
  final ProjectService? service;

  const RecommendationResultScreen({
    super.key,
    required this.topics,
    this.project,
    this.service,
  });

  static const Color kCream = Color(0xFFFCFAF7);
  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFEBE2DE);
  static const Color kText = Color(0xFF231A1C);
  static const Color kSub = Color(0xFF8C7E7F);
  static const Color kWine = Color(0xFFA31621);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kText,
        title: const Text('AI 추천 결과',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            // 상단 헤더 카드 - 사자 캐릭터가 말하는 디자인
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사자 캐릭터 이미지
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/face.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 말풍선 부분
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1D9D9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('주제 3가지를 추천해줄게요!',
                              style: TextStyle(
                                  color: kText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          const Text(
                            '팀원들 의견을 모아서 골라봤어요!',
                            style: TextStyle(
                                color: kSub,
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 추천 주제 리스트
            Expanded(
              child: ListView.builder(
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: kBorder),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 8,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: kWine,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('${index + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                topic['topic_name'] ?? '주제명 없음',
                                style: const TextStyle(
                                    color: kText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                            '💡 추천 이유', topic['reason'] ?? ''),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                            '🎯 기대 효과', topic['expected_effect'] ?? ''),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 하단 버튼 영역
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (project != null && service != null) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            settings: const RouteSettings(name: 'ProjectDetailScreen'),
                            builder: (_) => ProjectDetailScreen(
                              project: project!,
                              service: service!,
                            ),
                          ),
                          (route) => route.isFirst,
                        );
                      } else {
                        Navigator.of(context).popUntil((route) {
                          return route.settings.name == 'ProjectDetailScreen' || route.isFirst;
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kWine,
                      side: const BorderSide(color: kWine, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('돌아가기',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoleAssignmentStageScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kWine,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('역할 분배하기',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFA), // 수정: 0xFFFFFFAFA → 0xFFFFFAFA
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: kWine)),
          const SizedBox(height: 6),
          Text(content,
              style: const TextStyle(
                  fontSize: 14,
                  color: kText,
                  height: 1.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}