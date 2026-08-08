// repository_interfaces.dart
import 'dart:typed_data';
import '../../models/models.dart';
import '../../models/user_role.dart';

abstract class AuthRepository {
  Future<Profile?> login(String usernameOrEmail, String password);
  Future<void> logout();
  Future<Profile?> getCurrentSessionProfile();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String newPassword, {String? currentPassword});
  Stream<Profile?> get onAuthStateChanged;
}

abstract class ProfileRepository {
  Future<Profile> getProfile(String id);
  Future<List<Profile>> getProfilesByRole(UserRole role);
  Future<void> updateProfile(Profile profile);
  Future<String> uploadProfileAvatar(String profileId, Uint8List fileBytes, String fileName);
  Future<void> deactivateUser(String id);
}

abstract class StudentRepository {
  Future<Student> getStudentById(String id);
  Future<Student?> getStudentByProfileId(String profileId);
  Future<List<Student>> getAllStudents();
  Future<List<Student>> getStudentsByClass(String classId);
  Future<Student> createStudent(
    Student student, {
    String? email,
    String? password,
  });
  Future<void> updateStudent(Student student);
  Future<void> deactivateStudent(String id);
  Future<void> transferStudent(String studentId, String targetClassId);
  Future<String> uploadStudentPhoto(
    String studentId,
    Uint8List fileBytes,
    String extension,
  );
  Future<String> getSignedPhotoUrl(String photoPath);
  Future<void> deleteStudent(String id);
}

abstract class TeacherRepository {
  Future<Teacher> getTeacherById(String id);
  Future<Teacher> getTeacherByProfileId(String profileId);
  Future<List<Teacher>> getAllTeachers();
  Future<Teacher> createTeacher(
    Teacher teacher, {
    required String fullName,
    required String email,
    String? phone,
    required String classId,
    String? password,
  });
  Future<void> updateTeacher(Teacher teacher, String fullName, String? phone);
  Future<Teacher> updateTeacherProfile(String profileId, {String? fullName, String? email, String? phone});
  Future<String> uploadTeacherAvatar(String profileId, Uint8List fileBytes, String fileName);
  Future<void> deactivateTeacher(String id);
  Future<void> deleteTeacher(String id);
}

abstract class ClassRepository {
  Future<ClassInfo> getClassById(String id);
  Future<List<ClassInfo>> getAllClasses();
  Future<ClassInfo> createClass(ClassInfo classInfo);
  Future<void> updateClass(ClassInfo classInfo);
  Future<void> assignTeacher(String classId, String? classTeacherId);
  Future<void> deactivateClass(String id);
}

abstract class SubjectRepository {
  Future<Subject> getSubjectById(String id);
  Future<List<Subject>> getSubjectsByClass(String classId);
  Future<Subject> createSubject(Subject subject);
  Future<void> updateSubject(Subject subject);
  Future<void> deactivateSubject(String id);
}

abstract class ExamRepository {
  Future<Exam> getExamById(String id);
  Future<List<Exam>> getExamsByClass(String classId);
  Future<List<Exam>> getAllExams();
  Future<Exam> createExam(Exam exam);
  Future<void> updateExam(Exam exam);
  Future<void> setResultsPublished(String examId, bool published);
  Future<void> setHallTicketsLocked(String examId, bool locked);
  Future<void> deleteExam(String id);

  // Exam Subjects
  Future<List<ExamSubject>> getExamSubjects(String examId);
  Future<void> saveExamSubjects(String examId, List<ExamSubject> subjects);
}

abstract class ResultRepository {
  Future<List<Result>> getResultsByStudent(String studentId);
  Future<List<Result>> getResultsByExam(String examId);
  Future<List<Result>> getResultsByExamAndClass(String examId, String classId);
  Future<List<Result>> getResultsByClass(String classId);
  Future<List<Result>> getAllResults();
  Future<Result> createResult(Result result);
  Future<Result> updateResult(Result result);
  Future<void> deleteResult(String resultId);
  Future<void> uploadResultsBulk(String examId, List<Result> results);
  Future<void> publishResults(String examId, String classId, bool publish);
  Future<String> uploadResultImportFile(
    String examId,
    Uint8List fileBytes,
    String fileName,
  );
  Future<Map<String, dynamic>> importResultsExcel(
    Uint8List fileBytes,
    String fileName,
  );
}

abstract class NotesRepository {
  Future<List<Note>> getNotesByClass(String classId);
  Future<List<Note>> getAllNotes();
  Future<Note> uploadNote({
    required String title,
    required String? description,
    required String classId,
    required String? subjectId,
    required String teacherId,
    required Uint8List fileBytes,
    required String fileName,
  });
  Future<void> updateNotePublishStatus(String noteId, bool isPublished);
  Future<void> deleteNote(String noteId);
  Future<String> getSignedDownloadUrl(String filePath);
}

abstract class HallTicketRepository {
  Future<HallTicket?> getHallTicketByStudentAndExam(
    String studentId,
    String examId,
  );
  Future<List<HallTicket>> getHallTicketsByClass(String classId);
  Future<List<HallTicket>> getHallTicketsByStudent(String studentId);
  Future<void> generateHallTickets(String examId, String classId);
  Future<void> updateHallTicketStatus(String hallTicketId, String status);
  Future<String> uploadHallTicketFile(
    String examId,
    String studentId,
    Uint8List pdfBytes,
  );
  Future<String> getSignedHallTicketUrl(String filePath);
}

abstract class AnnouncementRepository {
  Future<List<Announcement>> getAnnouncementsForStudent(String classId);
  Future<List<Announcement>> getAnnouncementsForTeacher(String classId);
  Future<List<Announcement>> getAllAnnouncements();
  Future<Announcement> publishAnnouncement(Announcement announcement);
  Future<void> deactivateAnnouncement(String id);
}

abstract class SettingsRepository {
  Future<Map<String, dynamic>> getSettings();
  Future<void> updateSetting(String key, dynamic value);
}

abstract class ActivityLogRepository {
  Future<List<ActivityLog>> getLogsByClass(String classId);
  Future<List<ActivityLog>> getAllLogs();
  Future<void> logActivity({
    required String action,
    String? entityType,
    String? entityId,
    String? description,
    String? classId,
  });
}
