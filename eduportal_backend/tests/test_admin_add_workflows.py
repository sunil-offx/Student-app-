import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app import models, schemas
from app.database import Base
from app import bootstrap_admin
from app.routers.admin_router import (
    add_section_to_class,
    create_class,
    create_student,
    create_teacher,
)


@pytest.fixture
def db():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    session_factory = sessionmaker(bind=engine)
    session = session_factory()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)
        engine.dispose()


def test_create_section_requires_existing_class_and_unique_name(db: Session):
    klass = models.Class(name="Class 10", grade_level=10)
    db.add(klass)
    db.commit()

    section = add_section_to_class(
        klass.id,
        schemas.SectionCreate(class_id=klass.id, name=" Section A "),
        db,
    )
    assert section["name"] == "Section A"

    with pytest.raises(HTTPException) as error:
        add_section_to_class(
            klass.id,
            schemas.SectionCreate(class_id=klass.id, name="section a"),
            db,
        )
    assert error.value.status_code == 409


def test_create_student_persists_user_enrollment_and_class_subjects(db: Session):
    academic_year = models.AcademicYear(name="2026-2027", is_active=True)
    klass = models.Class(name="Class 10", grade_level=10)
    subject = models.Subject(name="English", code="ENG")
    db.add_all([academic_year, klass, subject])
    db.flush()
    section = models.Section(class_id=klass.id, name="Section A")
    klass.subjects.append(subject)
    db.add(section)
    db.commit()

    result = create_student(
        schemas.UserCreate(
            username="student.one",
            password="StudentPass123",
            full_name="Student One",
            email="student.one@example.com",
            role="student",
            class_id=klass.id,
            section_id=section.id,
        ),
        db,
    )

    student = db.query(models.User).filter_by(id=result["id"]).one()
    assert student.role == "student"
    assert student.enrollments[0].academic_year_id == academic_year.id
    assert student.enrollments[0].section_id == section.id
    assert [item.id for item in student.enrolled_subjects] == [subject.id]


def test_create_student_rejects_section_from_another_class(db: Session):
    academic_year = models.AcademicYear(name="2026-2027", is_active=True)
    first_class = models.Class(name="Class 9", grade_level=9)
    second_class = models.Class(name="Class 10", grade_level=10)
    db.add_all([academic_year, first_class, second_class])
    db.flush()
    section = models.Section(class_id=second_class.id, name="Section A")
    db.add(section)
    db.commit()

    with pytest.raises(HTTPException) as error:
        create_student(
            schemas.UserCreate(
                username="student.two",
                password="StudentPass123",
                full_name="Student Two",
                role="student",
                class_id=first_class.id,
                section_id=section.id,
            ),
            db,
        )
    assert error.value.status_code == 400
    assert db.query(models.User).filter_by(username="student.two").count() == 0


def test_create_teacher_rejects_subject_outside_selected_class(db: Session):
    academic_year = models.AcademicYear(name="2026-2027", is_active=True)
    first_class = models.Class(name="Class 9", grade_level=9)
    second_class = models.Class(name="Class 10", grade_level=10)
    subject = models.Subject(name="English", code="ENG")
    second_class.subjects.append(subject)
    db.add_all([academic_year, first_class, second_class, subject])
    db.commit()

    with pytest.raises(HTTPException) as error:
        create_teacher(
            schemas.TeacherCreate(
                username="teacher.one",
                password="TeacherPass123",
                full_name="Teacher One",
                class_id=first_class.id,
                subject_id=subject.id,
            ),
            db,
        )
    assert error.value.status_code == 400
    assert db.query(models.User).filter_by(username="teacher.one").count() == 0


def test_create_class_rejects_duplicate_names_case_insensitively(db: Session):
    db.add(models.Class(name="Class 10", grade_level=10))
    db.commit()

    with pytest.raises(HTTPException) as error:
        create_class(schemas.ClassCreate(name=" class 10 "), db)
    assert error.value.status_code == 409


def test_render_bootstrap_is_idempotent_and_does_not_seed_demo_accounts(
    monkeypatch,
):
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    session_factory = sessionmaker(bind=engine)
    monkeypatch.setattr(bootstrap_admin, "engine", engine)
    monkeypatch.setattr(bootstrap_admin, "SessionLocal", session_factory)
    monkeypatch.setenv("ADMIN_USERNAME", "initial-admin")
    monkeypatch.setenv("ADMIN_PASSWORD", "A-strong-test-password")
    monkeypatch.setenv("ADMIN_EMAIL", "admin@example.com")

    bootstrap_admin.create_initial_admin()
    bootstrap_admin.create_initial_admin()

    with session_factory() as db:
        assert db.query(models.User).count() == 1
        assert db.query(models.User).filter_by(role="admin").count() == 1
        assert db.query(models.Class).count() == 5
        assert db.query(models.Section).count() == 7
        assert db.query(models.Subject).count() == 5
        assert db.query(models.AcademicYear).filter_by(is_active=True).count() == 1
    engine.dispose()
