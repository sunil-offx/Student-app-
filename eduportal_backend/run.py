# eduportal_backend/run.py
import uvicorn
import os
from app.seed import seed_database

if __name__ == "__main__":
    # Seed database with initial data if not present
    seed_database()

    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    print(f"Starting EduPortal FastAPI Server on http://{host}:{port}")
    uvicorn.run("app.main:app", host=host, port=port, reload=True)
