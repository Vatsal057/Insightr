# Use a lightweight Python base image
FROM python:3.10-slim

# Install system dependencies (ffmpeg and tesseract-ocr are required by the pipeline)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    tesseract-ocr \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set up a new user named "user" with UID 1000 to comply with Hugging Face policies
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

WORKDIR $HOME/app

# Copy requirements and install Python dependencies
COPY --chown=user requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Copy the rest of the backend files
COPY --chown=user . .

# Hugging Face Spaces runs on port 7860
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "7860"]
