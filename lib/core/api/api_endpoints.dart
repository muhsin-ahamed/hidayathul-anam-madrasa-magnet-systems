class ApiEndpoints {
  // Base URL for the backend
  // In development, defaults to http://localhost:5000/api.
  // In production, pass --dart-define=API_BASE_URL=https://[YOUR-RENDER-BACKEND-URL]/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  // Auth
  static String get login => '$baseUrl/auth/login';
  static String get me => '$baseUrl/auth/me';

  // Modules
  static String get dashboard => '$baseUrl/dashboard';
  static String get teachers => '$baseUrl/teachers';
  static String get students => '$baseUrl/students';
  static String get classes => '$baseUrl/classes';
  static String get results => '$baseUrl/results';
  static String get notes => '$baseUrl/notes';
  static String get hallTickets => '$baseUrl/hall-tickets';
  static String get activityLogs => '$baseUrl/activity-logs';
}

