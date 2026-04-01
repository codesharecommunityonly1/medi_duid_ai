# MediGuide AI - OpenEnv Docker Space
FROM ghcr.io/meta-pytorch/openenv-base:latest

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server/ ./server/
COPY openenv.yaml .
COPY pyproject.toml .

EXPOSE 7860

CMD ["python", "-m", "server.app"]