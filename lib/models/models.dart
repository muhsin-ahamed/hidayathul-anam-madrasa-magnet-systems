// models.dart
import 'package:flutter/material.dart';
import 'user_role.dart';

enum UserStatus { active, inactive }

enum ResultStatus { pass, fail }

enum HallTicketStatus { generated, locked }

enum AnnouncementTarget { all, students, teachers, classTarget }

// Helper function to safely parse dates
DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

// Helper to safely parse double
double parseDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? defaultValue;
}

// Helper to safely parse int
int parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? defaultValue;
}

// Helper to resolve class name from various JSON shapes
String? _resolveClassName(dynamic map) {
  if (map == null) return null;
  if (map is Map) {
    if (map['className'] != null && map['className'].toString().trim().isNotEmpty) {
      final val = map['className'].toString().trim();
      if (val != 'Class') return val;
    }
    if (map['class_name'] != null && map['class_name'].toString().trim().isNotEmpty) {
      final val = map['class_name'].toString().trim();
      if (val != 'Class') return val;
    }
    if (map['assignedClassName'] != null && map['assignedClassName'].toString().trim().isNotEmpty) {
      final val = map['assignedClassName'].toString().trim();
      if (val != 'Class') return val;
    }
    final classData = map['class'] ?? map['classes'];
    if (classData != null) {
      if (classData is Map) {
        final section = classData['section']?.toString();
        final name = (classData['class_name'] ?? classData['className'] ?? classData['name'] ?? '').toString();
        if (name.isNotEmpty) {
          return (section != null && section.isNotEmpty && !name.contains(section))
              ? '$name - $section'
              : name;
        }
      } else if (classData is List && classData.isNotEmpty) {
        final first = classData.first;
        if (first is Map) {
          final section = first['section']?.toString();
          final name = (first['class_name'] ?? first['className'] ?? first['name'] ?? '').toString();
          if (name.isNotEmpty) {
            return (section != null && section.isNotEmpty && !name.contains(section))
                ? '$name - $section'
                : name;
          }
        }
      }
    }
  }
  return null;
}

class Profile {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? avatarUrl;

  Profile({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
  });

  Profile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? avatarUrl,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? map['fullName'] as String? ?? '',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      role: UserRoleLabel.fromDbValue(map['role'] as String? ?? 'super_admin'),
      isActive: map['is_active'] as bool? ?? map['isActive'] as bool? ?? true,
      createdAt: parseDateTime(map['created_at'] ?? map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updated_at'] ?? map['updatedAt']) ?? DateTime.now(),
      avatarUrl: map['avatar_url'] as String? ?? map['avatarUrl'] as String? ?? map['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role.dbValue,
      'is_active': isActive,
      'avatar_url': avatarUrl,
    };
  }
}

class ClassInfo {
  final String id;
  final String className;
  final String? section;
  final String academicYear;
  final String? classTeacherId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Resolved name helper
  final String? classTeacherName;
  final int? studentCount;

  ClassInfo({
    required this.id,
    required this.className,
    this.section,
    required this.academicYear,
    this.classTeacherId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.classTeacherName,
    this.studentCount,
  });

  String get displayName => section != null && section!.isNotEmpty
      ? '$className - $section'
      : className;

