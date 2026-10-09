# eduportal_backend/app/routers/admin_router.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import datetime

from .. import models, schemas
from ..database import get_db
from ..auth import hash_password, get_admin

router = APIRouter(prefix="/admin", tags=["admin"])


# ── Dashboard Overview ────────────────────────────────────────────────────────
@router.get("/dashboard")
def get_dashboard_summary(db: Session = Depends(get_db), _=Depends(get_admin)):
    total_students = db.query(models.User).filter(models.User.role == "student").count()
    total_teachers = db.query(models.User).filter(models.User.role == "teacher").count()
    total_classes = db.query(models.Class).count()
    total_subjects = db.query(models.Subject).count()
    total_materials = db.query(models.Material).count()
    total_published = db.query(models.Material).filter(models.Material.publication_status == "published").count()

    recent_users = db.query(models.User).order_by(models.User.created_at.desc()).limit(5).all()
    recent_announcements = db.query(models.Announcement).order_by(models.Announcement.created_at.desc()).limit(3).all()

    return {
        "stats": {
            "total_students": total_students,
            "total_teachers": total_teachers,
            "total_classes": total_classes,
            "total_subjects": total_subjects,
            "total_materials": total_materials,
            "published_materials": total_published,
        },
        "recent_users": [
            {
                "id": u.id,
                "username": u.username,
                "full_name": u.full_name,
                "role": u.role,
                "created_at": u.created_at.isoformat() if u.created_at else "",
            }
            for u in recent_users
        ],
        "recent_announcements": [
            {"id": a.id, "title": a.title, "content": a.content, "target_role": a.target_role}
            for a in recent_announcements
        ]
    }


# ── Academic Years ────────────────────────────────────────────────────────────
@router.get("/academic-years")
def list_academic_years(db: Session = Depends(get_db), _=Depends(get_admin)):
    years = db.query(models.AcademicYear).order_by(models.AcademicYear.id.desc()).all()
    return {
        "academic_years": [
            {"id": y.id, "name": y.name, "is_active": y.is_active}
            for y in years
        ]
    }

@router.post("/academic-years", status_code=201)
def create_academic_year(
    body: schemas.AcademicYearCreate,
    db: Session = Depends(get_db),
    _=Depends(get_admin)
):
    name = body.name.strip()
    if not name:
        raise HTTPException(400, "Academic year name is required")
    existing = db.query(models.AcademicYear).filter(
        models.AcademicYear.name.ilike(name)
    ).first()
    if existing:
        raise HTTPException(400, "Academic year already exists")
    ay = models.AcademicYear(name=name, is_active=body.is_active)
    db.add(ay)
    db.commit()
    db.refresh(ay)
    return {"id": ay.id, "name": ay.name, "is_active": ay.is_active}


# ── Classes & Tabs Management (Academic Structure) ──────────────────────────
@router.get("/classes")
def list_classes(db: Session = Depends(get_db), _=Depends(get_admin)):
    classes = db.query(models.Class).order_by(models.Class.grade_level, models.Class.id).all()
    results = []
    for c in classes:
        # Calculate active student enrollments
        active_enrolled = db.query(models.StudentEnrollment).filter(
            models.StudentEnrollment.class_id == c.id,
            models.StudentEnrollment.enrollment_status == "active"
        ).count()
        teacher_count = db.query(models.TeacherAssignment.teacher_id).filter(
            models.TeacherAssignment.class_id == c.id
        ).distinct().count()

        results.append({
            "id": c.id,
            "name": c.name,
            "grade_level": c.grade_level,
            "student_count": active_enrolled if active_enrolled > 0 else len(c.legacy_students),
            "section_count": len(c.sections),
            "subject_count": len(c.subjects),
            "teacher_count": teacher_count,
        })
    return {"classes": results}

