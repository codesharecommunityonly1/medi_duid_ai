# MediGuide AI - Docker Configuration for HuggingFace Space
FROM python:3.11-slim

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all application files
COPY app.py .
COPY inference.py .
COPY models.py .
COPY openenv.yaml .
COPY README.md .

# Expose port
EXPOSE 7860

# Run app.py which has Gradio UI
CMD ["python", "app.py"]
