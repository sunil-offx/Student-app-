# eduportal_backend/app/main.py
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .database import engine, Base
from .routers import auth_router, admin_router, teacher_router, student_router

# Create database tables automatically
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="AcademyAlys LMS API",
    description="Educational Learning Management Platform supporting Admin, Teacher, and Student workflows for Classes 6-10.",
    version="1.0.0"
)

# CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Upload directory
UPLOAD_DIR = os.getenv("UPLOAD_DIR", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# Include Routers with /api prefix
app.include_router(auth_router.router, prefix="/api")
app.include_router(admin_router.router, prefix="/api")
app.include_router(teacher_router.router, prefix="/api")
app.include_router(student_router.router, prefix="/api")

@app.get("/")
def root():
    return {
        "status": "online",
        "service": "EduPortal API",
        "version": "1.0.0",
        "docs_url": "/docs"
    }

@app.get("/api/health")
def health_check():
    return {"status": "ok", "message": "EduPortal API is running cleanly"}
