import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../../models/user_role.dart';
import 'repository_interfaces.dart';
import '../../core/services/http_service.dart';
import '../../core/constants/subjects.dart';


class ApiProfileRepository implements ProfileRepository {
  @override
  Future<Profile> getProfile(String id) async {
    try {
      final res = await ApiClient.instance.dio.get('/profiles/$id');
      return Profile.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Profile>> getProfilesByRole(UserRole role) async {
    try {
      final res = await ApiClient.instance.dio.get('/profiles', queryParameters: {'role': role.dbValue});
      return (res.data['data'] as List).map((x) => Profile.fromMap(x)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    try {
      await ApiClient.instance.dio.put('/profiles/${profile.id}', data: profile.toMap());
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<String> uploadProfileAvatar(String profileId, Uint8List fileBytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      final res = await ApiClient.instance.dio.post(
        '/profiles/$profileId/avatar',
        data: formData,
      );
      final data = res.data['data'] ?? res.data;
      return data['avatarUrl'] ?? data['avatar_url'] ?? '';
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deactivateUser(String id) async {
    try {
      await ApiClient.instance.dio.post('/users/deactivate', data: {'userId': id});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ApiStudentRepository implements StudentRepository {
  @override
  Future<Student> getStudentById(String id) async {
    try {
      final res = await ApiClient.instance.dio.get('/students/$id');
      return Student.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Student?> getStudentByProfileId(String profileId) async {
    try {
      final res = await ApiClient.instance.dio.get('/students/profile/$profileId');
      if (res.data == null || res.data['data'] == null) return null;
      return Student.fromMap(res.data['data']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Student>> getAllStudents() async {
    try {
      final res = await ApiClient.instance.dio.get('/students');
      return (res.data['data'] as List).map((x) => Student.fromMap(x)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Student>> getStudentsByClass(String classId) async {
    try {
      final res = await ApiClient.instance.dio.get('/students', queryParameters: {'classId': classId});
      return (res.data['data'] as List).map((x) => Student.fromMap(x)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Student> createStudent(
    Student student, {
    String? email,
    String? password,
  }) async {
    try {
      final payload = {
        ...student.toMap(),
        'email': email,
        'password': password ?? student.admissionNumber,
      };
      // Uses the new custom API creation flow
      final response = await ApiClient.instance.dio.post('/students', data: payload);
      
      // Assume the backend returns { data: { student: {...} } } or similar
      final dataMap = response.data['data'] ?? response.data;
      final studentData = dataMap['student'] ?? dataMap;
      return Student.fromMap(studentData);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> updateStudent(Student student) async {
    try {
      await ApiClient.instance.dio.put('/students/${student.id}', data: student.toMap());
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deactivateStudent(String id) async {
    try {
      await ApiClient.instance.dio.post('/students/$id/deactivate');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteStudent(String id) async {
    try {
      await ApiClient.instance.dio.delete('/students/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> transferStudent(String studentId, String targetClassId) async {
    try {
      await ApiClient.instance.dio.post('/students/$studentId/transfer', data: {'classId': targetClassId});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<String> uploadStudentPhoto(String studentId, Uint8List fileBytes, String extension) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: 'profile.$extension'),
      });
      final res = await ApiClient.instance.dio.post(
        '/students/$studentId/photo',
        data: formData,
      );
      return res.data['data']['photoUrl'];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<String> getSignedPhotoUrl(String photoPath) async {
    try {
      final res = await ApiClient.instance.dio.post('/files/signed-url', data: {'path': photoPath});
      return res.data['data']['signedUrl'];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ApiTeacherRepository implements TeacherRepository {
  @override
  Future<Teacher> getTeacherById(String id) async {
    try {
      final res = await ApiClient.instance.dio.get('/teachers/$id');
      return Teacher.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Teacher> getTeacherByProfileId(String profileId) async {
    try {
      final res = await ApiClient.instance.dio.get('/teachers/profile/$profileId');
      return Teacher.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Teacher>> getAllTeachers() async {
    try {
      final res = await ApiClient.instance.dio.get('/teachers');
      return (res.data['data'] as List).map((x) => Teacher.fromMap(x)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Teacher> createTeacher(
    Teacher teacher, {
    required String fullName,
    required String email,
    String? phone,
    required String classId,
    String? password,
  }) async {
    try {
      final cleanEmail = (email.trim().isEmpty) ? null : email.trim();
      final cleanPhone = (phone == null || phone.trim().isEmpty) ? null : phone.trim();
      final cleanUsername = (cleanEmail != null && cleanEmail.contains('@'))
          ? cleanEmail.split('@')[0].toLowerCase()
          : fullName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');

      final payload = {
        'fullName': fullName.trim(),
        'username': cleanUsername,
        'classId': classId,
        'password': password ?? 'Ham@123',
        ...teacher.toMap(),
        'email': cleanEmail,
        'phone': cleanPhone,
      };
      final res = await ApiClient.instance.dio.post('/teachers', data: payload);
      final dataMap = res.data['data'] ?? res.data;
      final teacherData = dataMap['teacher'] ?? dataMap;
      return Teacher.fromMap(teacherData);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> updateTeacher(Teacher teacher, String fullName, String? phone) async {
    try {
      final payload = {
        'teacher': teacher.toMap(),
        'fullName': fullName,
        'phone': phone,
      };
      await ApiClient.instance.dio.put('/teachers/${teacher.id}', data: payload);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Teacher> updateTeacherProfile(String profileId, {String? fullName, String? email, String? phone}) async {
    try {
      final res = await ApiClient.instance.dio.put('/teacher/profile', data: {
        'fullName': ?fullName,
        'email': ?email,
        'phone': ?phone,
      });
      final dataMap = res.data['data'] ?? res.data;
      return Teacher.fromMap(dataMap);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<String> uploadTeacherAvatar(String profileId, Uint8List fileBytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      final res = await ApiClient.instance.dio.post(
        '/teacher/profile/avatar',
        data: formData,
      );
      final data = res.data['data'] ?? res.data;
      return data['avatarUrl'] ?? data['avatar_url'] ?? '';
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deactivateTeacher(String id) async {
    try {
      await ApiClient.instance.dio.post('/teachers/$id/deactivate');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteTeacher(String id) async {
    try {
      await ApiClient.instance.dio.delete('/teachers/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ApiClassRepository implements ClassRepository {
  @override
  Future<ClassInfo> getClassById(String id) async {
    try {
      final res = await ApiClient.instance.dio.get('/classes/$id');
      return ClassInfo.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<ClassInfo>> getAllClasses() async {
    try {
      final res = await ApiClient.instance.dio.get('/classes');
      return (res.data['data'] as List).map((x) => ClassInfo.fromMap(x)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ClassInfo> createClass(ClassInfo classInfo) async {
    try {
      final res = await ApiClient.instance.dio.post('/classes', data: classInfo.toMap());
      return ClassInfo.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> updateClass(ClassInfo classInfo) async {
    try {
      await ApiClient.instance.dio.put('/classes/${classInfo.id}', data: classInfo.toMap());
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> assignTeacher(String classId, String? classTeacherId) async {
    try {
      await ApiClient.instance.dio.post('/classes/$classId/assign-teacher', data: {'teacherId': classTeacherId});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deactivateClass(String id) async {
    try {
      await ApiClient.instance.dio.post('/classes/$id/deactivate');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ApiSubjectRepository implements SubjectRepository {
  @override
  Future<Subject> getSubjectById(String id) async {
    try {
      final res = await ApiClient.instance.dio.get('/subjects/$id');
      return Subject.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Subject>> getSubjectsByClass(String classId) async {
    try {
      final res = await ApiClient.instance.dio.get('/subjects', queryParameters: classId.isNotEmpty ? {'classId': classId} : null);
      final rawList = res.data != null ? res.data['data'] : null;
      if (rawList is List && rawList.isNotEmpty) {
        return rawList.map((x) => Subject.fromMap(x as Map<String, dynamic>)).toList();
      }
      return getSubjectModelsForClass(classId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return getSubjectModelsForClass(classId);
      return getSubjectModelsForClass(classId);
    } catch (_) {
      return getSubjectModelsForClass(classId);
    }
  }

  @override
  Future<Subject> createSubject(Subject subject) async {
    try {
      final res = await ApiClient.instance.dio.post('/subjects', data: subject.toMap());
      return Subject.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> updateSubject(Subject subject) async {
    try {
      await ApiClient.instance.dio.put('/subjects/${subject.id}', data: subject.toMap());
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deactivateSubject(String id) async {
    try {
      await ApiClient.instance.dio.post('/subjects/$id/deactivate');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ApiExamRepository implements ExamRepository {
  @override
  Future<Exam> getExamById(String id) async {
    try {
      final res = await ApiClient.instance.dio.get('/exams/$id');
      return Exam.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Exam>> getExamsByClass(String classId) async {
    try {
      final res = await ApiClient.instance.dio.get('/exams', queryParameters: classId.isNotEmpty ? {'classId': classId} : null);
      final rawList = res.data != null ? res.data['data'] : null;
      if (rawList is List) {
        return rawList.map((x) => Exam.fromMap(x as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Exam>> getAllExams() async {
    try {
      final res = await ApiClient.instance.dio.get('/exams');
      final rawList = res.data != null ? res.data['data'] : null;
      if (rawList is List) {
        return rawList.map((x) => Exam.fromMap(x as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Exam> createExam(Exam exam) async {
    try {
      final res = await ApiClient.instance.dio.post('/exams', data: exam.toMap());
      return Exam.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> updateExam(Exam exam) async {
    try {
      await ApiClient.instance.dio.put('/exams/${exam.id}', data: exam.toMap());
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> setResultsPublished(String examId, bool published) async {
    try {
      await ApiClient.instance.dio.post('/exams/$examId/results/publish', data: {'published': published});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> setHallTicketsLocked(String examId, bool locked) async {
    try {
      await ApiClient.instance.dio.post('/exams/$examId/hall-tickets/lock', data: {'locked': locked});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteExam(String id) async {
    try {
      await ApiClient.instance.dio.delete('/exams/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<ExamSubject>> getExamSubjects(String examId) async {
    try {
      final res = await ApiClient.instance.dio.get('/exams/$examId/subjects');
      return (res.data['data'] as List).map((x) => ExamSubject.fromMap(x)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> saveExamSubjects(String examId, List<ExamSubject> subjects) async {
    try {
      final data = subjects.map((s) => s.toMap()).toList();
      await ApiClient.instance.dio.post('/exams/$examId/subjects', data: {'subjects': data});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ApiResultRepository implements ResultRepository {
  @override
  Future<List<Result>> getResultsByStudent(String studentId) async {
    try {
      final res = await ApiClient.instance.dio.get('/student/results', queryParameters: {'studentId': studentId});
      final rawList = res.data['data'] ?? res.data['results'];
      if (rawList is List) {
        return rawList.map((x) => Result.fromMap(x as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Result>> getResultsByExam(String examId) async {
    try {
      final res = await ApiClient.instance.dio.get('/results', queryParameters: {'examId': examId});
      final rawList = res.data['data'] ?? res.data['results'];
      if (rawList is List) {
        return rawList.map((x) => Result.fromMap(x as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Result>> getResultsByExamAndClass(String examId, String classId) async {
    try {
      final res = await ApiClient.instance.dio.get('/results', queryParameters: {'examId': examId, 'classId': classId});
      final rawList = res.data['data'] ?? res.data['results'];
      if (rawList is List) {
        return rawList.map((x) => Result.fromMap(x as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Result>> getResultsByClass(String classId) async {
    const url = '/results';
    final fullUrl = '${ApiClient.instance.dio.options.baseUrl}$url';
    final headers = ApiClient.instance.dio.options.headers;
    final token = headers['Authorization'];

    debugPrint('========== [FLUTTER RESULTS REPO - BEFORE DIO.GET] ==========');
    debugPrint('[REQUEST URL]: $fullUrl?classId=$classId');
    debugPrint('[HEADERS]: $headers');
    debugPrint('[JWT TOKEN]: $token');

    try {
      final res = await ApiClient.instance.dio.get(
        url,
        queryParameters: classId.isNotEmpty ? {'classId': classId} : null,
      );

      debugPrint('========== [FLUTTER RESULTS REPO - AFTER DIO.GET] ==========');
      debugPrint('[REAL URI]: ${res.realUri}');
      debugPrint('[STATUS CODE]: ${res.statusCode}');
      debugPrint('[RESPONSE BODY]: ${res.data}');

      final rawList = res.data != null ? (res.data['data'] ?? res.data['results']) : null;
      if (rawList is List) {
        final parsed = <Result>[];
        for (final x in rawList) {
          if (x is Map<String, dynamic>) {
            try {
              parsed.add(Result.fromMap(x));
            } catch (parseError) {
              debugPrint('[FLUTTER RESULTS REPO ERROR] Item parsing exception: $parseError | Item: $x');
            }
          }
        }
        debugPrint('[PARSED JSON COUNT]: ${parsed.length}');
        return parsed;
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[FLUTTER RESULTS REPO ERROR] DioException: ${e.message} | Status: ${e.response?.statusCode} | Response: ${e.response?.data}');
      if (e.response?.statusCode == 404) return [];
      throw ApiException.fromDioException(e);
    } catch (ex, stack) {
      debugPrint('[FLUTTER RESULTS REPO ERROR] General Exception: $ex\n$stack');
      rethrow;
    }
  }

  @override
  Future<List<Result>> getAllResults() async {
    const url = '/results';
    final fullUrl = '${ApiClient.instance.dio.options.baseUrl}$url';
    final headers = ApiClient.instance.dio.options.headers;
    final token = headers['Authorization'];

    debugPrint('========== [FLUTTER RESULTS REPO - BEFORE DIO.GET] ==========');
    debugPrint('[REQUEST URL]: $fullUrl');
    debugPrint('[HEADERS]: $headers');
    debugPrint('[JWT TOKEN]: $token');

    try {
      final res = await ApiClient.instance.dio.get(url);

      debugPrint('========== [FLUTTER RESULTS REPO - AFTER DIO.GET] ==========');
      debugPrint('[REAL URI]: ${res.realUri}');
      debugPrint('[STATUS CODE]: ${res.statusCode}');
      debugPrint('[RESPONSE BODY]: ${res.data}');

      final rawList = res.data != null ? (res.data['data'] ?? res.data['results']) : null;
      if (rawList is List) {
        try {
          final parsed = rawList.map((x) => Result.fromMap(x as Map<String, dynamic>)).toList();
          debugPrint('[PARSED JSON COUNT]: ${parsed.length}');
          return parsed;
        } catch (parseError) {
          debugPrint('[FLUTTER RESULTS REPO ERROR] Parsing exception: $parseError');
          rethrow;
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[FLUTTER RESULTS REPO ERROR] DioException: ${e.message} | Status: ${e.response?.statusCode} | Response: ${e.response?.data}');
      if (e.response?.statusCode == 404) return [];
      throw ApiException.fromDioException(e);
    } catch (ex, stack) {
      debugPrint('[FLUTTER RESULTS REPO ERROR] General Exception: $ex\n$stack');
      rethrow;
    }
  }

  @override
  Future<Result> createResult(Result result) async {
    try {
      final res = await ApiClient.instance.dio.post('/results', data: result.toMap());
      return Result.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Result> updateResult(Result result) async {
    try {
      final res = await ApiClient.instance.dio.put('/results/${result.id}', data: result.toMap());
      return Result.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteResult(String resultId) async {
    try {
      await ApiClient.instance.dio.delete('/results/$resultId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> uploadResultsBulk(String examId, List<Result> results) async {
    try {
      final data = results.map((r) => r.toMap()).toList();
      await ApiClient.instance.dio.post('/results/bulk', data: {'examId': examId, 'results': data});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> publishResults(String examId, String classId, bool publish) async {
    try {
      await ApiClient.instance.dio.post('/results/publish', data: {'examId': examId, 'classId': classId, 'publish': publish});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<String> uploadResultImportFile(String examId, Uint8List fileBytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      final res = await ApiClient.instance.dio.post('/results/import/$examId', data: formData);
      return res.data['data']['url'] ?? '';
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> importResultsExcel(Uint8List fileBytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      final res = await ApiClient.instance.dio.post('/results/import', data: formData);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ApiNotesRepository implements NotesRepository {
  @override
  Future<List<Note>> getNotesByClass(String classId) async {
    try {
      final res = await ApiClient.instance.dio.get('/student/notes', queryParameters: {'classId': classId});
      final rawList = res.data['data'] ?? res.data['notes'];
      if (rawList is List) {
        return rawList.map((x) => Note.fromMap(x as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Note>> getAllNotes() async {
    try {
      final res = await ApiClient.instance.dio.get('/notes');
      final rawList = res.data['data'] ?? res.data['notes'];
      if (rawList is List) {
        return rawList.map((x) => Note.fromMap(x as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Note> uploadNote({
    required String title,
    required String? description,
    required String classId,
    required String? subjectId,
    required String teacherId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        'title': title,
        'description': description ?? '',
        'classId': classId,
        'class_id': classId,
        'subjectId': subjectId ?? '',
        'subject_id': subjectId ?? '',
        'subject': subjectId ?? '',
        'teacherId': teacherId,
        'teacher_id': teacherId,
        'uploadedBy': teacherId,
        'fileName': fileName,
        'file_name': fileName,
      });
      final res = await ApiClient.instance.dio.post('/notes', data: formData);
      return Note.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> updateNotePublishStatus(String noteId, bool isPublished) async {
    try {
      await ApiClient.instance.dio.put('/notes/$noteId/publish', data: {'isPublished': isPublished});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    try {
      await ApiClient.instance.dio.delete('/notes/$noteId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<String> getSignedDownloadUrl(String filePath) async {
    try {
      final res = await ApiClient.instance.dio.post('/files/signed-url', data: {'path': filePath});
      final signedUrl = res.data['data']?['signedUrl'] ?? res.data['signedUrl'];
      if (signedUrl != null && signedUrl.toString().isNotEmpty) {
        return signedUrl.toString();
      }
    } catch (_) {}

    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    final baseUrl = ApiClient.instance.dio.options.baseUrl.replaceAll('/api', '');
    final cleanPath = filePath.startsWith('/') ? filePath : '/$filePath';
    return '$baseUrl$cleanPath';
  }
}

class ApiHallTicketRepository implements HallTicketRepository {
  @override
  Future<HallTicket?> getHallTicketByStudentAndExam(String studentId, String examId) async {
    try {
      final res = await ApiClient.instance.dio.get('/student/hall-ticket', queryParameters: {'studentId': studentId, 'examId': examId});
      final rawList = res.data['data'] ?? res.data['hallTickets'];
      if (rawList is List && rawList.isNotEmpty) {
        return HallTicket.fromMap(rawList.first as Map<String, dynamic>);
      }
      if (res.data['hallTicket'] != null) {
        return HallTicket.fromMap(res.data['hallTicket'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<HallTicket>> getHallTicketsByClass(String classId) async {
    try {
      final res = await ApiClient.instance.dio.get('/hall-tickets', queryParameters: {'classId': classId});
      final rawList = res.data['data'] ?? res.data['hallTickets'];
      if (rawList is List) {
        return rawList.map((x) => HallTicket.fromMap(x as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<HallTicket>> getHallTicketsByStudent(String studentId) async {
    try {
      final res = await ApiClient.instance.dio.get('/student/hall-ticket', queryParameters: {'studentId': studentId});
      final rawList = res.data['data'] ?? res.data['hallTickets'];
      if (rawList is List) {
        return rawList.map((x) => HallTicket.fromMap(x as Map<String, dynamic>)).toList();
      }
      if (res.data['hallTicket'] != null) {
        return [HallTicket.fromMap(res.data['hallTicket'] as Map<String, dynamic>)];
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> generateHallTickets(String examId, String classId) async {
    try {
      await ApiClient.instance.dio.post('/hall-tickets/generate', data: {'examId': examId, 'classId': classId});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> updateHallTicketStatus(String hallTicketId, String status) async {
    try {
      await ApiClient.instance.dio.put('/hall-tickets/$hallTicketId/status', data: {'status': status});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<String> uploadHallTicketFile(String examId, String studentId, Uint8List pdfBytes) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(pdfBytes, filename: 'hall_ticket.pdf'),
      });
      final res = await ApiClient.instance.dio.post('/hall-tickets/upload', queryParameters: {'examId': examId, 'studentId': studentId}, data: formData);
      return res.data['data']['url'];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<String> getSignedHallTicketUrl(String filePath) async {
    try {
      final res = await ApiClient.instance.dio.post('/files/signed-url', data: {'path': filePath});
      final signedUrl = res.data['data']?['signedUrl'] ?? res.data['signedUrl'];
      if (signedUrl != null && signedUrl.toString().isNotEmpty) {
        return signedUrl.toString();
      }
    } catch (_) {}

    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    final baseUrl = ApiClient.instance.dio.options.baseUrl.replaceAll('/api', '');
    final cleanPath = filePath.startsWith('/') ? filePath : '/$filePath';
    return '$baseUrl$cleanPath';
  }
}

class ApiAnnouncementRepository implements AnnouncementRepository {
  @override
  Future<List<Announcement>> getAnnouncementsForStudent(String classId) async {
    try {
      final res = await ApiClient.instance.dio.get('/announcements/student', queryParameters: {'classId': classId});
      return (res.data['data'] as List).map((x) => Announcement.fromMap(x)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Announcement>> getAnnouncementsForTeacher(String classId) async {
    try {
      final res = await ApiClient.instance.dio.get('/announcements/teacher', queryParameters: {'classId': classId});
      return (res.data['data'] as List).map((x) => Announcement.fromMap(x)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Announcement>> getAllAnnouncements() async {
    try {
      final res = await ApiClient.instance.dio.get('/announcements');
      return (res.data['data'] as List).map((x) => Announcement.fromMap(x)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Announcement> publishAnnouncement(Announcement announcement) async {
    try {
      final res = await ApiClient.instance.dio.post('/announcements', data: announcement.toMap());
      return Announcement.fromMap(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deactivateAnnouncement(String id) async {
    try {
      await ApiClient.instance.dio.post('/announcements/$id/deactivate');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ApiSettingsRepository implements SettingsRepository {
  @override
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final res = await ApiClient.instance.dio.get('/settings');
      return Map<String, dynamic>.from(res.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> updateSetting(String key, dynamic value) async {
    try {
      await ApiClient.instance.dio.put('/settings/$key', data: {'value': value});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ApiActivityLogRepository implements ActivityLogRepository {
  @override
  Future<List<ActivityLog>> getLogsByClass(String classId) async {
    try {
      final res = await ApiClient.instance.dio.get('/activity-logs', queryParameters: classId.isNotEmpty ? {'classId': classId} : null);
      final rawList = res.data != null ? res.data['data'] : null;
      if (rawList is List) {
        return rawList.map((x) => ActivityLog.fromMap(x as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<ActivityLog>> getAllLogs() async {
    try {
      final res = await ApiClient.instance.dio.get('/activity-logs');
      final rawList = res.data != null ? res.data['data'] : null;
      if (rawList is List) {
        return rawList.map((x) => ActivityLog.fromMap(x as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> logActivity({
    required String action,
    String? entityType,
    String? entityId,
    String? description,
    String? classId,
  }) async {
    try {
      await ApiClient.instance.dio.post('/activity-logs', data: {
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'description': description,
        'classId': classId,
      });
    } catch (_) {}
  }
}
