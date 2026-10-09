# eduportal_backend/app/models.py
from sqlalchemy import (
    Column, Integer, String, Text, Boolean, DateTime,
    ForeignKey, Table, JSON
)
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

# ── Association tables ──────────────────────────────────────────────────────
student_subjects = Table(
    "student_subjects",
    Base.metadata,
    Column("student_id", Integer, ForeignKey("users.id"), primary_key=True),
    Column("subject_id", Integer, ForeignKey("subjects.id"), primary_key=True),
)

class_subjects = Table(
    "class_subjects",
    Base.metadata,
    Column("class_id", Integer, ForeignKey("classes.id"), primary_key=True),
    Column("subject_id", Integer, ForeignKey("subjects.id"), primary_key=True),
)

# ── Academic Year ───────────────────────────────────────────────────────────
class AcademicYear(Base):
    __tablename__ = "academic_years"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False)  # e.g. "2026-2027"
    is_active = Column(Boolean, default=True)
    start_date = Column(DateTime, nullable=True)
    end_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    enrollments = relationship("StudentEnrollment", back_populates="academic_year", cascade="all, delete")
    teacher_assignments = relationship("TeacherAssignment", back_populates="academic_year", cascade="all, delete")

# ── Class ───────────────────────────────────────────────────────────────────
class Class(Base):
    __tablename__ = "classes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)  # "Class 6", "Class 10"
    grade_level = Column(Integer, nullable=True)  # 6, 7, 8, 9, 10
    created_at = Column(DateTime, default=datetime.utcnow)

    sections = relationship("Section", back_populates="klass", cascade="all, delete")
    subjects = relationship("Subject", secondary=class_subjects, back_populates="classes")
    enrollments = relationship("StudentEnrollment", back_populates="klass", cascade="all, delete")
    teacher_assignments = relationship("TeacherAssignment", back_populates="klass", cascade="all, delete")
    legacy_students = relationship("User", back_populates="klass", foreign_keys="User.class_id")
    legacy_subjects = relationship("Subject", back_populates="legacy_klass", foreign_keys="Subject.class_id")

# ── Section ─────────────────────────────────────────────────────────────────
class Section(Base):
    __tablename__ = "sections"

    id = Column(Integer, primary_key=True, index=True)
    class_id = Column(Integer, ForeignKey("classes.id"), nullable=False)
    name = Column(String(50), nullable=False)  # "Section A", "Section B"
    room_number = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    klass = relationship("Class", back_populates="sections")
    enrollments = relationship("StudentEnrollment", back_populates="section")

# ── User ────────────────────────────────────────────────────────────────────
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    full_name = Column(String(100), nullable=False)
    email = Column(String(120), unique=True, nullable=True)
    hashed_password = Column(String(200), nullable=False)
    role = Column(String(20), nullable=False)  # admin | teacher | student
    profile_pic = Column(String(300), nullable=True)
    class_id = Column(Integer, ForeignKey("classes.id"), nullable=True)  # legacy compatibility
    is_active = Column(Boolean, default=True)
    roll_number = Column(String(50), nullable=True)
    date_of_birth = Column(String(50), nullable=True)
    contact_number = Column(String(50), nullable=True)
    parent_name = Column(String(100), nullable=True)
    parent_contact = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relations
    klass = relationship("Class", back_populates="legacy_students", foreign_keys=[class_id])
    taught_subjects = relationship("Subject", back_populates="teacher", foreign_keys="Subject.teacher_id")
    enrolled_subjects = relationship("Subject", secondary=student_subjects, back_populates="students")
    uploads = relationship("Material", back_populates="uploader")
    quiz_attempts = relationship("QuizAttempt", back_populates="student")
    assignment_submissions = relationship("AssignmentSubmission", back_populates="student")
    
    # AcademyAlys relations
    enrollments = relationship("StudentEnrollment", back_populates="student", cascade="all, delete")
    teacher_assignments = relationship("TeacherAssignment", back_populates="teacher", cascade="all, delete")

# ── Student Enrollment (Historical preservation) ───────────────────────────
class StudentEnrollment(Base):
    __tablename__ = "student_enrollments"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    academic_year_id = Column(Integer, ForeignKey("academic_years.id"), nullable=False)
    class_id = Column(Integer, ForeignKey("classes.id"), nullable=False)
    section_id = Column(Integer, ForeignKey("sections.id"), nullable=True)
    enrollment_status = Column(String(20), default="active")  # active | completed | transferred
    enrolled_at = Column(DateTime, default=datetime.utcnow)

    student = relationship("User", back_populates="enrollments")
    academic_year = relationship("AcademicYear", back_populates="enrollments")
    klass = relationship("Class", back_populates="enrollments")
    section = relationship("Section", back_populates="enrollments")

