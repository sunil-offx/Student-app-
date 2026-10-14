import sys
import os
import time
import subprocess
import urllib.request
from playwright.sync_api import sync_playwright

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

def run_playwright_subject_tests():
    print("=" * 65)
    print("[PLAYWRIGHT AUTOMATION]: ADD SUBJECT FUNCTIONALITY TEST SUITE")
    print("=" * 65)

    base_url = "http://127.0.0.1:8000"
    server_process = None

    def is_server_up():
        try:
            with urllib.request.urlopen(f"{base_url}/docs", timeout=1.5) as r:
                return r.status == 200
        except Exception:
            return False

    if is_server_up():
        print("Backend server is already running on port 8000.")
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
        api_request = p.request.new_context(base_url=base_url)

        # STEP 1: Admin Authentication
        print("\n[Step 1] Logging in as Admin via Playwright API context...")
        login_res = api_request.post("/api/auth/login", data={
            "username": "admin",
            "password": "admin123",
            "role": "admin"
        })
        assert login_res.status == 200, f"Login failed: {login_res.text()}"
        login_data = login_res.json()
        token = login_data["access_token"]
        auth_headers = {"Authorization": f"Bearer {token}"}
        print(f"  --> Logged in successfully: {login_data['user']['full_name']} (Role: admin)")

        # STEP 2: Baseline Dashboard Stats
        print("\n[Step 2] Fetching initial Dashboard Stats...")
        dash_res = api_request.get("/api/admin/dashboard", headers=auth_headers)
        assert dash_res.status == 200, f"Dashboard fetch failed: {dash_res.text()}"
        initial_stats = dash_res.json()["stats"]
        initial_sub_count = initial_stats["total_subjects"]
        print(f"  --> Initial Total Subjects in Dashboard: {initial_sub_count}")

        # STEP 3: Initial Subject Listing
        print("\n[Step 3] Fetching initial Subject Directory...")
        subjects_res = api_request.get("/api/admin/subjects", headers=auth_headers)
        assert subjects_res.status == 200, f"Subjects fetch failed: {subjects_res.text()}"
        initial_subjects = subjects_res.json()["subjects"]
        print(f"  --> Existing curriculum subjects: {[s['name'] + ' (' + s['code'] + ')' for s in initial_subjects]}")

        # STEP 4: Input Validation Tests for Add Subject
        print("\n[Step 4] Testing Add Subject Input Validation rules...")
        
        # 4a. Empty name rejected
        bad_name_res = api_request.post("/api/admin/subjects", headers=auth_headers, data={
            "name": "",
            "code": "TEST",
            "class_id": 5
        })
        assert bad_name_res.status == 400, f"Expected 400 for empty name, got {bad_name_res.status}"
        print("  --> Passed: Empty subject name rejected with 400 Bad Request")

        # 4b. Empty code rejected
        bad_code_res = api_request.post("/api/admin/subjects", headers=auth_headers, data={
            "name": "Test Subject",
            "code": "",
            "class_id": 5
        })
        assert bad_code_res.status == 400, f"Expected 400 for empty code, got {bad_code_res.status}"
        print("  --> Passed: Empty subject code rejected with 400 Bad Request")

        # 4c. Non-existent class ID rejected
        bad_class_res = api_request.post("/api/admin/subjects", headers=auth_headers, data={
            "name": "Robotics Lab",
            "code": "ROB99",
            "class_id": 99999
        })
        assert bad_class_res.status == 404, f"Expected 404 for invalid class_id, got {bad_class_res.status}"
        print("  --> Passed: Invalid class_id rejected with 404 Not Found")

        # STEP 5: Add New Subject (e.g. Artificial Intelligence / Robotics)
        unique_suffix = int(time.time()) % 10000
        new_subject_name = f"Artificial Intelligence {unique_suffix}"
        new_subject_code = f"AI{unique_suffix}"
        target_class_id = 5  # Class 10

        print(f"\n[Step 5] Admin adding new subject '{new_subject_name}' ({new_subject_code}) for Class 10...")
        create_res = api_request.post("/api/admin/subjects", headers=auth_headers, data={
            "name": new_subject_name,
            "code": new_subject_code,
            "class_id": target_class_id,
            "icon_color": "#4F46E5",
            "description": "Foundations of AI, machine learning, and ethics in computing"
        })
        assert create_res.status == 201, f"Failed to create subject: {create_res.text()}"
        created_subject = create_res.json()
        new_subject_id = created_subject["id"]
        print(f"  --> Subject created successfully! ID={new_subject_id}, Name='{created_subject['name']}', Code='{created_subject['code']}'")
        assert created_subject.get("class_name") == "Class 10", f"Unexpected class_name: {created_subject.get('class_name')}"
        assert target_class_id == created_subject.get("class_id"), f"Unexpected class_id: {created_subject.get('class_id')}"
        assert "Class 10" in created_subject.get("classes", []), f"Class 10 not in classes list: {created_subject.get('classes')}"
        print("  --> Verified return payload contains class_id, class_name, and classes array.")

        # STEP 6: Duplicate Prevention Tests
        print("\n[Step 6] Testing Duplicate Prevention...")
        dup_code_res = api_request.post("/api/admin/subjects", headers=auth_headers, data={
            "name": f"Other Subject {unique_suffix}",
            "code": new_subject_code,
            "class_id": target_class_id
        })
        assert dup_code_res.status == 409, f"Expected 409 Conflict for duplicate code, got {dup_code_res.status}"
        print("  --> Passed: Duplicate subject code rejected with 409 Conflict")

        dup_name_res = api_request.post("/api/admin/subjects", headers=auth_headers, data={
            "name": new_subject_name,
            "code": f"DIFF{unique_suffix}",
            "class_id": target_class_id
        })
        assert dup_name_res.status == 409, f"Expected 409 Conflict for duplicate name, got {dup_name_res.status}"
        print("  --> Passed: Duplicate subject name rejected with 409 Conflict")

        # STEP 7: Verify Subject in Admin Subjects Listing
        print("\n[Step 7] Verifying new subject appears in GET /api/admin/subjects...")
        subjects_res_updated = api_request.get("/api/admin/subjects", headers=auth_headers)
        assert subjects_res_updated.status == 200
        all_subjects = subjects_res_updated.json()["subjects"]
        matched_subjects = [s for s in all_subjects if s["id"] == new_subject_id]
        assert len(matched_subjects) == 1, f"New subject ID {new_subject_id} not found in directory!"
        subject_record = matched_subjects[0]
        assert subject_record["code"] == new_subject_code
        assert subject_record["class_name"] == "Class 10"
        assert subject_record["class_id"] == target_class_id
        assert "Class 10" in subject_record["classes"]
        print(f"  --> Found in listing: {subject_record['name']} | Code: {subject_record['code']} | Class: {subject_record['class_name']} (ID: {subject_record['class_id']})")

        # STEP 8: Verify Class Tabs contains the new Subject
        print(f"\n[Step 8] Verifying new subject appears in Class 10 Tabs (/api/admin/classes/{target_class_id}/tabs)...")
        tabs_res = api_request.get(f"/api/admin/classes/{target_class_id}/tabs", headers=auth_headers)
        assert tabs_res.status == 200, f"Class tabs failed: {tabs_res.text()}"
        class_subjects = tabs_res.json().get("subjects", [])
        class_subject_ids = [s["id"] for s in class_subjects]
        assert new_subject_id in class_subject_ids, "New subject missing from Class 10 tabs!"
        print(f"  --> Verified: Subject {new_subject_name} is mapped to Class 10 subjects list ({len(class_subjects)} total subjects)")

        # STEP 9: Verify Dashboard Stats Incremented
        print("\n[Step 9] Verifying Dashboard Mode Stats incremented...")
        dash_res_updated = api_request.get("/api/admin/dashboard", headers=auth_headers)
        assert dash_res_updated.status == 200
        new_stats = dash_res_updated.json()["stats"]
        print(f"  --> Updated Total Subjects: {new_stats['total_subjects']} (Was: {initial_sub_count})")
        assert new_stats["total_subjects"] == initial_sub_count + 1, "Subject count did not increment in dashboard stats!"

        # STEP 10: Assign Teacher to the New Subject
        print(f"\n[Step 10] Assigning Teacher (ID=2 Ms. Priya) to '{new_subject_name}'...")
        assign_res = api_request.post("/api/admin/teachers/assign", headers=auth_headers, data={
            "teacher_id": 2,
            "class_id": target_class_id,
            "subject_id": new_subject_id,
            "academic_year_id": 1
        })
        assert assign_res.status in (200, 201), f"Teacher assignment failed: {assign_res.text()}"
        print("  --> Teacher successfully assigned to the subject")

        # Verify teacher appears in Subject listing
        subjects_res_post_assign = api_request.get("/api/admin/subjects", headers=auth_headers)
        subject_record_post = [s for s in subjects_res_post_assign.json()["subjects"] if s["id"] == new_subject_id][0]
        assert subject_record_post["teacher"] is not None, "Teacher info missing after assignment!"
        print(f"  --> Subject assigned teacher verified: {subject_record_post['teacher']['full_name']}")

        # STEP 11: Teacher Login and Verify Access to New Subject
        print("\n[Step 11] Logging in as Teacher (priya) to verify subject access...")
        t_login = api_request.post("/api/auth/login", data={
            "username": "priya",
            "password": "priya123",
            "role": "teacher"
        })
        assert t_login.status == 200, f"Teacher login failed: {t_login.text()}"
        t_token = t_login.json()["access_token"]
        t_subjects_res = api_request.get("/api/teacher/subjects", headers={"Authorization": f"Bearer {t_token}"})
        assert t_subjects_res.status == 200
        t_subjects = t_subjects_res.json().get("subjects", [])
        t_subject_ids = [s["id"] for s in t_subjects]
        assert new_subject_id in t_subject_ids, "New subject not found in teacher assigned subjects list!"
        print(f"  --> Verified teacher has access to '{new_subject_name}' in assigned subjects list")

        # STEP 12: Student Login and Verify Curriculum Visibility
        print("\n[Step 12] Logging in as Student (rahul - Class 10) to verify subject visibility...")
        s_login = api_request.post("/api/auth/login", data={
            "username": "rahul",
            "password": "rahul123",
            "role": "student"
        })
        assert s_login.status == 200, f"Student login failed: {s_login.text()}"
        s_token = s_login.json()["access_token"]
        s_subjects_res = api_request.get("/api/student/subjects", headers={"Authorization": f"Bearer {s_token}"})
        assert s_subjects_res.status == 200
        s_subjects = s_subjects_res.json().get("subjects", [])
        s_subject_ids = [s["id"] for s in s_subjects]
        assert new_subject_id in s_subject_ids, "New subject not found in Class 10 student curriculum!"
        print(f"  --> Verified student sees '{new_subject_name}' in their curriculum ({len(s_subjects)} subjects)")

        api_request.dispose()

    print("\n" + "=" * 65)
    print("[SUCCESS] ALL 12 PLAYWRIGHT ADD SUBJECT TEST SUITES PASSED PERFECTLY!")
    print("=" * 65)

    if server_process:
        server_process.terminate()

if __name__ == "__main__":
    run_playwright_subject_tests()
