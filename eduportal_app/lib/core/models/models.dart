// lib/core/models/models.dart

// ── Enrollment History Model ───────────────────────────────────────────────
class StudentEnrollmentHistory {
  final String academicYear;
  final String className;
  final String? sectionName;
  final String status;
  final String? enrolledAt;

  const StudentEnrollmentHistory({
    required this.academicYear,
    required this.className,
    this.sectionName,
    required this.status,
    this.enrolledAt,
  });

  factory StudentEnrollmentHistory.fromJson(Map<String, dynamic> json) =>
      StudentEnrollmentHistory(
        academicYear: json['academic_year'] ?? '',
        className: json['class_name'] ?? '',
        sectionName: json['section_name'],
        status: json['status'] ?? 'active',
        enrolledAt: json['enrolled_at'],
      );

  Map<String, dynamic> toJson() => {
        'academic_year': academicYear,
        'class_name': className,
        'section_name': sectionName,
        'status': status,
        'enrolled_at': enrolledAt,
      };
}

// ── User Model ─────────────────────────────────────────────────────────────
class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String role; // 'admin', 'teacher', 'student'
  final String? profilePic;
  final int? classId;
  final String? className;
  final String? sectionName;
  final String? rollNumber;
  final String? phoneNumber;
  final String? contactNumber;
  final String? dateOfBirth;
  final String? parentName;
  final String? parentContact;
  final bool isActive;
  final List<StudentEnrollmentHistory> enrollmentHistory;

  const UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.profilePic,
    this.classId,
    this.className,
    this.sectionName,
    this.rollNumber,
    this.phoneNumber,
    this.contactNumber,
    this.dateOfBirth,
    this.parentName,
    this.parentContact,
    this.isActive = true,
    this.enrollmentHistory = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? 0,
        username: json['username'] ?? '',
        fullName: json['full_name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'student',
        profilePic: json['profile_pic'],
        classId: json['class_id'],
        className: json['class_name'],
        sectionName: json['section_name'],
        rollNumber: json['roll_number'] ?? json['register_number'],
        phoneNumber: json['phone_number'] ?? json['contact_number'],
        contactNumber: json['contact_number'] ?? json['phone_number'],
        dateOfBirth: json['date_of_birth'],
        parentName: json['parent_name'],
        parentContact: json['parent_contact'],
        isActive: json['is_active'] ?? true,
        enrollmentHistory: (json['enrollment_history'] as List<dynamic>? ?? [])
            .map((e) => StudentEnrollmentHistory.fromJson(e))
            .toList(),
      );

  UserModel copyWith({
    String? fullName,
    String? email,
    String? rollNumber,
    String? registerNumber,
    String? phoneNumber,
    String? contactNumber,
    String? dateOfBirth,
    String? parentName,
    String? parentContact,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      username: username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role,
      profilePic: profilePic,
      classId: classId,
      className: className,
      sectionName: sectionName,
      rollNumber: rollNumber ?? registerNumber ?? this.rollNumber,
      contactNumber: contactNumber ?? phoneNumber ?? this.contactNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      parentName: parentName ?? this.parentName,
      parentContact: parentContact ?? this.parentContact,
      isActive: isActive ?? this.isActive,
      enrollmentHistory: enrollmentHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'email': email,
        'role': role,
        'profile_pic': profilePic,
        'class_id': classId,
        'class_name': className,
        'section_name': sectionName,
        'roll_number': rollNumber,
        'contact_number': contactNumber,
        'date_of_birth': dateOfBirth,
        'parent_name': parentName,
        'parent_contact': parentContact,
        'is_active': isActive,
      };
}

// ── Subject Model ──────────────────────────────────────────────────────────
class SubjectModel {
  final int id;
  final String name;
  final String code;
  final String className;
  final int classId;
  final String? iconColor;
  final String? description;
  final TeacherInfo? teacher;
  final List<String> classes;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.code,
    required this.className,
    required this.classId,
    this.iconColor,
    this.description,
    this.teacher,
    this.classes = const [],
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    final classesList = (json['classes'] as List<dynamic>? ?? [])
        .map((className) => className.toString())
        .toList();
    final rawClassName = json['class_name']?.toString() ?? '';
    final fallbackClassName = classesList.isNotEmpty ? classesList.first : '';
    return SubjectModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      className: rawClassName.isNotEmpty ? rawClassName : fallbackClassName,
      classId: json['class_id'] ?? 0,
      iconColor: json['icon_color'],
      description: json['description'],
      teacher: json['teacher'] != null ? TeacherInfo.fromJson(json['teacher']) : null,
      classes: classesList,
    );
  }
}

class TeacherInfo {
  final int id;
  final String fullName;

  const TeacherInfo({required this.id, required this.fullName});

  factory TeacherInfo.fromJson(Map<String, dynamic> json) =>
      TeacherInfo(id: json['id'] ?? 0, fullName: json['full_name'] ?? '');
}

// ── Lesson Model ───────────────────────────────────────────────────────────
class LessonModel {
  final int id;
  final int subjectId;
  final int? classId;
  final int? unitId;
  final String? unitTitle;
  final String title;
  final String description;
  final int orderIndex;
  final int materialCount;
  final DateTime createdAt;