# ── Teacher Assignment (Explicit permission model) ─────────────────────────
class TeacherAssignment(Base):
    __tablename__ = "teacher_assignments"

    id = Column(Integer, primary_key=True, index=True)
    teacher_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    academic_year_id = Column(Integer, ForeignKey("academic_years.id"), nullable=False)
    class_id = Column(Integer, ForeignKey("classes.id"), nullable=False)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False)
    section_id = Column(Integer, ForeignKey("sections.id"), nullable=True)
    assigned_at = Column(DateTime, default=datetime.utcnow)

    teacher = relationship("User", back_populates="teacher_assignments")
    academic_year = relationship("AcademicYear", back_populates="teacher_assignments")
    klass = relationship("Class", back_populates="teacher_assignments")
    subject = relationship("Subject", back_populates="teacher_assignments")
    section = relationship("Section")

# ── Subject ─────────────────────────────────────────────────────────────────
class Subject(Base):
    __tablename__ = "subjects"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)  # "English", "Mathematics", "Science"
    code = Column(String(20), nullable=False)
    class_id = Column(Integer, ForeignKey("classes.id"), nullable=True)  # legacy compatibility
    teacher_id = Column(Integer, ForeignKey("users.id"), nullable=True)  # legacy primary teacher
    icon_color = Column(String(10), nullable=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    legacy_klass = relationship("Class", back_populates="legacy_subjects", foreign_keys=[class_id])
    classes = relationship("Class", secondary=class_subjects, back_populates="subjects")
    teacher = relationship("User", back_populates="taught_subjects", foreign_keys=[teacher_id])
    students = relationship("User", secondary=student_subjects, back_populates="enrolled_subjects")
    
    units = relationship("Unit", back_populates="subject", cascade="all, delete")
    lessons = relationship("Lesson", back_populates="subject", cascade="all, delete")
    assignments = relationship("Assignment", back_populates="subject", cascade="all, delete")
    quizzes = relationship("Quiz", back_populates="subject", cascade="all, delete")
    flashcards = relationship("Flashcard", back_populates="subject", cascade="all, delete")
    mindmaps = relationship("Mindmap", back_populates="subject", cascade="all, delete")
    teacher_assignments = relationship("TeacherAssignment", back_populates="subject", cascade="all, delete")

# ── Unit ────────────────────────────────────────────────────────────────────
class Unit(Base):
    __tablename__ = "units"

    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False)
    class_id = Column(Integer, ForeignKey("classes.id"), nullable=True)
    title = Column(String(200), nullable=False)  # "Unit 1 - Prose"
    order_index = Column(Integer, default=1)
    created_at = Column(DateTime, default=datetime.utcnow)

    subject = relationship("Subject", back_populates="units")
    lessons = relationship("Lesson", back_populates="unit")

# ── Lesson ───────────────────────────────────────────────────────────────────
class Lesson(Base):
    __tablename__ = "lessons"

    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False)
    class_id = Column(Integer, ForeignKey("classes.id"), nullable=True)
    unit_id = Column(Integer, ForeignKey("units.id"), nullable=True)
    title = Column(String(200), nullable=False)  # "Lesson 1: A Letter to God"
    description = Column(Text, default="")
    order_index = Column(Integer, default=1)
    created_at = Column(DateTime, default=datetime.utcnow)

    subject = relationship("Subject", back_populates="lessons")
    unit = relationship("Unit", back_populates="lessons")
    materials = relationship("Material", back_populates="lesson", cascade="all, delete")

# ── Material ─────────────────────────────────────────────────────────────────
class Material(Base):
    __tablename__ = "materials"

    id = Column(Integer, primary_key=True, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=False)
    uploader_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text, default="")
    material_type = Column(String(30), nullable=False)  # video | pdf | ppt | notes | doc | link | practice
    file_type = Column(String(30), nullable=False)      # legacy compatibility
    file_path = Column(String(500), nullable=True)
    external_url = Column(String(500), nullable=True)
    duration = Column(String(50), nullable=True)        # e.g. "24:15"
    thumbnail_url = Column(String(500), nullable=True)
    publication_status = Column(String(20), default="published")  # published | draft
    uploaded_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    lesson = relationship("Lesson", back_populates="materials")
    uploader = relationship("User", back_populates="uploads")

# ── Assignment ───────────────────────────────────────────────────────────────
class Assignment(Base):
    __tablename__ = "assignments"

    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False)
    class_id = Column(Integer, ForeignKey("classes.id"), nullable=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, default="")
    due_date = Column(DateTime, nullable=False)
    max_score = Column(Integer, default=100)
    created_at = Column(DateTime, default=datetime.utcnow)

    subject = relationship("Subject", back_populates="assignments")
    submissions = relationship("AssignmentSubmission", back_populates="assignment", cascade="all, delete")

