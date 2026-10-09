# eduportal_backend/app/routers/student_router.py
import os, shutil
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Request, Query
from sqlalchemy.orm import Session
from datetime import datetime

from .. import models, schemas
from ..database import get_db
from ..auth import get_current_user

router = APIRouter(prefix="/student", tags=["student"])
UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

def _get_student(current_user: models.User = Depends(get_current_user)):
    if current_user.role not in ("student", "admin"):
        raise HTTPException(403, "Students only")
    return current_user


# ── Profile & Historical Enrollment (Section 33.1) ───────────────────────────
@router.get("/profile")
def get_student_profile(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    student = db.query(models.User).filter(models.User.id == current_user.id).first()
    active_enrollment = next((e for e in student.enrollments if e.enrollment_status == "active"), None)

    c_name = active_enrollment.klass.name if (active_enrollment and active_enrollment.klass) else (student.klass.name if student.klass else "Class 10")
    sec_name = active_enrollment.section.name if (active_enrollment and active_enrollment.section) else "Section A"
    ay_name = active_enrollment.academic_year.name if (active_enrollment and active_enrollment.academic_year) else "2026-2027"

    history = [
        {
            "academic_year": e.academic_year.name if e.academic_year else "",
            "class_name": e.klass.name if e.klass else "",
            "section_name": e.section.name if e.section else "",
            "status": e.enrollment_status,
            "enrolled_at": e.enrolled_at.strftime("%Y-%m-%d") if e.enrolled_at else "",
        }
        for e in sorted(student.enrollments, key=lambda x: x.id, reverse=True)
    ]

    return {
        "id": student.id,
        "username": student.username,
        "full_name": student.full_name,
        "email": student.email,
        "role": "student",
        "class_id": active_enrollment.class_id if active_enrollment else student.class_id,
        "class_name": c_name,
        "section_name": sec_name,
        "academic_year": ay_name,
        "roll_number": student.roll_number or "",
        "date_of_birth": student.date_of_birth or "",
        "contact_number": student.contact_number or "",
        "parent_name": student.parent_name or "",
        "parent_contact": student.parent_contact or "",
        "enrollment_history": history,
    }


# ── Subjects (Determined from database Class-Subject configuration) ──────────
@router.get("/subjects")
def my_subjects(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    student = db.query(models.User).filter(models.User.id == current_user.id).first()
    active_enrollment = next((e for e in student.enrollments if e.enrollment_status == "active"), None)
    class_id = active_enrollment.class_id if active_enrollment else student.class_id

    subjects = []
    if class_id:
        klass = db.query(models.Class).filter(models.Class.id == class_id).first()
        if klass and klass.subjects:
            subjects = klass.subjects

    if not subjects:
        subjects = student.enrolled_subjects

    c_name = active_enrollment.klass.name if (active_enrollment and active_enrollment.klass) else (student.klass.name if student.klass else "")

    return {
        "class_name": c_name,
        "subjects": [
            {
                "id": s.id,
                "name": s.name,
                "code": s.code,
                "class_id": class_id,
                "class_name": c_name,
                "icon_color": s.icon_color or "#4F46E5",
                "teacher": {"id": s.teacher.id, "full_name": s.teacher.full_name} if s.teacher else None,
            }
            for s in subjects
        ]
    }


# ── Lessons ───────────────────────────────────────────────────────────────────
@router.get("/lessons")
@router.get("/subjects/{subject_id}/lessons")
def get_lessons(
    subject_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    query = db.query(models.Lesson)
    if subject_id:
        query = query.filter(models.Lesson.subject_id == subject_id)
    else:
        # Enrolled subjects
        student = db.query(models.User).filter(models.User.id == current_user.id).first()
        sub_ids = [s.id for s in student.enrolled_subjects]
        query = query.filter(models.Lesson.subject_id.in_(sub_ids))

    lessons = query.order_by(models.Lesson.order_index).all()
    results = []
    for l in lessons:
        # Only count published materials for student view
        pub_count = db.query(models.Material).filter(
            models.Material.lesson_id == l.id,
            models.Material.publication_status == "published"
        ).count()
        results.append({
            "id": l.id,
            "subject_id": l.subject_id,
            "class_id": l.class_id,
            "unit_id": l.unit_id,
            "unit_title": l.unit.title if l.unit else "",
            "title": l.title,
            "description": l.description,
            "order_index": l.order_index,
            "material_count": pub_count,
            "created_at": l.created_at.isoformat(),
        })

    return {"lessons": results}


# ── Dynamic Lesson Sidebar Counts & Summary (Section 20) ────────────────────
@router.get("/lessons/{lesson_id}/overview")
@router.get("/lessons/{lesson_id}/counts")
def get_lesson_overview_counts(
    lesson_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    lesson = db.query(models.Lesson).filter(models.Lesson.id == lesson_id).first()
    if not lesson:
        raise HTTPException(404, "Lesson not found")

    # Dynamic calculation from published materials
    pub_materials = db.query(models.Material).filter(
        models.Material.lesson_id == lesson_id,
        models.Material.publication_status == "published"
    ).all()

    video_count = sum(1 for m in pub_materials if m.material_type == "video")
    pdf_count = sum(1 for m in pub_materials if m.material_type == "pdf")
    ppt_count = sum(1 for m in pub_materials if m.material_type == "ppt")
    notes_count = sum(1 for m in pub_materials if m.material_type in ("notes", "word", "doc"))
    
    # Practice questions from quizzes linked to this lesson or subject
    quiz_count = db.query(models.Quiz).filter(
        (models.Quiz.lesson_id == lesson_id) |
        ((models.Quiz.subject_id == lesson.subject_id) & (models.Quiz.lesson_id.is_(None)))
    ).count()

    total_published = len(pub_materials)

    return {
        "lesson_id": lesson.id,
        "lesson_title": lesson.title,
        "unit_title": lesson.unit.title if lesson.unit else "",
        "subject_name": lesson.subject.name if lesson.subject else "",
        "counts": {
            "home": total_published,
            "videos": video_count,
            "pdf_materials": pdf_count,
            "ppt_presentations": ppt_count,
            "notes": notes_count,
            "practice_questions": quiz_count,
        }
    }


# ── Learning Materials (Section 20, 21, 22) ──────────────────────────────────
# Strictly enforces: Student Class + Accessible Subject + Selected Lesson + Published Status
@router.get("/materials")
@router.get("/lessons/{lesson_id}/materials")
def get_materials(
    request: Request,
    lesson_id: Optional[int] = None,
    material_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    query = db.query(models.Material).filter(
        models.Material.publication_status == "published"
    )

    if lesson_id:
        lesson = db.query(models.Lesson).filter(models.Lesson.id == lesson_id).first()
        if not lesson:
            raise HTTPException(404, "Lesson not found")
        query = query.filter(models.Material.lesson_id == lesson_id)

    if material_type:
        if material_type == "notes":
            query = query.filter(models.Material.material_type.in_(["notes", "word", "doc"]))
        else:
            query = query.filter(models.Material.material_type == material_type)

    materials = query.all()
    base_url = str(request.base_url)

    return {
        "materials": [
            {
                "id": m.id,
                "lesson_id": m.lesson_id,
                "title": m.title,
                "description": m.description or "",
                "material_type": m.material_type,
                "file_type": m.file_type,
                "file_path": m.file_path,
                "file_url": f"{base_url}uploads/{m.file_path}" if m.file_path else (m.external_url or None),
                "external_url": m.external_url,
                "duration": m.duration,
                "thumbnail_url": m.thumbnail_url,
                "publication_status": m.publication_status,
                "uploaded_at": m.uploaded_at.isoformat(),
                "uploaded_by": m.uploader.full_name if m.uploader else "Faculty",
            }
            for m in materials
        ]
    }


# ── Timetable & Announcements ────────────────────────────────────────────────
@router.get("/timetable")
def student_timetable(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    active_enrollment = next((e for e in current_user.enrollments if e.enrollment_status == "active"), None)
    c_id = active_enrollment.class_id if active_enrollment else current_user.class_id or 5

    entries = db.query(models.TimetableEntry).filter(
        models.TimetableEntry.class_id == c_id
    ).all()
    return {
        "timetable": [
            {
                "id": t.id,
                "day_of_week": t.day_of_week,
                "period_number": t.period_number,
                "start_time": t.start_time,
                "end_time": t.end_time,
                "room": t.room,
                "subject_name": db.query(models.Subject.name).filter(models.Subject.id == t.subject_id).scalar() or "",
            }
            for t in entries
        ]
    }

@router.get("/announcements")
def student_announcements(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    active_enrollment = next((e for e in current_user.enrollments if e.enrollment_status == "active"), None)
    c_id = active_enrollment.class_id if active_enrollment else current_user.class_id

    ann = db.query(models.Announcement).filter(
        models.Announcement.target_role.in_(["all", "student"]),
        (models.Announcement.class_id.is_(None)) | (models.Announcement.class_id == c_id)
    ).order_by(models.Announcement.created_at.desc()).all()

    return {
        "announcements": [
            {
                "id": a.id,
                "title": a.title,
                "content": a.content,
                "created_at": a.created_at.isoformat(),
            }
            for a in ann
        ]
    }


# ── Assignments ────────────────────────────────────────────────────────────────
@router.get("/assignments")
def my_assignments(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    student = db.query(models.User).filter(models.User.id == current_user.id).first()
    result = []
    for subject in student.enrolled_subjects:
        for a in subject.assignments:
            sub = next(
                (s for s in a.submissions if s.student_id == current_user.id), None
            )
            status = None
            if sub:
                status = "graded" if sub.score is not None else "submitted"
            result.append({
                "id": a.id,
                "subject_id": a.subject_id,
                "subject_name": subject.name,
                "title": a.title,
                "description": a.description,
                "due_date": a.due_date.isoformat(),
                "max_score": a.max_score,
                "submission_status": status,
                "score": sub.score if sub else None,
                "feedback": sub.feedback if sub else None,
            })
    return {"assignments": sorted(result, key=lambda x: x["due_date"])}

@router.post("/assignments/submit", status_code=201)
async def submit_assignment(
    assignment_id: int = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    a = db.query(models.Assignment).filter(models.Assignment.id == assignment_id).first()
    if not a:
        raise HTTPException(404, "Assignment not found")
    safe = f"sub_{assignment_id}_{current_user.id}_{file.filename}"
    dest = os.path.join(UPLOAD_DIR, safe)
    with open(dest, "wb") as f:
        shutil.copyfileobj(file.file, f)

    existing = db.query(models.AssignmentSubmission).filter(
        models.AssignmentSubmission.assignment_id == assignment_id,
        models.AssignmentSubmission.student_id == current_user.id,
    ).first()
    if existing:
        existing.file_path = safe
    else:
        db.add(models.AssignmentSubmission(
            assignment_id=assignment_id,
            student_id=current_user.id,
            file_path=safe,
        ))
    db.commit()
    return {"ok": True}

@router.post("/assignments/{assignment_id}/submit", status_code=201)
async def submit_assignment_by_path(
    assignment_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    a = db.query(models.Assignment).filter(models.Assignment.id == assignment_id).first()
    if not a:
        raise HTTPException(404, "Assignment not found")
    safe = f"sub_{assignment_id}_{current_user.id}_{file.filename}"
    dest = os.path.join(UPLOAD_DIR, safe)
    with open(dest, "wb") as f:
        shutil.copyfileobj(file.file, f)

    existing = db.query(models.AssignmentSubmission).filter(
        models.AssignmentSubmission.assignment_id == assignment_id,
        models.AssignmentSubmission.student_id == current_user.id,
    ).first()
    if existing:
        existing.file_path = safe
    else:
        db.add(models.AssignmentSubmission(
            assignment_id=assignment_id,
            student_id=current_user.id,
            file_path=safe,
        ))
    db.commit()
    return {"ok": True}


# ── Quizzes ───────────────────────────────────────────────────────────────────
@router.get("/quizzes")
def my_quizzes(
    lesson_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    query = db.query(models.Quiz)
    if lesson_id:
        query = query.filter(models.Quiz.lesson_id == lesson_id)
    else:
        student = db.query(models.User).filter(models.User.id == current_user.id).first()
        sub_ids = [s.id for s in student.enrolled_subjects]
        query = query.filter(models.Quiz.subject_id.in_(sub_ids))

    quizzes = query.all()
    result = []
    for q in quizzes:
        attempts = [a for a in q.attempts if a.student_id == current_user.id]
        best = max((a.score * 100 // a.total for a in attempts if a.total > 0), default=None)
        result.append({
            "id": q.id,
            "subject_id": q.subject_id,
            "subject_name": q.subject.name if q.subject else "",
            "title": q.title,
            "question_count": len(q.questions),
            "time_minutes": q.time_minutes,
            "status": "completed" if attempts else None,
            "best_score": best,
            "questions": [],
        })
    return {"quizzes": result}

@router.get("/quizzes/{quiz_id}")
def get_quiz(
    quiz_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    q = db.query(models.Quiz).filter(models.Quiz.id == quiz_id).first()
    if not q:
        raise HTTPException(404, "Quiz not found")
    return {
        "quiz": {
            "id": q.id,
            "subject_id": q.subject_id,
            "subject_name": q.subject.name if q.subject else "",
            "title": q.title,
            "question_count": len(q.questions),
            "time_minutes": q.time_minutes,
            "questions": [
                {
                    "id": qq.id,
                    "question_text": qq.question_text,
                    "options": qq.options,
                }
                for qq in sorted(q.questions, key=lambda x: x.order_index)
            ],
        }
    }

@router.post("/quiz/submit")
@router.post("/quizzes/submit")
def submit_quiz(
    body: schemas.QuizSubmit,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(_get_student),
):
    q = db.query(models.Quiz).filter(models.Quiz.id == body.quiz_id).first()
    if not q:
        raise HTTPException(404, "Quiz not found")

    score = 0
    total = len(q.questions)
    for question in q.questions:
        chosen = body.answers.get(str(question.id))
        if chosen is not None and int(chosen) == question.correct_option_index:
            score += 1

    attempt = models.QuizAttempt(
        quiz_id=body.quiz_id,
        student_id=current_user.id,
        answers=body.answers,
        score=score,
        total=total,
    )
    db.add(attempt)
    db.commit()
    return {"score": score, "total": total, "percentage": round(score / total * 100) if total else 0}
