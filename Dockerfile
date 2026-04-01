# MediGuide AI - OpenEnv Docker Space
FROM ghcr.io/meta-pytorch/openenv-base:latest

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY mediguide/ ./mediguide/
COPY openenv.yaml .

EXPOSE 8000

CMD ["python", "-m", "mediguide.server.app"]