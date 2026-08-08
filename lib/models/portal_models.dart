import 'package:flutter/material.dart';

class StudentProfile {
  const StudentProfile({
    required this.name,
    required this.className,
    required this.rollNumber,
    required this.email,
    required this.phone,
    required this.address,
    required this.photoInitials,
  });

  final String name;
  final String className;
  final String rollNumber;
  final String email;
  final String phone;
  final String address;
  final String photoInitials;
}

class ResultRecord {
  const ResultRecord({
    required this.subject,
    required this.marks,
    required this.grade,
    required this.status,
  });

  final String subject;
  final int marks;
  final String grade;
  final String status;
}

class NoteItem {
  const NoteItem({
    required this.subject,
    required this.teacher,
    required this.className,
    required this.title,
    required this.uploadDate,
    required this.icon,
  });

  final String subject;
  final String teacher;
  final String className;
  final String title;
  final String uploadDate;
  final IconData icon;
}

class Announcement {
  const Announcement({
    required this.title,
    required this.message,
    required this.date,
    required this.icon,
  });

  final String title;
  final String message;
  final String date;
  final IconData icon;
}

class ExamSchedule {
  const ExamSchedule({
    required this.subject,
    required this.date,
    required this.time,
  });

  final String subject;
  final String date;
  final String time;
}

class AdminActivity {
  const AdminActivity({
    required this.action,
    required this.owner,
    required this.date,
    required this.status,
  });

  final String action;
  final String owner;
  final String date;
  final String status;
}

class StudentRecord {
  const StudentRecord({
    required this.name,
    required this.className,
    required this.rollNumber,
    required this.email,
    required this.status,
  });

  final String name;
  final String className;
  final String rollNumber;
  final String email;
  final String status;
}

class SummaryMetric {
  const SummaryMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}
