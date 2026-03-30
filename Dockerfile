# MediGuide AI - OpenEnv Docker Space
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY inference.py .

EXPOSE 7860

CMD ["python", "inference.py"]
