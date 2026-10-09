import os
from datetime import datetime

from . import models
from .auth import hash_password
from .database import Base, SessionLocal, engine


def create_initial_admin() -> None:
    username = os.getenv("ADMIN_USERNAME", "").strip()
    password = os.getenv("ADMIN_PASSWORD", "")
    email = os.getenv("ADMIN_EMAIL", "").strip() or None

    if not username or len(password) < 12:
        raise RuntimeError(
            "Set ADMIN_USERNAME and an ADMIN_PASSWORD of at least 12 characters."
        )

    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        existing_user = (
            db.query(models.User)
            .filter(models.User.username == username)
            .first()
        )
        if existing_user:
            if existing_user.role != "admin":
                raise RuntimeError(
                    "ADMIN_USERNAME is already assigned to a non-admin account."
                )
        elif email and db.query(models.User).filter(models.User.email == email).first():
            raise RuntimeError("ADMIN_EMAIL is already assigned to another account.")

        if not existing_user:
            db.add(
                models.User(
                    username=username,
                    full_name="System Administrator",
                    email=email,
                    hashed_password=hash_password(password),
                    role="admin",
                    is_active=True,
                )
            )

        academic_year = db.query(models.AcademicYear).filter(
            models.AcademicYear.is_active.is_(True)
        ).first()
        if not academic_year:
            now = datetime.now()
            start_year = now.year if now.month >= 6 else now.year - 1
            db.add(
                models.AcademicYear(
                    name=f"{start_year}-{start_year + 1}",
                    is_active=True,
                )
            )

        classes = db.query(models.Class).all()
        if not classes:
            classes_by_grade = {}
            for grade in range(6, 11):
                klass = models.Class(name=f"Class {grade}", grade_level=grade)
                db.add(klass)
                classes_by_grade[grade] = klass
            db.flush()

            for grade, klass in classes_by_grade.items():
                section_names = ("Section A", "Section B") if grade >= 9 else ("Section A",)
                for section_name in section_names:
                    db.add(models.Section(class_id=klass.id, name=section_name))

            subjects = [
                models.Subject(name="English", code="ENG"),
                models.Subject(name="Mathematics", code="MATH"),
                models.Subject(name="Science", code="SCI"),
                models.Subject(name="Social Science", code="SOC"),
                models.Subject(name="Tamil", code="TAM"),
            ]
            db.add_all(subjects)
            db.flush()
            for grade, klass in classes_by_grade.items():
                klass.subjects.extend(
                    subjects if grade >= 9 else subjects[:3]
                )

        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    create_initial_admin()
