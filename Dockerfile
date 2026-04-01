# MediGuide AI - OpenEnv Docker Space
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY app.py .
COPY inference.py .
COPY models.py .
COPY openenv.yaml .
COPY pyproject.toml .

EXPOSE 7860

CMD ["python", "inference.py"]