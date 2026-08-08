// lib/core/constants/subjects.dart
import '../../models/models.dart';

/// Centralized class-wise subject mapping for the HIDAYATHUL ANAM MADRASA Portal.
/// DO NOT hardcode subjects anywhere else in the application.
const Map<String, List<String>> classSubjects = {
  'Class 1': [
    'تفهيم',
  ],
  'Class 2': [
    'قرأن',
    'حفظ',
    'فقه',
    'لسان',
    'عقيدة',
    'دروس الإحسان',
  ],
  'Class 3': [
    'قرأن',
    'حفظ',
    'عقيدة',
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تريخ',
  ],
  'Class 4': [
    'قرأن',
    'حفظ',
    'عقيدة',
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تريخ',
  ],
  'Class 5': [
    'قرأن',
    'حفظ',
    'تجويد',
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تريخ',
  ],
  'Class 6': [
    'قرأن',
    'حفظ',
    'تجويد',
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تريخ',
    'ഉപപാഠപുസ്തകം',
  ],
  'Class 7': [
    'قرأن',
    'حفظ',
    'تجويد',
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تريخ',
    'ഉപപാഠപുസ്തകം',
  ],
  'Class 8': [
    'قرأن',
    'حفظ',
    'تجويد',
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تريخ',
    'ഉപപാഠപുസ്തകം',
  ],
  'Class 9': [
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تاريخ',
  ],
  'Class 10': [
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تفسير',
  ],
  'Class 11': [
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تفسير',
  ],
  'Class 12': [
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تفسير',
  ],
};

/// Normalizes any class identifier or class name string to "Class X".
String normalizeClassName(String? input) {
  if (input == null || input.trim().isEmpty) return 'Class 1';
  final raw = input.trim();

  // Try matching class number (1 to 12)
  final match = RegExp(r'\b(1[0-2]|[1-9])\b').firstMatch(raw);
  if (match != null) {
    final numStr = match.group(1);
    return 'Class $numStr';
  }

  // Exact case-insensitive match check
  for (final key in classSubjects.keys) {
    if (key.toLowerCase() == raw.toLowerCase()) {
      return key;
    }
  }

  return 'Class 1';
}

/// Returns the subject names for a given class name, class ID, or ClassInfo list.
List<String> getSubjectsForClass(String? classNameOrId, {List<ClassInfo>? classes}) {
  if (classNameOrId == null || classNameOrId.isEmpty) {
    return classSubjects['Class 1']!;
  }

  String resolvedName = classNameOrId;

  if (classes != null && classes.isNotEmpty) {
    final found = classes.firstWhere(
      (c) => c.id == classNameOrId || c.className == classNameOrId,
      orElse: () => ClassInfo(
        id: '',
        className: classNameOrId,
        academicYear: '2026',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (found.className.isNotEmpty) {
      resolvedName = found.className;
    }
  }

  final classKey = normalizeClassName(resolvedName);
  return classSubjects[classKey] ?? classSubjects['Class 1']!;
}

/// Returns a list of [Subject] model objects for a given class.
List<Subject> getSubjectModelsForClass(String? classNameOrId, {List<ClassInfo>? classes}) {
  final names = getSubjectsForClass(classNameOrId, classes: classes);
  final classKey = normalizeClassName(classNameOrId);

  return names.map((name) => Subject(
    id: 'sub-$classKey-$name',
    subjectName: name,
    subjectCode: name,
    classId: classNameOrId ?? classKey,
    maximumMarks: 100,
    passMarks: 35,
    isActive: true,
    createdAt: DateTime.now(),
  )).toList();
}

/// Validates whether a subject is valid for the specified class.
bool isValidSubjectForClass(String? classNameOrId, String? subjectName, {List<ClassInfo>? classes}) {
  if (subjectName == null || subjectName.trim().isEmpty) return false;
  final validSubjects = getSubjectsForClass(classNameOrId, classes: classes);
  final cleanSubject = subjectName.trim().toLowerCase();
  return validSubjects.any((s) => s.trim().toLowerCase() == cleanSubject);
}
