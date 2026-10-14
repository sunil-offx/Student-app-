#!/bin/sh
set -e

# Wait for database connection if using PostgreSQL
python - << 'EOF'
import os
import time
from urllib.parse import urlparse

db_url = os.getenv("DATABASE_URL", "")
if db_url.startswith("postgres"):
    print("Connecting to PostgreSQL database...")
    from sqlalchemy import create_engine
    engine = create_engine(db_url)
    connected = False
    for i in range(30):
        try:
            with engine.connect() as conn:
                print("Database connection established!")
                connected = True
                break
        except Exception:
            time.sleep(1)
    if not connected:
        print("Warning: Could not connect to PostgreSQL after 30s. Proceeding...")
EOF

# Run database seed if AUTO_SEED is set to "true" (default: true)
if [ "${AUTO_SEED:-true}" = "true" ]; then
    echo "Checking / seeding database initial data..."
    python -c "from app.seed import seed_database; seed_database()" || echo "Notice: Database seed check finished."
fi

# Run admin bootstrap if credentials are provided
if [ -n "$ADMIN_USERNAME" ] && [ -n "$ADMIN_PASSWORD" ]; then
    echo "Bootstrapping administrator user..."
    python -m app.bootstrap_admin || echo "Notice: Admin bootstrap completed or already exists."
fi

# Execute main process (uvicorn)
echo "Starting EduPortal FastAPI Server on port ${PORT:-8000}..."
exec "$@"