class AssignmentSubmission(Base):
    __tablename__ = "assignment_submissions"

    id = Column(Integer, primary_key=True, index=True)
    assignment_id = Column(Integer, ForeignKey("assignments.id"), nullable=False)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    file_path = Column(String(500), nullable=True)
    score = Column(Integer, nullable=True)
    feedback = Column(Text, nullable=True)
    submitted_at = Column(DateTime, default=datetime.utcnow)
    graded_at = Column(DateTime, nullable=True)

    assignment = relationship("Assignment", back_populates="submissions")
    student = relationship("User", back_populates="assignment_submissions")

# ── Quiz ──────────────────────────────────────────────────────────────────────
class Quiz(Base):
    __tablename__ = "quizzes"

    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=True)
    title = Column(String(200), nullable=False)
    time_minutes = Column(Integer, default=10)
    created_at = Column(DateTime, default=datetime.utcnow)

    subject = relationship("Subject", back_populates="quizzes")
    questions = relationship("QuizQuestion", back_populates="quiz", cascade="all, delete")
    attempts = relationship("QuizAttempt", back_populates="quiz", cascade="all, delete")

class QuizQuestion(Base):
    __tablename__ = "quiz_questions"

    id = Column(Integer, primary_key=True, index=True)
    quiz_id = Column(Integer, ForeignKey("quizzes.id"), nullable=False)
    question_text = Column(Text, nullable=False)
    options = Column(JSON, nullable=False)         # list[str]
    correct_option_index = Column(Integer, nullable=False)
    order_index = Column(Integer, default=0)

    quiz = relationship("Quiz", back_populates="questions")

class QuizAttempt(Base):
    __tablename__ = "quiz_attempts"

    id = Column(Integer, primary_key=True, index=True)
    quiz_id = Column(Integer, ForeignKey("quizzes.id"), nullable=False)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    answers = Column(JSON, nullable=False)         # {question_id: chosen_index}
    score = Column(Integer, default=0)
    total = Column(Integer, default=0)
    attempted_at = Column(DateTime, default=datetime.utcnow)

    quiz = relationship("Quiz", back_populates="attempts")
    student = relationship("User", back_populates="quiz_attempts")

# ── Flashcard ─────────────────────────────────────────────────────────────────
class Flashcard(Base):
    __tablename__ = "flashcards"

    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=True)
    title = Column(String(200), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    subject = relationship("Subject", back_populates="flashcards")
    cards = relationship("FlashcardItem", back_populates="flashcard", cascade="all, delete")

class FlashcardItem(Base):
    __tablename__ = "flashcard_items"

    id = Column(Integer, primary_key=True, index=True)
    flashcard_id = Column(Integer, ForeignKey("flashcards.id"), nullable=False)
    front = Column(Text, nullable=False)
    back = Column(Text, nullable=False)
    order_index = Column(Integer, default=0)

    flashcard = relationship("Flashcard", back_populates="cards")

# ── Mindmap ───────────────────────────────────────────────────────────────────
class Mindmap(Base):
    __tablename__ = "mindmaps"

    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=True)
    title = Column(String(200), nullable=False)
    central_topic = Column(String(200), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    subject = relationship("Subject", back_populates="mindmaps")
    branches = relationship("MindmapBranch", back_populates="mindmap", cascade="all, delete")

class MindmapBranch(Base):
    __tablename__ = "mindmap_branches"

    id = Column(Integer, primary_key=True, index=True)
    mindmap_id = Column(Integer, ForeignKey("mindmaps.id"), nullable=False)
    label = Column(String(200), nullable=False)
    sub_topics = Column(JSON, default=list)
    color = Column(String(10), default="#6C63FF")
    order_index = Column(Integer, default=0)

    mindmap = relationship("Mindmap", back_populates="branches")

# ── Announcements & Timetable ────────────────────────────────────────────────
class Announcement(Base):
    __tablename__ = "announcements"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    target_role = Column(String(20), default="all")  # all | student | teacher | admin
    class_id = Column(Integer, ForeignKey("classes.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class TimetableEntry(Base):
    __tablename__ = "timetable"

    id = Column(Integer, primary_key=True, index=True)
    class_id = Column(Integer, ForeignKey("classes.id"), nullable=False)
    section_id = Column(Integer, ForeignKey("sections.id"), nullable=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False)
    teacher_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    day_of_week = Column(String(20), nullable=False)  # Monday, Tuesday, ...
    period_number = Column(Integer, nullable=False)
    start_time = Column(String(10), nullable=False)  # "09:00"
    end_time = Column(String(10), nullable=False)    # "09:45"
    room = Column(String(50), default="")

class ActivityLog(Base):
    __tablename__ = "activity_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    action = Column(String(100), nullable=False)
    details = Column(Text, default="")
    timestamp = Column(DateTime, default=datetime.utcnow)
