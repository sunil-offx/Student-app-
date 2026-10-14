// @ts-check
import { test, expect } from '@playwright/test';

const BASE_URL = 'http://127.0.0.1:8000';

test.describe.serial('Admin Add Subject & Curriculum Flow', () => {
  let adminToken = '';
  const timestamp = Date.now() % 10000;
  const newSubjectName = `Robotics Engineering ${timestamp}`;
  const newSubjectCode = `ROB${timestamp}`;
  let createdSubjectId = 0;
  let initialCount = 0;

  test.beforeAll(async ({ request }) => {
    // 1. Admin Login with JSON payload
    const loginRes = await request.post(`${BASE_URL}/api/auth/login`, {
      data: {
        username: 'admin',
        password: 'admin123',
        role: 'admin',
      },
    });
    expect(loginRes.ok()).toBeTruthy();
    const loginData = await loginRes.json();
    adminToken = loginData.access_token;
    expect(adminToken).toBeTruthy();
  });

  test('Validates empty inputs and invalid class_id', async ({ request }) => {
    const headers = { Authorization: `Bearer ${adminToken}` };

    // Empty name rejected
    const emptyNameRes = await request.post(`${BASE_URL}/api/admin/subjects`, {
      headers,
      data: { name: '', code: 'ROB01', class_id: 5 },
    });
    expect(emptyNameRes.status()).toBe(400);

    // Empty code rejected
    const emptyCodeRes = await request.post(`${BASE_URL}/api/admin/subjects`, {
      headers,
      data: { name: 'Robotics', code: '', class_id: 5 },
    });
    expect(emptyCodeRes.status()).toBe(400);

    // Invalid class rejected
    const invalidClassRes = await request.post(`${BASE_URL}/api/admin/subjects`, {
      headers,
      data: { name: 'Robotics', code: 'ROB99', class_id: 99999 },
    });
    expect(invalidClassRes.status()).toBe(404);
  });

  test('Successfully creates a new subject assigned to Class 10', async ({ request }) => {
    const headers = { Authorization: `Bearer ${adminToken}` };

    // Get initial count
    const initialDash = await request.get(`${BASE_URL}/api/admin/dashboard`, { headers });
    expect(initialDash.ok()).toBeTruthy();
    initialCount = (await initialDash.json()).stats.total_subjects;

    // Create subject
    const createRes = await request.post(`${BASE_URL}/api/admin/subjects`, {
      headers,
      data: {
        name: newSubjectName,
        code: newSubjectCode,
        class_id: 5,
        icon_color: '#6366F1',
        description: 'Applied robotics and electronics laboratory',
      },
    });
    expect(createRes.status()).toBe(201);
    const body = await createRes.json();
    expect(body.name).toBe(newSubjectName);
    expect(body.code).toBe(newSubjectCode);
    expect(body.class_name).toBe('Class 10');
    expect(body.class_id).toBe(5);
    expect(body.classes).toContain('Class 10');
    createdSubjectId = body.id;

    // Verify dashboard count incremented
    const updatedDash = await request.get(`${BASE_URL}/api/admin/dashboard`, { headers });
    const updatedCount = (await updatedDash.json()).stats.total_subjects;
    expect(updatedCount).toBe(initialCount + 1);
  });

  test('Prevents duplicate subject codes and names', async ({ request }) => {
    const headers = { Authorization: `Bearer ${adminToken}` };

    // Duplicate code
    const dupCodeRes = await request.post(`${BASE_URL}/api/admin/subjects`, {
      headers,
      data: {
        name: `Different Name ${timestamp}`,
        code: newSubjectCode,
        class_id: 5,
      },
    });
    expect(dupCodeRes.status()).toBe(409);

    // Duplicate name
    const dupNameRes = await request.post(`${BASE_URL}/api/admin/subjects`, {
      headers,
      data: {
        name: newSubjectName,
        code: `DIFF${timestamp}`,
        class_id: 5,
      },
    });
    expect(dupNameRes.status()).toBe(409);
  });

  test('Verifies subject appears in Subject Directory and Class Tabs', async ({ request }) => {
    const headers = { Authorization: `Bearer ${adminToken}` };

    // Check subjects list
    const subjectsRes = await request.get(`${BASE_URL}/api/admin/subjects`, { headers });
    expect(subjectsRes.ok()).toBeTruthy();
    const subjects = (await subjectsRes.json()).subjects;
    const found = subjects.find((s) => s.id === createdSubjectId);
    expect(found).toBeTruthy();
    expect(found.code).toBe(newSubjectCode);
    expect(found.class_name).toBe('Class 10');

    // Check class 10 tabs
    const tabsRes = await request.get(`${BASE_URL}/api/admin/classes/5/tabs`, { headers });
    expect(tabsRes.ok()).toBeTruthy();
    const classTabs = await tabsRes.json();
    const tabSubject = classTabs.subjects.find((s) => s.id === createdSubjectId);
    expect(tabSubject).toBeTruthy();
  });

  test('Assigns teacher to the new subject and verifies teacher access', async ({ request }) => {
    const headers = { Authorization: `Bearer ${adminToken}` };

    // Assign teacher 2 (Priya) to this subject
    const assignRes = await request.post(`${BASE_URL}/api/admin/teachers/assign`, {
      headers,
      data: {
        teacher_id: 2,
        class_id: 5,
        subject_id: createdSubjectId,
        academic_year_id: 1,
      },
    });
    expect(assignRes.status()).toBe(201);

    // Login as teacher
    const tLogin = await request.post(`${BASE_URL}/api/auth/login`, {
      data: {
        username: 'priya',
        password: 'priya123',
        role: 'teacher',
      },
    });
    expect(tLogin.ok()).toBeTruthy();
    const tToken = (await tLogin.json()).access_token;

    // Verify teacher sees assigned subject
    const tSubjectsRes = await request.get(`${BASE_URL}/api/teacher/subjects`, {
      headers: { Authorization: `Bearer ${tToken}` },
    });
    expect(tSubjectsRes.ok()).toBeTruthy();
    const tSubjects = (await tSubjectsRes.json()).subjects;
    const teacherHasSubject = tSubjects.some((s) => s.id === createdSubjectId);
    expect(teacherHasSubject).toBeTruthy();
  });

  test('Class 10 student sees newly added subject in student portal', async ({ request }) => {
    // Login as student rahul (Class 10)
    const sLogin = await request.post(`${BASE_URL}/api/auth/login`, {
      data: {
        username: 'rahul',
        password: 'rahul123',
        role: 'student',
      },
    });
    expect(sLogin.ok()).toBeTruthy();
    const sToken = (await sLogin.json()).access_token;

    // Verify student sees new subject
    const sSubjectsRes = await request.get(`${BASE_URL}/api/student/subjects`, {
      headers: { Authorization: `Bearer ${sToken}` },
    });
    expect(sSubjectsRes.ok()).toBeTruthy();
    const sSubjects = (await sSubjectsRes.json()).subjects;
    const studentHasSubject = sSubjects.some((s) => s.id === createdSubjectId);
    expect(studentHasSubject).toBeTruthy();
  });
});