  const LessonModel({
    required this.id,
    required this.subjectId,
    this.classId,
    this.unitId,
    this.unitTitle,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.materialCount,
    required this.createdAt,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) => LessonModel(
        id: json['id'] ?? 0,
        subjectId: json['subject_id'] ?? 0,
        classId: json['class_id'],
        unitId: json['unit_id'],
        unitTitle: json['unit_title'],
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        orderIndex: json['order_index'] ?? 1,
        materialCount: json['material_count'] ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
            : DateTime.now(),
      );
}

// ── Lesson Sidebar Dynamic Counts (Section 20) ─────────────────────────────
class LessonSidebarCounts {
  final int home;
  final int videos;
  final int pdfMaterials;
  final int pptPresentations;
  final int notes;
  final int practiceQuestions;

  const LessonSidebarCounts({
    this.home = 0,
    this.videos = 0,
    this.pdfMaterials = 0,
    this.pptPresentations = 0,
    this.notes = 0,
    this.practiceQuestions = 0,
  });

  factory LessonSidebarCounts.fromJson(Map<String, dynamic> json) =>
      LessonSidebarCounts(
        home: json['home'] ?? 0,
        videos: json['videos'] ?? 0,
        pdfMaterials: json['pdf_materials'] ?? 0,
        pptPresentations: json['ppt_presentations'] ?? 0,
        notes: json['notes'] ?? 0,
        practiceQuestions: json['practice_questions'] ?? 0,
      );
}

// ── Material Model (Section 17 & 21 & 22) ──────────────────────────────────
class MaterialModel {
  final int id;
  final int lessonId;
  final String title;
  final String description;
  final String materialType; // 'video', 'pdf', 'ppt', 'notes', 'doc', 'link', 'other'
  final String fileType;
  final String? filePath;
  final String? fileUrl;
  final String? externalUrl;
  final String? duration;
  final String? thumbnailUrl;
  final String publicationStatus; // 'published', 'draft'
  final DateTime uploadedAt;
  final String uploadedBy;

  const MaterialModel({
    required this.id,
    required this.lessonId,
    required this.title,
    this.description = '',
    required this.materialType,
    required this.fileType,
    this.filePath,
    this.fileUrl,
    this.externalUrl,
    this.duration,
    this.thumbnailUrl,
    this.publicationStatus = 'published',
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) => MaterialModel(
        id: json['id'] ?? 0,
        lessonId: json['lesson_id'] ?? 0,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        materialType: json['material_type'] ?? json['file_type'] ?? 'pdf',
        fileType: json['file_type'] ?? 'pdf',
        filePath: json['file_path'],
        fileUrl: json['file_url'],
        externalUrl: json['external_url'],
        duration: json['duration'],
        thumbnailUrl: json['thumbnail_url'],
        publicationStatus: json['publication_status'] ?? 'published',
        uploadedAt: json['uploaded_at'] != null
            ? DateTime.tryParse(json['uploaded_at']) ?? DateTime.now()
            : DateTime.now(),
        uploadedBy: json['uploaded_by'] ?? 'Teacher',
      );
}

// ── Section Model ──────────────────────────────────────────────────────────
class SectionModel {
  final int id;
  final int classId;
  final String name;
  final String? roomNumber;

  const SectionModel({
    required this.id,
    required this.classId,
    required this.name,
    this.roomNumber,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) => SectionModel(
        id: json['id'] ?? 0,
        classId: json['class_id'] ?? 0,
        name: json['name'] ?? '',
        roomNumber: json['room_number'],
      );
}

// ── Class Model ────────────────────────────────────────────────────────────
class ClassModel {
  final int id;
  final String name;
  final int? gradeLevel;
  final int studentCount;
  final int sectionCount;
  final int subjectCount;
  final int teacherCount;

  const ClassModel({
    required this.id,
    required this.name,
    this.gradeLevel,
    required this.studentCount,
    this.sectionCount = 0,
    this.subjectCount = 0,
    this.teacherCount = 0,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        gradeLevel: json['grade_level'],
        studentCount: json['student_count'] ?? 0,
        sectionCount: json['section_count'] ?? 0,
        subjectCount: json['subject_count'] ?? 0,
        teacherCount: json['teacher_count'] ?? 0,
      );
}

// ── Class Tabs Data Model (Section 9.2) ────────────────────────────────────
class ClassTabsDataModel {
  final Map<String, dynamic> classInfo;
  final Map<String, dynamic> overview;
  final List<UserModel> students;
  final List<SectionModel> sections;
  final List<Map<String, dynamic>> teachers;
  final List<SubjectModel> subjects;
  final List<Map<String, dynamic>> lessons;

  const ClassTabsDataModel({
    required this.classInfo,
    required this.overview,
    required this.students,
    required this.sections,
    required this.teachers,
    required this.subjects,
    required this.lessons,
  });

