# eduportal_backend/app/seed.py
import os
from datetime import datetime, timedelta
from .database import engine, SessionLocal, Base
from .models import (
    User, Class, Section, AcademicYear, Subject, class_subjects,
    StudentEnrollment, TeacherAssignment, Unit, Lesson, Material,
    Assignment, AssignmentSubmission, Quiz, QuizQuestion,
    Flashcard, FlashcardItem, Mindmap, MindmapBranch,
    Announcement, TimetableEntry
)
from .auth import hash_password

def seed_database():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # Check if already seeded with AcademyAlys data
        admin_check = db.query(User).filter(User.username == "admin").first()
        if admin_check:
            c10 = db.query(Class).filter(Class.name == "Class 10").first()
            if c10:
                print("AcademyAlys database is up to date.")
                return
        Base.metadata.drop_all(bind=engine)
        Base.metadata.create_all(bind=engine)

        print("Seeding AcademyAlys academic LMS platform...")

        # ── 1. Academic Years ────────────────────────────────────────────────
        ay_prev = AcademicYear(name="2025-2026", is_active=False)
        ay_curr = AcademicYear(name="2026-2027", is_active=True)
        db.add_all([ay_prev, ay_curr])
        db.commit()
        db.refresh(ay_prev)
        db.refresh(ay_curr)

        # ── 2. Classes 6 to 10 (Project Scope: Classes 6–10) ──────────────────
        classes = {}
        for g in range(6, 11):
            c = Class(name=f"Class {g}", grade_level=g)
            db.add(c)
            classes[g] = c
        db.commit()
        for g in range(6, 11):
            db.refresh(classes[g])

        # ── 3. Sections ───────────────────────────────────────────────────────
        sections = {}
        # Class 10: Section A, Section B
        sec_10a = Section(class_id=classes[10].id, name="Section A", room_number="Room 101")
        sec_10b = Section(class_id=classes[10].id, name="Section B", room_number="Room 102")
        # Class 9: Section A, Section B
        sec_9a = Section(class_id=classes[9].id, name="Section A", room_number="Room 201")
        sec_9b = Section(class_id=classes[9].id, name="Section B", room_number="Room 202")
        # Class 8, 7, 6: Section A
        sec_8a = Section(class_id=classes[8].id, name="Section A", room_number="Room 301")
        sec_7a = Section(class_id=classes[7].id, name="Section A", room_number="Room 302")
        sec_6a = Section(class_id=classes[6].id, name="Section A", room_number="Room 401")
        
        db.add_all([sec_10a, sec_10b, sec_9a, sec_9b, sec_8a, sec_7a, sec_6a])
        db.commit()
        db.refresh(sec_10a)
        db.refresh(sec_10b)
        db.refresh(sec_9a)
        db.refresh(sec_8a)

        # ── 4. Subjects ───────────────────────────────────────────────────────
        # Subjects across curriculum
        sub_eng = Subject(name="English", code="ENG", icon_color="#4F46E5", description="Literature, grammar, comprehension and creative writing")
        sub_math = Subject(name="Mathematics", code="MATH", icon_color="#0EA5E9", description="Algebra, Geometry, Trigonometry, and Statistics")
        sub_sci = Subject(name="Science", code="SCI", icon_color="#10B981", description="Physics, Chemistry, and Biology fundamentals")
        sub_soc = Subject(name="Social Science", code="SOC", icon_color="#F59E0B", description="History, Geography, Political Science, and Economics")
        sub_tam = Subject(name="Tamil", code="TAM", icon_color="#EC4899", description="Language literature, poetry, and grammar")

        db.add_all([sub_eng, sub_math, sub_sci, sub_soc, sub_tam])
        db.commit()
        for s in [sub_eng, sub_math, sub_sci, sub_soc, sub_tam]:
            db.refresh(s)

        # Map subjects to classes (class_subjects mapping)
        # Class 10 has all 5
        classes[10].subjects.extend([sub_eng, sub_math, sub_sci, sub_soc, sub_tam])
        # Class 9 has all 5
        classes[9].subjects.extend([sub_eng, sub_math, sub_sci, sub_soc, sub_tam])
        # Classes 6, 7, 8 have English, Math, Science
        for g in [6, 7, 8]:
            classes[g].subjects.extend([sub_eng, sub_math, sub_sci])
        db.commit()

        # Legacy class_id link for backward-compat
        sub_eng.class_id = classes[10].id
        sub_math.class_id = classes[10].id
        sub_sci.class_id = classes[10].id
        db.commit()

        # ── 5. Users (Admin, Teachers, Students) ───────────────────────────────
        # Admin
        admin_user = User(
            username="admin",
            full_name="System Administrator",
            email="admin@academyalys.com",
            hashed_password=hash_password("admin123"),
            role="admin",
            is_active=True
        )

        # Teachers
        # Teacher Priya: Assigned to Class 10 English & Class 9 English
        t_priya = User(
            username="priya",
            full_name="Ms. Priya",
            email="priya@academyalys.com",
            hashed_password=hash_password("priya123"),
            role="teacher",
            contact_number="+91 98765 43210",
            is_active=True
        )

        # Teacher Rajesh: Assigned to Class 10 Math & Class 8 Math
        t_rajesh = User(
            username="rajesh",
            full_name="Mr. Rajesh Kumar",
            email="rajesh@academyalys.com",
            hashed_password=hash_password("rajesh123"),
            role="teacher",
            contact_number="+91 98765 43211",
            is_active=True
        )

        # Teacher Geetha: Assigned to Class 10 Science
        t_geetha = User(
            username="geetha",
            full_name="Mrs. Geetha Raman",
            email="geetha@academyalys.com",
            hashed_password=hash_password("geetha123"),
            role="teacher",
            contact_number="+91 98765 43212",
            is_active=True
        )

        # Teacher Sarah: Assigned to Class 9 Science
        t_sarah = User(
            username="sarah",
            full_name="Ms. Sarah Jenkins",
            email="sarah@academyalys.com",
            hashed_password=hash_password("sarah123"),
            role="teacher",
            contact_number="+91 98765 43213",
            is_active=True
        )

        # Students
        # Student Rahul: Class 10 Section A (Historical: Class 9 in 2025-2026!)
        s_rahul = User(
            username="rahul",
            full_name="Rahul Sharma",
            email="rahul@student.academyalys.com",
            hashed_password=hash_password("rahul123"),
            role="student",
            class_id=classes[10].id,
            roll_number="10-A-01",
            date_of_birth="2010-05-14",
            contact_number="+91 98401 23456",
            parent_name="Venkatesh Sharma",
            parent_contact="+91 98401 11111",
            is_active=True
        )

        # Student Ananya: Class 9 Section A
        s_ananya = User(
            username="ananya",
            full_name="Ananya Sundaram",
            email="ananya@student.academyalys.com",
            hashed_password=hash_password("ananya123"),
            role="student",
            class_id=classes[9].id,
            roll_number="09-A-04",
            date_of_birth="2011-08-22",
            contact_number="+91 98402 34567",
            parent_name="Sundaram Ramaswamy",
            parent_contact="+91 98402 22222",
            is_active=True
        )

        # Student Vikram: Class 8 Section A
        s_vikram = User(
            username="vikram",
            full_name="Vikram Patel",
            email="vikram@student.academyalys.com",
            hashed_password=hash_password("vikram123"),
            role="student",
            class_id=classes[8].id,
            roll_number="08-A-12",
            date_of_birth="2012-03-10",
            contact_number="+91 98403 45678",
            parent_name="Kiran Patel",
            parent_contact="+91 98403 33333",
            is_active=True
        )

        # Student Meera: Class 10 Section B
        s_meera = User(
            username="meera",
            full_name="Meera Krishnan",
            email="meera@student.academyalys.com",
            hashed_password=hash_password("meera123"),
            role="student",
            class_id=classes[10].id,
            roll_number="10-B-08",
            date_of_birth="2010-11-19",
            contact_number="+91 98404 56789",
            parent_name="Krishnan Narayanan",
            parent_contact="+91 98404 44444",
            is_active=True
        )

        db.add_all([admin_user, t_priya, t_rajesh, t_geetha, t_sarah, s_rahul, s_ananya, s_vikram, s_meera])
        db.commit()
        for u in [admin_user, t_priya, t_rajesh, t_geetha, t_sarah, s_rahul, s_ananya, s_vikram, s_meera]:
            db.refresh(u)

        # Set primary legacy teacher
        sub_eng.teacher_id = t_priya.id
        sub_math.teacher_id = t_rajesh.id
        sub_sci.teacher_id = t_geetha.id
        db.commit()

        # ── 6. Student Enrollments (Historical preservation: Section 33.1) ────
        # Rahul: 2025-2026 -> Class 9 Section A (completed)
        #        2026-2027 -> Class 10 Section A (active)
        e_rahul_prev = StudentEnrollment(
            student_id=s_rahul.id,
            academic_year_id=ay_prev.id,
            class_id=classes[9].id,
            section_id=sec_9a.id,
            enrollment_status="completed"
        )
        e_rahul_curr = StudentEnrollment(
            student_id=s_rahul.id,
            academic_year_id=ay_curr.id,
            class_id=classes[10].id,
            section_id=sec_10a.id,
            enrollment_status="active"
        )
        e_ananya = StudentEnrollment(
            student_id=s_ananya.id,
            academic_year_id=ay_curr.id,
            class_id=classes[9].id,
            section_id=sec_9a.id,
            enrollment_status="active"
        )
        e_vikram = StudentEnrollment(
            student_id=s_vikram.id,
            academic_year_id=ay_curr.id,
            class_id=classes[8].id,
            section_id=sec_8a.id,
            enrollment_status="active"
        )
        e_meera = StudentEnrollment(
            student_id=s_meera.id,
            academic_year_id=ay_curr.id,
            class_id=classes[10].id,
            section_id=sec_10b.id,
            enrollment_status="active"
        )
        db.add_all([e_rahul_prev, e_rahul_curr, e_ananya, e_vikram, e_meera])
        db.commit()

        # Enrolled subjects for student Rahul & Meera
        s_rahul.enrolled_subjects.extend([sub_eng, sub_math, sub_sci, sub_soc, sub_tam])
        s_meera.enrolled_subjects.extend([sub_eng, sub_math, sub_sci, sub_soc, sub_tam])
        s_ananya.enrolled_subjects.extend([sub_eng, sub_math, sub_sci, sub_soc, sub_tam])
        s_vikram.enrolled_subjects.extend([sub_eng, sub_math, sub_sci])
        db.commit()

        # ── 7. Teacher Assignments (Explicit permissions: Section 15 & 24.2) ──
        # Teacher Priya: Class 10 -> English, Class 9 -> English
        ta_priya_10 = TeacherAssignment(
            teacher_id=t_priya.id,
            academic_year_id=ay_curr.id,
            class_id=classes[10].id,
            subject_id=sub_eng.id,
            section_id=sec_10a.id
        )
        ta_priya_9 = TeacherAssignment(
            teacher_id=t_priya.id,
            academic_year_id=ay_curr.id,
            class_id=classes[9].id,
            subject_id=sub_eng.id,
            section_id=sec_9a.id
        )
        # Teacher Rajesh: Class 10 -> Math, Class 8 -> Math
        ta_rajesh_10 = TeacherAssignment(
            teacher_id=t_rajesh.id,
            academic_year_id=ay_curr.id,
            class_id=classes[10].id,
            subject_id=sub_math.id,
            section_id=sec_10a.id
        )
        ta_rajesh_8 = TeacherAssignment(
            teacher_id=t_rajesh.id,
            academic_year_id=ay_curr.id,
            class_id=classes[8].id,
            subject_id=sub_math.id,
            section_id=sec_8a.id
        )
        # Teacher Geetha: Class 10 -> Science
        ta_geetha_10 = TeacherAssignment(
            teacher_id=t_geetha.id,
            academic_year_id=ay_curr.id,
            class_id=classes[10].id,
            subject_id=sub_sci.id,
            section_id=sec_10a.id
        )
        # Teacher Sarah: Class 9 -> Science
        ta_sarah_9 = TeacherAssignment(
            teacher_id=t_sarah.id,
            academic_year_id=ay_curr.id,
            class_id=classes[9].id,
            subject_id=sub_sci.id,
            section_id=sec_9a.id
        )

        db.add_all([ta_priya_10, ta_priya_9, ta_rajesh_10, ta_rajesh_8, ta_geetha_10, ta_sarah_9])
        db.commit()

        # ── 8. Units & Lessons for Class 10 English (Architecture doc match) ──
        # Academic Year: 2026-2027
        # Class: 10
        # Subject: English
        # Unit: Unit 1 - Prose
        # Lesson: A Letter to God
        unit_10_eng = Unit(
            subject_id=sub_eng.id,
            class_id=classes[10].id,
            title="Unit 1 - Prose",
            order_index=1
        )
        db.add(unit_10_eng)
        db.commit()
        db.refresh(unit_10_eng)

        lesson_10_l1 = Lesson(
            subject_id=sub_eng.id,
            class_id=classes[10].id,
            unit_id=unit_10_eng.id,
            title="Lesson 1: A Letter to God",
            description="Examine Lencho's unwavering faith in God, the devastation of the hailstorm, and the post office employees' compassionate deed.",
            order_index=1
        )
        lesson_10_l2 = Lesson(
            subject_id=sub_eng.id,
            class_id=classes[10].id,
            unit_id=unit_10_eng.id,
            title="Lesson 2: Nelson Mandela: Long Walk to Freedom",
            description="Autobiographical extract on the struggle against apartheid and the extraordinary courage of freedom fighters in South Africa.",
            order_index=2
        )
        db.add_all([lesson_10_l1, lesson_10_l2])
        db.commit()
        db.refresh(lesson_10_l1)
        db.refresh(lesson_10_l2)

        # ── 9. Learning Materials for Lesson 1: A Letter to God ───────────────
        # Matching exact counts from Architecture PDF Page 20 & 21:
        # Home/Summary 8, Videos 2, PDF Materials 3, PPT Presentations 1, Notes 2, Practice Questions 2
        upload_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads")
        os.makedirs(upload_dir, exist_ok=True)
        sample_pdf = os.path.join(upload_dir, "a_letter_to_god_study_guide.pdf")
        if not os.path.exists(sample_pdf):
            with open(sample_pdf, "wb") as f:
                f.write(b"%PDF-1.4 AcademyAlys Sample Study Notes - A Letter to God by G.L. Fuentes")

        materials = [
            # 2 Videos
            Material(
                lesson_id=lesson_10_l1.id,
                uploader_id=t_priya.id,
                title="Complete Explanation",
                description="Comprehensive line-by-line explanation, character motivations, and literary themes in English.",
                material_type="video",
                file_type="video",
                external_url="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                duration="24:15",
                publication_status="published"
            ),
            Material(
                lesson_id=lesson_10_l1.id,
                uploader_id=t_priya.id,
                title="Animated Story & Visual Summary",
                description="Visual depiction of Lencho's cornfield, the sudden hail storm, and the postmaster's heartwarming response.",
                material_type="video",
                file_type="video",
                external_url="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
                duration="12:30",
                publication_status="published"
            ),
            # 3 PDFs
            Material(
                lesson_id=lesson_10_l1.id,
                uploader_id=t_priya.id,
                title="Detailed Chapter Analysis & Questions",
                description="In-depth textual critique, character sketches, and CBSE board examination questions with model answers.",
                material_type="pdf",
                file_type="pdf",
                file_path="a_letter_to_god_study_guide.pdf",
                publication_status="published"
            ),
            Material(
                lesson_id=lesson_10_l1.id,
                uploader_id=t_priya.id,
                title="Vocabulary and Literary Devices",
                description="Analysis of irony, metaphors ('locusts plague', 'draped in a curtain of rain'), and synonyms.",
                material_type="pdf",
                file_type="pdf",
                file_path="a_letter_to_god_study_guide.pdf",
                publication_status="published"
            ),
            Material(
                lesson_id=lesson_10_l1.id,
                uploader_id=t_priya.id,
                title="NCERT Textbook Solutions & Answers",
                description="Official solutions to 'Thinking about the Text' and 'Oral Comprehension Check' questions.",
                material_type="pdf",
                file_type="pdf",
                file_path="a_letter_to_god_study_guide.pdf",
                publication_status="published"
            ),
            # 1 PPT
            Material(
                lesson_id=lesson_10_l1.id,
                uploader_id=t_priya.id,
                title="A Letter to God - Interactive Slide Deck",
                description="High-definition presentation deck used in lecture sessions with discussion prompts.",
                material_type="ppt",
                file_type="pptx",
                file_path="a_letter_to_god_slides.pptx",
                publication_status="published"
            ),
            # 2 Notes
            Material(
                lesson_id=lesson_10_l1.id,
                uploader_id=t_priya.id,
                title="Character Sketch of Lencho & Themes of Faith",
                description="Examines Lencho's innocence, single-minded devotion, and tragic irony in mistaking helpers for thieves.",
                material_type="notes",
                file_type="word",
                file_path="character_sketch_lencho.docx",
                publication_status="published"
            ),
            Material(
                lesson_id=lesson_10_l1.id,
                uploader_id=t_priya.id,
                title="Key Quotations & Board Examination Tips",
                description="Essential memory aids, high-scoring answer structures, and 5-mark long question templates.",
                material_type="notes",
                file_type="word",
                file_path="exam_tips_english10.docx",
                publication_status="published"
            ),
        ]
        db.add_all(materials)
        db.commit()

        # ── 10. Practice Questions / Quizzes for Lesson 1 (2 Quizzes) ─────────
        q1 = Quiz(
            subject_id=sub_eng.id,
            lesson_id=lesson_10_l1.id,
            title="A Letter to God - Comprehension Check",
            time_minutes=10
        )
        q2 = Quiz(
            subject_id=sub_eng.id,
            lesson_id=lesson_10_l1.id,
            title="Literary Devices & Irony Assessment",
            time_minutes=10
        )
        db.add_all([q1, q2])
        db.commit()
        db.refresh(q1)
        db.refresh(q2)

        q1_questions = [
            QuizQuestion(
                quiz_id=q1.id,
                question_text="What did Lencho hope for to save his ripe corn crops?",
                options=["A downpour or at least a shower", "Strong winds to dry the seeds", "New farm machinery", "A loan from the local bank"],
                correct_option_index=0,
                order_index=1
            ),
            QuizQuestion(
                quiz_id=q1.id,
                question_text="Why did Lencho describe the raindrops as new coins?",
                options=["Because they were shiny like silver", "Because rain promised a prosperous harvest", "Because rain was turning into ice coins", "Because he owed money to the post office"],
                correct_option_index=1,
                order_index=2
            ),
            QuizQuestion(
                quiz_id=q1.id,
                question_text="How much money did the postmaster manage to collect for Lencho?",
                options=["100 pesos", "70 pesos", "50 pesos", "30 pesos"],
                correct_option_index=1,
                order_index=3
            ),
            QuizQuestion(
                quiz_id=q1.id,
                question_text="What ironical term did Lencho use for the post office employees?",
                options=["God's angels", "A bunch of crooks", "Faithful servants", "Gentle souls"],
                correct_option_index=1,
                order_index=4
            ),
        ]
        q2_questions = [
            QuizQuestion(
                quiz_id=q2.id,
                question_text="What is the central irony of 'A Letter to God'?",
                options=[
                    "Lencho asked for money and got seeds instead",
                    "The people who helped Lencho were suspected of stealing from him",
                    "The postmaster ignored the letter",
                    "The storm actually made the harvest richer"
                ],
                correct_option_index=1,
                order_index=1
            ),
            QuizQuestion(
                quiz_id=q2.id,
                question_text="What metaphor did Lencho use for the hailstones?",
                options=["White diamonds", "Frozen pearls", "Silver coins", "Locust swarms"],
                correct_option_index=1,
                order_index=2
            ),
        ]
        db.add_all(q1_questions + q2_questions)
        db.commit()

        # ── 11. Science Lessons & Quizzes for Class 10 ─────────────────────────
        unit_10_sci = Unit(
            subject_id=sub_sci.id,
            class_id=classes[10].id,
            title="Unit 1 - Chemical Substances",
            order_index=1
        )
        db.add(unit_10_sci)
        db.commit()
        db.refresh(unit_10_sci)

        l_sci1 = Lesson(
            subject_id=sub_sci.id,
            class_id=classes[10].id,
            unit_id=unit_10_sci.id,
            title="Chemical Reactions and Equations",
            description="Master balancing chemical equations, displacement reactions, oxidation, and reduction.",
            order_index=1
        )
        l_sci2 = Lesson(
            subject_id=sub_sci.id,
            class_id=classes[10].id,
            unit_id=unit_10_sci.id,
            title="Acids, Bases and Salts",
            description="Examine indicators, pH scale, neutralization reactions, and practical salt preparations.",
            order_index=2
        )
        db.add_all([l_sci1, l_sci2])
        db.commit()
        db.refresh(l_sci1)

        # Materials for Science
        db.add(Material(
            lesson_id=l_sci1.id,
            uploader_id=t_geetha.id,
            title="Chemical Reactions Lecture Video",
            description="Visual laboratory demonstration of magnesium ribbon burning and displacement reactions.",
            material_type="video",
            file_type="video",
            external_url="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            duration="18:40",
            publication_status="published"
        ))
        db.add(Material(
            lesson_id=l_sci1.id,
            uploader_id=t_geetha.id,
            title="Balancing Equations Master Guide",
            description="Step-by-step balancing worksheet with 25 practice problems.",
            material_type="pdf",
            file_type="pdf",
            file_path="a_letter_to_god_study_guide.pdf",
            publication_status="published"
        ))
        db.commit()

        # Flashcards for Science
        fc = Flashcard(subject_id=sub_sci.id, lesson_id=l_sci1.id, title="Chemical Reactions Recall Decks")
        db.add(fc)
        db.commit()
        db.refresh(fc)
        db.add_all([
            FlashcardItem(flashcard_id=fc.id, front="What is an Exothermic reaction?", back="A chemical process that releases thermal energy into the environment.", order_index=1),
            FlashcardItem(flashcard_id=fc.id, front="What is a precipitate?", back="An insoluble solid that emerges from a liquid solution.", order_index=2),
            FlashcardItem(flashcard_id=fc.id, front="Define Oxidation (OIL).", back="Oxidation is the loss of electrons or gain of oxygen.", order_index=3),
        ])
        db.commit()

        # Mindmap for Science
        mm = Mindmap(subject_id=sub_sci.id, lesson_id=l_sci1.id, title="Types of Chemical Reactions", central_topic="Reactions")
        db.add(mm)
        db.commit()
        db.refresh(mm)
        db.add_all([
            MindmapBranch(mindmap_id=mm.id, label="Combination", sub_topics=["A + B -> AB", "Exothermic"], color="#4F46E5", order_index=1),
            MindmapBranch(mindmap_id=mm.id, label="Decomposition", sub_topics=["Thermal", "Electrolytic"], color="#0EA5E9", order_index=2),
            MindmapBranch(mindmap_id=mm.id, label="Displacement", sub_topics=["Reactivity Series", "Precipitation"], color="#10B981", order_index=3),
        ])
        db.commit()

        # ── 12. Announcements ────────────────────────────────────────────────
        announcements = [
            Announcement(
                title="Welcome to AcademyAlys Session 2026-2027",
                content="Welcome students and faculty to the new academic year. All course curricula for Classes 6 to 10 are now active.",
                target_role="all"
            ),
            Announcement(
                title="Class 10 Board Revision Sessions",
                content="Ms. Priya will conduct special English literature revision sessions this Saturday at 10:00 AM.",
                target_role="student",
                class_id=classes[10].id
            ),
            Announcement(
                title="Staff Curriculum Planning Meeting",
                content="All teachers handling Classes 6–10 are requested to review lesson modules and upload first term materials by Friday.",
                target_role="teacher"
            ),
        ]
        db.add_all(announcements)

        # ── 13. Timetable Entries for Class 10 Section A ──────────────────────
        timetable_data = [
            ("Monday", 1, "09:00", "09:45", sub_eng.id, t_priya.id, "Room 101"),
            ("Monday", 2, "09:45", "10:30", sub_math.id, t_rajesh.id, "Room 101"),
            ("Monday", 3, "10:45", "11:30", sub_sci.id, t_geetha.id, "Lab 2"),
            ("Monday", 4, "11:30", "12:15", sub_soc.id, None, "Room 101"),
            ("Monday", 5, "01:00", "01:45", sub_tam.id, None, "Room 101"),
            ("Tuesday", 1, "09:00", "09:45", sub_sci.id, t_geetha.id, "Lab 2"),
            ("Tuesday", 2, "09:45", "10:30", sub_eng.id, t_priya.id, "Room 101"),
            ("Tuesday", 3, "10:45", "11:30", sub_math.id, t_rajesh.id, "Room 101"),
        ]
        for day, period, start, end, s_id, teacher_id, room in timetable_data:
            db.add(TimetableEntry(
                class_id=classes[10].id,
                section_id=sec_10a.id,
                subject_id=s_id,
                teacher_id=teacher_id,
                day_of_week=day,
                period_number=period,
                start_time=start,
                end_time=end,
                room=room
            ))

        db.commit()

        print("AcademyAlys demo data seeded successfully!")
        print("=" * 60)
        print("Academic Structure Configured: Classes 6, 7, 8, 9, 10")
        print("Active Academic Year: 2026-2027 (with 2025-2026 historical records)")
        print("-" * 60)
        print("Demo User Credentials:")
        print("  ADMIN:   username='admin',   password='admin123'")
        print("  TEACHER: username='priya',   password='priya123'  (Class 10 & 9 English)")
        print("  TEACHER: username='rajesh',  password='rajesh123' (Class 10 & 8 Mathematics)")
        print("  TEACHER: username='geetha',  password='geetha123' (Class 10 Science)")
        print("  TEACHER: username='sarah',   password='sarah123'  (Class 9 Science)")
        print("  STUDENT: username='rahul',   password='rahul123'  (Class 10 Section A - English, Math, Science)")
        print("  STUDENT: username='ananya',  password='ananya123' (Class 9 Section A)")
        print("  STUDENT: username='vikram',  password='vikram123' (Class 8 Section A)")
        print("  STUDENT: username='meera',   password='meera123'  (Class 10 Section B)")
        print("=" * 60)

    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
