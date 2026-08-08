class ApiEndpoints {
  // Base URL for the backend
  // In development (Android emulator), use 10.0.2.2. For Web/iOS, use localhost.
  static const String baseUrl = 'http://localhost:5000/api';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';

  // Modules
  static const String dashboard = '$baseUrl/dashboard';
  static const String teachers = '$baseUrl/teachers';
  static const String students = '$baseUrl/students';
  static const String classes = '$baseUrl/classes';
  static const String results = '$baseUrl/results';
  static const String notes = '$baseUrl/notes';
  static const String hallTickets = '$baseUrl/hall-tickets';
  static const String activityLogs = '$baseUrl/activity-logs';
}
