// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String defaultBaseUrl = String.fromEnvironment('API_BASE_URL');

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminStudents = '/admin/students';
  static const String adminBulkImportStudents = '/admin/students/import';
  static const String adminTeachers = '/admin/teachers';
  static const String adminAssignTeacher = '/admin/teachers/assign';
  static const String adminClasses = '/admin/classes';
  static String adminClassTabs(int classId) => '/admin/classes/$classId/tabs';
  static String adminClassSections(int classId) => '/admin/classes/$classId/sections';
  static const String adminSubjects = '/admin/subjects';
  static const String adminMaterials = '/admin/materials';
  static String adminPublishMaterial(int id) => '/admin/materials/$id/publish';
  static const String adminAnnouncements = '/admin/announcements';
  static const String adminTimetable = '/admin/timetable';
  static const String adminAcademicYears = '/admin/academic-years';

  // Student
  static const String studentProfile = '/student/profile';
  static const String studentSubjects = '/student/subjects';
  static const String studentLessons = '/student/lessons';
  static String studentLessonOverview(int lessonId) => '/student/lessons/$lessonId/overview';
  static const String studentMaterials = '/student/materials';
  static const String studentAssignments = '/student/assignments';
  static const String studentSubmitAssignment = '/student/assignments/submit';
  static const String studentQuizzes = '/student/quizzes';
  static const String studentSubmitQuiz = '/student/quiz/submit';
  static const String studentTimetable = '/student/timetable';
  static const String studentAnnouncements = '/student/announcements';

  // Teacher
  static const String teacherSubjects = '/teacher/subjects';
  static const String teacherLessons = '/teacher/lessons';
  static const String teacherMaterials = '/teacher/materials';
  static const String teacherUploadMaterial = '/teacher/materials/upload';
  static String teacherPublishMaterial(int id) => '/teacher/materials/$id/publish';
  static const String teacherAssignments = '/teacher/assignments';
  static const String teacherCreateAssignment = '/teacher/assignments/create';
  static const String teacherAssignmentSubmissions = '/teacher/assignments/submissions';
  static const String teacherGradeSubmission = '/teacher/assignments/grade';
  static const String teacherQuizzes = '/teacher/quizzes';
  static const String teacherCreateQuiz = '/teacher/quiz/create';
  static const String teacherFlashcards = '/teacher/flashcards';
  static const String teacherCreateFlashcard = '/teacher/flashcards/create';
  static const String teacherMindmaps = '/teacher/mindmaps';
  static const String teacherCreateMindmap = '/teacher/mindmaps/create';
  static const String teacherTimetable = '/teacher/timetable';
  static const String teacherAnnouncements = '/teacher/announcements';
}