  factory ClassInfo.fromMap(Map<String, dynamic> map) {
    return ClassInfo(
      id: map['id'] as String,
      className: map['class_name'] as String,
      section: map['section'] as String?,
      academicYear: map['academic_year'] as String,
      classTeacherId: map['class_teacher_id'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updated_at']) ?? DateTime.now(),
      classTeacherName: map['class_teacher_name'] as String? ??
          map['classTeacherName'] as String? ??
          map['profiles']?['full_name'] as String? ??
          map['profile']?['full_name'] as String?,
      studentCount: map['student_count'] != null
          ? parseInt(map['student_count'])
          : (map['_count']?['students'] != null
              ? parseInt(map['_count']['students'])
              : (map['students'] is List ? (map['students'] as List).length : null)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_name': className,
      'section': section,
      'academic_year': academicYear,
      'class_teacher_id': classTeacherId,
      'is_active': isActive,
    };
  }
}

class Student {
  final String id;
  final String? profileId;
  final String admissionNumber;
  final String rollNumber;
  final String fullName;
  final String classId;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? guardianName;
  final String? guardianPhone;
  final String? address;
  final String? photoPath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined information
  final String? className;
  final String? email;
  final String? phone;

  Student({
    required this.id,
    this.profileId,
    required this.admissionNumber,
    required this.rollNumber,
    required this.fullName,
    required this.classId,
    this.dateOfBirth,
    this.gender,
    this.guardianName,
    this.guardianPhone,
    this.address,
    this.photoPath,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.className,
    this.email,
    this.phone,
  });

  String get photoInitials {
    final names = fullName.split(' ');
    if (names.isEmpty) return 'ST';
    if (names.length == 1) {
      return names[0].substring(0, names[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (names[0][0] + names[names.length - 1][0]).toUpperCase();
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    final resolvedClassName = _resolveClassName(map);

    return Student(
      id: map['id'] as String,
      profileId: map['profile_id'] as String?,
      admissionNumber: map['admission_number'] as String,
      rollNumber: map['roll_number'] as String,
      fullName: map['full_name'] as String,
      classId: map['class_id'] as String? ?? '',
      dateOfBirth: parseDateTime(map['date_of_birth']),
      gender: map['gender'] as String?,
      guardianName: map['guardian_name'] as String?,
      guardianPhone: map['guardian_phone'] as String?,
      address: map['address'] as String?,
      photoPath: map['photo_path'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updated_at']) ?? DateTime.now(),
      className: resolvedClassName,
      email: map['profiles']?['email'] as String?,
      phone: map['profiles']?['phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'admission_number': admissionNumber,
      'roll_number': rollNumber,
      'full_name': fullName,
      'class_id': classId,
      'date_of_birth': dateOfBirth?.toIso8601String().substring(0, 10),
      'gender': gender,
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
      'address': address,
      'photo_path': photoPath,
      'is_active': isActive,
    };
  }
}

class Teacher {
  final String id;
  final String profileId;
  final DateTime? joinedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined information
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? username;
  final bool isActive;
  final String? assignedClassId;
  final String? assignedClassName;

  Teacher({
    required this.id,
    required this.profileId,
    this.joinedDate,
    required this.createdAt,
    required this.updatedAt,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.username,
    this.isActive = true,
    this.assignedClassId,
    this.assignedClassName,
  });

  String get photoInitials {
    final names = fullName.split(' ');
    if (names.isEmpty) return 'TC';
    if (names.length == 1) {
      return names[0].substring(0, names[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (names[0][0] + names[names.length - 1][0]).toUpperCase();
  }

  Teacher copyWith({
    String? id,
    String? profileId,
    DateTime? joinedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? username,
    bool? isActive,
    String? assignedClassId,
    String? assignedClassName,
  }) {
    return Teacher(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      joinedDate: joinedDate ?? this.joinedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      username: username ?? this.username,
      isActive: isActive ?? this.isActive,
      assignedClassId: assignedClassId ?? this.assignedClassId,
      assignedClassName: assignedClassName ?? this.assignedClassName,
    );
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    final profile = map['profile'] is Map<String, dynamic>
        ? map['profile'] as Map<String, dynamic>
        : (map['profiles'] is Map<String, dynamic> ? map['profiles'] as Map<String, dynamic> : null);

    final assignedClassMap = map['assignedClass'] is Map<String, dynamic>
        ? map['assignedClass'] as Map<String, dynamic>
        : (map['assigned_class'] is Map<String, dynamic> ? map['assigned_class'] as Map<String, dynamic> : null);

    // Determine assigned class
    String? assignedClassId = map['assignedClassId'] as String? ??
        map['assigned_class_id'] as String? ??
        assignedClassMap?['id'] as String?;

    String? assignedClassName = map['assignedClassName'] as String? ??
        map['className'] as String? ??
        map['class_name'] as String? ??
        assignedClassMap?['className'] as String? ??
        assignedClassMap?['class_name'] as String?;

    final classesData = profile != null ? (profile['classes'] ?? profile['class']) : (map['classes'] ?? map['class']);

    if (assignedClassName == null && classesData != null) {
      if (classesData is List && classesData.isNotEmpty) {
        assignedClassId ??= classesData[0]['id'] as String?;
        final section = classesData[0]['section'] as String?;
        final className = classesData[0]['class_name'] as String? ?? '';
        assignedClassName = (section != null && section.isNotEmpty)
            ? '$className - $section'
            : className;
      } else if (classesData is Map) {
        assignedClassId ??= classesData['id'] as String?;
        final section = classesData['section'] as String?;
        final className = classesData['class_name'] as String? ?? '';
        assignedClassName = (section != null && section.isNotEmpty)
            ? '$className - $section'
            : className;
      }
    }

    final fullName = map['fullName'] as String? ??
        map['full_name'] as String? ??
        profile?['full_name'] as String? ??
        profile?['fullName'] as String? ??
        map['user']?['full_name'] as String? ??
        map['username'] as String? ??
        profile?['username'] as String? ??
        '';

    final email = map['email'] as String? ?? profile?['email'] as String?;
    final phone = map['phone'] as String? ?? profile?['phone'] as String?;
    final avatarUrl = map['avatarUrl'] as String? ??
        map['avatar_url'] as String? ??
        map['photo_url'] as String? ??
        profile?['avatar_url'] as String? ??
        profile?['photo_url'] as String?;
    final username = map['username'] as String? ?? profile?['username'] as String?;
    final isActive = (map['is_active'] ?? profile?['is_active'] ?? map['isActive']) as bool? ?? true;

    return Teacher(
      id: map['id'] as String? ?? profile?['id'] as String? ?? '',
      profileId: map['profile_id'] as String? ?? map['profileId'] as String? ?? profile?['id'] as String? ?? '',
      joinedDate: parseDateTime(map['joined_date'] ?? map['joinedDate']),
      createdAt: parseDateTime(map['created_at'] ?? map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updated_at'] ?? map['updatedAt']) ?? DateTime.now(),
      fullName: fullName,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      username: username,
      isActive: isActive,
      assignedClassId: assignedClassId,
      assignedClassName: assignedClassName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'username': username,
      'joined_date': joinedDate?.toIso8601String().substring(0, 10),
    };
  }
}

class Subject {
  final String id;
  final String subjectName;
  final String? subjectCode;
  final String classId;
  final double maximumMarks;
  final double passMarks;
  final bool isActive;
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.subjectName,
    this.subjectCode,
    required this.classId,
    this.maximumMarks = 100,
    this.passMarks = 35,
    this.isActive = true,
    required this.createdAt,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      subjectName: map['subject_name'] as String,
      subjectCode: map['subject_code'] as String?,
      classId: map['class_id'] as String,
      maximumMarks: parseDouble(map['maximum_marks']),
      passMarks: parseDouble(map['pass_marks']),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: parseDateTime(map['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'class_id': classId,
      'maximum_marks': maximumMarks,
      'pass_marks': passMarks,
      'is_active': isActive,
    };
  }
}

class Exam {
  final String id;
  final String examName;
  final String? term;
  final String classId;
  final String? examCenter;
  final String? reportingTime;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool resultsPublished;
  final bool hallTicketLocked;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined information
  final String? className;

  Exam({
    required this.id,
    required this.examName,
    this.term,
    required this.classId,
    this.examCenter,
    this.reportingTime,
    this.startDate,
    this.endDate,
    this.resultsPublished = false,
    this.hallTicketLocked = false,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.className,
  });

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as String,
      examName: map['exam_name'] as String,
      term: map['term'] as String?,
      classId: map['class_id'] as String,
      examCenter: map['exam_center'] as String?,
      reportingTime: map['reporting_time'] as String?,
      startDate: parseDateTime(map['start_date']),
      endDate: parseDateTime(map['end_date']),
      resultsPublished: map['results_published'] as bool? ?? false,
      hallTicketLocked: map['hall_ticket_locked'] as bool? ?? false,
      createdBy: map['created_by'] as String?,
      createdAt: parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updated_at']) ?? DateTime.now(),
      className: _resolveClassName(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_name': examName,
      'term': term,
      'class_id': classId,
      'exam_center': examCenter,
      'reporting_time': reportingTime,
      'start_date': startDate?.toIso8601String().substring(0, 10),
      'end_date': endDate?.toIso8601String().substring(0, 10),
      'results_published': resultsPublished,
      'hall_ticket_locked': hallTicketLocked,
      'created_by': createdBy,
    };
  }
}

class ExamSubject {
  final String id;
  final String examId;
  final String subjectId;
  final DateTime? examDate;
  final String? startTime;
  final String? endTime;
  final double maximumMarks;
  final double passMarks;

  // Joined information
  final String? subjectName;
  final String? subjectCode;

  ExamSubject({
    required this.id,
    required this.examId,
    required this.subjectId,
    this.examDate,
    this.startTime,
    this.endTime,
    this.maximumMarks = 100,
    this.passMarks = 35,
    this.subjectName,
    this.subjectCode,
  });

  factory ExamSubject.fromMap(Map<String, dynamic> map) {
    return ExamSubject(
      id: map['id'] as String,
      examId: map['exam_id'] as String,
      subjectId: map['subject_id'] as String,
      examDate: parseDateTime(map['exam_date']),
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      maximumMarks: parseDouble(map['maximum_marks']),
      passMarks: parseDouble(map['pass_marks']),
      subjectName: map['subjects']?['subject_name'] as String?,
      subjectCode: map['subjects']?['subject_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'subject_id': subjectId,
      'exam_date': examDate?.toIso8601String().substring(0, 10),
      'start_time': startTime,
      'end_time': endTime,
      'maximum_marks': maximumMarks,
      'pass_marks': passMarks,
    };
  }
}

class Result {
  final String id;
  final String examId;
  final String studentId;
  final String subjectId;
  final double? marksObtained;
  final double maximumMarks;
  final String? grade;
  final String? resultStatus;
  final String? remarks;
  final bool isPublished;
  final DateTime? publishedAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined information
  final String? studentName;
  final String? rollNumber;
  final String? subjectName;
  final String? subjectCode;
  final String? examName;

  Result({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.subjectId,
    this.marksObtained,
    this.maximumMarks = 100,
    this.grade,
    this.resultStatus,
    this.remarks,
    this.isPublished = false,
    this.publishedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
    this.rollNumber,
    this.subjectName,
    this.subjectCode,
    this.examName,
  });

  factory Result.fromMap(Map<String, dynamic> map) {
    final studentMap = map['students'] is Map<String, dynamic> ? map['students'] as Map<String, dynamic> : (map['student'] is Map<String, dynamic> ? map['student'] as Map<String, dynamic> : null);
    final subjectMap = map['subjects'] is Map<String, dynamic> ? map['subjects'] as Map<String, dynamic> : (map['subject'] is Map<String, dynamic> ? map['subject'] as Map<String, dynamic> : null);
    final examMap = map['exams'] is Map<String, dynamic> ? map['exams'] as Map<String, dynamic> : (map['exam'] is Map<String, dynamic> ? map['exam'] as Map<String, dynamic> : null);

    return Result(
      id: map['id'] as String,
      examId: (map['exam_id'] ?? map['examId']) as String? ?? '',
      studentId: (map['student_id'] ?? map['studentId']) as String? ?? '',
      subjectId: (map['subject_id'] ?? map['subjectId']) as String? ?? '',
      marksObtained: (map['marks_obtained'] ?? map['marksObtained']) != null
          ? parseDouble(map['marks_obtained'] ?? map['marksObtained'])
          : null,
      maximumMarks: parseDouble(map['maximum_marks'] ?? map['maximumMarks']),
      grade: map['grade'] as String?,
      resultStatus: (map['result_status'] ?? map['resultStatus']) as String?,
      remarks: map['remarks'] as String?,
      isPublished: (map['is_published'] ?? map['isPublished']) as bool? ?? false,
      publishedAt: parseDateTime(map['published_at'] ?? map['publishedAt']),
      createdBy: (map['created_by'] ?? map['createdBy']) as String?,
      createdAt: parseDateTime(map['created_at'] ?? map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updated_at'] ?? map['updatedAt']) ?? DateTime.now(),
      studentName: studentMap?['full_name'] as String?,
      rollNumber: studentMap?['roll_number'] as String?,
      subjectName: subjectMap?['subject_name'] as String?,
      subjectCode: subjectMap?['subject_code'] as String?,
      examName: examMap?['exam_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'student_id': studentId,
      'subject_id': subjectId,
      'marks_obtained': marksObtained,
      'maximum_marks': maximumMarks,
      'grade': grade,
      'result_status': resultStatus,
      'remarks': remarks,
      'is_published': isPublished,
      'published_at': publishedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }
}

class Note {
  final String id;
  final String title;
  final String? description;
  final String classId;
  final String? subjectId;
  final String? teacherId;
  final String filePath;
  final String? fileName;
  final int? fileSize;
  final bool isPublished;
  final DateTime uploadedAt;

  // Joined information
  final String? teacherName;
  final String? subjectName;
  final String? className;

  Note({
    required this.id,
    required this.title,
    this.description,
    required this.classId,
    this.subjectId,
    this.teacherId,
    required this.filePath,
    this.fileName,
    this.fileSize,
    this.isPublished = true,
    required this.uploadedAt,
    this.teacherName,
    this.subjectName,
    this.className,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      classId: map['class_id'] as String,
      subjectId: map['subject_id'] as String?,
      teacherId: map['teacher_id'] as String?,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String?,
      fileSize: map['file_size'] != null ? parseInt(map['file_size']) : null,
      isPublished: map['is_published'] as bool? ?? true,
      uploadedAt: parseDateTime(map['uploaded_at']) ?? DateTime.now(),
      teacherName: map['profiles']?['full_name'] as String?,
      subjectName: map['subjects']?['subject_name'] as String?,
      className: _resolveClassName(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'class_id': classId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'is_published': isPublished,
    };
  }
}

class HallTicket {
  final String id;
  final String examId;
  final String studentId;
  final String hallTicketNumber;
  final String status;
  final DateTime generatedAt;
  final DateTime? lockedAt;
  final String? filePath;

  // Joined information
  final String? examName;
  final String? examCenter;
  final String? reportingTime;
  final String? studentName;
  final String? rollNumber;
  final String? admissionNumber;
  final String? className;

  HallTicket({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.hallTicketNumber,
    this.status = 'generated',
    required this.generatedAt,
    this.lockedAt,
    this.filePath,
    this.examName,
    this.examCenter,
    this.reportingTime,
    this.studentName,
    this.rollNumber,
    this.admissionNumber,
    this.className,
  });

  factory HallTicket.fromMap(Map<String, dynamic> map) {
    return HallTicket(
      id: map['id'] as String,
      examId: map['exam_id'] as String,
      studentId: map['student_id'] as String,
      hallTicketNumber: map['hall_ticket_number'] as String,
      status: map['status'] as String? ?? 'generated',
      generatedAt: parseDateTime(map['generated_at']) ?? DateTime.now(),
      lockedAt: parseDateTime(map['locked_at']),
      filePath: map['file_path'] as String?,
      examName: map['exams']?['exam_name'] as String?,
      examCenter: map['exams']?['exam_center'] as String?,
      reportingTime: map['exams']?['reporting_time'] as String?,
      studentName: map['students']?['full_name'] as String?,
      rollNumber: map['students']?['roll_number'] as String?,
      admissionNumber: map['students']?['admission_number'] as String?,
      className: _resolveClassName(map['students']) ?? _resolveClassName(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'student_id': studentId,
      'hall_ticket_number': hallTicketNumber,
      'status': status,
      'locked_at': lockedAt?.toIso8601String(),
      'file_path': filePath,
    };
  }
}

class Announcement {
  final String id;
  final String title;
  final String message;
  final String targetType;
  final String? targetClassId;
  final String? publishedBy;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final bool isActive;

  // Joined information
  final String? publisherName;
  final String? className;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    this.targetType = 'all',
    this.targetClassId,
    this.publishedBy,
    required this.publishedAt,
    this.expiresAt,
    this.isActive = true,
    this.publisherName,
    this.className,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      targetType: map['target_type'] as String? ?? 'all',
      targetClassId: map['target_class_id'] as String?,
      publishedBy: map['published_by'] as String?,
      publishedAt: parseDateTime(map['published_at']) ?? DateTime.now(),
      expiresAt: parseDateTime(map['expires_at']),
      isActive: map['is_active'] as bool? ?? true,
      publisherName: map['profiles']?['full_name'] as String?,
      className: _resolveClassName(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'target_type': targetType,
      'target_class_id': targetClassId,
      'published_by': publishedBy,
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
    };
  }
}

class ActivityLog {
  final String id;
  final String? userId;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? description;
  final String? classId;
  final DateTime createdAt;

  // Joined information
  final String? userFullName;
  final String? className;

  ActivityLog({
    required this.id,
    this.userId,
    required this.action,
    this.entityType,
    this.entityId,
    this.description,
    this.classId,
    required this.createdAt,
    this.userFullName,
    this.className,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      action: map['action'] as String,
      entityType: map['entity_type'] as String?,
      entityId: map['entity_id'] as String?,
      description: map['description'] as String?,
      classId: map['class_id'] as String?,
      createdAt: parseDateTime(map['created_at']) ?? DateTime.now(),
      userFullName: map['profiles']?['full_name'] as String?,
      className: _resolveClassName(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'description': description,
      'class_id': classId,
    };
  }
}

class AppSettings {
  final String id;
  final String settingKey;
  final dynamic settingValue;
  final String? updatedBy;
  final DateTime updatedAt;

  AppSettings({
    required this.id,
    required this.settingKey,
    required this.settingValue,
    this.updatedBy,
    required this.updatedAt,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] as String,
      settingKey: map['setting_key'] as String,
      settingValue: map['setting_value'],
      updatedBy: map['updated_by'] as String?,
      updatedAt: parseDateTime(map['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setting_key': settingKey,
      'setting_value': settingValue,
      'updated_by': updatedBy,
    };
  }
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
