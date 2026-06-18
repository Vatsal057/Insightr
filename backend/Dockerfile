# Use a lightweight Python base image
FROM python:3.10-slim

# Install system dependencies (ffmpeg and tesseract-ocr are required by the pipeline)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    tesseract-ocr \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the backend files
COPY . .

# Start the FastAPI application, binding to the port provided by Render
CMD ["sh", "-c", "uvicorn api:app --host 0.0.0.0 --port ${PORT:-8000}"]
