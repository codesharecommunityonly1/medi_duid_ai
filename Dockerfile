# ─────────────────────────────────────────────────────────────
# MediGuide AI — OpenEnv-Compatible Docker Space
# Meta + Hugging Face Hackathon 2026
# ─────────────────────────────────────────────────────────────
FROM python:3.11-slim

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user (HF Spaces requirement)
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

WORKDIR $HOME/app

# Install Python dependencies
COPY --chown=user requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY --chown=user . .

# Health check (OpenEnv validator uses this)
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=5 \
    CMD curl -f http://localhost:7860/health || exit 1

# Expose port 7860 (HF Spaces default)
EXPOSE 7860
EXPOSE 7861

# Run the OpenEnv server (inference.py at repo root)
CMD ["python", "inference.py"]
