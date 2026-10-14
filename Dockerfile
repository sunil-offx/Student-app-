# syntax=docker/dockerfile:1
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    HOST=0.0.0.0 \
    UPLOAD_DIR=/app/uploads

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy dependency specifications and install python packages
COPY eduportal_backend/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy backend application source
COPY eduportal_backend/ .

# Prepare directories and script permissions
RUN mkdir -p /app/uploads /app/data && \
    chmod -R 777 /app/uploads /app/data && \
    sed -i 's/\r$//' /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

# Expose backend port
EXPOSE 8000

# Health check against API health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${PORT}/api/health || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