  factory ClassTabsDataModel.fromJson(Map<String, dynamic> json) =>
      ClassTabsDataModel(
        classInfo: Map<String, dynamic>.from(json['class_info'] ?? {}),
        overview: Map<String, dynamic>.from(json['overview'] ?? {}),
        students: (json['students'] as List<dynamic>? ?? [])
            .map((s) => UserModel.fromJson(s))
            .toList(),
        sections: (json['sections'] as List<dynamic>? ?? [])
            .map((s) => SectionModel.fromJson(s))
            .toList(),
        teachers: (json['teachers'] as List<dynamic>? ?? [])
            .map((t) => Map<String, dynamic>.from(t))
            .toList(),
        subjects: (json['subjects'] as List<dynamic>? ?? [])
            .map((s) => SubjectModel.fromJson(s))
            .toList(),
        lessons: (json['lessons'] as List<dynamic>? ?? [])
            .map((l) => Map<String, dynamic>.from(l))
            .toList(),
      );
}

// ── Assignment & Quiz Models ───────────────────────────────────────────────
class AssignmentModel {
  final int id;
  final int subjectId;
  final String subjectName;
  final String title;
  final String description;
  final DateTime dueDate;
  final int maxScore;
  final String? submissionStatus;
  final int? score;
  final String? feedback;

  const AssignmentModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.maxScore,
    this.submissionStatus,
    this.score,
    this.feedback,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) => AssignmentModel(
        id: json['id'] ?? 0,
        subjectId: json['subject_id'] ?? 0,
        subjectName: json['subject_name'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        dueDate: json['due_date'] != null
            ? DateTime.tryParse(json['due_date']) ?? DateTime.now()
            : DateTime.now(),
        maxScore: json['max_score'] ?? 100,
        submissionStatus: json['submission_status'],
        score: json['score'],
        feedback: json['feedback'],
      );
}

class QuizModel {
  final int id;
  final int subjectId;
  final String subjectName;
  final String title;
  final int questionCount;
  final int timeMinutes;
  final String? status;
  final int? bestScore;
  final List<QuizQuestion> questions;

  const QuizModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.title,
    required this.questionCount,
    required this.timeMinutes,
    this.status,
    this.bestScore,
    this.questions = const [],
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) => QuizModel(
        id: json['id'] ?? 0,
        subjectId: json['subject_id'] ?? 0,
        subjectName: json['subject_name'] ?? '',
        title: json['title'] ?? '',
        questionCount: json['question_count'] ?? 0,
        timeMinutes: json['time_minutes'] ?? 10,
        status: json['status'],
        bestScore: json['best_score'],
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((q) => QuizQuestion.fromJson(q))
            .toList(),
      );
}

class QuizQuestion {
  final int id;
  final String questionText;
  final List<String> options;
  final int? correctOptionIndex;

  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    this.correctOptionIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['id'] ?? 0,
        questionText: json['question_text'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        correctOptionIndex: json['correct_option_index'],
      );
}

// ── Flashcard & Mindmap Models ─────────────────────────────────────────────
class FlashcardModel {
  final int id;
  final int subjectId;
  final String title;
  final List<FlashcardItem> cards;

  const FlashcardModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.cards,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) => FlashcardModel(
        id: json['id'] ?? 0,
        subjectId: json['subject_id'] ?? 0,
        title: json['title'] ?? '',
        cards: (json['cards'] as List<dynamic>? ?? [])
            .map((c) => FlashcardItem.fromJson(c))
            .toList(),
      );
}

class FlashcardItem {
  final int id;
  final String front;
  final String back;

  const FlashcardItem({required this.id, required this.front, required this.back});

  factory FlashcardItem.fromJson(Map<String, dynamic> json) => FlashcardItem(
        id: json['id'] ?? 0,
        front: json['front'] ?? '',
        back: json['back'] ?? '',
      );
}

class MindmapModel {
  final int id;
  final int subjectId;
  final String title;
  final String centralTopic;
  final List<MindmapBranch> branches;

  const MindmapModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.centralTopic,
    required this.branches,
  });

  factory MindmapModel.fromJson(Map<String, dynamic> json) => MindmapModel(
        id: json['id'] ?? 0,
        subjectId: json['subject_id'] ?? 0,
        title: json['title'] ?? '',
        centralTopic: json['central_topic'] ?? '',
        branches: (json['branches'] as List<dynamic>? ?? [])
            .map((b) => MindmapBranch.fromJson(b))
            .toList(),
      );
}

class MindmapBranch {
  final int id;
  final String label;
  final List<String> subTopics;
  final String color;

  const MindmapBranch({
    required this.id,
    required this.label,
    required this.subTopics,
    required this.color,
  });

  factory MindmapBranch.fromJson(Map<String, dynamic> json) => MindmapBranch(
        id: json['id'] ?? 0,
        label: json['label'] ?? '',
        subTopics: List<String>.from(json['sub_topics'] ?? []),
        color: json['color'] ?? '#4F46E5',
      );
}

// ── Announcement & Timetable ───────────────────────────────────────────────
class AnnouncementModel {
  final int id;
  final String title;
  final String content;
  final String targetRole;
  final String createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.targetRole,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) =>
      AnnouncementModel(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        targetRole: json['target_role'] ?? 'all',
        createdAt: json['created_at'] ?? '',
      );
}
