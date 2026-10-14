# 🎓 AcademyAlys - Educational Learning Management Platform

AcademyAlys is a production-grade Learning Management System (LMS) strictly engineered for **Classes 6 to 10**, adhering to the core organizational model:
$$\text{ADMIN} \longrightarrow \text{PERMISSIONS} \longrightarrow \text{TEACHER} \longrightarrow \text{CONTENT} \longrightarrow \text{STUDENT}$$

The platform includes a **FastAPI (Python)** backend with SQLite database persistence, and a **Flutter (Dart)** client application supporting Windows Desktop, Web, Android, and iOS. It also features a zero-configuration embedded mock database service (`EmbeddedBackendService`) for offline presentation.

---

## 🌟 Core Architecture & Feature Matrix

### 1. 🛡️ Admin Portal (Central Academic Workspace)
- **Class Workspace for Classes 6–10**:
  - Dedicated class management view with tabs: `Overview`, `Students`, `Sections`, `Teachers`, `Subjects`, and `Lessons`.
  - Academic year tracking (Active: `2026-2027`, Historical: `2025-2026`).
- **Global Student Directory (Section 10)**:
  - Search by Student Name, Roll Number, or Email.
  - Multi-attribute filters: Class (Classes 6 to 10), Section (Section A, Section B), and Status (Active / Inactive).
  - Quick action to inspect historical progression and toggle account state.
- **Add Student Wizard (Section 11)**:
  - Enrollment fields: Full Name, Roll Number, Email, Password, Date of Birth, Contact, Parent Details, Class, Section.
  - Preserves enrollment records with historical audit logs.
- **Bulk Student CSV Import (Section 12)**:
  - CSV parser with format `Full Name, Email, Roll Number, Section, DOB, Contact`.
  - Built-in validation checks (required fields, email format, duplicate detection) with preview table before commit.
- **Teacher Directory & Multi-Assignment (Sections 13 & 14)**:
  - Multi-class and multi-subject allocation (e.g. Ms. Priya assigned to Class 10 & 9 English).
  - Explicit authorization enforcing that teachers cannot modify or upload to unassigned class subjects.
- **Materials Review & Publishing Control (Section 19)**:
  - Global oversight to review, publish, draft, or delete educational resources.

---

### 2. 👩‍🏫 Teacher Portal (Scoped Content Studio)
- **Strict Authorization Engine**:
  - Teacher accounts are restricted exclusively to their assigned Class + Subject combinations.
  - Denied access to unauthorized classes (e.g. Ms. Priya accessing Math or Science is blocked).
- **Material Upload & Publishing Workflow (Sections 17 & 17.1)**:
  - Step 1: Select Class (only from assigned classes: e.g., Class 10, Class 9).
  - Step 2: Select Subject (only assigned subjects: e.g., English).
  - Step 3: Select Lesson (e.g., Lesson 1: *A Letter to God*).
  - Step 4: Material Type:
    - 📹 **Video Lecture**: Title, description, duration (e.g. `24:15`, `12:30`), video embed URL or MP4 upload.
    - 📄 **PDF Materials**: Curated chapter solutions and study guides.
    - 📊 **PPT Presentations**: Visual lecture decks.
    - 📝 **Notes / Summaries**: Comprehensive chapter notes.
    - 🌐 **Web Links / References**: External educational links.
  - Step 5: **Publication Status**: Instant toggle between `Published` (live for students) and `Draft` (private).
- **My Materials Management**:
  - Review materials per lesson, switch live/draft status, and delete old resources.

---

### 3. 👨‍🎓 Student Portal (Adaptive Learning Experience)
- **Enrolled Class Scope**:
  - Students see only published materials for their enrolled class subjects.
- **Two-Column Student Lesson Learning Interface (Sections 20, 21, 22)**:
  - **Lesson Header**: Subject, Class badge, Unit, and Lesson Title (*A Letter to God*).
  - **Left Sidebar with Dynamic Counters**:
    - 🏠 **Home / Summary**: `[8]`
    - 📹 **Videos**: `[2]`
    - 📄 **PDF Materials**: `[3]`
    - 📊 **PPT Presentations**: `[1]`
    - 📝 **Notes**: `[2]`
    - ❓ **Practice Questions / Quizzes**: `[2]`
  - **Adaptive Main Viewer**:
    - **Interactive Video Player**: Play/pause, duration tracking (`24:15`, `12:30`), volume controls, scrub bar.
    - **Document & PDF Reader**: Embedded document reader with page count and zoom controls.
    - **Presentation Viewer**: Slide-by-slide presentation deck controls.
    - **Study Notes Reader**: Clean typographic notes view with copy/download options.
    - **Interactive Practice Quizzes**: Timed practice assessments with instant feedback.
- **Historical Enrollment Preservation (Section 33.1)**:
  - Displays multi-year academic progression (e.g. `2026-2027: Class 10 - Section A (Active)` and `2025-2026: Class 9 - Section A (Completed)`).

---

## 🔑 Pre-Seeded AcademyAlys Demo Credentials

