// lib/core/providers/teacher_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class TeacherProvider extends ChangeNotifier {
  final _api = ApiService();

  List<SubjectModel> _subjects = [];
  List<LessonModel> _lessons = [];
  List<MaterialModel> _materials = [];
  List<AssignmentModel> _assignments = [];
  List<QuizModel> _quizzes = [];
  List<FlashcardModel> _flashcards = [];
  List<MindmapModel> _mindmaps = [];
  bool _loading = false;
  double _uploadProgress = 0;
  String? _error;

  List<SubjectModel> get subjects => _subjects;
  List<LessonModel> get lessons => _lessons;
  List<MaterialModel> get materials => _materials;
  List<AssignmentModel> get assignments => _assignments;
  List<QuizModel> get quizzes => _quizzes;
  List<FlashcardModel> get flashcards => _flashcards;
  List<MindmapModel> get mindmaps => _mindmaps;
  bool get loading => _loading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;

  Future<void> fetchSubjects() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.get(ApiConstants.teacherSubjects);
      _subjects = (data['subjects'] as List).map((s) => SubjectModel.fromJson(s)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLessons(int subjectId, {int? classId}) async {
    _loading = true;
    notifyListeners();
    try {
      final params = <String, dynamic>{'subject_id': subjectId};
      if (classId != null) params['class_id'] = classId;
      final data = await _api.get(ApiConstants.teacherLessons, queryParams: params);
      _lessons = (data['lessons'] as List).map((l) => LessonModel.fromJson(l)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createLesson({
    required int subjectId,
    required String title,
    required String description,
    int? classId,
    int? unitId,
  }) async {
    try {
      await _api.post(ApiConstants.teacherLessons, data: {
        'subject_id': subjectId,
        'title': title,
        'description': description,
        if (classId != null) 'class_id': classId,
        if (unitId != null) 'unit_id': unitId,
      });
      await fetchLessons(subjectId, classId: classId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMaterials(int lessonId) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.get(ApiConstants.teacherMaterials, queryParams: {'lesson_id': lessonId});
      _materials = (data['materials'] as List).map((m) => MaterialModel.fromJson(m)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadMaterial({
    required int lessonId,
    required String title,
    String description = '',
    required String materialType, // 'video', 'pdf', 'ppt', 'notes', 'doc', 'link', 'other'
    String publicationStatus = 'published',
    String? duration,
    String? externalUrl,
    File? file,
  }) async {
    _uploadProgress = 0;
    notifyListeners();
    try {
      final extra = <String, String>{
        'lesson_id': lessonId.toString(),
        'title': title,
        'description': description,
        'material_type': materialType,
        'publication_status': publicationStatus,
      };
      if (duration != null) extra['duration'] = duration;
      if (externalUrl != null) extra['external_url'] = externalUrl;

      if (file != null) {
        await _api.uploadFile(
          ApiConstants.teacherUploadMaterial,
          file,
          extraFields: extra,
          onProgress: (sent, total) {
            _uploadProgress = total > 0 ? sent / total : 0.0;
            notifyListeners();
          },
        );
      } else {
        // Upload without file (e.g. video URL or external resource)
        await _api.postForm(ApiConstants.teacherUploadMaterial, fields: extra);
      }

      await fetchMaterials(lessonId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _uploadProgress = 0;
      notifyListeners();
    }
  }

  Future<bool> setMaterialPublicationStatus(int materialId, String status, int lessonId) async {
    try {
      await _api.put('${ApiConstants.teacherMaterials}/$materialId/publish?status=$status');
      await fetchMaterials(lessonId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMaterial(int materialId, int lessonId) async {
    try {
      await _api.delete('${ApiConstants.teacherMaterials}/$materialId');
      await fetchMaterials(lessonId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAssignments(int subjectId) async {
    try {
      final data = await _api.get(ApiConstants.teacherAssignments, queryParams: {'subject_id': subjectId});
      _assignments = (data['assignments'] as List).map((a) => AssignmentModel.fromJson(a)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
    }
  }

  Future<void> fetchQuizzes(int subjectId) async {
    try {
      final data = await _api.get(ApiConstants.teacherQuizzes, queryParams: {'subject_id': subjectId});
      _quizzes = (data['quizzes'] as List).map((q) => QuizModel.fromJson(q)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching quizzes: $e');
    }
  }

  Future<void> fetchFlashcards(int subjectId) async {
    try {
      final data = await _api.get(ApiConstants.teacherFlashcards, queryParams: {'subject_id': subjectId});
      _flashcards = (data['flashcards'] as List).map((f) => FlashcardModel.fromJson(f)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching flashcards: $e');
    }
  }

  Future<void> fetchMindmaps(int subjectId) async {
    try {
      final data = await _api.get(ApiConstants.teacherMindmaps, queryParams: {'subject_id': subjectId});
      _mindmaps = (data['mindmaps'] as List).map((m) => MindmapModel.fromJson(m)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching mindmaps: $e');
    }
  }

  Future<bool> createAssignment({
    required int subjectId,
    required String title,
    required String description,
    required DateTime dueDate,
    required int maxScore,
  }) async {
    try {
      await _api.post(ApiConstants.teacherAssignments, data: {
        'subject_id': subjectId,
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String(),
        'max_score': maxScore,
      });
      await fetchAssignments(subjectId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createQuiz({
    required int subjectId,
    required String title,
    required int timeMinutes,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      await _api.post(ApiConstants.teacherQuizzes, data: {
        'subject_id': subjectId,
        'title': title,
        'time_minutes': timeMinutes,
        'questions': questions,
      });
      await fetchQuizzes(subjectId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
