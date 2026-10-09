# eduportal_backend/app/schemas.py
from pydantic import BaseModel, EmailStr
from typing import Optional, List, Any, Dict
from datetime import datetime


# ── Auth ─────────────────────────────────────────────────────────────────────
class LoginRequest(BaseModel):
    username: str
    password: str
    role: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    user: dict

class RefreshRequest(BaseModel):
    refresh_token: str


# ── Academic Year ───────────────────────────────────────────────────────────
class AcademicYearOut(BaseModel):
    id: int
    name: str
    is_active: bool

    class Config:
        from_attributes = True

class AcademicYearCreate(BaseModel):
    name: str
    is_active: bool = True


# ── Section ─────────────────────────────────────────────────────────────────
class SectionOut(BaseModel):
    id: int
    class_id: int
    name: str
    room_number: Optional[str] = None

    class Config:
        from_attributes = True

class SectionCreate(BaseModel):
    class_id: int
    name: str
    room_number: Optional[str] = None


# ── User & Student ──────────────────────────────────────────────────────────
class UserCreate(BaseModel):
    username: str
    password: str
    full_name: str
    email: Optional[str] = None
    role: str
    class_id: Optional[int] = None
    section_id: Optional[int] = None
    roll_number: Optional[str] = None
    date_of_birth: Optional[str] = None
    contact_number: Optional[str] = None
    parent_name: Optional[str] = None
    parent_contact: Optional[str] = None

class StudentEnrollmentHistory(BaseModel):
    academic_year: str
    class_name: str
    section_name: Optional[str] = None
    status: str

class UserOut(BaseModel):
    id: int
    username: str
    full_name: str
    email: Optional[str]
    role: str
    profile_pic: Optional[str]
    class_id: Optional[int] = None
    class_name: Optional[str] = None
    section_name: Optional[str] = None
    roll_number: Optional[str] = None
    date_of_birth: Optional[str] = None
    contact_number: Optional[str] = None
    parent_name: Optional[str] = None
    parent_contact: Optional[str] = None
    is_active: bool = True
    enrollment_history: List[StudentEnrollmentHistory] = []

    class Config:
        from_attributes = True

class BulkStudentRow(BaseModel):
    full_name: str
    email: str
    roll_number: str
    section: str
    contact_number: Optional[str] = None
    date_of_birth: Optional[str] = None
    parent_name: Optional[str] = None

class BulkStudentImportRequest(BaseModel):
    class_id: int
    students: List[BulkStudentRow]

class TeacherCreate(BaseModel):
    username: str
    password: str
    full_name: str
    email: Optional[str] = None
    contact_number: Optional[str] = None
    class_id: Optional[int] = None
    subject_id: Optional[int] = None
    section_id: Optional[int] = None


# ── Class ─────────────────────────────────────────────────────────────────────
class ClassCreate(BaseModel):
    name: str
    grade_level: Optional[int] = None

class ClassOut(BaseModel):
    id: int
    name: str
    grade_level: Optional[int] = None
    student_count: int = 0
    section_count: int = 0
    subject_count: int = 0
    teacher_count: int = 0

    class Config:
        from_attributes = True

class ClassTabsData(BaseModel):
    class_info: dict
    overview: dict
    students: List[dict]
    sections: List[dict]
    teachers: List[dict]
    subjects: List[dict]
    lessons: List[dict]


# ── Subject ───────────────────────────────────────────────────────────────────
class SubjectCreate(BaseModel):
    name: str
    code: str
    class_ids: Optional[List[int]] = []
    class_id: Optional[int] = None  # legacy support
    icon_color: Optional[str] = None
    description: Optional[str] = None

class TeacherAssignmentCreate(BaseModel):
    teacher_id: int
    class_id: int
    subject_id: int
    section_id: Optional[int] = None
    academic_year_id: Optional[int] = None

class AssignTeacher(BaseModel):
    subject_id: int
    teacher_id: int
    class_id: Optional[int] = None

class AssignStudentSubjects(BaseModel):
    student_id: int
    subject_ids: List[int]

class TeacherInfo(BaseModel):
    id: int
    full_name: str

class SubjectOut(BaseModel):
    id: int
    name: str
    code: str
    class_name: Optional[str] = ""
    class_id: Optional[int] = None
    icon_color: Optional[str] = None
    description: Optional[str] = None
    teachers: List[TeacherInfo] = []
    teacher: Optional[TeacherInfo] = None

    class Config:
        from_attributes = True


