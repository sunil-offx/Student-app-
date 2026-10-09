import sys
import os
import time
import subprocess
import urllib.request
from playwright.sync_api import sync_playwright

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

def run_playwright_admin_tests():
    print("=" * 60)
    print("[PLAYWRIGHT AUTOMATION]: ADMIN DASHBOARD & ADD USER FEATURES")
    print("=" * 60)

    # 1. Start or check backend server
    base_url = "http://127.0.0.1:8000"
    server_process = None
    def is_server_up():
        try:
            with urllib.request.urlopen(f"{base_url}/docs", timeout=1.5) as r:
                return r.status == 200
        except Exception:
            return False

    if is_server_up():
        print("Backend server already running on port 8000.")
    else:
        print("Starting FastAPI backend server...")
        server_process = subprocess.Popen(
            [sys.executable, "run.py"],
            cwd="."
        )
        for _ in range(25):
            time.sleep(0.5)
            if is_server_up():
                print("Backend server successfully started.")
                break

    with sync_playwright() as p:
        # Use Playwright APIRequestContext
        api_request = p.request.new_context(base_url=base_url)

        # STEP 1: Admin Login via Playwright
        print("\n[Step 1] Logging in as Admin via Playwright API context...")
        login_res = api_request.post("/api/auth/login", data={
            "username": "admin",
            "password": "admin123",
            "role": "admin"
        })
        assert login_res.status == 200, f"Login failed: {login_res.text()}"
        login_data = login_res.json()
        token = login_data["access_token"]
        print(f"  --> Logged in successfully: {login_data['user']['full_name']} (Role: {login_data['user']['role']})")

        auth_headers = {"Authorization": f"Bearer {token}"}

        # STEP 2: Check initial Dashboard Stats
        print("\n[Step 2] Fetching initial Dashboard Stats in Dashboard Mode...")
        dash_res = api_request.get("/api/admin/dashboard", headers=auth_headers)
        assert dash_res.status == 200, f"Dashboard fetch failed: {dash_res.text()}"
        initial_stats = dash_res.json()["stats"]
        print(f"  --> Current Students: {initial_stats['total_students']}")
        print(f"  --> Current Teachers: {initial_stats['total_teachers']}")
        print(f"  --> Current Classes:  {initial_stats['total_classes']}")
        print(f"  --> Current Subjects: {initial_stats['total_subjects']}")

        # STEP 3: Add Student in Dashboard Mode
        print("\n[Step 3] Admin adding new student ('Aarav Gupta')...")
        unique_suffix = int(time.time()) % 10000
        student_username = f"aarav_{unique_suffix}"
        student_email = f"aarav_{unique_suffix}@school.edu"

        create_student_res = api_request.post("/api/admin/students", headers=auth_headers, data={
            "username": student_username,
            "password": "student123",
            "full_name": "Aarav Gupta",
            "email": student_email,
            "role": "student",
            "class_id": 5,  # Class 10
            "section_id": 1,
            "roll_number": f"ROLL-10A-{unique_suffix}",
            "contact_number": "+91 98765 11111",
            "parent_name": "Mr. Rajiv Gupta",
            "parent_contact": "+91 98765 00001",
            "date_of_birth": "2010-06-15"
        })
        assert create_student_res.status == 201, f"Create student failed: {create_student_res.text()}"
        new_student = create_student_res.json()
        print(f"  --> Student created: ID={new_student['id']}, Username={new_student['username']}")

        # STEP 4: Add Teacher in Dashboard Mode
        print("\n[Step 4] Admin adding new teacher ('Ms. Shalini Verma')...")
        teacher_username = f"shalini_{unique_suffix}"
        teacher_email = f"shalini_{unique_suffix}@academyalys.com"

        create_teacher_res = api_request.post("/api/admin/teachers", headers=auth_headers, data={
            "username": teacher_username,
            "password": "teacher123",
            "full_name": "Ms. Shalini Verma",
            "email": teacher_email,
            "contact_number": "+91 98765 22222",
            "class_id": 5,     # Class 10
            "subject_id": 1,   # English
            "section_id": 1
        })
        assert create_teacher_res.status == 201, f"Create teacher failed: {create_teacher_res.text()}"
        new_teacher = create_teacher_res.json()
        print(f"  --> Teacher created: ID={new_teacher['id']}, Username={new_teacher['username']}, Assigned Class 10 English")

        # STEP 5: Verify Student Directory listing
        print("\n[Step 5] Verifying Student Directory contains newly added student...")
        students_res = api_request.get(f"/api/admin/students?q={student_username}", headers=auth_headers)
        assert students_res.status == 200
        found_students = [s for s in students_res.json()["students"] if s["username"] == student_username]
        assert len(found_students) == 1, "New student not found in directory!"
        print(f"  --> Found student: {found_students[0]['full_name']} | Roll: {found_students[0]['roll_number']} | Class: {found_students[0]['class_name']}")

        # STEP 6: Verify Teacher Directory listing
        print("\n[Step 6] Verifying Teacher Directory contains newly added teacher...")
        teachers_res = api_request.get("/api/admin/teachers", headers=auth_headers)
        assert teachers_res.status == 200
        found_teachers = [t for t in teachers_res.json()["teachers"] if t["username"] == teacher_username]
        assert len(found_teachers) == 1, "New teacher not found in directory!"
        print(f"  --> Found teacher: {found_teachers[0]['full_name']} | Assigned Classes: {found_teachers[0]['assigned_classes']} | Subjects: {found_teachers[0]['assigned_subjects']}")

        # STEP 7: Verify All Users listing (/api/admin/users)
        print("\n[Step 7] Verifying /api/admin/users endpoint...")
        users_res = api_request.get("/api/admin/users", headers=auth_headers)
        assert users_res.status == 200, f"/api/admin/users failed: {users_res.text()}"
        all_users = users_res.json()["users"]
        user_names = [u["username"] for u in all_users]
        assert student_username in user_names, "Student missing from all users!"
        assert teacher_username in user_names, "Teacher missing from all users!"
        print(f"  --> Total system users: {len(all_users)} (Includes both new student and teacher)")

        # STEP 8: Verify Dashboard Mode Stats Updated
        print("\n[Step 8] Verifying Dashboard Mode Stats incremented...")
        dash_res_updated = api_request.get("/api/admin/dashboard", headers=auth_headers)
        assert dash_res_updated.status == 200
        updated_stats = dash_res_updated.json()["stats"]
        print(f"  --> Updated Students: {updated_stats['total_students']} (Was: {initial_stats['total_students']})")
        print(f"  --> Updated Teachers: {updated_stats['total_teachers']} (Was: {initial_stats['total_teachers']})")
        assert updated_stats["total_students"] == initial_stats["total_students"] + 1, "Student count did not increment!"
        assert updated_stats["total_teachers"] == initial_stats["total_teachers"] + 1, "Teacher count did not increment!"

        # STEP 9: Test newly created Teacher login & scoped permissions
        print(f"\n[Step 9] Logging in as new Teacher ({teacher_username})...")
        t_login = api_request.post("/api/auth/login", data={
            "username": teacher_username,
            "password": "teacher123",
            "role": "teacher"
        })
        assert t_login.status == 200, f"Teacher login failed: {t_login.text()}"
        t_token = t_login.json()["access_token"]
        t_subjects = api_request.get("/api/teacher/subjects", headers={"Authorization": f"Bearer {t_token}"})
        assert t_subjects.status == 200
        print(f"  --> Teacher successfully authenticated and accessed scoped assigned subjects ({len(t_subjects.json().get('subjects', []))} subjects)")

        # STEP 10: Test newly created Student login
        print(f"\n[Step 10] Logging in as new Student ({student_username})...")
        s_login = api_request.post("/api/auth/login", data={
            "username": student_username,
            "password": "student123",
            "role": "student"
        })
        assert s_login.status == 200, f"Student login failed: {s_login.text()}"
        s_token = s_login.json()["access_token"]
        s_profile = api_request.get("/api/student/profile", headers={"Authorization": f"Bearer {s_token}"})
        assert s_profile.status == 200
        print(f"  --> Student successfully authenticated: Roll Number = {s_login.json()['user'].get('roll_number')}")

        api_request.dispose()

    print("\n" + "=" * 60)
    print("[SUCCESS] ALL 10 PLAYWRIGHT TEST SUITES PASSED PERFECTLY!")
    print("=" * 60)

    if server_process:
        server_process.terminate()

if __name__ == "__main__":
    run_playwright_admin_tests()
