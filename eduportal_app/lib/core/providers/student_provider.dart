// lib/core/providers/student_provider.dart
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class StudentProvider extends ChangeNotifier {
  final _api = ApiService();

  UserModel? _profile;
  List<SubjectModel> _subjects = [];
  List<LessonModel> _lessons = [];
  List<MaterialModel> _materials = [];
  LessonSidebarCounts _currentCounts = const LessonSidebarCounts();
  List<AssignmentModel> _assignments = [];
  List<QuizModel> _quizzes = [];
  List<AnnouncementModel> _announcements = [];
  bool _loading = false;
  String? _error;

  UserModel? get profile => _profile;
  List<SubjectModel> get subjects => _subjects;
  List<LessonModel> get lessons => _lessons;
  List<MaterialModel> get materials => _materials;
  LessonSidebarCounts get currentCounts => _currentCounts;
  List<AssignmentModel> get assignments => _assignments;
  List<QuizModel> get quizzes => _quizzes;
  List<AnnouncementModel> get announcements => _announcements;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchProfile() async {
    try {
      final data = await _api.get(ApiConstants.studentProfile);
      _profile = UserModel.fromJson(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching student profile: $e');
    }
  }

  Future<void> fetchSubjects() async {
    _loading = true;
    notifyListeners();
    try {
      await fetchProfile();
      final data = await _api.get(ApiConstants.studentSubjects);
      _subjects = (data['subjects'] as List).map((s) => SubjectModel.fromJson(s)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLessons(int subjectId) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.get(ApiConstants.studentLessons, queryParams: {'subject_id': subjectId});
      _lessons = (data['lessons'] as List).map((l) => LessonModel.fromJson(l)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLessonOverview(int lessonId) async {
    try {
      final data = await _api.get(ApiConstants.studentLessonOverview(lessonId));
      if (data['counts'] != null) {
        _currentCounts = LessonSidebarCounts.fromJson(data['counts']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching lesson overview counts: $e');
    }
  }

  Future<void> fetchMaterials(int lessonId, {String? materialType}) async {
    _loading = true;
    notifyListeners();
    try {
      await fetchLessonOverview(lessonId);
      final query = <String, dynamic>{'lesson_id': lessonId};
      if (materialType != null && materialType.isNotEmpty && materialType != 'all') {
        query['material_type'] = materialType;
      }
      final data = await _api.get(ApiConstants.studentMaterials, queryParams: query);
      _materials = (data['materials'] as List).map((m) => MaterialModel.fromJson(m)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAssignments() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.get(ApiConstants.studentAssignments);
      _assignments = (data['assignments'] as List).map((a) => AssignmentModel.fromJson(a)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> submitAssignment(int assignmentId, dynamic file) async {
    try {
      await _api.uploadFile(
        ApiConstants.studentSubmitAssignment,
        file,
        extraFields: {'assignment_id': assignmentId.toString()},
      );
      await fetchAssignments();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchQuizzes({int? lessonId}) async {
    _loading = true;
    notifyListeners();
    try {
      final query = lessonId != null ? {'lesson_id': lessonId} : null;
      final data = await _api.get(ApiConstants.studentQuizzes, queryParams: query);
      _quizzes = (data['quizzes'] as List).map((q) => QuizModel.fromJson(q)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<QuizModel?> fetchQuizDetail(int quizId) async {
    try {
      final data = await _api.get('${ApiConstants.studentQuizzes}/$quizId');
      return QuizModel.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching quiz detail: $e');
      final matches = _quizzes.where((q) => q.id == quizId).toList();
      return matches.isNotEmpty ? matches.first : null;
    }
  }

  Future<Map<String, dynamic>?> submitQuiz(int quizId, Map<dynamic, int> answers) async {
    try {
      final res = await _api.post(ApiConstants.studentSubmitQuiz, data: {
        'quiz_id': quizId,
        'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      });
      await fetchQuizzes();
      return res;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchAnnouncements() async {
    try {
      final data = await _api.get(ApiConstants.studentAnnouncements);
      _announcements = (data['announcements'] as List)
          .map((a) => AnnouncementModel.fromJson(a))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
    }
  }
}