@router.get("/classes/{class_id}/tabs")
def get_class_tabs_data(class_id: int, db: Session = Depends(get_db), _=Depends(get_admin)):
    c = db.query(models.Class).filter(models.Class.id == class_id).first()
    if not c:
        raise HTTPException(404, "Class not found")

    # 1. Enrolled students
    enrollments = db.query(models.StudentEnrollment).filter(
        models.StudentEnrollment.class_id == class_id,
        models.StudentEnrollment.enrollment_status == "active"
    ).all()
    students_list = []
    for e in enrollments:
        u = e.student
        students_list.append({
            "id": u.id,
            "username": u.username,
            "full_name": u.full_name,
            "email": u.email,
            "roll_number": u.roll_number,
            "section_name": e.section.name if e.section else "",
            "section_id": e.section_id,
            "contact_number": u.contact_number,
            "is_active": u.is_active,
        })
    if not students_list:
        for u in c.legacy_students:
            students_list.append({
                "id": u.id,
                "username": u.username,
                "full_name": u.full_name,
                "email": u.email,
                "roll_number": u.roll_number,
                "section_name": "Section A",
                "section_id": None,
                "contact_number": u.contact_number,
                "is_active": u.is_active,
            })

    # 2. Sections
    sections_list = [
        {"id": s.id, "name": s.name, "room_number": s.room_number, "class_id": s.class_id}
        for s in c.sections
    ]

    # 3. Assigned Teachers
    assignments = db.query(models.TeacherAssignment).filter(
        models.TeacherAssignment.class_id == class_id
    ).all()
    teachers_list = []
    for a in assignments:
        teachers_list.append({
            "assignment_id": a.id,
            "teacher_id": a.teacher_id,
            "teacher_name": a.teacher.full_name if a.teacher else "",
            "subject_id": a.subject_id,
            "subject_name": a.subject.name if a.subject else "",
            "section_name": a.section.name if a.section else "All Sections",
        })

    # 4. Subjects
    subjects_list = [
        {"id": s.id, "name": s.name, "code": s.code, "icon_color": s.icon_color}
        for s in c.subjects
    ]

    # 5. Lessons
    lessons = db.query(models.Lesson).filter(
        models.Lesson.class_id == class_id
    ).all()
    lessons_list = [
        {
            "id": l.id,
            "subject_name": l.subject.name if l.subject else "",
            "unit_title": l.unit.title if l.unit else "",
            "title": l.title,
            "material_count": len(l.materials),
        }
        for l in lessons
    ]

    return {
        "class_info": {"id": c.id, "name": c.name, "grade_level": c.grade_level},
        "overview": {
            "total_students": len(students_list),
            "total_sections": len(sections_list),
            "total_subjects": len(subjects_list),
            "total_teachers": len(set(t["teacher_id"] for t in teachers_list)),
            "academic_year": "2026-2027",
            "status": "Active",
        },
        "students": students_list,
        "sections": sections_list,
        "teachers": teachers_list,
        "subjects": subjects_list,
        "lessons": lessons_list,
    }

@router.post("/classes/{class_id}/sections", status_code=201)
def add_section_to_class(class_id: int, body: schemas.SectionCreate, db: Session = Depends(get_db), _=Depends(get_admin)):
    klass = db.query(models.Class).filter(models.Class.id == class_id).first()
    if not klass:
        raise HTTPException(404, "Class not found")
    name = body.name.strip()
    if not name:
        raise HTTPException(400, "Section name is required")
    existing_sections = db.query(models.Section).filter(
        models.Section.class_id == class_id
    ).all()
    if any(section.name.casefold() == name.casefold() for section in existing_sections):
        raise HTTPException(409, "Section already exists in this class")

    sec = models.Section(class_id=class_id, name=name, room_number=body.room_number)
    db.add(sec)
    db.commit()
    db.refresh(sec)
    return {"id": sec.id, "name": sec.name, "class_id": sec.class_id}

@router.post("/classes", status_code=201)
def create_class(body: schemas.ClassCreate, db: Session = Depends(get_db), _=Depends(get_admin)):
    name = body.name.strip()
    if not name:
        raise HTTPException(400, "Class name is required")
    existing_classes = db.query(models.Class).filter(
        models.Class.name.ilike(name)
    ).first()
    if existing_classes:
        raise HTTPException(409, "Class already exists")

    klass = models.Class(name=name, grade_level=body.grade_level)
    db.add(klass)
    db.commit()
    db.refresh(klass)
    return {"id": klass.id, "name": klass.name, "grade_level": klass.grade_level}


