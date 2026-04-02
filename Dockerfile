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

# Create necessary directories
RUN mkdir -p mediguide/server

# Copy mediguide package
COPY mediguide/__init__.py mediguide/
COPY mediguide/models.py mediguide/
COPY mediguide/client.py mediguide/
COPY mediguide/openenv.yaml mediguide/
COPY mediguide/pyproject.toml mediguide/
COPY mediguide/uv.lock mediguide/

# Copy server files
COPY mediguide/server/__init__.py mediguide/server/
COPY mediguide/server/app.py mediguide/server/
COPY mediguide/server/mediguide_environment.py mediguide/server/
COPY mediguide/server/__init__.py mediguide/server/

# Expose port
EXPOSE 7860

# Run app.py which has Gradio UI
CMD ["python", "app.py"]