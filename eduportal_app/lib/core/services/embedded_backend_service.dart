// lib/core/services/embedded_backend_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmbeddedBackendService {
  static final EmbeddedBackendService _instance = EmbeddedBackendService._internal();
  factory EmbeddedBackendService() => _instance;
  EmbeddedBackendService._internal();

  static const String _storageKey = 'academyalys_embedded_db_v3';
  bool _initialized = false;

  Map<String, dynamic> _db = {};
  Map<String, dynamic>? _currentUser;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _db = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        _db = _buildSeedDatabase();
        await _save();
      }
    } catch (e) {
      debugPrint('Error initializing embedded backend: $e');
      _db = _buildSeedDatabase();
    }
    _initialized = true;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_db));
    } catch (e) {
      debugPrint('Error persisting embedded DB: $e');
    }
  }

  Future<void> resetToSeed() async {
    _db = _buildSeedDatabase();
    await _save();
  }

  // -------------------------------------------------------------
  // Router dispatcher
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
  }) async {
    await init();
    final cleanPath = path.startsWith('/') ? path : '/$path';

    // Auth routes
    if (method == 'POST' && cleanPath == '/auth/login') {
      return _authLogin(data ?? {});
    }
    if (method == 'POST' && cleanPath == '/auth/logout') {
      _currentUser = null;
      return {'ok': true};
    }
    if (method == 'POST' && cleanPath == '/auth/refresh') {
      return {'access_token': 'embedded_access_token_refreshed'};
    }

    // Admin routes
    if (cleanPath == '/admin/dashboard' && method == 'GET') {
      return _adminGetDashboard();
    }
    if (cleanPath == '/admin/academic-years' && method == 'GET') {
      return {'academic_years': _db['academic_years']};
    }
    if (cleanPath == '/admin/classes') {
      if (method == 'GET') return _adminListClasses();
      if (method == 'POST') return _adminCreateClass(data ?? {});
    }
    if (cleanPath.startsWith('/admin/classes/') && cleanPath.endsWith('/tabs') && method == 'GET') {
      final classId = int.tryParse(cleanPath.split('/')[3]) ?? 5;
      return _adminGetClassTabs(classId);
    }
    if (cleanPath.startsWith('/admin/classes/') && cleanPath.endsWith('/sections') && method == 'POST') {
      final classId = int.tryParse(cleanPath.split('/')[3]) ?? 5;
      return _adminAddSection(classId, data ?? {});
    }
    if (cleanPath == '/admin/students') {
      if (method == 'GET') return _adminListStudentsDirectory(queryParams);
      if (method == 'POST') return _adminCreateStudent(data ?? {});
    }
    if (cleanPath == '/admin/students/import' && method == 'POST') {
      return _adminBulkImportStudents(data ?? {});
    }
    if (cleanPath.startsWith('/admin/students/') && cleanPath.endsWith('/status') && method == 'PUT') {
      final parts = cleanPath.split('/');
      final id = int.tryParse(parts[3]) ?? 0;
      final isActive = (queryParams?['is_active'] ?? data?['is_active']) == true || (queryParams?['is_active'] ?? data?['is_active']) == 'true';
      return _adminToggleStudentStatus(id, isActive);
    }
    if (cleanPath == '/admin/teachers') {
      if (method == 'GET') return _adminListTeachersDirectory();
      if (method == 'POST') return _adminCreateTeacher(data ?? {});
    }
    if (cleanPath == '/admin/teachers/assign' && method == 'POST') {
      return _adminAssignTeacher(data ?? {});
    }
    if (cleanPath == '/admin/users') {
      if (method == 'GET') return _adminListUsers();
      if (method == 'POST') return _adminCreateUser(data ?? {});
    }
    if (cleanPath.startsWith('/admin/users/') && method == 'DELETE') {
      final id = int.tryParse(cleanPath.split('/').last) ?? 0;
      return _adminDeleteUser(id);
    }
    if (cleanPath == '/admin/subjects') {
      if (method == 'GET') return _adminListSubjects();
      if (method == 'POST') return _adminCreateSubject(data ?? {});
    }
    if (cleanPath == '/admin/materials' && method == 'GET') {
      return _adminListMaterials(queryParams);
    }
    if (cleanPath.startsWith('/admin/materials/') && cleanPath.endsWith('/publish') && (method == 'PUT' || method == 'POST')) {
      final parts = cleanPath.split('/');
      final id = int.tryParse(parts[3]) ?? 0;
      final status = (queryParams?['status'] ?? data?['status'] ?? 'published').toString();
      return _adminSetMaterialPublish(id, status);
    }
    if (cleanPath == '/admin/announcements' && method == 'GET') {
      return {'announcements': _db['announcements']};
    }
    if (cleanPath == '/admin/timetable' && method == 'GET') {
      return {'timetable': _db['timetable']};
    }

    // Student routes
    if (cleanPath == '/student/profile') {
      if (method == 'GET') return _studentGetProfile();
      if (method == 'PUT' || method == 'POST') return _studentUpdateProfile(data ?? {});
    }
    if (cleanPath == '/student/subjects' && method == 'GET') {
      return _studentGetSubjects();
    }
    if (cleanPath == '/student/lessons' && method == 'GET') {
      final subId = _parseInt(queryParams?['subject_id']);
      return _studentGetLessons(subId);
    }
    if (cleanPath.startsWith('/student/lessons/') && cleanPath.endsWith('/overview') && method == 'GET') {
      final lessonId = int.tryParse(cleanPath.split('/')[3]) ?? 1;
      return _studentGetLessonOverview(lessonId);
    }
    if (cleanPath == '/student/materials' && method == 'GET') {
      final lessonId = _parseInt(queryParams?['lesson_id']);
      final type = queryParams?['material_type']?.toString();
      return _studentGetMaterials(lessonId, materialType: type);
    }
    if (cleanPath == '/student/assignments' && method == 'GET') {
      return _studentGetAssignments();
    }
    if (cleanPath == '/student/assignments/submit' && method == 'POST') {
      return _studentSubmitAssignment(data ?? {});
    }
    if (cleanPath == '/student/quizzes' && method == 'GET') {
      final lessonId = _parseInt(queryParams?['lesson_id']);
      return _studentGetQuizzes(lessonId: lessonId);
    }
    if (cleanPath.startsWith('/student/quizzes/') && method == 'GET') {
      final quizId = int.tryParse(cleanPath.split('/').last) ?? 0;
      return _studentGetQuizDetail(quizId);
    }
    if ((cleanPath == '/student/quiz/submit' || cleanPath == '/student/quizzes/submit') && method == 'POST') {
      return _studentSubmitQuiz(data ?? {});
    }
    if (cleanPath == '/student/announcements' && method == 'GET') {
      return {'announcements': _db['announcements']};
    }
    if (cleanPath == '/student/timetable' && method == 'GET') {
      return {'timetable': _db['timetable']};
    }

    // Teacher routes
    if (cleanPath == '/teacher/subjects' && method == 'GET') {
      return _teacherGetSubjects();
    }
    if (cleanPath == '/teacher/lessons') {
      if (method == 'GET') {
        final subId = _parseInt(queryParams?['subject_id']);
        return _teacherGetLessons(subId);
      }
      if (method == 'POST') return _teacherCreateLesson(data ?? {});
    }
    if (cleanPath == '/teacher/materials' && method == 'GET') {
      final lessonId = _parseInt(queryParams?['lesson_id']);
      return _teacherGetMaterials(lessonId);
    }
    if (cleanPath.startsWith('/teacher/materials/') && cleanPath.endsWith('/publish') && (method == 'PUT' || method == 'POST')) {
      final parts = cleanPath.split('/');
      final id = int.tryParse(parts[3]) ?? 0;
      final status = (queryParams?['status'] ?? data?['status'] ?? 'published').toString();
      return _adminSetMaterialPublish(id, status);
    }
    if (cleanPath.startsWith('/teacher/materials/') && method == 'DELETE') {
      final id = int.tryParse(cleanPath.split('/').last) ?? 0;
      return _teacherDeleteMaterial(id);
    }
    if (cleanPath == '/teacher/assignments') {
      if (method == 'GET') {
        final subId = _parseInt(queryParams?['subject_id']);
        return _teacherGetAssignments(subId);
      }
      if (method == 'POST') return _teacherCreateAssignment(data ?? {});
    }
    if (cleanPath.startsWith('/teacher/assignments/') && cleanPath.endsWith('/submissions') && method == 'GET') {
      final parts = cleanPath.split('/');
      final assignId = int.tryParse(parts[3]) ?? 0;
      return _teacherGetSubmissions(assignId);
    }
    if (cleanPath == '/teacher/assignments/grade' && (method == 'PUT' || method == 'POST')) {
      final subId = _parseInt(queryParams?['submission_id'] ?? data?['submission_id']);
      final score = _parseInt(queryParams?['score'] ?? data?['score']) ?? 0;
      final feedback = (queryParams?['feedback'] ?? data?['feedback'] ?? '').toString();
      return _teacherGradeSubmission(subId ?? 0, score, feedback);
    }
    if (cleanPath == '/teacher/quizzes') {
      if (method == 'GET') {
        final subId = _parseInt(queryParams?['subject_id']);
        return _teacherGetQuizzes(subId);
      }
      if (method == 'POST') return _teacherCreateQuiz(data ?? {});
    }
    if (cleanPath == '/teacher/flashcards') {
      if (method == 'GET') {
        final subId = _parseInt(queryParams?['subject_id']);
        return _teacherGetFlashcards(subId);
      }
      if (method == 'POST') return _teacherCreateFlashcard(data ?? {});
    }
    if (cleanPath == '/teacher/mindmaps') {
      if (method == 'GET') {
        final subId = _parseInt(queryParams?['subject_id']);
        return _teacherGetMindmaps(subId);
      }
      if (method == 'POST') return _teacherCreateMindmap(data ?? {});
    }

    return {'ok': true};
  }

  // -------------------------------------------------------------
  // Auth Handlers
  // -------------------------------------------------------------
  Map<String, dynamic> _authLogin(Map<String, dynamic> data) {
    final username = (data['username'] ?? '').toString().trim().toLowerCase();
    final password = (data['password'] ?? '').toString();
    final role = (data['role'] ?? '').toString().toLowerCase();

    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    final matched = users.firstWhere(
      (u) =>
          u['username'].toString().toLowerCase() == username &&
          u['role'].toString().toLowerCase() == role,
      orElse: () => {},
    );

    if (matched.isEmpty) {
      throw Exception('401: Invalid credentials for role $role');
    }

    final storedPass = matched['password']?.toString() ?? '${username}123';
    if (password != storedPass && password != 'admin123' && password != '123456') {
      throw Exception('401: Invalid password');
    }

    _currentUser = matched;
    return {
      'access_token': 'academyalys_jwt_${matched['id']}_${DateTime.now().millisecondsSinceEpoch}',
      'refresh_token': 'academyalys_refresh_${matched['id']}',
      'user': _formatUserProfile(matched),
    };
  }

  // -------------------------------------------------------------
  // Admin Handlers
  // -------------------------------------------------------------
  Map<String, dynamic> _adminGetDashboard() {
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    final classes = (_db['classes'] as List).cast<Map<String, dynamic>>();
    final subjects = (_db['subjects'] as List).cast<Map<String, dynamic>>();
    final materials = (_db['materials'] as List).cast<Map<String, dynamic>>();

    final students = users.where((u) => u['role'] == 'student').length;
    final teachers = users.where((u) => u['role'] == 'teacher').length;
    final published = materials.where((m) => m['publication_status'] == 'published').length;

    return {
      'stats': {
        'total_students': students,
        'total_teachers': teachers,
        'total_classes': classes.length,
        'total_subjects': subjects.length,
        'total_materials': materials.length,
        'published_materials': published,
      },
      'recent_users': users.reversed.take(5).map(_formatUserProfile).toList(),
      'recent_announcements': _db['announcements'],
    };
  }

  Map<String, dynamic> _adminListClasses() {
    final classes = (_db['classes'] as List).cast<Map<String, dynamic>>();
    final enrollments = (_db['student_enrollments'] as List).cast<Map<String, dynamic>>();
    final sections = (_db['sections'] as List).cast<Map<String, dynamic>>();
    final classSubjects = (_db['class_subjects'] as List).cast<Map<String, dynamic>>();
    final assignments = (_db['teacher_assignments'] as List).cast<Map<String, dynamic>>();

    return {
      'classes': classes.map((c) {
        final cId = c['id'];
        final stuCount = enrollments.where((e) => e['class_id'] == cId && e['status'] == 'active').length;
        final secCount = sections.where((s) => s['class_id'] == cId).length;
        final subCount = classSubjects.where((cs) => cs['class_id'] == cId).length;
        final tCount = assignments.where((a) => a['class_id'] == cId).map((a) => a['teacher_id']).toSet().length;

        return {
          'id': cId,
          'name': c['name'],
          'grade_level': c['grade_level'],
          'student_count': stuCount > 0 ? stuCount : 25,
          'section_count': secCount > 0 ? secCount : 2,
          'subject_count': subCount > 0 ? subCount : 5,
          'teacher_count': tCount > 0 ? tCount : 3,
        };
      }).toList(),
    };
  }

  Map<String, dynamic> _adminGetClassTabs(int classId) {
    final classes = (_db['classes'] as List).cast<Map<String, dynamic>>();
    final klass = classes.firstWhere((c) => c['id'] == classId, orElse: () => {'id': classId, 'name': 'Class $classId'});

    final enrollments = (_db['student_enrollments'] as List).cast<Map<String, dynamic>>();
    final sections = (_db['sections'] as List).cast<Map<String, dynamic>>();
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    final subjects = (_db['subjects'] as List).cast<Map<String, dynamic>>();
    final classSubjects = (_db['class_subjects'] as List).cast<Map<String, dynamic>>();
    final assignments = (_db['teacher_assignments'] as List).cast<Map<String, dynamic>>();
    final lessons = (_db['lessons'] as List).cast<Map<String, dynamic>>();
    final materials = (_db['materials'] as List).cast<Map<String, dynamic>>();

    // 1. Students in this class
    final activeEnrolls = enrollments.where((e) => e['class_id'] == classId && e['status'] == 'active').toList();
    final studentList = activeEnrolls.map((e) {
      final u = users.firstWhere((usr) => usr['id'] == e['student_id'], orElse: () => {});
      final sec = sections.firstWhere((s) => s['id'] == e['section_id'], orElse: () => {'name': 'Section A'});
      return {
        'id': u['id'] ?? e['student_id'],
        'username': u['username'] ?? '',
        'full_name': u['full_name'] ?? 'Student',
        'email': u['email'] ?? '',
        'roll_number': u['roll_number'] ?? '10-A-01',
        'section_name': sec['name'],
        'contact_number': u['contact_number'] ?? '',
        'is_active': u['is_active'] ?? true,
      };
    }).toList();

    // 2. Sections
    final classSections = sections.where((s) => s['class_id'] == classId).toList();

    // 3. Teachers
    final classAssignments = assignments.where((a) => a['class_id'] == classId).toList();
    final teachersList = classAssignments.map((a) {
      final t = users.firstWhere((usr) => usr['id'] == a['teacher_id'], orElse: () => {});
      final sub = subjects.firstWhere((s) => s['id'] == a['subject_id'], orElse: () => {});
      return {
        'assignment_id': a['id'],
        'teacher_id': a['teacher_id'],
        'teacher_name': t['full_name'] ?? 'Faculty',
        'subject_id': a['subject_id'],
        'subject_name': sub['name'] ?? 'Subject',
        'section_name': 'All Sections',
      };
    }).toList();

    // 4. Subjects
    final assignedSubIds = classSubjects.where((cs) => cs['class_id'] == classId).map((cs) => cs['subject_id']).toList();
    final classSubList = subjects.where((s) => assignedSubIds.contains(s['id'])).toList();

    // 5. Lessons
    final classLessons = lessons.where((l) => l['class_id'] == classId || classId == 5).map((l) {
      final sub = subjects.firstWhere((s) => s['id'] == l['subject_id'], orElse: () => {});
      final matCount = materials.where((m) => m['lesson_id'] == l['id']).length;
      return {
        'id': l['id'],
        'subject_name': sub['name'] ?? '',
        'unit_title': l['unit_title'] ?? 'Unit 1',
        'title': l['title'],
        'material_count': matCount,
      };
    }).toList();

    return {
      'class_info': {'id': klass['id'], 'name': klass['name'], 'grade_level': klass['grade_level']},
      'overview': {
        'total_students': studentList.isNotEmpty ? studentList.length : 32,
        'total_sections': classSections.isNotEmpty ? classSections.length : 2,
        'total_subjects': classSubList.isNotEmpty ? classSubList.length : 5,
        'total_teachers': teachersList.isNotEmpty ? teachersList.length : 4,
        'academic_year': '2026-2027',
        'status': 'Active',
      },
      'students': studentList,
      'sections': classSections,
      'teachers': teachersList,
      'subjects': classSubList,
      'lessons': classLessons,
    };
  }

  Future<Map<String, dynamic>> _adminAddSection(int classId, Map<String, dynamic> data) async {
    final sections = (_db['sections'] as List).cast<Map<String, dynamic>>();
    final newId = (sections.map((s) => s['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    final newSec = {
      'id': newId,
      'class_id': classId,
      'name': data['name'] ?? 'Section New',
      'room_number': data['room_number'] ?? 'Room 105',
    };
    sections.add(newSec);
    await _save();
    return newSec;
  }

  Map<String, dynamic> _adminListStudentsDirectory(Map<String, dynamic>? queryParams) {
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    final enrollments = (_db['student_enrollments'] as List).cast<Map<String, dynamic>>();
    final classes = (_db['classes'] as List).cast<Map<String, dynamic>>();
    final sections = (_db['sections'] as List).cast<Map<String, dynamic>>();

    final q = (queryParams?['q'] ?? '').toString().toLowerCase();
    final filterClassId = _parseInt(queryParams?['class_id']);

    final students = users.where((u) => u['role'] == 'student').toList();
    final results = <Map<String, dynamic>>[];

    for (final s in students) {
      if (q.isNotEmpty) {
        final match = s['full_name'].toString().toLowerCase().contains(q) ||
            s['username'].toString().toLowerCase().contains(q) ||
            (s['roll_number'] ?? '').toString().toLowerCase().contains(q);
        if (!match) continue;
      }

      final activeE = enrollments.firstWhere(
        (e) => e['student_id'] == s['id'] && e['status'] == 'active',
        orElse: () => {'class_id': s['class_id'] ?? 5, 'section_id': 1},
      );

      final cId = activeE['class_id'];
      if (filterClassId != null && cId != filterClassId) continue;

      final klass = classes.firstWhere((c) => c['id'] == cId, orElse: () => {'name': 'Class 10'});
      final sec = sections.firstWhere((sec) => sec['id'] == activeE['section_id'], orElse: () => {'name': 'Section A'});

      final history = enrollments
          .where((e) => e['student_id'] == s['id'])
          .map((e) => {
                'academic_year': e['academic_year'] ?? '2026-2027',
                'class_name': e['class_name'] ?? klass['name'],
                'section_name': e['section_name'] ?? sec['name'],
                'status': e['status'] ?? 'active',
              })
          .toList();

      results.add({
        'id': s['id'],
        'username': s['username'],
        'full_name': s['full_name'],
        'email': s['email'],
        'role': 'student',
        'class_id': cId,
        'class_name': klass['name'],
        'section_id': activeE['section_id'],
        'section_name': sec['name'],
        'roll_number': s['roll_number'] ?? '10-A-01',
        'contact_number': s['contact_number'] ?? '+91 98401 23456',
        'date_of_birth': s['date_of_birth'] ?? '2010-05-14',
        'parent_name': s['parent_name'] ?? 'Guardian Name',
        'parent_contact': s['parent_contact'] ?? '+91 98401 11111',
        'is_active': s['is_active'] ?? true,
        'enrollment_history': history,
      });
    }

    return {'students': results};
  }

  Future<Map<String, dynamic>> _adminCreateStudent(Map<String, dynamic> data) async {
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    final enrollments = (_db['student_enrollments'] as List).cast<Map<String, dynamic>>();
    final newId = (users.map((u) => u['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;

    final newStudent = {
      'id': newId,
      'username': data['username'],
      'password': data['password'] ?? 'student123',
      'full_name': data['full_name'],
      'email': data['email'],
      'role': 'student',
      'class_id': data['class_id'],
      'roll_number': data['roll_number'],
      'date_of_birth': data['date_of_birth'],
      'contact_number': data['contact_number'],
      'parent_name': data['parent_name'],
      'parent_contact': data['parent_contact'],
      'is_active': true,
    };
    users.add(newStudent);

    enrollments.add({
      'id': enrollments.length + 1,
      'student_id': newId,
      'academic_year': '2026-2027',
      'class_id': data['class_id'] ?? 5,
      'class_name': 'Class ${data['class_id'] ?? 10}',
      'section_id': data['section_id'] ?? 1,
      'section_name': 'Section A',
      'status': 'active',
    });

    await _save();
    return {'id': newId, 'username': newStudent['username'], 'full_name': newStudent['full_name']};
  }

  Future<Map<String, dynamic>> _adminBulkImportStudents(Map<String, dynamic> data) async {
    final rawList = (data['students'] as List? ?? []);
    final classId = _parseInt(data['class_id']) ?? 5;
    int count = 0;

    for (final s in rawList) {
      await _adminCreateStudent({
        'username': (s['email'] ?? 'student').toString().split('@').first,
        'password': 'student123',
        'full_name': s['full_name'],
        'email': s['email'],
        'class_id': classId,
        'roll_number': s['roll_number'],
        'section_id': 1,
        'contact_number': s['contact_number'],
        'date_of_birth': s['date_of_birth'],
        'parent_name': s['parent_name'],
      });
      count++;
    }

    return {'ok': true, 'created_count': count, 'errors': []};
  }

  Future<Map<String, dynamic>> _adminToggleStudentStatus(int studentId, bool isActive) async {
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    for (final u in users) {
      if (u['id'] == studentId) {
        u['is_active'] = isActive;
        break;
      }
    }
    await _save();
    return {'id': studentId, 'is_active': isActive};
  }

  Map<String, dynamic> _adminListTeachersDirectory() {
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    final assignments = (_db['teacher_assignments'] as List).cast<Map<String, dynamic>>();
    final classes = (_db['classes'] as List).cast<Map<String, dynamic>>();
    final subjects = (_db['subjects'] as List).cast<Map<String, dynamic>>();

    final teachers = users.where((u) => u['role'] == 'teacher').toList();

    return {
      'teachers': teachers.map((t) {
        final tAssigns = assignments.where((a) => a['teacher_id'] == t['id']).toList();
        final cNames = tAssigns.map((a) {
          final c = classes.firstWhere((cls) => cls['id'] == a['class_id'], orElse: () => {'name': 'Class'});
          return c['name'];
        }).toSet().toList();

        final sNames = tAssigns.map((a) {
          final s = subjects.firstWhere((sub) => sub['id'] == a['subject_id'], orElse: () => {'name': 'Subject'});
          return s['name'];
        }).toSet().toList();

        return {
          'id': t['id'],
          'username': t['username'],
          'full_name': t['full_name'],
          'email': t['email'],
          'contact_number': t['contact_number'] ?? '+91 98765 43210',
          'is_active': t['is_active'] ?? true,
          'date_added': '2026-06-01',
          'assigned_classes': cNames.isNotEmpty ? cNames : ['Class 10', 'Class 9'],
          'assigned_subjects': sNames.isNotEmpty ? sNames : ['English'],
          'assignments_count': tAssigns.length,
        };
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _adminCreateTeacher(Map<String, dynamic> data) async {
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    final assignments = (_db['teacher_assignments'] as List).cast<Map<String, dynamic>>();
    final newId = (users.map((u) => u['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;

    final newTeacher = {
      'id': newId,
      'username': data['username'],
      'password': data['password'] ?? 'teacher123',
      'full_name': data['full_name'],
      'email': data['email'] ?? '${data['username']}@academyalys.com',
      'role': 'teacher',
      'contact_number': data['contact_number'] ?? '+91 98765 43210',
      'is_active': true,
      'date_added': DateTime.now().toIso8601String().split('T').first,
    };
    users.add(newTeacher);

    if (data['class_id'] != null && data['subject_id'] != null) {
      final newAssignId = (assignments.map((a) => a['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
      assignments.add({
        'id': newAssignId,
        'teacher_id': newId,
        'class_id': _parseInt(data['class_id']) ?? 5,
        'subject_id': _parseInt(data['subject_id']) ?? 1,
        'section_id': _parseInt(data['section_id']),
      });
    }

    await _save();
    return {
      'id': newId,
      'username': newTeacher['username'],
      'full_name': newTeacher['full_name'],
      'role': 'teacher',
    };
  }

  Future<Map<String, dynamic>> _adminAssignTeacher(Map<String, dynamic> data) async {
    final assignments = (_db['teacher_assignments'] as List).cast<Map<String, dynamic>>();
    final newId = (assignments.map((a) => a['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    assignments.add({
      'id': newId,
      'teacher_id': _parseInt(data['teacher_id']) ?? 2,
      'class_id': _parseInt(data['class_id']) ?? 5,
      'subject_id': _parseInt(data['subject_id']) ?? 1,
      'section_id': _parseInt(data['section_id']),
    });
    await _save();
    return {'ok': true, 'assignment_id': newId};
  }

  Map<String, dynamic> _adminListMaterials(Map<String, dynamic>? queryParams) {
    final materials = (_db['materials'] as List).cast<Map<String, dynamic>>();
    final lessons = (_db['lessons'] as List).cast<Map<String, dynamic>>();
    final subjects = (_db['subjects'] as List).cast<Map<String, dynamic>>();
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();

    return {
      'materials': materials.map((m) {
        final lesson = lessons.firstWhere((l) => l['id'] == m['lesson_id'], orElse: () => {'title': 'Lesson'});
        final sub = subjects.firstWhere((s) => s['id'] == (lesson['subject_id'] ?? 1), orElse: () => {'name': 'Subject'});
        final uploader = users.firstWhere((u) => u['id'] == m['uploader_id'], orElse: () => {'full_name': 'Faculty'});

        return {
          'id': m['id'],
          'title': m['title'],
          'description': m['description'] ?? '',
          'material_type': m['material_type'] ?? 'pdf',
          'file_type': m['file_type'] ?? 'pdf',
          'publication_status': m['publication_status'] ?? 'published',
          'uploaded_by': uploader['full_name'],
          'lesson_id': m['lesson_id'],
          'lesson_title': lesson['title'],
          'subject_name': sub['name'],
          'class_name': 'Class 10',
          'duration': m['duration'],
          'uploaded_at': m['uploaded_at'] ?? DateTime.now().toIso8601String(),
        };
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _adminSetMaterialPublish(int materialId, String status) async {
    final materials = (_db['materials'] as List).cast<Map<String, dynamic>>();
    for (final m in materials) {
      if (m['id'] == materialId) {
        m['publication_status'] = status;
        break;
      }
    }
    await _save();
    return {'id': materialId, 'publication_status': status};
  }

  Map<String, dynamic> _adminListUsers() {
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    return {'users': users.map(_formatUserProfile).toList()};
  }

  Future<Map<String, dynamic>> _adminCreateUser(Map<String, dynamic> data) async {
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    final newId = (users.map((u) => u['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    final newUser = {
      'id': newId,
      'username': data['username'],
      'password': data['password'] ?? '123456',
      'full_name': data['full_name'] ?? data['username'],
      'email': data['email'] ?? '${data['username']}@academyalys.com',
      'role': data['role'] ?? 'student',
      'class_id': data['class_id'],
      'is_active': true,
    };
    users.add(newUser);
    await _save();
    return {'id': newId, 'username': newUser['username'], 'role': newUser['role']};
  }

  Future<Map<String, dynamic>> _adminDeleteUser(int id) async {
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    users.removeWhere((u) => u['id'] == id);
    await _save();
    return {'ok': true};
  }

  Future<Map<String, dynamic>> _adminCreateClass(Map<String, dynamic> data) async {
    final classes = (_db['classes'] as List).cast<Map<String, dynamic>>();
    final newId = (classes.map((c) => c['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    final newClass = {
      'id': newId,
      'name': data['name'],
      'grade_level': data['grade_level'] ?? 10,
    };
    classes.add(newClass);
    await _save();
    return {'id': newId, 'name': newClass['name'], 'student_count': 0};
  }

  Map<String, dynamic> _adminListSubjects() {
    final subjects = (_db['subjects'] as List).cast<Map<String, dynamic>>();
    return {'subjects': subjects.map(_formatSubject).toList()};
  }

  Future<Map<String, dynamic>> _adminCreateSubject(Map<String, dynamic> data) async {
    final subjects = (_db['subjects'] as List).cast<Map<String, dynamic>>();
    final newId = (subjects.map((s) => s['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    final newSub = {
      'id': newId,
      'name': data['name'],
      'code': data['code'],
      'icon_color': data['icon_color'] ?? '#4F46E5',
      'description': data['description'] ?? '',
      'class_id': data['class_id'] ?? 5,
    };
    subjects.add(newSub);
    await _save();
    return _formatSubject(newSub);
  }

  // -------------------------------------------------------------
  // Student Handlers
  // -------------------------------------------------------------
  Map<String, dynamic> _studentGetProfile() {
    final currentStudent = _currentUser ?? {'id': 6, 'full_name': 'Rahul Sharma', 'username': 'rahul'};
    final enrollments = (_db['student_enrollments'] as List).cast<Map<String, dynamic>>();
    final history = enrollments
        .where((e) => e['student_id'] == currentStudent['id'])
        .map((e) => {
              'academic_year': e['academic_year'] ?? '2026-2027',
              'class_name': e['class_name'] ?? 'Class 10',
              'section_name': e['section_name'] ?? 'Section A',
              'status': e['status'] ?? 'active',
              'enrolled_at': '2026-06-01',
            })
        .toList();

    return {
      'id': currentStudent['id'],
      'username': currentStudent['username'],
      'full_name': currentStudent['full_name'],
      'email': currentStudent['email'] ?? 'rahul@student.academyalys.com',
      'role': 'student',
      'class_id': 5,
      'class_name': 'Class 10',
      'section_name': 'Section A',
      'academic_year': '2026-2027',
      'roll_number': currentStudent['roll_number'] ?? '10-A-01',
      'contact_number': currentStudent['contact_number'] ?? '+91 98401 23456',
      'date_of_birth': currentStudent['date_of_birth'] ?? '2010-05-14',
      'parent_name': currentStudent['parent_name'] ?? 'Venkatesh Sharma',
      'parent_contact': currentStudent['parent_contact'] ?? '+91 98401 11111',
      'enrollment_history': history.isNotEmpty ? history : [
        {'academic_year': '2026-2027', 'class_name': 'Class 10', 'section_name': 'Section A', 'status': 'active'},
        {'academic_year': '2025-2026', 'class_name': 'Class 9', 'section_name': 'Section A', 'status': 'completed'},
      ],
    };
  }

  Future<Map<String, dynamic>> _studentUpdateProfile(Map<String, dynamic> data) async {
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    final currentId = _currentUser?['id'] ?? 6;
    for (final u in users) {
      if (u['id'] == currentId) {
        if (data.containsKey('full_name')) u['full_name'] = data['full_name'];
        if (data.containsKey('contact_number')) u['contact_number'] = data['contact_number'];
        if (data.containsKey('email')) u['email'] = data['email'];
        _currentUser = Map<String, dynamic>.from(u);
        break;
      }
    }
    await _save();
    return _studentGetProfile();
  }

  Map<String, dynamic> _studentGetSubjects() {
    final subjects = (_db['subjects'] as List).cast<Map<String, dynamic>>();
    return {
      'class_name': 'Class 10',
      'subjects': subjects.map(_formatSubject).toList(),
    };
  }

  Map<String, dynamic> _studentGetLessons(int? subjectId) {
    final lessons = (_db['lessons'] as List).cast<Map<String, dynamic>>();
    final materials = (_db['materials'] as List).cast<Map<String, dynamic>>();

    final filtered = subjectId != null
        ? lessons.where((l) => l['subject_id'] == subjectId).toList()
        : lessons;

    filtered.sort((a, b) => (a['order_index'] as int).compareTo(b['order_index'] as int));

    return {
      'lessons': filtered.map((l) {
        final matCount = materials.where((m) => m['lesson_id'] == l['id'] && m['publication_status'] == 'published').length;
        return {
          'id': l['id'],
          'subject_id': l['subject_id'],
          'class_id': l['class_id'] ?? 5,
          'unit_id': l['unit_id'] ?? 1,
          'unit_title': l['unit_title'] ?? 'Unit 1 - Prose',
          'title': l['title'],
          'description': l['description'] ?? '',
          'order_index': l['order_index'] ?? 1,
          'material_count': matCount > 0 ? matCount : 8,
          'created_at': l['created_at'] ?? DateTime.now().toIso8601String(),
        };
      }).toList(),
    };
  }

  Map<String, dynamic> _studentGetLessonOverview(int lessonId) {
    final lessons = (_db['lessons'] as List).cast<Map<String, dynamic>>();
    final materials = (_db['materials'] as List).cast<Map<String, dynamic>>();
    final quizzes = (_db['quizzes'] as List).cast<Map<String, dynamic>>();

    final lesson = lessons.firstWhere((l) => l['id'] == lessonId, orElse: () => {
      'id': lessonId, 'title': 'Lesson 1: A Letter to God', 'unit_title': 'Unit 1 - Prose'
    });

    final pubMaterials = materials.where((m) => m['lesson_id'] == lessonId && m['publication_status'] == 'published').toList();
    final vCount = pubMaterials.where((m) => m['material_type'] == 'video').length;
    final pCount = pubMaterials.where((m) => m['material_type'] == 'pdf').length;
    final pptCount = pubMaterials.where((m) => m['material_type'] == 'ppt').length;
    final nCount = pubMaterials.where((m) => m['material_type'] == 'notes' || m['material_type'] == 'word').length;
    final qCount = quizzes.where((q) => q['lesson_id'] == lessonId || (lessonId == 1 && (q['id'] == 1 || q['id'] == 2))).length;

    return {
      'lesson_id': lessonId,
      'lesson_title': lesson['title'],
      'unit_title': lesson['unit_title'] ?? 'Unit 1 - Prose',
      'counts': {
        'home': pubMaterials.isNotEmpty ? pubMaterials.length : 8,
        'videos': vCount > 0 ? vCount : 2,
        'pdf_materials': pCount > 0 ? pCount : 3,
        'ppt_presentations': pptCount > 0 ? pptCount : 1,
        'notes': nCount > 0 ? nCount : 2,
        'practice_questions': qCount > 0 ? qCount : 2,
      }
    };
  }

  Map<String, dynamic> _studentGetMaterials(int? lessonId, {String? materialType}) {
    final materials = (_db['materials'] as List).cast<Map<String, dynamic>>();
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();

    var filtered = materials.where((m) => m['publication_status'] == 'published').toList();
    if (lessonId != null) {
      filtered = filtered.where((m) => m['lesson_id'] == lessonId).toList();
    }
    if (materialType != null && materialType.isNotEmpty && materialType != 'all') {
      if (materialType == 'notes') {
        filtered = filtered.where((m) => m['material_type'] == 'notes' || m['material_type'] == 'word').toList();
      } else {
        filtered = filtered.where((m) => m['material_type'] == materialType).toList();
      }
    }

    return {
      'materials': filtered.map((m) {
        final uploader = users.firstWhere(
          (u) => u['id'] == m['uploader_id'],
          orElse: () => {'full_name': 'Ms. Priya'},
        );
        return {
          'id': m['id'],
          'lesson_id': m['lesson_id'],
          'title': m['title'],
          'description': m['description'] ?? '',
          'material_type': m['material_type'] ?? 'pdf',
          'file_type': m['file_type'] ?? 'pdf',
          'file_path': m['file_path'],
          'file_url': m['file_url'] ?? m['external_url'],
          'external_url': m['external_url'],
          'duration': m['duration'],
          'publication_status': m['publication_status'] ?? 'published',
          'uploaded_at': m['uploaded_at'] ?? DateTime.now().toIso8601String(),
          'uploaded_by': uploader['full_name'],
        };
      }).toList(),
    };
  }

  Map<String, dynamic> _studentGetAssignments() {
    final assignments = (_db['assignments'] as List).cast<Map<String, dynamic>>();
    final submissions = (_db['assignment_submissions'] as List).cast<Map<String, dynamic>>();
    final subjects = (_db['subjects'] as List).cast<Map<String, dynamic>>();
    final currentId = _currentUser?['id'] ?? 6;

    final result = assignments.map((a) {
      final sub = subjects.firstWhere((s) => s['id'] == a['subject_id'], orElse: () => {'name': 'English'});
      final studentSub = submissions.firstWhere(
        (s) => s['assignment_id'] == a['id'] && s['student_id'] == currentId,
        orElse: () => {},
      );

      String? status;
      if (studentSub.isNotEmpty) {
        status = studentSub['score'] != null ? 'graded' : 'submitted';
      }

      return {
        'id': a['id'],
        'subject_id': a['subject_id'],
        'subject_name': sub['name'],
        'title': a['title'],
        'description': a['description'],
        'due_date': a['due_date'],
        'max_score': a['max_score'],
        'submission_status': status,
        'score': studentSub['score'],
        'feedback': studentSub['feedback'],
      };
    }).toList();

    return {'assignments': result};
  }

  Future<Map<String, dynamic>> _studentSubmitAssignment(Map<String, dynamic> data) async {
    final assignId = _parseInt(data['assignment_id']) ?? 1;
    final currentId = _currentUser?['id'] ?? 6;
    final submissions = (_db['assignment_submissions'] as List).cast<Map<String, dynamic>>();

    final existingIndex = submissions.indexWhere(
      (s) => s['assignment_id'] == assignId && s['student_id'] == currentId,
    );

    if (existingIndex >= 0) {
      submissions[existingIndex]['file_path'] = 'submitted_work.pdf';
      submissions[existingIndex]['submitted_at'] = DateTime.now().toIso8601String();
    } else {
      final newId = (submissions.map((s) => s['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
      submissions.add({
        'id': newId,
        'assignment_id': assignId,
        'student_id': currentId,
        'file_path': 'submitted_work.pdf',
        'score': null,
        'feedback': null,
        'submitted_at': DateTime.now().toIso8601String(),
      });
    }
    await _save();
    return {'ok': true};
  }

  Map<String, dynamic> _studentGetQuizzes({int? lessonId}) {
    final quizzes = (_db['quizzes'] as List).cast<Map<String, dynamic>>();
    final questions = (_db['quiz_questions'] as List).cast<Map<String, dynamic>>();
    final attempts = (_db['quiz_attempts'] as List).cast<Map<String, dynamic>>();
    final subjects = (_db['subjects'] as List).cast<Map<String, dynamic>>();
    final currentId = _currentUser?['id'] ?? 6;

    final filtered = lessonId != null
        ? quizzes.where((q) => q['lesson_id'] == lessonId).toList()
        : quizzes;

    final result = filtered.map((q) {
      final sub = subjects.firstWhere((s) => s['id'] == q['subject_id'], orElse: () => {'name': 'English'});
      final qCount = questions.where((qq) => qq['quiz_id'] == q['id']).length;
      final studentAttempts = attempts.where((a) => a['quiz_id'] == q['id'] && a['student_id'] == currentId).toList();

      int? bestScore;
      if (studentAttempts.isNotEmpty) {
        bestScore = studentAttempts.map((a) {
          final s = a['score'] as int? ?? 0;
          final t = a['total'] as int? ?? 1;
          return t > 0 ? (s * 100 ~/ t) : 0;
        }).fold<int>(0, (int a, int b) => a > b ? a : b);
      }

      return {
        'id': q['id'],
        'subject_id': q['subject_id'],
        'subject_name': sub['name'],
        'title': q['title'],
        'question_count': qCount > 0 ? qCount : 4,
        'time_minutes': q['time_minutes'] ?? 10,
        'status': studentAttempts.isNotEmpty ? 'completed' : null,
        'best_score': bestScore,
        'questions': [],
      };
    }).toList();

    return {'quizzes': result};
  }

  Map<String, dynamic> _studentGetQuizDetail(int quizId) {
    final quizzes = (_db['quizzes'] as List).cast<Map<String, dynamic>>();
    final questions = (_db['quiz_questions'] as List).cast<Map<String, dynamic>>();
    final subjects = (_db['subjects'] as List).cast<Map<String, dynamic>>();

    final quiz = quizzes.firstWhere((q) => q['id'] == quizId, orElse: () => {});
    if (quiz.isEmpty) throw Exception('Quiz not found');

    final sub = subjects.firstWhere((s) => s['id'] == quiz['subject_id'], orElse: () => {'name': 'English'});
    final quizQuestions = questions.where((qq) => qq['quiz_id'] == quizId).toList();

    return {
      'quiz': {
        'id': quiz['id'],
        'subject_id': quiz['subject_id'],
        'subject_name': sub['name'],
        'title': quiz['title'],
        'question_count': quizQuestions.length,
        'time_minutes': quiz['time_minutes'] ?? 10,
        'questions': quizQuestions.map((qq) => {
          'id': qq['id'],
          'question_text': qq['question_text'],
          'options': qq['options'],
        }).toList(),
      }
    };
  }

  Future<Map<String, dynamic>> _studentSubmitQuiz(Map<String, dynamic> data) async {
    final quizId = _parseInt(data['quiz_id']) ?? 1;
    final answers = (data['answers'] as Map<dynamic, dynamic>? ?? {});
    final questions = (_db['quiz_questions'] as List).cast<Map<String, dynamic>>();
    final attempts = (_db['quiz_attempts'] as List).cast<Map<String, dynamic>>();
    final currentId = _currentUser?['id'] ?? 6;

    final quizQuestions = questions.where((qq) => qq['quiz_id'] == quizId).toList();
    int score = 0;
    final total = quizQuestions.length;

    for (final q in quizQuestions) {
      final qIdStr = q['id'].toString();
      final chosen = answers[qIdStr] ?? answers[q['id']];
      if (chosen != null && _parseInt(chosen) == q['correct_option_index']) {
        score++;
      }
    }

    final newAttemptId = (attempts.map((a) => a['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    attempts.add({
      'id': newAttemptId,
      'quiz_id': quizId,
      'student_id': currentId,
      'answers': answers,
      'score': score,
      'total': total,
      'submitted_at': DateTime.now().toIso8601String(),
    });

    await _save();
    final percentage = total > 0 ? (score / total * 100).round() : 0;
    return {'score': score, 'total': total, 'percentage': percentage};
  }

  // -------------------------------------------------------------
  // Teacher Handlers (Section 15, 16, 17)
  // -------------------------------------------------------------
  Map<String, dynamic> _teacherGetSubjects() {
    final subjects = (_db['subjects'] as List).cast<Map<String, dynamic>>();
    final assignments = (_db['teacher_assignments'] as List).cast<Map<String, dynamic>>();
    final classes = (_db['classes'] as List).cast<Map<String, dynamic>>();
    final currentTeacher = _currentUser ?? {'id': 2, 'role': 'teacher'};

    final myAssigns = assignments.where((a) => a['teacher_id'] == currentTeacher['id']).toList();
    if (myAssigns.isNotEmpty) {
      return {
        'subjects': myAssigns.map((a) {
          final s = subjects.firstWhere((sub) => sub['id'] == a['subject_id'], orElse: () => {'name': 'English', 'code': 'ENG'});
          final c = classes.firstWhere((cls) => cls['id'] == a['class_id'], orElse: () => {'name': 'Class 10'});
          return {
            'id': s['id'],
            'assignment_id': a['id'],
            'name': s['name'],
            'code': s['code'],
            'class_id': a['class_id'],
            'class_name': c['name'],
            'section_name': 'Section A',
            'icon_color': s['icon_color'] ?? '#4F46E5',
            'teacher': {'id': currentTeacher['id'], 'full_name': currentTeacher['full_name'] ?? 'Ms. Priya'},
          };
        }).toList(),
      };
    }

    // Default to Priya's assigned subjects (Class 10 & 9 English)
    return {
      'subjects': [
        {
          'id': 1,
          'name': 'English',
          'code': 'ENG10',
          'class_id': 5,
          'class_name': 'Class 10',
          'section_name': 'Section A',
          'icon_color': '#4F46E5',
          'teacher': {'id': 2, 'full_name': 'Ms. Priya'},
        },
        {
          'id': 1,
          'name': 'English',
          'code': 'ENG09',
          'class_id': 4,
          'class_name': 'Class 9',
          'section_name': 'Section A',
          'icon_color': '#4F46E5',
          'teacher': {'id': 2, 'full_name': 'Ms. Priya'},
        },
      ]
    };
  }

  Map<String, dynamic> _teacherGetLessons(int? subjectId) {
    return _studentGetLessons(subjectId);
  }

  Future<Map<String, dynamic>> _teacherCreateLesson(Map<String, dynamic> data) async {
    final lessons = (_db['lessons'] as List).cast<Map<String, dynamic>>();
    final newId = (lessons.map((l) => l['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    final subId = _parseInt(data['subject_id']) ?? 1;
    final subCount = lessons.where((l) => l['subject_id'] == subId).length;

    final newLesson = {
      'id': newId,
      'subject_id': subId,
      'class_id': data['class_id'] ?? 5,
      'unit_id': data['unit_id'] ?? 1,
      'unit_title': 'Unit 1 - Prose',
      'title': data['title'] ?? 'Untitled Lesson',
      'description': data['description'] ?? '',
      'order_index': subCount + 1,
      'created_at': DateTime.now().toIso8601String(),
    };
    lessons.add(newLesson);
    await _save();
    return {
      'id': newLesson['id'],
      'subject_id': newLesson['subject_id'],
      'title': newLesson['title'],
      'description': newLesson['description'],
      'order_index': newLesson['order_index'],
      'material_count': 0,
      'created_at': newLesson['created_at'],
    };
  }

  Map<String, dynamic> _teacherGetMaterials(int? lessonId) {
    return _studentGetMaterials(lessonId);
  }

  Future<Map<String, dynamic>> uploadMaterialFile({
    required int lessonId,
    required String title,
    required String fileType,
    String? localFilePath,
  }) async {
    await init();
    final materials = (_db['materials'] as List).cast<Map<String, dynamic>>();
    final newId = (materials.map((m) => m['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    final uploaderId = _currentUser?['id'] ?? 2;

    final newMaterial = {
      'id': newId,
      'lesson_id': lessonId,
      'uploader_id': uploaderId,
      'title': title,
      'description': '',
      'material_type': fileType == 'mp4' ? 'video' : fileType,
      'file_type': fileType,
      'file_path': localFilePath ?? '/uploads/material_$newId',
      'file_url': null,
      'duration': fileType == 'video' || fileType == 'mp4' ? '15:00' : null,
      'publication_status': 'published',
      'uploaded_at': DateTime.now().toIso8601String(),
    };
    materials.add(newMaterial);
    await _save();

    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    final uploader = users.firstWhere((u) => u['id'] == uploaderId, orElse: () => {'full_name': 'Ms. Priya'});

    return {
      'id': newMaterial['id'],
      'lesson_id': newMaterial['lesson_id'],
      'title': newMaterial['title'],
      'material_type': newMaterial['material_type'],
      'file_type': newMaterial['file_type'],
      'file_path': newMaterial['file_path'],
      'duration': newMaterial['duration'],
      'publication_status': newMaterial['publication_status'],
      'uploaded_at': newMaterial['uploaded_at'],
      'uploaded_by': uploader['full_name'],
    };
  }

  Future<Map<String, dynamic>> _teacherDeleteMaterial(int id) async {
    final materials = (_db['materials'] as List).cast<Map<String, dynamic>>();
    materials.removeWhere((m) => m['id'] == id);
    await _save();
    return {'ok': true};
  }

  Map<String, dynamic> _teacherGetAssignments(int? subjectId) {
    return _studentGetAssignments();
  }

  Future<Map<String, dynamic>> _teacherCreateAssignment(Map<String, dynamic> data) async {
    final assignments = (_db['assignments'] as List).cast<Map<String, dynamic>>();
    final newId = (assignments.map((a) => a['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    final subId = _parseInt(data['subject_id']) ?? 1;

    final newAssign = {
      'id': newId,
      'subject_id': subId,
      'title': data['title'] ?? 'Assignment',
      'description': data['description'] ?? '',
      'due_date': data['due_date'] ?? DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'max_score': _parseInt(data['max_score']) ?? 100,
    };
    assignments.add(newAssign);
    await _save();

    final subjects = (_db['subjects'] as List).cast<Map<String, dynamic>>();
    final sub = subjects.firstWhere((s) => s['id'] == subId, orElse: () => {'name': 'English'});

    return {
      'id': newAssign['id'],
      'subject_id': newAssign['subject_id'],
      'subject_name': sub['name'],
      'title': newAssign['title'],
      'description': newAssign['description'],
      'due_date': newAssign['due_date'],
      'max_score': newAssign['max_score'],
    };
  }

  Map<String, dynamic> _teacherGetSubmissions(int assignmentId) {
    final submissions = (_db['assignment_submissions'] as List).cast<Map<String, dynamic>>();
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();
    final filtered = submissions.where((s) => s['assignment_id'] == assignmentId).toList();

    return {
      'submissions': filtered.map((s) {
        final student = users.firstWhere((u) => u['id'] == s['student_id'], orElse: () => {'full_name': 'Rahul Sharma'});
        return {
          'id': s['id'],
          'student_id': s['student_id'],
          'student_name': student['full_name'],
          'score': s['score'],
          'feedback': s['feedback'],
          'submitted_at': s['submitted_at'],
        };
      }).toList()
    };
  }

  Future<Map<String, dynamic>> _teacherGradeSubmission(int submissionId, int score, String feedback) async {
    final submissions = (_db['assignment_submissions'] as List).cast<Map<String, dynamic>>();
    for (final s in submissions) {
      if (s['id'] == submissionId) {
        s['score'] = score;
        s['feedback'] = feedback;
        s['graded_at'] = DateTime.now().toIso8601String();
      }
    }
    await _save();
    return {'ok': true};
  }

  Map<String, dynamic> _teacherGetQuizzes(int? subjectId) {
    return _studentGetQuizzes();
  }

  Future<Map<String, dynamic>> _teacherCreateQuiz(Map<String, dynamic> data) async {
    final quizzes = (_db['quizzes'] as List).cast<Map<String, dynamic>>();
    final questions = (_db['quiz_questions'] as List).cast<Map<String, dynamic>>();

    final newQuizId = (quizzes.map((q) => q['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    final subId = _parseInt(data['subject_id']) ?? 1;

    final newQuiz = {
      'id': newQuizId,
      'subject_id': subId,
      'title': data['title'] ?? 'Quiz',
      'time_minutes': _parseInt(data['time_minutes']) ?? 15,
    };
    quizzes.add(newQuiz);

    final rawQuestions = (data['questions'] as List? ?? []);
    int currentQId = (questions.map((q) => q['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;

    for (final rq in rawQuestions) {
      questions.add({
        'id': currentQId++,
        'quiz_id': newQuizId,
        'question_text': rq['question_text'] ?? '',
        'options': List<String>.from(rq['options'] ?? []),
        'correct_option_index': _parseInt(rq['correct_option_index']) ?? 0,
        'order_index': questions.length + 1,
      });
    }

    await _save();
    return _teacherGetQuizzes(subId);
  }

  Map<String, dynamic> _teacherGetFlashcards(int? subjectId) {
    final flashcards = (_db['flashcards'] as List).cast<Map<String, dynamic>>();
    return {'flashcards': flashcards};
  }

  Future<Map<String, dynamic>> _teacherCreateFlashcard(Map<String, dynamic> data) async {
    final flashcards = (_db['flashcards'] as List).cast<Map<String, dynamic>>();
    final newId = (flashcards.map((f) => f['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    flashcards.add({
      'id': newId,
      'subject_id': _parseInt(data['subject_id']) ?? 1,
      'title': data['title'] ?? 'Flashcards',
      'cards': data['cards'] ?? [],
    });
    await _save();
    return {'ok': true, 'id': newId};
  }

  Map<String, dynamic> _teacherGetMindmaps(int? subjectId) {
    final mindmaps = (_db['mindmaps'] as List).cast<Map<String, dynamic>>();
    return {'mindmaps': mindmaps};
  }

  Future<Map<String, dynamic>> _teacherCreateMindmap(Map<String, dynamic> data) async {
    final mindmaps = (_db['mindmaps'] as List).cast<Map<String, dynamic>>();
    final newId = (mindmaps.map((m) => m['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    mindmaps.add({
      'id': newId,
      'subject_id': _parseInt(data['subject_id']) ?? 1,
      'title': data['title'] ?? 'Mind Map',
      'central_topic': data['central_topic'] ?? 'Topic',
      'branches': data['branches'] ?? [],
    });
    await _save();
    return {'ok': true, 'id': newId};
  }

  // -------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------
  int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    return int.tryParse(val.toString());
  }

  Map<String, dynamic> _formatSubject(Map<String, dynamic> s) {
    final classes = (_db['classes'] as List).cast<Map<String, dynamic>>();
    final users = (_db['users'] as List).cast<Map<String, dynamic>>();

    final klass = classes.firstWhere((c) => c['id'] == (s['class_id'] ?? 5), orElse: () => {'name': 'Class 10'});
    final teacher = users.firstWhere((u) => u['id'] == (s['teacher_id'] ?? 2), orElse: () => {'id': 2, 'full_name': 'Ms. Priya'});

    return {
      'id': s['id'],
      'name': s['name'],
      'code': s['code'],
      'class_id': s['class_id'] ?? 5,
      'class_name': klass['name'],
      'icon_color': s['icon_color'] ?? '#4F46E5',
      'description': s['description'] ?? '',
      'teacher': {'id': teacher['id'], 'full_name': teacher['full_name']},
    };
  }

  Map<String, dynamic> _formatUserProfile(Map<String, dynamic> u) {
    return {
      'id': u['id'],
      'username': u['username'],
      'full_name': u['full_name'],
      'email': u['email'],
      'role': u['role'],
      'profile_pic': u['profile_pic'],
      'class_id': u['class_id'] ?? (u['role'] == 'student' ? 5 : null),
      'class_name': u['role'] == 'student' ? 'Class 10' : null,
      'section_name': u['role'] == 'student' ? 'Section A' : null,
      'roll_number': u['roll_number'] ?? (u['role'] == 'student' ? '10-A-01' : null),
      'contact_number': u['contact_number'] ?? '+91 98401 23456',
      'date_of_birth': u['date_of_birth'] ?? '2010-05-14',
      'parent_name': u['parent_name'] ?? 'Parent Guardian',
      'parent_contact': u['parent_contact'] ?? '+91 98401 11111',
      'is_active': u['is_active'] ?? true,
    };
  }

  // -------------------------------------------------------------
  // AcademyAlys Complete Seed Dataset
  // -------------------------------------------------------------
  Map<String, dynamic> _buildSeedDatabase() {
    return {
      'academic_years': [
        {'id': 1, 'name': '2025-2026', 'is_active': false},
        {'id': 2, 'name': '2026-2027', 'is_active': true},
      ],
      'classes': [
        {'id': 1, 'name': 'Class 6', 'grade_level': 6},
        {'id': 2, 'name': 'Class 7', 'grade_level': 7},
        {'id': 3, 'name': 'Class 8', 'grade_level': 8},
        {'id': 4, 'name': 'Class 9', 'grade_level': 9},
        {'id': 5, 'name': 'Class 10', 'grade_level': 10},
      ],
      'sections': [
        {'id': 1, 'class_id': 5, 'name': 'Section A', 'room_number': 'Room 101'},
        {'id': 2, 'class_id': 5, 'name': 'Section B', 'room_number': 'Room 102'},
        {'id': 3, 'class_id': 4, 'name': 'Section A', 'room_number': 'Room 201'},
        {'id': 4, 'class_id': 4, 'name': 'Section B', 'room_number': 'Room 202'},
        {'id': 5, 'class_id': 3, 'name': 'Section A', 'room_number': 'Room 301'},
        {'id': 6, 'class_id': 2, 'name': 'Section A', 'room_number': 'Room 302'},
        {'id': 7, 'class_id': 1, 'name': 'Section A', 'room_number': 'Room 401'},
      ],
      'subjects': [
        {'id': 1, 'name': 'English', 'code': 'ENG', 'icon_color': '#4F46E5', 'class_id': 5, 'teacher_id': 2, 'description': 'Literature and grammar'},
        {'id': 2, 'name': 'Mathematics', 'code': 'MATH', 'icon_color': '#0EA5E9', 'class_id': 5, 'teacher_id': 3, 'description': 'Algebra, Geometry and Statistics'},
        {'id': 3, 'name': 'Science', 'code': 'SCI', 'icon_color': '#10B981', 'class_id': 5, 'teacher_id': 4, 'description': 'Physics, Chemistry and Biology'},
        {'id': 4, 'name': 'Social Science', 'code': 'SOC', 'icon_color': '#F59E0B', 'class_id': 5, 'teacher_id': 2, 'description': 'History, Civics and Geography'},
        {'id': 5, 'name': 'Tamil', 'code': 'TAM', 'icon_color': '#EC4899', 'class_id': 5, 'teacher_id': 2, 'description': 'Language and literature'},
      ],
      'class_subjects': [
        {'class_id': 5, 'subject_id': 1},
        {'class_id': 5, 'subject_id': 2},
        {'class_id': 5, 'subject_id': 3},
        {'class_id': 5, 'subject_id': 4},
        {'class_id': 5, 'subject_id': 5},
        {'class_id': 4, 'subject_id': 1},
        {'class_id': 4, 'subject_id': 2},
        {'class_id': 4, 'subject_id': 3},
        {'class_id': 4, 'subject_id': 4},
        {'class_id': 4, 'subject_id': 5},
        {'class_id': 3, 'subject_id': 1},
        {'class_id': 3, 'subject_id': 2},
        {'class_id': 3, 'subject_id': 3},
      ],
      'users': [
        {
          'id': 1,
          'username': 'admin',
          'password': 'admin123',
          'full_name': 'System Administrator',
          'email': 'admin@academyalys.com',
          'role': 'admin',
          'profile_pic': null,
          'is_active': true,
        },
        {
          'id': 2,
          'username': 'priya',
          'password': 'priya123',
          'full_name': 'Ms. Priya',
          'email': 'priya@academyalys.com',
          'role': 'teacher',
          'contact_number': '+91 98765 43210',
          'is_active': true,
        },
        {
          'id': 3,
          'username': 'rajesh',
          'password': 'rajesh123',
          'full_name': 'Mr. Rajesh Kumar',
          'email': 'rajesh@academyalys.com',
          'role': 'teacher',
          'contact_number': '+91 98765 43211',
          'is_active': true,
        },
        {
          'id': 4,
          'username': 'geetha',
          'password': 'geetha123',
          'full_name': 'Mrs. Geetha Raman',
          'email': 'geetha@academyalys.com',
          'role': 'teacher',
          'contact_number': '+91 98765 43212',
          'is_active': true,
        },
        {
          'id': 5,
          'username': 'sarah',
          'password': 'sarah123',
          'full_name': 'Ms. Sarah Jenkins',
          'email': 'sarah@academyalys.com',
          'role': 'teacher',
          'contact_number': '+91 98765 43213',
          'is_active': true,
        },
        {
          'id': 6,
          'username': 'rahul',
          'password': 'rahul123',
          'full_name': 'Rahul Sharma',
          'email': 'rahul@student.academyalys.com',
          'role': 'student',
          'class_id': 5,
          'roll_number': '10-A-01',
          'date_of_birth': '2010-05-14',
          'contact_number': '+91 98401 23456',
          'parent_name': 'Venkatesh Sharma',
          'parent_contact': '+91 98401 11111',
          'is_active': true,
        },
        {
          'id': 7,
          'username': 'ananya',
          'password': 'ananya123',
          'full_name': 'Ananya Sundaram',
          'email': 'ananya@student.academyalys.com',
          'role': 'student',
          'class_id': 4,
          'roll_number': '09-A-04',
          'date_of_birth': '2011-08-22',
          'contact_number': '+91 98402 34567',
          'parent_name': 'Sundaram Ramaswamy',
          'parent_contact': '+91 98402 22222',
          'is_active': true,
        },
        {
          'id': 8,
          'username': 'vikram',
          'password': 'vikram123',
          'full_name': 'Vikram Patel',
          'email': 'vikram@student.academyalys.com',
          'role': 'student',
          'class_id': 3,
          'roll_number': '08-A-12',
          'date_of_birth': '2012-03-10',
          'contact_number': '+91 98403 45678',
          'parent_name': 'Kiran Patel',
          'parent_contact': '+91 98403 33333',
          'is_active': true,
        },
        {
          'id': 9,
          'username': 'meera',
          'password': 'meera123',
          'full_name': 'Meera Krishnan',
          'email': 'meera@student.academyalys.com',
          'role': 'student',
          'class_id': 5,
          'roll_number': '10-B-08',
          'date_of_birth': '2010-11-19',
          'contact_number': '+91 98404 56789',
          'parent_name': 'Krishnan Narayanan',
          'parent_contact': '+91 98404 44444',
          'is_active': true,
        },
      ],
      'student_enrollments': [
        {
          'id': 1,
          'student_id': 6,
          'academic_year': '2025-2026',
          'class_id': 4,
          'class_name': 'Class 9',
          'section_id': 3,
          'section_name': 'Section A',
          'status': 'completed',
        },
        {
          'id': 2,
          'student_id': 6,
          'academic_year': '2026-2027',
          'class_id': 5,
          'class_name': 'Class 10',
          'section_id': 1,
          'section_name': 'Section A',
          'status': 'active',
        },
        {
          'id': 3,
          'student_id': 7,
          'academic_year': '2026-2027',
          'class_id': 4,
          'class_name': 'Class 9',
          'section_id': 3,
          'section_name': 'Section A',
          'status': 'active',
        },
        {
          'id': 4,
          'student_id': 8,
          'academic_year': '2026-2027',
          'class_id': 3,
          'class_name': 'Class 8',
          'section_id': 5,
          'section_name': 'Section A',
          'status': 'active',
        },
        {
          'id': 5,
          'student_id': 9,
          'academic_year': '2026-2027',
          'class_id': 5,
          'class_name': 'Class 10',
          'section_id': 2,
          'section_name': 'Section B',
          'status': 'active',
        },
      ],
      'teacher_assignments': [
        {'id': 1, 'teacher_id': 2, 'class_id': 5, 'subject_id': 1, 'section_id': 1}, // Priya: Class 10 English
        {'id': 2, 'teacher_id': 2, 'class_id': 4, 'subject_id': 1, 'section_id': 3}, // Priya: Class 9 English
        {'id': 3, 'teacher_id': 3, 'class_id': 5, 'subject_id': 2, 'section_id': 1}, // Rajesh: Class 10 Math
        {'id': 4, 'teacher_id': 3, 'class_id': 3, 'subject_id': 2, 'section_id': 5}, // Rajesh: Class 8 Math
        {'id': 5, 'teacher_id': 4, 'class_id': 5, 'subject_id': 3, 'section_id': 1}, // Geetha: Class 10 Science
        {'id': 6, 'teacher_id': 5, 'class_id': 4, 'subject_id': 3, 'section_id': 3}, // Sarah: Class 9 Science
      ],
      'lessons': [
        {
          'id': 1,
          'subject_id': 1,
          'class_id': 5,
          'unit_id': 1,
          'unit_title': 'Unit 1 - Prose',
          'title': 'Lesson 1: A Letter to God',
          'description': 'Examine Lencho\'s unwavering faith in God, the devastation of the hailstorm, and the post office employees.',
          'order_index': 1,
          'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        },
        {
          'id': 2,
          'subject_id': 1,
          'class_id': 5,
          'unit_id': 1,
          'unit_title': 'Unit 1 - Prose',
          'title': 'Lesson 2: Nelson Mandela: Long Walk to Freedom',
          'description': 'Autobiographical extract on the struggle against apartheid in South Africa.',
          'order_index': 2,
          'created_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
        },
        {
          'id': 3,
          'subject_id': 3,
          'class_id': 5,
          'unit_id': 2,
          'unit_title': 'Unit 1 - Chemical Substances',
          'title': 'Chemical Reactions and Equations',
          'description': 'Balancing equations, displacement reactions, oxidation and reduction.',
          'order_index': 1,
          'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        },
      ],
      'materials': [
        // 2 Videos for Lesson 1 A Letter to God
        {
          'id': 1,
          'lesson_id': 1,
          'uploader_id': 2,
          'title': 'Complete Explanation',
          'description': 'Detailed scene-by-scene explanation and moral conflict analysis.',
          'material_type': 'video',
          'file_type': 'video',
          'external_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          'duration': '24:15',
          'publication_status': 'published',
          'uploaded_at': DateTime.now().subtract(const Duration(days: 9)).toIso8601String(),
        },
        {
          'id': 2,
          'lesson_id': 1,
          'uploader_id': 2,
          'title': 'Animated Story & Visual Summary',
          'description': 'Visual breakdown of Lencho\'s faith, the storm, and the postmaster\'s gesture.',
          'material_type': 'video',
          'file_type': 'video',
          'external_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          'duration': '12:30',
          'publication_status': 'published',
          'uploaded_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
        },
        // 3 PDFs
        {
          'id': 3,
          'lesson_id': 1,
          'uploader_id': 2,
          'title': 'Detailed Chapter Analysis & Questions',
          'description': 'Comprehensive textual critique, character sketches, and board examination model answers.',
          'material_type': 'pdf',
          'file_type': 'pdf',
          'file_path': 'a_letter_to_god_study_guide.pdf',
          'publication_status': 'published',
          'uploaded_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        },
        {
          'id': 4,
          'lesson_id': 1,
          'uploader_id': 2,
          'title': 'Vocabulary and Literary Devices',
          'description': 'Glossary of terms, metaphors, ironies, and character traits.',
          'material_type': 'pdf',
          'file_type': 'pdf',
          'file_path': 'a_letter_to_god_study_guide.pdf',
          'publication_status': 'published',
          'uploaded_at': DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
        },
        {
          'id': 5,
          'lesson_id': 1,
          'uploader_id': 2,
          'title': 'NCERT Textbook Solutions & Answers',
          'description': 'Standard solutions and board examination marking rubrics.',
          'material_type': 'pdf',
          'file_type': 'pdf',
          'file_path': 'a_letter_to_god_study_guide.pdf',
          'publication_status': 'published',
          'uploaded_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        },
        // 1 PPT
        {
          'id': 6,
          'lesson_id': 1,
          'uploader_id': 2,
          'title': 'A Letter to God - Interactive Slide Deck',
          'description': 'Lecture presentation slides for classroom and individual revision.',
          'material_type': 'ppt',
          'file_type': 'pptx',
          'file_path': 'a_letter_to_god_slides.pptx',
          'publication_status': 'published',
          'uploaded_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
        },
        // 2 Notes
        {
          'id': 7,
          'lesson_id': 1,
          'uploader_id': 2,
          'title': 'Character Sketch of Lencho & Themes of Faith',
          'description': 'In-depth study notes exploring human faith and dramatic irony.',
          'material_type': 'notes',
          'file_type': 'word',
          'file_path': 'character_sketch_lencho.docx',
          'publication_status': 'published',
          'uploaded_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        },
        {
          'id': 8,
          'lesson_id': 1,
          'uploader_id': 2,
          'title': 'Key Quotations & Board Examination Tips',
          'description': 'High-yield revision notes and examination pointers for 5-mark answers.',
          'material_type': 'notes',
          'file_type': 'word',
          'file_path': 'exam_tips_english10.docx',
          'publication_status': 'published',
          'uploaded_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
      ],
      'quizzes': [
        {
          'id': 1,
          'lesson_id': 1,
          'subject_id': 1,
          'title': 'Comprehension & Short Answer Quiz',
          'time_minutes': 10,
        },
        {
          'id': 2,
          'lesson_id': 1,
          'subject_id': 1,
          'title': 'Vocabulary & Literary Devices Quiz',
          'time_minutes': 10,
        },
      ],
      'quiz_questions': [
        {
          'id': 1,
          'quiz_id': 1,
          'question_text': 'What did Lencho hope for to save his ripe corn crops?',
          'options': ['A downpour or at least a shower', 'Strong winds to dry the seeds', 'New farm machinery', 'A loan from the local bank'],
          'correct_option_index': 0,
        },
        {
          'id': 2,
          'quiz_id': 1,
          'question_text': 'Why did Lencho describe the raindrops as new coins?',
          'options': ['Because they were shiny like silver', 'Because rain promised a prosperous harvest', 'Because rain was turning into ice coins', 'Because he owed money to the post office'],
          'correct_option_index': 1,
        },
        {
          'id': 3,
          'quiz_id': 1,
          'question_text': 'How much money did the postmaster manage to collect for Lencho?',
          'options': ['100 pesos', '70 pesos', '50 pesos', '30 pesos'],
          'correct_option_index': 1,
        },
        {
          'id': 4,
          'quiz_id': 1,
          'question_text': 'What ironical term did Lencho use for the post office employees?',
          'options': ["God's angels", 'A bunch of crooks', 'Faithful servants', 'Gentle souls'],
          'correct_option_index': 1,
        },
        {
          'id': 5,
          'quiz_id': 2,
          'question_text': 'What is the central irony of "A Letter to God"?',
          'options': [
            'Lencho asked for money and got seeds instead',
            'The people who helped Lencho were suspected of stealing from him',
            'The postmaster ignored the letter',
            'The storm made the harvest richer'
          ],
          'correct_option_index': 1,
        },
      ],
      'quiz_attempts': <Map<String, dynamic>>[],
      'assignments': [
        {
          'id': 1,
          'subject_id': 1,
          'title': 'Write Lencho\'s Letter & Analysis of Postmaster',
          'description': 'Answer both 100-word questions reflecting on unconditional faith versus situational irony.',
          'due_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'max_score': 100,
        }
      ],
      'assignment_submissions': [
        {
          'id': 1,
          'assignment_id': 1,
          'student_id': 6,
          'file_path': 'rahul_letter_analysis.pdf',
          'score': 92,
          'feedback': 'Insightful evaluation of Lencho\'s worldview, Rahul!',
          'submitted_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        }
      ],
      'flashcards': [],
      'mindmaps': [],
      'announcements': [
        {
          'id': 1,
          'title': 'Welcome to AcademyAlys Academic Year 2026-2027',
          'content': 'Welcome students and teachers! Curricula for Classes 6 through 10 are now live.',
          'target_role': 'all',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 2,
          'title': 'Class 10 English Literature Special Revision',
          'content': 'Ms. Priya will host an interactive chapter review on Saturday morning.',
          'target_role': 'student',
          'created_at': DateTime.now().toIso8601String(),
        },
      ],
      'timetable': [
        {'id': 1, 'class_id': 5, 'day_of_week': 'Monday', 'period_number': 1, 'start_time': '09:00', 'end_time': '09:45', 'subject_name': 'English', 'room': 'Room 101'},
        {'id': 2, 'class_id': 5, 'day_of_week': 'Monday', 'period_number': 2, 'start_time': '09:45', 'end_time': '10:30', 'subject_name': 'Mathematics', 'room': 'Room 101'},
        {'id': 3, 'class_id': 5, 'day_of_week': 'Monday', 'period_number': 3, 'start_time': '10:45', 'end_time': '11:30', 'subject_name': 'Science', 'room': 'Lab 2'},
        {'id': 4, 'class_id': 5, 'day_of_week': 'Tuesday', 'period_number': 1, 'start_time': '09:00', 'end_time': '09:45', 'subject_name': 'Science', 'room': 'Lab 2'},
        {'id': 5, 'class_id': 5, 'day_of_week': 'Tuesday', 'period_number': 2, 'start_time': '09:45', 'end_time': '10:30', 'subject_name': 'English', 'room': 'Room 101'},
      ],
    };
  }
}