# ── Global Student Directory & Student Workflows ─────────────────────────────
@router.get("/students")
def list_students_directory(
    q: Optional[str] = None,
    class_id: Optional[int] = None,
    section_id: Optional[int] = None,
    is_active: Optional[bool] = None,
    db: Session = Depends(get_db),
    _=Depends(get_admin),
):
    query = db.query(models.User).filter(models.User.role == "student")
    if is_active is not None:
        query = query.filter(models.User.is_active == is_active)
    if q:
        query = query.filter(
            (models.User.full_name.ilike(f"%{q}%")) |
            (models.User.username.ilike(f"%{q}%")) |
            (models.User.roll_number.ilike(f"%{q}%")) |
            (models.User.email.ilike(f"%{q}%"))
        )

    students = query.all()
    results = []
    for s in students:
        # Find active enrollment
        curr_enroll = next((e for e in s.enrollments if e.enrollment_status == "active"), None)
        c_id = curr_enroll.class_id if curr_enroll else s.class_id
        sec_id = curr_enroll.section_id if curr_enroll else None

        if class_id and c_id != class_id:
            continue
        if section_id and sec_id != section_id:
            continue

        c_name = curr_enroll.klass.name if (curr_enroll and curr_enroll.klass) else (s.klass.name if s.klass else "")
        sec_name = curr_enroll.section.name if (curr_enroll and curr_enroll.section) else ""

        history = [
            {
                "academic_year": e.academic_year.name if e.academic_year else "",
                "class_name": e.klass.name if e.klass else "",
                "section_name": e.section.name if e.section else "",
                "status": e.enrollment_status,
            }
            for e in s.enrollments
        ]

        results.append({
            "id": s.id,
            "username": s.username,
            "full_name": s.full_name,
            "email": s.email,
            "role": "student",
            "class_id": c_id,
            "class_name": c_name,
            "section_id": sec_id,
            "section_name": sec_name,
            "roll_number": s.roll_number or "",
            "date_of_birth": s.date_of_birth or "",
            "contact_number": s.contact_number or "",
            "parent_name": s.parent_name or "",
            "parent_contact": s.parent_contact or "",
            "is_active": s.is_active,
            "enrollment_history": history,
        })

    return {"students": results}

@router.post("/students", status_code=201)
def create_student(body: schemas.UserCreate, db: Session = Depends(get_db), _=Depends(get_admin)):
    username = body.username.strip()
    full_name = body.full_name.strip()
    if not username:
        raise HTTPException(400, "Username is required")
    if not full_name:
        raise HTTPException(400, "Full name is required")
    if db.query(models.User).filter(models.User.username.ilike(username)).first():
        raise HTTPException(400, "Username already exists")
    if body.email and db.query(models.User).filter(models.User.email.ilike(body.email)).first():
        raise HTTPException(400, "Email already exists")

    klass = db.query(models.Class).filter(models.Class.id == body.class_id).first()
    if not klass:
        raise HTTPException(404, "Class not found")
    if body.section_id is not None:
        section = db.query(models.Section).filter(
            models.Section.id == body.section_id,
            models.Section.class_id == body.class_id,
        ).first()
        if not section:
            raise HTTPException(400, "The selected section does not belong to this class")
    if body.roll_number and db.query(models.User).filter(
        models.User.class_id == body.class_id,
        models.User.roll_number == body.roll_number,
    ).first():
        raise HTTPException(409, "Roll number already exists in this class")

    active_ay = db.query(models.AcademicYear).filter(models.AcademicYear.is_active == True).first()
    if not active_ay:
        active_ay = db.query(models.AcademicYear).first()
    if not active_ay:
        raise HTTPException(400, "Create an academic year before enrolling students")

    student = models.User(
        username=body.username,
        hashed_password=hash_password(body.password),
        full_name=body.full_name,
        email=body.email,
        role="student",
        class_id=body.class_id,
        roll_number=body.roll_number,
        date_of_birth=body.date_of_birth,
        contact_number=body.contact_number,
        parent_name=body.parent_name,
        parent_contact=body.parent_contact,
        is_active=True,
    )
    db.add(student)
    try:
        db.flush()
        db.add(models.StudentEnrollment(
            student_id=student.id,
            academic_year_id=active_ay.id,
            class_id=body.class_id,
            section_id=body.section_id,
            enrollment_status="active",
        ))
        student.enrolled_subjects = klass.subjects
        db.commit()
    except Exception:
        db.rollback()
        raise
    db.refresh(student)

    return {"id": student.id, "username": student.username, "full_name": student.full_name}

