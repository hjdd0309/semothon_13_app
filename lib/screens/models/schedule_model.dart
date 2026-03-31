import 'package:flutter/material.dart';

class ScheduleModel {
  final int id;
  final String title;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const ScheduleModel({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final dynamic dateValue = json['date'] ?? json['day'];
    final dynamic titleValue = json['title'] ?? json['name'];
    final dynamic startValue = json['startTime'] ?? json['start_time'];
    final dynamic endValue = json['endTime'] ?? json['end_time'];

    return ScheduleModel(
      id: _toInt(json['id']),
      title: _toString(titleValue),
      date: _parseDate(dateValue),
      startTime: _parseTimeOfDay(startValue),
      endTime: _parseTimeOfDay(endValue),
    );
  }

  ScheduleModel copyWith({
    int? id,
    String? title,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'startTime': _timeOfDayToString(startTime),
      'endTime': _timeOfDayToString(endTime),
    };
  }

  String get startTimeText => _timeOfDayToString(startTime);
  String get endTimeText => _timeOfDayToString(endTime);

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();

    final raw = value.toString();
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;

    return DateTime.now();
  }

  static TimeOfDay _parseTimeOfDay(dynamic value) {
    if (value == null) {
      return const TimeOfDay(hour: 9, minute: 0);
    }

    if (value is TimeOfDay) return value;

    final raw = value.toString().trim();
    final parts = raw.split(':');

    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }

    return const TimeOfDay(hour: 9, minute: 0);
  }

  static String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
