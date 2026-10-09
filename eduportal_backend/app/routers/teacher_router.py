# eduportal_backend/app/routers/teacher_router.py
import os, shutil
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Request, Query
from sqlalchemy.orm import Session
from datetime import datetime

from .. import models, schemas
from ..database import get_db
from ..auth import get_teacher, get_current_user

router = APIRouter(prefix="/teacher", tags=["teacher"])
UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)


# ── Subjects & Assigned Classes (Section 15 & 16) ────────────────────────────
@router.get("/subjects")
def my_assigned_subjects(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    # Query explicit teacher assignments
    assignments = db.query(models.TeacherAssignment).filter(
        models.TeacherAssignment.teacher_id == current_user.id
    ).all()

    results = []
    seen = set()
    for a in assignments:
        key = (a.class_id, a.subject_id)
        if key in seen:
            continue
        seen.add(key)
        results.append({
            "id": a.subject.id,
            "assignment_id": a.id,
            "name": a.subject.name,
            "code": a.subject.code,
            "class_id": a.class_id,
            "class_name": a.klass.name if a.klass else f"Class {a.class_id}",
            "section_name": a.section.name if a.section else "All Sections",
            "icon_color": a.subject.icon_color or "#4F46E5",
            "teacher": {"id": current_user.id, "full_name": current_user.full_name},
        })

    # Fallback to legacy taught_subjects if no new assignments exist
    if not results:
        for s in current_user.taught_subjects:
            c_name = s.legacy_klass.name if s.legacy_klass else (s.classes[0].name if s.classes else "")
            c_id = s.class_id or (s.classes[0].id if s.classes else 1)
            results.append({
                "id": s.id,
                "name": s.name,
                "code": s.code,
                "class_id": c_id,
                "class_name": c_name,
                "section_name": "All Sections",
                "icon_color": s.icon_color or "#4F46E5",
                "teacher": {"id": current_user.id, "full_name": current_user.full_name},
            })

    return {"subjects": results}


# ── Lessons ───────────────────────────────────────────────────────────────────
@router.get("/lessons")
@router.get("/subjects/{subject_id}/lessons")
def get_lessons(
    subject_id: Optional[int] = None,
    class_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    query = db.query(models.Lesson)
    if subject_id:
        _assert_teacher_assigned(db, current_user.id, subject_id, class_id)
        query = query.filter(models.Lesson.subject_id == subject_id)
        if class_id:
            query = query.filter(models.Lesson.class_id == class_id)
    else:
        # Lessons for all assigned subjects
        assigned_subjects = _get_assigned_subject_ids(db, current_user.id)
        query = query.filter(models.Lesson.subject_id.in_(assigned_subjects))

    lessons = query.order_by(models.Lesson.order_index).all()
    return {"lessons": [_serialize_lesson(l) for l in lessons]}

@router.post("/lessons", status_code=201)
def create_lesson(
    body: schemas.LessonCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    _assert_teacher_assigned(db, current_user.id, body.subject_id, body.class_id)
    count = db.query(models.Lesson).filter(
        models.Lesson.subject_id == body.subject_id
    ).count()
    lesson = models.Lesson(
        subject_id=body.subject_id,
        class_id=body.class_id,
        unit_id=body.unit_id,
        title=body.title,
        description=body.description or "",
        order_index=count + 1,
    )
    db.add(lesson)
    db.commit()
    db.refresh(lesson)
    return _serialize_lesson(lesson)


# ── Materials Management (Section 17 & 17.1 Video Upload) ─────────────────────
@router.get("/materials")
@router.get("/lessons/{lesson_id}/materials")
def get_materials(
    request: Request,
    lesson_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    query = db.query(models.Material).filter(models.Material.uploader_id == current_user.id)
    if lesson_id:
        query = query.filter(models.Material.lesson_id == lesson_id)
    materials = query.order_by(models.Material.uploaded_at.desc()).all()
    return {"materials": [_serialize_material(m, str(request.base_url)) for m in materials]}

@router.post("/materials/upload", status_code=201)
async def upload_material(
    request: Request,
    lesson_id: int = Form(...),
    title: str = Form(...),
    description: str = Form(""),
    material_type: str = Form(...),  # video | pdf | ppt | notes | doc | link | other
    publication_status: str = Form("published"),  # published | draft
    duration: Optional[str] = Form(None),
    external_url: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    lesson = _get_lesson(db, lesson_id)
    # Check permissions
    _assert_teacher_assigned(db, current_user.id, lesson.subject_id, lesson.class_id)

    safe_name = None
    if file and file.filename:
        safe_name = f"{lesson_id}_{current_user.id}_{file.filename}"
        dest = os.path.join(UPLOAD_DIR, safe_name)
        with open(dest, "wb") as f:
            shutil.copyfileobj(file.file, f)

    m = models.Material(
        lesson_id=lesson_id,
        uploader_id=current_user.id,
        title=title,
        description=description,
        material_type=material_type,
        file_type=material_type if material_type != "video" else "mp4",
        file_path=safe_name,
        external_url=external_url,
        duration=duration or ("15:00" if material_type == "video" else None),
        publication_status=publication_status,
    )
    db.add(m)
    db.commit()
    db.refresh(m)
    return _serialize_material(m, str(request.base_url))

@router.put("/materials/{material_id}/publish")
def toggle_material_publication(
    material_id: int,
    status: str = Query("published"),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    m = db.query(models.Material).filter(models.Material.id == material_id).first()
    if not m:
        raise HTTPException(404, "Material not found")
    if m.uploader_id != current_user.id and current_user.role != "admin":
        raise HTTPException(403, "Not authorized to modify this material")
    m.publication_status = status
    db.commit()
    return {"id": m.id, "publication_status": m.publication_status}

@router.delete("/materials/{material_id}", status_code=204)
def delete_material(
    material_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    m = db.query(models.Material).filter(models.Material.id == material_id).first()
    if not m:
        raise HTTPException(404, "Material not found")
    if m.uploader_id != current_user.id and current_user.role != "admin":
        raise HTTPException(403, "Not authorized to delete this material")
    if m.file_path:
        full = os.path.join(UPLOAD_DIR, m.file_path)
        if os.path.exists(full):
            os.remove(full)
    db.delete(m)
    db.commit()


# ── Timetable & Announcements ────────────────────────────────────────────────
@router.get("/timetable")
def my_timetable(db: Session = Depends(get_db), current_user: models.User = Depends(get_teacher)):
    entries = db.query(models.TimetableEntry).filter(
        models.TimetableEntry.teacher_id == current_user.id
    ).all()
    return {
        "timetable": [
            {
                "id": t.id,
                "class_id": t.class_id,
                "class_name": f"Class {t.class_id}",
                "day_of_week": t.day_of_week,
                "period_number": t.period_number,
                "start_time": t.start_time,
                "end_time": t.end_time,
                "room": t.room,
            }
            for t in entries
        ]
    }

@router.get("/announcements")
def teacher_announcements(db: Session = Depends(get_db), _=Depends(get_teacher)):
    ann = db.query(models.Announcement).filter(
        models.Announcement.target_role.in_(["all", "teacher"])
    ).order_by(models.Announcement.created_at.desc()).all()
    return {
        "announcements": [
            {"id": a.id, "title": a.title, "content": a.content, "created_at": a.created_at.isoformat()}
            for a in ann
        ]
    }


# ── Quizzes, Assignments, Flashcards, Mindmaps ──────────────────────────────
@router.get("/quizzes")
@router.get("/subjects/{subject_id}/quizzes")
def get_quizzes(
    subject_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    query = db.query(models.Quiz)
    if subject_id:
        _assert_teacher_assigned(db, current_user.id, subject_id)
        query = query.filter(models.Quiz.subject_id == subject_id)
    else:
        assigned = _get_assigned_subject_ids(db, current_user.id)
        query = query.filter(models.Quiz.subject_id.in_(assigned))
    quizzes = query.all()
    return {"quizzes": [_serialize_quiz(q, include_correct=True) for q in quizzes]}

@router.post("/quiz/create", status_code=201)
@router.post("/quizzes", status_code=201)
def create_quiz(
    body: schemas.QuizCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    _assert_teacher_assigned(db, current_user.id, body.subject_id)
    quiz = models.Quiz(
        subject_id=body.subject_id,
        title=body.title,
        time_minutes=body.time_minutes,
    )
    db.add(quiz)
    db.flush()
    for i, q in enumerate(body.questions):
        db.add(models.QuizQuestion(
            quiz_id=quiz.id,
            question_text=q.question_text,
            options=q.options,
            correct_option_index=q.correct_option_index,
            order_index=i,
        ))
    db.commit()
    db.refresh(quiz)
    return _serialize_quiz(quiz, include_correct=True)

@router.get("/assignments")
@router.get("/subjects/{subject_id}/assignments")
def get_assignments(
    subject_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    query = db.query(models.Assignment)
    if subject_id:
        _assert_teacher_assigned(db, current_user.id, subject_id)
        query = query.filter(models.Assignment.subject_id == subject_id)
    else:
        assigned = _get_assigned_subject_ids(db, current_user.id)
        query = query.filter(models.Assignment.subject_id.in_(assigned))
    assignments = query.order_by(models.Assignment.due_date).all()
    return {"assignments": [_serialize_assignment(a) for a in assignments]}

@router.post("/assignments/create", status_code=201)
@router.post("/assignments", status_code=201)
def create_assignment(
    body: schemas.AssignmentCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    _assert_teacher_assigned(db, current_user.id, body.subject_id)
    a = models.Assignment(
        subject_id=body.subject_id,
        title=body.title,
        description=body.description or "",
        due_date=body.due_date,
        max_score=body.max_score,
    )
    db.add(a)
    db.commit()
    db.refresh(a)
    return _serialize_assignment(a)

@router.get("/assignments/{assignment_id}/submissions")
def get_submissions(
    assignment_id: int,
    db: Session = Depends(get_db),
    _=Depends(get_teacher),
):
    subs = db.query(models.AssignmentSubmission).filter(
        models.AssignmentSubmission.assignment_id == assignment_id
    ).all()
    return {
        "submissions": [
            {
                "id": s.id,
                "student_id": s.student_id,
                "student_name": s.student.full_name if s.student else "",
                "score": s.score,
                "feedback": s.feedback,
                "submitted_at": s.submitted_at.isoformat() if s.submitted_at else None,
            }
            for s in subs
        ]
    }

@router.put("/assignments/grade")
def grade_submission(
    submission_id: int = Query(...),
    score: int = Query(...),
    feedback: str = Query(""),
    db: Session = Depends(get_db),
    _=Depends(get_teacher),
):
    sub = db.query(models.AssignmentSubmission).filter(
        models.AssignmentSubmission.id == submission_id
    ).first()
    if not sub:
        raise HTTPException(404, "Submission not found")
    sub.score = score
    sub.feedback = feedback
    sub.graded_at = datetime.utcnow()
    db.commit()
    return {"ok": True}

@router.put("/submissions/{submission_id}/grade")
def grade_submission_by_path(
    submission_id: int,
    score: int = Query(...),
    feedback: str = Query(""),
    db: Session = Depends(get_db),
    _=Depends(get_teacher),
):
    sub = db.query(models.AssignmentSubmission).filter(
        models.AssignmentSubmission.id == submission_id
    ).first()
    if not sub:
        raise HTTPException(404, "Submission not found")
    sub.score = score
    sub.feedback = feedback
    sub.graded_at = datetime.utcnow()
    db.commit()
    return {"ok": True}

@router.get("/flashcards")
@router.get("/subjects/{subject_id}/flashcards")
def get_flashcards(
    subject_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    query = db.query(models.Flashcard)
    if subject_id:
        _assert_teacher_assigned(db, current_user.id, subject_id)
        query = query.filter(models.Flashcard.subject_id == subject_id)
    flashcards = query.all()
    return {
        "flashcards": [
            {
                "id": f.id,
                "subject_id": f.subject_id,
                "title": f.title,
                "cards": [
                    {"id": c.id, "front": c.front, "back": c.back, "order_index": c.order_index}
                    for c in sorted(f.cards, key=lambda x: x.order_index)
                ]
            }
            for f in flashcards
        ]
    }

@router.post("/flashcards/create", status_code=201)
@router.post("/flashcards", status_code=201)
def create_flashcard(
    body: schemas.FlashcardCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    _assert_teacher_assigned(db, current_user.id, body.subject_id)
    fc = models.Flashcard(subject_id=body.subject_id, title=body.title)
    db.add(fc)
    db.flush()
    for i, card in enumerate(body.cards):
        db.add(models.FlashcardItem(flashcard_id=fc.id, front=card.front, back=card.back, order_index=i))
    db.commit()
    return {"ok": True, "id": fc.id}

@router.get("/mindmaps")
@router.get("/subjects/{subject_id}/mindmaps")
def get_mindmaps(
    subject_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    query = db.query(models.Mindmap)
    if subject_id:
        _assert_teacher_assigned(db, current_user.id, subject_id)
        query = query.filter(models.Mindmap.subject_id == subject_id)
    mindmaps = query.all()
    return {
        "mindmaps": [
            {
                "id": mm.id,
                "subject_id": mm.subject_id,
                "title": mm.title,
                "central_topic": mm.central_topic,
                "branches": [
                    {"id": b.id, "label": b.label, "sub_topics": b.sub_topics, "color": b.color}
                    for b in mm.branches
                ]
            }
            for mm in mindmaps
        ]
    }

@router.post("/mindmaps/create", status_code=201)
@router.post("/mindmaps", status_code=201)
def create_mindmap(
    body: schemas.MindmapCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_teacher),
):
    _assert_teacher_assigned(db, current_user.id, body.subject_id)
    mm = models.Mindmap(subject_id=body.subject_id, title=body.title, central_topic=body.central_topic)
    db.add(mm)
    db.flush()
    for i, branch in enumerate(body.branches):
        db.add(models.MindmapBranch(
            mindmap_id=mm.id, label=branch.label, sub_topics=branch.sub_topics, color=branch.color, order_index=i
        ))
    db.commit()
    return {"ok": True, "id": mm.id}


# ── Helpers & Strict Authorization (Section 15) ───────────────────────────────
def _get_assigned_subject_ids(db: Session, teacher_id: int) -> List[int]:
    assignments = db.query(models.TeacherAssignment.subject_id).filter(
        models.TeacherAssignment.teacher_id == teacher_id
    ).all()
    sub_ids = [a[0] for a in assignments]
    # Add legacy taught subjects
    legacy_subs = db.query(models.Subject.id).filter(models.Subject.teacher_id == teacher_id).all()
    sub_ids.extend([s[0] for s in legacy_subs])
    return list(set(sub_ids))

def _assert_teacher_assigned(db: Session, teacher_id: int, subject_id: int, class_id: Optional[int] = None):
    # Admin has system-wide override
    user = db.query(models.User).filter(models.User.id == teacher_id).first()
    if user and user.role == "admin":
        return

    # Check TeacherAssignment
    query = db.query(models.TeacherAssignment).filter(
        models.TeacherAssignment.teacher_id == teacher_id,
        models.TeacherAssignment.subject_id == subject_id,
    )
    if class_id:
        query = query.filter(models.TeacherAssignment.class_id == class_id)
    assignment = query.first()

    if not assignment:
        # Check legacy teacher_id on subject
        legacy = db.query(models.Subject).filter(
            models.Subject.id == subject_id,
            models.Subject.teacher_id == teacher_id
        ).first()
        if not legacy:
            raise HTTPException(
                403,
                "Access Denied: You are not authorized for this class and subject combination."
            )

def _get_lesson(db: Session, lesson_id: int):
    l = db.query(models.Lesson).filter(models.Lesson.id == lesson_id).first()
    if not l:
        raise HTTPException(404, "Lesson not found")
    return l

def _serialize_lesson(l: models.Lesson) -> dict:
    return {
        "id": l.id,
        "subject_id": l.subject_id,
        "class_id": l.class_id,
        "unit_id": l.unit_id,
        "unit_title": l.unit.title if l.unit else "",
        "title": l.title,
        "description": l.description,
        "order_index": l.order_index,
        "material_count": len(l.materials),
        "created_at": l.created_at.isoformat(),
    }

def _serialize_material(m: models.Material, base_url: str) -> dict:
    return {
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
        "publication_status": m.publication_status,
        "uploaded_at": m.uploaded_at.isoformat(),
        "uploaded_by": m.uploader.full_name if m.uploader else "",
    }

def _serialize_assignment(a: models.Assignment) -> dict:
    return {
        "id": a.id,
        "subject_id": a.subject_id,
        "subject_name": a.subject.name if a.subject else "",
        "title": a.title,
        "description": a.description,
        "due_date": a.due_date.isoformat(),
        "max_score": a.max_score,
    }

def _serialize_quiz(q: models.Quiz, include_correct: bool = False) -> dict:
    return {
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
                **({"correct_option_index": qq.correct_option_index} if include_correct else {}),
            }
            for qq in sorted(q.questions, key=lambda x: x.order_index)
        ],
    }