# ── Lesson ─────────────────────────────────────────────────────────────────────
class LessonCreate(BaseModel):
    subject_id: int
    class_id: Optional[int] = None
    unit_id: Optional[int] = None
    title: str
    description: Optional[str] = ""

class LessonCountsOut(BaseModel):
    home: int
    videos: int
    pdf_materials: int
    ppt_presentations: int
    notes: int
    practice_questions: int

class LessonOut(BaseModel):
    id: int
    subject_id: int
    class_id: Optional[int] = None
    unit_id: Optional[int] = None
    unit_title: Optional[str] = None
    title: str
    description: str
    order_index: int
    material_count: int = 0
    counts: Optional[LessonCountsOut] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ── Material ───────────────────────────────────────────────────────────────────
class MaterialCreate(BaseModel):
    lesson_id: int
    title: str
    description: Optional[str] = ""
    material_type: str  # video, pdf, ppt, notes, doc, link, other
    external_url: Optional[str] = None
    duration: Optional[str] = None
    publication_status: Optional[str] = "published"

class MaterialOut(BaseModel):
    id: int
    lesson_id: int
    title: str
    description: Optional[str] = ""
    material_type: str
    file_type: str
    file_path: Optional[str] = None
    file_url: Optional[str] = None
    external_url: Optional[str] = None
    duration: Optional[str] = None
    thumbnail_url: Optional[str] = None
    publication_status: str = "published"
    uploaded_at: datetime
    uploaded_by: str

    class Config:
        from_attributes = True


# ── Assignment ─────────────────────────────────────────────────────────────────
class AssignmentCreate(BaseModel):
    subject_id: int
    title: str
    description: Optional[str] = ""
    due_date: datetime
    max_score: int = 100

class AssignmentOut(BaseModel):
    id: int
    subject_id: int
    subject_name: str
    title: str
    description: str
    due_date: datetime
    max_score: int
    submission_status: Optional[str] = None
    score: Optional[int] = None
    feedback: Optional[str] = None

    class Config:
        from_attributes = True


# ── Quiz ──────────────────────────────────────────────────────────────────────
class QuestionCreate(BaseModel):
    question_text: str
    options: List[str]
    correct_option_index: int

class QuizCreate(BaseModel):
    subject_id: int
    title: str
    time_minutes: int = 10
    questions: List[QuestionCreate]

class QuizQuestionOut(BaseModel):
    id: int
    question_text: str
    options: List[str]
    correct_option_index: Optional[int] = None

    class Config:
        from_attributes = True

class QuizOut(BaseModel):
    id: int
    subject_id: int
    subject_name: str
    title: str
    question_count: int
    time_minutes: int
    status: Optional[str] = None
    best_score: Optional[int] = None
    questions: List[QuizQuestionOut] = []

    class Config:
        from_attributes = True

class QuizSubmit(BaseModel):
    quiz_id: int
    answers: dict


# ── Flashcard ─────────────────────────────────────────────────────────────────
class FlashcardItemCreate(BaseModel):
    front: str
    back: str

class FlashcardCreate(BaseModel):
    subject_id: int
    title: str
    cards: List[FlashcardItemCreate]

class FlashcardItemOut(BaseModel):
    id: int
    front: str
    back: str

    class Config:
        from_attributes = True

class FlashcardOut(BaseModel):
    id: int
    subject_id: int
    title: str
    cards: List[FlashcardItemOut]

    class Config:
        from_attributes = True


# ── Mindmap ───────────────────────────────────────────────────────────────────
class MindmapBranchCreate(BaseModel):
    label: str
    sub_topics: List[str] = []
    color: str = "#6C63FF"

class MindmapCreate(BaseModel):
    subject_id: int
    title: str
    central_topic: str
    branches: List[MindmapBranchCreate]

class MindmapBranchOut(BaseModel):
    id: int
    label: str
    sub_topics: List[str]
    color: str

    class Config:
        from_attributes = True

class MindmapOut(BaseModel):
    id: int
    subject_id: int
    title: str
    central_topic: str
    branches: List[MindmapBranchOut]

    class Config:
        from_attributes = True


# ── Announcements & Timetable ────────────────────────────────────────────────
class AnnouncementOut(BaseModel):
    id: int
    title: str
    content: str
    target_role: str
    class_id: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True

class TimetableOut(BaseModel):
    id: int
    class_id: int
    day_of_week: str
    period_number: int
    start_time: str
    end_time: str
    subject_name: str
    teacher_name: Optional[str] = None
    room: str = ""

    class Config:
        from_attributes = True
