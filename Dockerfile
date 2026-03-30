# MediGuide AI - OpenEnv-Compatible Docker Space
# Meta + Hugging Face Hackathon 2026
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Expose ports
EXPOSE 7860 7861

# Run the inference server (includes Gradio UI)
CMD ["python", "inference.py"]
