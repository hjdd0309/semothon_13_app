import 'package:flutter/material.dart';
import '../models/project_detail_model.dart';
import '../services/project_service.dart';
import '../services/ai_service.dart';

class RoleAssignmentStageScreen extends StatefulWidget {
  final ProjectDetailModel project;
  final ProjectService service;
  final String selectedTopic;

  const RoleAssignmentStageScreen({
    super.key,
    required this.project,
    required this.service,
    required this.selectedTopic,
  });

  @override
  State<RoleAssignmentStageScreen> createState() => _RoleAssignmentStageScreenState();
}

class _RoleAssignmentStageScreenState extends State<RoleAssignmentStageScreen> {
  bool isLoading = true;
  List<dynamic> assignedTasks = [];
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchRoleDistribution();
  }

  Future<void> _fetchRoleDistribution() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      if (widget.selectedTopic.isEmpty) {
        throw Exception('선택된 주제가 없습니다. 주제 선정 단계에서 먼저 주제를 확정해주세요.');
      }
      final roomId = int.parse(widget.project.projectNumber);
      final result = await AIService.distributeTasks(roomId, widget.selectedTopic);
      
      if (mounted) {
        setState(() {
          assignedTasks = result['todos'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kCream = Color(0xFFFCFAF7);
    const Color kWine = Color(0xFFA31621);
    const Color kText = Color(0xFF231A1C);
    const Color kSub = Color(0xFF8C7E7F);
    const Color kCard = Colors.white;
    const Color kBorder = Color(0xFFEBE2DE);

    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kText,
        title: const Text(
          '역할 및 업무 분배',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: kWine),
                  const SizedBox(height: 20),
                  Text(
                    'AI PM이 최적의 역할을 배분 중입니다...',
                    style: TextStyle(
                      color: kText.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: kWine, size: 48),
                        const SizedBox(height: 16),
                        Text('오류가 발생했습니다:\n$error', textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchRoleDistribution,
                          style: ElevatedButton.styleFrom(backgroundColor: kWine),
                          child: const Text('다시 시도', style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 완료 알림
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF1D9D9)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline, color: kWine, size: 44),
                            const SizedBox(height: 12),
                            const Text(
                              '역할 분배 완료!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: kText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '선택하신 "${widget.selectedTopic}" 주제를 바탕으로\nAI가 팀원별 업무를 할 일 목록에 등록했습니다.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kSub,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '팀원별 업무 배분 결과',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 업무 리스트
                      ...assignedTasks.map((task) {
                        final assigneeName = task['assignee_name'] ?? '미배정';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kWine.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      assigneeName,
                                      style: const TextStyle(
                                        color: kWine,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      task['title'] ?? '업무 내용 없음',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: kText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                task['description'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: kSub,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kWine,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '프로젝트 홈으로 돌아가기',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}