| Role | Username | Password | Assigned Scope & Notes |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin` | `admin123` | Full administrative control across Classes 6–10 |
| **Teacher** | `priya` | `priya123` | **Class 10 & 9 English** |
| **Teacher** | `rajesh` | `rajesh123` | **Class 10 & 8 Mathematics** |
| **Teacher** | `geetha` | `geetha123` | **Class 10 Science** |
| **Teacher** | `sarah` | `sarah123` | **Class 9 Science** |
| **Student** | `rahul` | `rahul123` | **Class 10 - Section A** (Roll: `ROLL-10A-01`) |
| **Student** | `ananya` | `ananya123` | **Class 9 - Section A** (Roll: `ROLL-09A-01`) |
| **Student** | `vikram` | `vikram123` | **Class 8 - Section A** (Roll: `ROLL-08A-01`) |
| **Student** | `meera` | `meera123` | **Class 10 - Section B** (Roll: `ROLL-10B-01`) |

---

## 🚀 Running the Project

### 1. Python FastAPI Backend

```bash
cd eduportal_backend
.\venv\Scripts\activate
python run.py
```
*API Swagger Documentation is available at: `http://127.0.0.1:8000/docs`*

### 2. Flutter Client Application

The client app uses the FastAPI backend for authentication and data. Configure a reachable HTTPS backend URL in the app before signing in.

```bash
cd eduportal_app
flutter run -d chrome     # Web
# or
flutter run -d windows    # Windows Desktop
# or
flutter run -d android    # Android
```

### 2.1. Open the local web app on phones over Wi-Fi

The Flutter debug server uses plain HTTP. Mobile browsers do not provide secure token storage to an HTTP page opened by a LAN IP, so use the local HTTPS server below instead.

1. Keep the FastAPI backend running on port `8000`, and build the web client with its API URL set to the same HTTPS origin. This makes the shared link work on new devices without configuring **Connect live backend**:

   ```powershell
   cd eduportal_app
   flutter build web --release --dart-define=API_BASE_URL=https://192.168.0.133:3001/api
   cd ..
   ```

2. Generate a local certificate for this computer's current Wi-Fi IPv4 address:

   ```powershell
   .\scripts\setup-lan-https.ps1 -LanIp 192.168.0.133
   ```

   Replace `192.168.0.133` with the address shown by `ipconfig` if it has changed. This adds a local CA certificate to the current Windows user's trust store. Its private key stays in the Windows certificate store; local certificate and key files are excluded from Git.

3. While the existing Flutter web server is still running on port `3000`, open `http://192.168.0.133:3000/lan-ca.cer` on each phone and install the downloaded certificate as a trusted CA certificate. Android's setting is usually under **Settings → Security & privacy → More security settings → Encryption & credentials → Install a certificate → CA certificate**; labels vary by device. Only install this certificate on devices you control.

4. Leave the Flutter web server running so it continues to provide the certificate download, then start the HTTPS server on port `3001` from the project root:

   ```powershell
   $env:LAN_IP = "192.168.0.133"
   $env:PORT = "3001"
   npm run serve:lan:https
   ```

5. Open `https://192.168.0.133:3001` on the phones. The app uses its built-in API URL, and the HTTPS server securely proxies `/api` requests to the local FastAPI backend. **Connect live backend** remains available if you later want to override the configured server.

6. To start the local API and HTTPS website automatically whenever you sign in to Windows, register the background task once:

   ```powershell
   .\scripts\install-local-stack-task.ps1
   ```

   The task keeps both services running and writes diagnostic logs under `logs\local-stack`. Your PC must be powered on, signed in, awake, and connected to the same Wi-Fi; this is a local network link, not a public website. Reserve `192.168.0.133` for this PC in your router so the address and certificate remain valid.

This local certificate is for trusted devices on your LAN only; do not expose this development server to the public internet.

### 3. Deploy the live backend on Render

The `render.yaml` Blueprint creates the FastAPI service and PostgreSQL database. From the project repository, create a new Blueprint in Render and select this repository. During setup, provide:

- `ADMIN_USERNAME` and `ADMIN_EMAIL` for the first administrator.
- A unique `ADMIN_PASSWORD` with at least 12 characters.
- Render generates `SECRET_KEY`; keep it private.

The first start creates the administrator, an active academic year, Classes 6–10, their sections, and the standard subjects. It does not create demo teacher or student accounts. Sign in as the new administrator to add accounts.

After Render deploys the service, copy its HTTPS URL (for example, `https://your-service.onrender.com`). In the APK, tap **Connect live backend**, enter that URL, and choose **Test and save**. The app verifies `/api/health` and stores the server address on the device. All API operations then use that server; failed requests are shown as errors and are never silently written to local demo data.

Render must be connected to the repository containing this Blueprint and the `eduportal_backend` folder. The database is PostgreSQL; files uploaded by teachers or students are currently stored in the service's local `uploads` directory, so configure durable file/object storage before relying on uploaded files in production.

Build an APK with a backend URL already set, if preferred:

```bash
cd eduportal_app
flutter build apk --release --dart-define=API_BASE_URL=https://your-service.onrender.com/api
```