@router.post("/students/import", status_code=201)
def bulk_import_students(body: schemas.BulkStudentImportRequest, db: Session = Depends(get_db), _=Depends(get_admin)):
    active_ay = db.query(models.AcademicYear).filter(models.AcademicYear.is_active == True).first()
    klass = db.query(models.Class).filter(models.Class.id == body.class_id).first()
    if not klass:
        raise HTTPException(404, "Class not found")

    # Map section names to section IDs
    sec_map = {s.name.lower().strip(): s.id for s in klass.sections}

    created = 0
    errors = []

    for i, row in enumerate(body.students):
        # Validation checks
        if not row.full_name or not row.email or not row.roll_number:
            errors.append(f"Row {i+1}: Missing required fields")
            continue
        if db.query(models.User).filter(models.User.email == row.email).first():
            errors.append(f"Row {i+1}: Email {row.email} already exists")
            continue

        username = row.email.split("@")[0].lower()
        if db.query(models.User).filter(models.User.username == username).first():
            username = f"{username}_{row.roll_number.replace('-', '_')}"

        section_id = sec_map.get(row.section.lower().strip())
        if not section_id and klass.sections:
            section_id = klass.sections[0].id

        user = models.User(
            username=username,
            hashed_password=hash_password(f"student{row.roll_number}"),
            full_name=row.full_name,
            email=row.email,
            role="student",
            class_id=body.class_id,
            roll_number=row.roll_number,
            date_of_birth=row.date_of_birth,
            contact_number=row.contact_number,
            parent_name=row.parent_name,
            is_active=True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

        if active_ay:
            enroll = models.StudentEnrollment(
                student_id=user.id,
                academic_year_id=active_ay.id,
                class_id=body.class_id,
                section_id=section_id,
                enrollment_status="active",
            )
            db.add(enroll)
            user.enrolled_subjects = klass.subjects
            db.commit()

        created += 1

    return {"ok": True, "created_count": created, "errors": errors}

@router.put("/students/{student_id}/status")
def toggle_student_status(student_id: int, is_active: bool, db: Session = Depends(get_db), _=Depends(get_admin)):
    s = db.query(models.User).filter(models.User.id == student_id, models.User.role == "student").first()
    if not s:
        raise HTTPException(404, "Student not found")
    s.is_active = is_active
    db.commit()
    return {"id": s.id, "is_active": s.is_active}

@router.get("/users")
def list_all_users(
    role: Optional[str] = None,
    db: Session = Depends(get_db),
    _=Depends(get_admin),
):
    query = db.query(models.User)
    if role:
        query = query.filter(models.User.role == role)
    users = query.all()
    results = []
    for u in users:
        results.append({
            "id": u.id,
            "username": u.username,
            "full_name": u.full_name,
            "email": u.email,
            "role": u.role,
            "class_id": u.class_id,
            "class_name": u.klass.name if u.klass else "",
            "roll_number": u.roll_number or "",
            "contact_number": u.contact_number or "",
            "is_active": u.is_active,
        })
    return {"users": results}

@router.post("/users", status_code=201)
def create_any_user(
    body: schemas.UserCreate,
    db: Session = Depends(get_db),
    _=Depends(get_admin),
):
    username = body.username.strip()
    full_name = body.full_name.strip()
    role = body.role.strip().lower()
    if not username:
        raise HTTPException(400, "Username is required")
    if not full_name:
        raise HTTPException(400, "Full name is required")
    if role not in {"admin", "teacher", "student"}:
        raise HTTPException(400, "Role must be admin, teacher, or student")
    if db.query(models.User).filter(models.User.username.ilike(username)).first():
        raise HTTPException(400, "Username already exists")
    if body.email and db.query(models.User).filter(models.User.email.ilike(body.email)).first():
        raise HTTPException(400, "Email already exists")

    if role == "student":
        if body.class_id is None:
            raise HTTPException(400, "Students must belong to a class")
        klass = db.query(models.Class).filter(models.Class.id == body.class_id).first()
        if not klass:
            raise HTTPException(404, "Class not found")
        if body.section_id is not None:
            section = db.query(models.Section).filter(
                models.Section.id == body.section_id,
                models.Section.class_id == body.class_id,
            ).first()
            if not section:
                raise HTTPException(400, "The selected section does not belong to this class")
        if body.roll_number and db.query(models.User).filter(
            models.User.class_id == body.class_id,
            models.User.roll_number == body.roll_number,
        ).first():
            raise HTTPException(409, "Roll number already exists in this class")

    user = models.User(
        username=username,
        hashed_password=hash_password(body.password),
        full_name=full_name,
        email=body.email,
        role=role,
        class_id=body.class_id,
        roll_number=body.roll_number,
        date_of_birth=body.date_of_birth,
        contact_number=body.contact_number,
        parent_name=body.parent_name,
        parent_contact=body.parent_contact,
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    if role == "student" and body.class_id:
        active_ay = db.query(models.AcademicYear).filter(models.AcademicYear.is_active == True).first()
        if not active_ay:
            active_ay = db.query(models.AcademicYear).first()
        if active_ay:
            enroll = models.StudentEnrollment(
                student_id=user.id,
                academic_year_id=active_ay.id,
                class_id=body.class_id,
                section_id=body.section_id,
                enrollment_status="active",
            )
            db.add(enroll)
            klass = db.query(models.Class).filter(models.Class.id == body.class_id).first()
            if klass:
                user.enrolled_subjects = klass.subjects
            db.commit()

    return {"id": user.id, "username": user.username, "full_name": user.full_name, "role": user.role}

@router.delete("/users/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db), _=Depends(get_admin)):
    u = db.query(models.User).filter(models.User.id == user_id).first()
    if not u:
        raise HTTPException(404, "User not found")
    # Clean up assignments or enrollments if needed
    db.query(models.TeacherAssignment).filter(models.TeacherAssignment.teacher_id == user_id).delete()
    db.query(models.StudentEnrollment).filter(models.StudentEnrollment.student_id == user_id).delete()
    db.delete(u)
    db.commit()
    return {"ok": True, "deleted_user_id": user_id}


# ── Teacher Directory & Assignment Workflows ─────────────────────────────────
@router.post("/teachers", status_code=201)
def create_teacher(
    body: schemas.TeacherCreate,
    db: Session = Depends(get_db),
    _=Depends(get_admin),
):
    username = body.username.strip()
    full_name = body.full_name.strip()
    if not username:
        raise HTTPException(400, "Username is required")
    if not full_name:
        raise HTTPException(400, "Full name is required")
    if db.query(models.User).filter(models.User.username.ilike(username)).first():
        raise HTTPException(400, "Username already exists")
    if body.email and db.query(models.User).filter(models.User.email.ilike(body.email)).first():
        raise HTTPException(400, "Email already exists")

    assignment = None
    if (body.class_id is None) != (body.subject_id is None):
        raise HTTPException(400, "Select both a class and a subject for an assignment")
    if body.class_id is not None and body.subject_id is not None:
        klass = db.query(models.Class).filter(models.Class.id == body.class_id).first()
        if not klass:
            raise HTTPException(404, "Class not found")
        subject = db.query(models.Subject).filter(
            models.Subject.id == body.subject_id
        ).first()
        if not subject:
            raise HTTPException(404, "Subject not found")
        if subject not in klass.subjects and subject.class_id != klass.id:
            raise HTTPException(400, "The selected subject is not assigned to this class")
        if body.section_id is not None and not db.query(models.Section).filter(
            models.Section.id == body.section_id,
            models.Section.class_id == body.class_id,
        ).first():
            raise HTTPException(400, "The selected section does not belong to this class")
        academic_year = db.query(models.AcademicYear).filter(
            models.AcademicYear.is_active == True
        ).first() or db.query(models.AcademicYear).first()
        if not academic_year:
            raise HTTPException(400, "Create an academic year before assigning teachers")
        assignment = (klass, subject, academic_year)

    teacher = models.User(
        username=username,
        hashed_password=hash_password(body.password),
        full_name=full_name,
        email=body.email or f"{username}@academyalys.com",
        role="teacher",
        contact_number=body.contact_number,
        is_active=True,
    )
    db.add(teacher)
    try:
        db.flush()
        if assignment is not None:
            klass, subject, academic_year = assignment
            assign = models.TeacherAssignment(
                teacher_id=teacher.id,
                academic_year_id=academic_year.id,
                class_id=klass.id,
                subject_id=subject.id,
                section_id=body.section_id,
            )
            db.add(assign)
            if subject not in teacher.taught_subjects:
                teacher.taught_subjects.append(subject)
        db.commit()
    except Exception:
        db.rollback()
        raise
    db.refresh(teacher)

    return {
        "id": teacher.id,
        "username": teacher.username,
        "full_name": teacher.full_name,
        "email": teacher.email,
        "role": teacher.role,
    }

@router.get("/teachers")
def list_teachers_directory(db: Session = Depends(get_db), _=Depends(get_admin)):
    teachers = db.query(models.User).filter(models.User.role == "teacher").all()
    results = []
    for t in teachers:
        # Get assigned classes and subjects
        assignments = db.query(models.TeacherAssignment).filter(
            models.TeacherAssignment.teacher_id == t.id
        ).all()

        class_names = list(set([a.klass.name for a in assignments if a.klass]))
        subject_names = list(set([a.subject.name for a in assignments if a.subject]))

        # Include legacy taught subjects
        if not subject_names:
            subject_names = [s.name for s in t.taught_subjects]

        results.append({
            "id": t.id,
            "username": t.username,
            "full_name": t.full_name,
            "email": t.email,
            "contact_number": t.contact_number or "",
            "is_active": t.is_active,
            "date_added": t.created_at.strftime("%Y-%m-%d") if t.created_at else "",
            "assigned_classes": class_names,
            "assigned_subjects": subject_names,
            "assignments_count": len(assignments),
        })

    return {"teachers": results}

@router.post("/teachers/assign", status_code=201)
def assign_teacher_to_class_subject(
    body: schemas.TeacherAssignmentCreate,
    db: Session = Depends(get_db),
    _=Depends(get_admin),
):
    teacher = db.query(models.User).filter(models.User.id == body.teacher_id, models.User.role == "teacher").first()
    if not teacher:
        raise HTTPException(404, "Teacher not found")
    klass = db.query(models.Class).filter(models.Class.id == body.class_id).first()
    if not klass:
        raise HTTPException(404, "Class not found")
    subject = db.query(models.Subject).filter(models.Subject.id == body.subject_id).first()
    if not subject:
        raise HTTPException(404, "Subject not found")

    active_ay = db.query(models.AcademicYear).filter(models.AcademicYear.is_active == True).first()
    ay_id = body.academic_year_id or (active_ay.id if active_ay else 1)

    # Check if duplicate assignment
    existing = db.query(models.TeacherAssignment).filter(
        models.TeacherAssignment.teacher_id == body.teacher_id,
        models.TeacherAssignment.class_id == body.class_id,
        models.TeacherAssignment.subject_id == body.subject_id,
        models.TeacherAssignment.academic_year_id == ay_id,
    ).first()

    if existing:
        return {"ok": True, "message": "Assignment already exists"}

    assign = models.TeacherAssignment(
        teacher_id=body.teacher_id,
        academic_year_id=ay_id,
        class_id=body.class_id,
        subject_id=body.subject_id,
        section_id=body.section_id,
    )
    db.add(assign)
    db.commit()
    return {"ok": True, "assignment_id": assign.id}


# ── Curriculum Subjects & Lessons ─────────────────────────────────────────────
@router.get("/subjects")
def list_curriculum_subjects(db: Session = Depends(get_db), _=Depends(get_admin)):
    subjects = db.query(models.Subject).all()
    results = []
    for s in subjects:
        teachers = db.query(models.TeacherAssignment).filter(models.TeacherAssignment.subject_id == s.id).all()
        t_infos = [{"id": a.teacher.id, "full_name": a.teacher.full_name} for a in teachers if a.teacher]
        results.append({
            "id": s.id,
            "name": s.name,
            "code": s.code,
            "icon_color": s.icon_color,
            "description": s.description or "",
            "classes": [c.name for c in s.classes],
            "teachers": t_infos,
            "teacher": {"id": s.teacher.id, "full_name": s.teacher.full_name} if s.teacher else None,
        })
    return {"subjects": results}

@router.post("/subjects", status_code=201)
def create_curriculum_subject(body: schemas.SubjectCreate, db: Session = Depends(get_db), _=Depends(get_admin)):
    name = (body.name or "").strip()
    code = (body.code or "").strip().upper()
    if not name:
        raise HTTPException(400, "Subject name is required")
    if not code:
        raise HTTPException(400, "Subject code is required")
    if db.query(models.Subject).filter(models.Subject.code.ilike(code)).first():
        raise HTTPException(409, "Subject code already exists")
    if db.query(models.Subject).filter(models.Subject.name.ilike(name)).first():
        raise HTTPException(409, "Subject name already exists")

    target_class_ids = list(dict.fromkeys((body.class_ids or []) if body.class_ids else ([body.class_id] if body.class_id else [])))
    classes = []
    if target_class_ids:
        classes = db.query(models.Class).filter(
            models.Class.id.in_(target_class_ids)
        ).all()
        if len(classes) != len(set(target_class_ids)):
            raise HTTPException(404, "One or more selected classes were not found")

    sub = models.Subject(
        name=name,
        code=code,
        icon_color=body.icon_color or "#4F46E5",
        description=(body.description or "").strip(),
    )
    db.add(sub)
    try:
        sub.classes.extend(classes)
        db.commit()
    except Exception:
        db.rollback()
        raise
    db.refresh(sub)

    return {"id": sub.id, "name": sub.name, "code": sub.code}


# ── Materials & Publishing Workflow ──────────────────────────────────────────
@router.get("/materials")
def list_all_materials(
    class_id: Optional[int] = None,
    publication_status: Optional[str] = None,
    db: Session = Depends(get_db),
    _=Depends(get_admin),
):
    query = db.query(models.Material)
    if publication_status:
        query = query.filter(models.Material.publication_status == publication_status)
    materials = query.all()

    results = []
    for m in materials:
        lesson = m.lesson
        subject = lesson.subject if lesson else None
        klass = lesson.subject.classes[0] if (subject and subject.classes) else (lesson.subject.legacy_klass if subject else None)

        if class_id and (not klass or klass.id != class_id):
            continue

        results.append({
            "id": m.id,
            "title": m.title,
            "material_type": m.material_type,
            "file_type": m.file_type,
            "publication_status": m.publication_status,
            "uploaded_by": m.uploader.full_name if m.uploader else "",
            "lesson_id": m.lesson_id,
            "lesson_title": lesson.title if lesson else "",
            "subject_name": subject.name if subject else "",
            "class_name": klass.name if klass else "Class 10",
            "duration": m.duration,
            "uploaded_at": m.uploaded_at.isoformat() if m.uploaded_at else "",
        })

    return {"materials": results}

@router.put("/materials/{material_id}/publish")
def set_material_publication_status(
    material_id: int,
    status: str = Query("published"),  # published | draft
    db: Session = Depends(get_db),
    _=Depends(get_admin),
):
    m = db.query(models.Material).filter(models.Material.id == material_id).first()
    if not m:
        raise HTTPException(404, "Material not found")
    m.publication_status = status
    db.commit()
    return {"id": m.id, "publication_status": m.publication_status}


# ── Announcements & Timetable ────────────────────────────────────────────────
@router.get("/announcements")
def list_announcements(db: Session = Depends(get_db), _=Depends(get_admin)):
    ann = db.query(models.Announcement).order_by(models.Announcement.created_at.desc()).all()
    return {
        "announcements": [
            {
                "id": a.id,
                "title": a.title,
                "content": a.content,
                "target_role": a.target_role,
                "created_at": a.created_at.isoformat(),
            }
            for a in ann
        ]
    }

@router.post("/announcements", status_code=201)
def create_announcement(title: str, content: str, target_role: str = "all", db: Session = Depends(get_db), _=Depends(get_admin)):
    a = models.Announcement(title=title, content=content, target_role=target_role)
    db.add(a)
    db.commit()
    db.refresh(a)
    return {"id": a.id, "title": a.title}

@router.get("/timetable")
def get_admin_timetable(class_id: int = 5, db: Session = Depends(get_db), _=Depends(get_admin)):
    entries = db.query(models.TimetableEntry).filter(models.TimetableEntry.class_id == class_id).all()
    return {
        "timetable": [
            {
                "id": t.id,
                "day_of_week": t.day_of_week,
                "period_number": t.period_number,
                "start_time": t.start_time,
                "end_time": t.end_time,
                "subject_id": t.subject_id,
                "room": t.room,
            }
            for t in entries
        ]
    }
