// user_role.dart

enum UserRole { student, classTeacher, superAdmin }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.classTeacher:
        return 'Class Teacher';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  String get dbValue {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.classTeacher:
        return 'class_teacher';
      case UserRole.superAdmin:
        return 'super_admin';
    }
  }

  static UserRole fromDbValue(String val) {
    switch (val.toLowerCase().trim()) {
      case 'student':
        return UserRole.student;
      case 'class_teacher':
      case 'teacher': // fallback for legacy values
        return UserRole.classTeacher;
      case 'super_admin':
      case 'admin': // fallback for legacy values
        return UserRole.superAdmin;
      default:
        throw ArgumentError('Invalid user role: $val');
    }
  }
}
