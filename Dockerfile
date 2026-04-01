# MediGuide AI - OpenEnv Docker Space
# Multi-stage build using openenv-base
FROM ghcr.io/meta-pytorch/openenv-base:latest AS builder

WORKDIR /app

# Ensure git is available
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*

# Copy environment code
COPY mediguide/ /app/env/

WORKDIR /app/env

# Install uv if not available
RUN if ! command -v uv >/dev/null 2>&1; then \
        curl -LsSf https://astral.sh/uv/install.sh | sh && \
        mv /root/.local/bin/uv /usr/local/bin/uv; \
    fi

# Install dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-install-project --no-editable

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-editable

# Final runtime stage
FROM ghcr.io/meta-pytorch/openenv-base:latest

WORKDIR /app

# Copy the virtual environment from builder
COPY --from=builder /app/env/.venv /app/.venv

# Copy the environment code
COPY --from=builder /app/env /app/env

# Set PATH to use the virtual environment
ENV PATH="/app/.venv/bin:$PATH"

# Set PYTHONPATH so imports work correctly
ENV PYTHONPATH="/app/env:$PYTHONPATH"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the FastAPI server
CMD ["sh", "-c", "cd /app/env && uvicorn mediguide.server.app:app --host 0.0.0.0 --port 8000"]