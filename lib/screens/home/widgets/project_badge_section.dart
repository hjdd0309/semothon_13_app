import 'package:flutter/material.dart';

class ProjectBadgeSection extends StatelessWidget {
  const ProjectBadgeSection({super.key});

  static const Color titleColor = Color(0xFF3A2A2A);
  static const Color subtitleColor = Color(0xFF7D6666);
  static const Color borderColor = Color(0xFFEAE1E1);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          '내 프로젝트 현황',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        SizedBox(height: 12),
        // Added 'const' here to the Row
        const Row(
          children: [
            Expanded(
              child: _ProjectBadgeCard(
                imagePath: 'assets/images/2nd.png',
                projectName: '세계와 시민',
                participation: '참여율 80%',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _ProjectBadgeCard(
                imagePath: 'assets/images/1st.png',
                projectName: '소프트웨어공학',
                participation: '참여율 95%',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _ProjectBadgeCard(
                imagePath: 'assets/images/3rd.png',
                projectName: '캡스톤 디자인',
                participation: '참여율 40%',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Ensure the sub-widget has a const constructor (which yours already does)
class _ProjectBadgeCard extends StatelessWidget {
  final String imagePath;
  final String projectName;
  final String participation;

  const _ProjectBadgeCard({
    required this.imagePath,
    required this.projectName,
    required this.participation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProjectBadgeSection.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            imagePath,
            width: 100,
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 3),
          Text(
            projectName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ProjectBadgeSection.titleColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            participation,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ProjectBadgeSection.subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}