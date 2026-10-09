// lib/core/providers/admin_provider.dart
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class AdminProvider extends ChangeNotifier {
  final _api = ApiService();

  List<UserModel> _users = [];
  List<UserModel> _directoryStudents = [];
  List<UserModel> _directoryTeachers = [];
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<MaterialModel> _materials = [];
  ClassTabsDataModel? _activeClassTabs;
  Map<String, dynamic> _dashboardStats = {};
  bool _loading = false;
  String? _error;

  List<UserModel> get users => _users;
  List<UserModel> get students => _directoryStudents.isNotEmpty
      ? _directoryStudents
      : _users.where((u) => u.role == 'student').toList();
  List<UserModel> get teachers => _directoryTeachers.isNotEmpty
      ? _directoryTeachers
      : _users.where((u) => u.role == 'teacher').toList();
  List<ClassModel> get classes => _classes;
  List<SubjectModel> get subjects => _subjects;
  List<MaterialModel> get materials => _materials;
  ClassTabsDataModel? get activeClassTabs => _activeClassTabs;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchAll() async {
    _loading = true;
    notifyListeners();
    try {
      await Future.wait([
        fetchDashboard(),
        fetchUsers(),
        fetchClasses(),
        fetchSubjects(),
        fetchStudentsDirectory(),
        fetchTeachersDirectory(),
        fetchMaterials(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboard() async {
    try {
      final data = await _api.get(ApiConstants.adminDashboard);
      _dashboardStats = Map<String, dynamic>.from(data['stats'] ?? {});
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching admin dashboard: $e');
    }
  }

  Future<void> fetchUsers() async {
    try {
      final data = await _api.get(ApiConstants.adminUsers);
      _users = (data['users'] as List).map((u) => UserModel.fromJson(u)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }

  Future<void> fetchStudentsDirectory({String? q, int? classId, int? sectionId, bool? isActive}) async {
    try {
      final params = <String, dynamic>{};
      if (q != null && q.isNotEmpty) params['q'] = q;
      if (classId != null) params['class_id'] = classId;
      if (sectionId != null) params['section_id'] = sectionId;
      if (isActive != null) params['is_active'] = isActive;

      final data = await _api.get(ApiConstants.adminStudents, queryParams: params);
      _directoryStudents = (data['students'] as List).map((s) => UserModel.fromJson(s)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching students directory: $e');
    }
  }

  Future<void> fetchTeachersDirectory() async {
    try {
      final data = await _api.get(ApiConstants.adminTeachers);
      _directoryTeachers = (data['teachers'] as List).map((t) => UserModel.fromJson(t)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching teachers directory: $e');
    }
  }

  Future<void> fetchClasses() async {
    try {
      final data = await _api.get(ApiConstants.adminClasses);
      _classes = (data['classes'] as List).map((c) => ClassModel.fromJson(c)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }
  }

  Future<void> fetchClassTabs(int classId) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.get(ApiConstants.adminClassTabs(classId));
      _activeClassTabs = ClassTabsDataModel.fromJson(data);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<SectionModel>> fetchClassSections(int classId) async {
    final data = await _api.get(ApiConstants.adminClassTabs(classId));
    final sections = data['sections'];
    if (sections is! List) {
      throw const FormatException('The server returned invalid class sections.');
    }
    return sections
        .map((section) =>
            SectionModel.fromJson(Map<String, dynamic>.from(section as Map)))
        .toList();
  }

  Future<void> fetchSubjects() async {
    try {
      final data = await _api.get(ApiConstants.adminSubjects);
      _subjects = (data['subjects'] as List).map((s) => SubjectModel.fromJson(s)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
    }
  }

  Future<void> fetchMaterials({int? classId, String? publicationStatus}) async {
    try {
      final params = <String, dynamic>{};
      if (classId != null) params['class_id'] = classId;
      if (publicationStatus != null) params['publication_status'] = publicationStatus;

      final data = await _api.get(ApiConstants.adminMaterials, queryParams: params);
      _materials = (data['materials'] as List).map((m) => MaterialModel.fromJson(m)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching admin materials: $e');
    }
  }

  Future<bool> setMaterialPublicationStatus(int materialId, String status) async {
    try {
      await _api.put('${ApiConstants.adminMaterials}/$materialId/publish?status=$status');
      await fetchMaterials();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createStudent({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required int classId,
    int? sectionId,
    String? rollNumber,
    String? dateOfBirth,
    String? contactNumber,
    String? parentName,
    String? parentContact,
  }) async {
    try {
      await _api.post(ApiConstants.adminStudents, data: {
        'username': username,
        'password': password,
        'full_name': fullName,
        'email': email,
        'role': 'student',
        'class_id': classId,
        if (sectionId != null) 'section_id': sectionId,
        if (rollNumber != null) 'roll_number': rollNumber,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (contactNumber != null) 'contact_number': contactNumber,
        if (parentName != null) 'parent_name': parentName,
        if (parentContact != null) 'parent_contact': parentContact,
      });
      await Future.wait([
        fetchStudentsDirectory(),
        fetchClasses(),
        fetchDashboard(),
        fetchUsers(),
      ]);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createTeacher({
    required String username,
    required String password,
    required String fullName,
    required String email,
    String? contactNumber,
    int? classId,
    int? subjectId,
    int? sectionId,
  }) async {
    try {
      await _api.post(ApiConstants.adminTeachers, data: {
        'username': username,
        'password': password,
        'full_name': fullName,
        'email': email,
        if (contactNumber != null) 'contact_number': contactNumber,
        if (classId != null) 'class_id': classId,
        if (subjectId != null) 'subject_id': subjectId,
        if (sectionId != null) 'section_id': sectionId,
      });
      await Future.wait([
        fetchTeachersDirectory(),
        fetchUsers(),
        fetchDashboard(),
        fetchClasses(),
      ]);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> bulkImportStudents({
    required int classId,
    required List<Map<String, dynamic>> students,
  }) async {
    try {
      final res = await _api.post(ApiConstants.adminBulkImportStudents, data: {
        'class_id': classId,
        'students': students,
      });
      await fetchStudentsDirectory();
      await fetchClasses();
      return res;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<bool> assignTeacher({
    required int teacherId,
    required int classId,
    required int subjectId,
    int? sectionId,
  }) async {
    try {
      await _api.post(ApiConstants.adminAssignTeacher, data: {
        'teacher_id': teacherId,
        'class_id': classId,
        'subject_id': subjectId,
        if (sectionId != null) 'section_id': sectionId,
      });
      await fetchClassTabs(classId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignSubjectToTeacher({
    required int subjectId,
    required int teacherId,
    int? classId,
  }) async {
    return assignTeacher(
      teacherId: teacherId,
      classId: classId ?? (_classes.isNotEmpty ? _classes.first.id : 5),
      subjectId: subjectId,
    );
  }

  Future<bool> addSectionToClass(int classId, String name, {String? room}) async {
    try {
      await _api.post(ApiConstants.adminClassSections(classId), data: {
        'class_id': classId,
        'name': name,
        if (room != null) 'room_number': room,
      });
      await fetchClassTabs(classId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createUser({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String role,
    int? classId,
  }) async {
    try {
      await _api.post(ApiConstants.adminUsers, data: {
        'username': username,
        'password': password,
        'full_name': fullName,
        'email': email,
        'role': role,
        if (classId != null) 'class_id': classId,
      });
      await fetchUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createClass(String name, {int? gradeLevel}) async {
    try {
      await _api.post(ApiConstants.adminClasses, data: {
        'name': name,
        if (gradeLevel != null) 'grade_level': gradeLevel,
      });
      await fetchClasses();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createSubject({
    required String name,
    required String code,
    List<int>? classIds,
    int? classId,
  }) async {
    try {
      await _api.post(ApiConstants.adminSubjects, data: {
        'name': name,
        'code': code,
        if (classIds != null) 'class_ids': classIds,
        if (classId != null) 'class_id': classId,
      });
      await fetchSubjects();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      await _api.delete('${ApiConstants.adminUsers}/$userId');
      await fetchUsers();
      await fetchStudentsDirectory();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleStudentStatus(int studentId, bool isActive) async {
    try {
      await _api.put('${ApiConstants.adminStudents}/$studentId/status?is_active=$isActive');
      await fetchStudentsDirectory();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
