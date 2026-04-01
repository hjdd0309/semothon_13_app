import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeCalendarCard extends StatefulWidget {
  const HomeCalendarCard({super.key});

  @override
  State<HomeCalendarCard> createState() => _HomeCalendarCardState();
}

class CalendarEvent {
  final String title;
  final Color color;
  const CalendarEvent(this.title, this.color);
}

class _HomeCalendarCardState extends State<HomeCalendarCard> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  final Map<DateTime, List<CalendarEvent>> _events = {
    DateTime(2026, 4, 1): const [
      CalendarEvent('디자인적 사고 아이디어 회의 18:00', Color(0xFF90CAF9)),
      CalendarEvent('캡스톤 디자인 발표 주제 정리', Color(0xFFFFCC80)),
    ],
    DateTime(2026, 4, 2): const [
      CalendarEvent('소프트웨어 공학 자료조사 마감', Color(0xFFA5D6A7)),
    ],
    DateTime(2026, 4, 3): const [
      CalendarEvent('세계와 시민 13조 중간 점검 회의 14:00', Color(0xFFB39DDB)),
      CalendarEvent('PPT 초안 작성', Color(0xFFEF9A9A)),
    ],
  };

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[_normalize(day)] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents =
        _selectedDay == null ? const <CalendarEvent>[] : _getEventsForDay(_selectedDay!);

    final textColor = const Color(0xFF2F3437);
    final subTextColor = const Color(0xFF6B6F76);
    final borderColor = const Color(0xFFE9E9E7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '일정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            locale: 'ko_KR',
            startingDayOfWeek: StartingDayOfWeek.monday,

            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            calendarFormat: CalendarFormat.month,

            // 줄(칩)을 넣으려면 칸 높이를 조금 넉넉하게
            daysOfWeekHeight: 22,
            rowHeight: 56,

            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: subTextColor),
              rightChevronIcon: Icon(Icons.chevron_right, color: subTextColor),
              headerPadding: const EdgeInsets.only(bottom: 6),
            ),

            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subTextColor,
              ),
              weekendStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subTextColor,
              ),
            ),

            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              isTodayHighlighted: true,

              // "점" 스타일은 안 쓰고 markerBuilder로 직접 그림
              markerSize: 0,
              markersMaxCount: 0,

              // 타일 여백
              cellMargin: const EdgeInsets.all(6),

              // 선택/오늘은 노션처럼 은은하게
              todayDecoration: BoxDecoration(
                color: const Color(0xFFEDF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              selectedDecoration: BoxDecoration(
                color: const Color(0xFF2F6FED).withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2F6FED), width: 1),
              ),
              defaultTextStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              weekendTextStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              todayTextStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
              selectedTextStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),

            // 핵심: "가로줄 일정"은 markerBuilder로 그린다
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;

                final items = events.take(3).toList(); // 최대 3개만 표시
                return Padding(
                  padding: const EdgeInsets.only(left: 3, right: 3, bottom: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final e in items)
                        Container(
                          height: 14,
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: e.color.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            e.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2328),
                            ),
                          ),
                        ),
                      if (events.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 2),
                          child: Text(
                            '+${events.length - 3} more',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: subTextColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },

              // 날짜 숫자를 위쪽에 고정 (칩이 아래에 쌓이게)
              defaultBuilder: (context, day, focusedDay) {
                return _DayNumberTop(day: day.day);
              },
              todayBuilder: (context, day, focusedDay) {
                return _DayNumberTop(day: day.day);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _DayNumberTop(day: day.day);
              },
            ),

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          ),

          const SizedBox(height: 14),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 12),

          Text(
            _selectedDay == null
                ? '선택한 날짜'
                : '${_selectedDay!.month}월 ${_selectedDay!.day}일',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),

          if (selectedEvents.isEmpty)
            Text(
              '등록된 일정이 없습니다.',
              style: TextStyle(
                fontSize: 13,
                color: subTextColor,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            ...selectedEvents.map((e) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: e.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: e.color.withOpacity(0.30)),
                ),
                child: Text(
                  e.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DayNumberTop extends StatelessWidget {
  const _DayNumberTop({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '$day',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2F3437),
          ),
        ),
      ),
    );
  }
}