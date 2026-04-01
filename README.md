---
title: MediGuide AI
emoji: 🏥
colorFrom: red
colorTo: blue
sdk: docker
app_port: 7860
short_description: OpenEnv RL Medical Diagnosis Environment for Healthcare
tags:
  - openenv
  - medical
  - healthcare
  - emergency
  - hindi
  - hackathon
  - rl-environment
pinned: false
---

# 🏥 MediGuide AI - OpenEnv Medical Diagnosis Environment

**Real-world RL Environment for Emergency Medical Assistance**

> Meta + Hugging Face Hackathon 2026 · Round 1 Submission

---

## 🎯 Task Overview

**Problem Statement:** Build a complete, real-world OpenEnv environment that an AI agent can learn from through the standard step()/reset()/state() API.

**Our Solution:** MediGuide AI is a medical diagnosis environment that helps users identify diseases based on symptoms and receive emergency guidance. This is a real-world healthcare task targeting rural India where medical resources are scarce.

---

## ✅ Pre-Submission Checklist

| Requirement | Status | Notes |
|-------------|--------|-------|
| HF Space deploys | ✅ | Returns 200, responds to reset() |
| OpenEnv spec compliance | ✅ | openenv.yaml, typed models, endpoints |
| Dockerfile builds | ✅ | Working Docker configuration |
| Baseline reproduces | ✅ | inference.py runs without error |
| 3+ tasks with graders | ✅ | Easy/Medium/Hard tasks with 0.0-1.0 scores |

---

## 📋 Environment Specification

### Observation Space
```python
{
    "episode_id": str,        # Unique episode identifier
    "step_count": int,       # Number of steps taken
    "query": str,            # User's symptom input
    "diagnoses": List[Dict], # List of possible diseases
    "emergency_steps": List[str], # Emergency guidance
    "message": str          # Status message
}
```

### Action Space
```python
{
    "symptoms": str,         # Comma-separated symptoms
    "query_type": str       # Type of query (diagnose/feedback)
}
```

---

## 📊 Tasks with Graders

| Task ID | Name | Difficulty | Grading Criteria | Max Score |
|---------|------|------------|-----------------|-----------|
| 1 | Simple Diagnosis | Easy | Returns valid diagnosis with at least 1 disease | 1.0 |
| 2 | Emergency Detection | Medium | Identifies HIGH or CRITICAL severity conditions | 1.0 |
| 3 | Treatment Recommendation | Hard | Provides actionable emergency_steps with guidance | 1.0 |

---

## 🔧 Setup Instructions

### Local Development
```bash
# Clone the repository
git clone https://github.com/codesharecommunityonly1/medi_duid_ai.git
cd medi_duid_ai

# Install dependencies
pip install -r requirements.txt

# Run the server
python inference.py

# Or run evaluation
python inference.py --eval
```

### Docker Deployment
```bash
# Build the container
docker build -t mediguide-ai .

# Run the container
docker run -p 7860:7860 mediguide-ai
```

### Hugging Face Space
The environment is deployed at: https://vinayakkuma-med-guid-ai.hf.space

---

## 📝 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/reset` | Start new episode |
| POST | `/step` | Process symptoms and return diagnosis |
| GET | `/state` | Get current episode state |
| GET | `/health` | Health check |

---

## 🧪 Evaluation

### Run Baseline Evaluation
```bash
python inference.py --eval
```

### Expected Output Format
```
[START] {"episode_id": "...", "message": "..."}
[STEP] {"step": 1, "diagnoses_count": 2, ...}
[END] {"task": "simple_diagnosis", "score": 1.0, "status": "PASS"}
```

---

## 🏆 Features

- **8 Diseases**: Malaria, Dengue, Typhoid, Pneumonia, Heart Attack, Snake Bite, Heatstroke, Cholera
- **Hindi Support**: Full Hindi symptom translation
- **Emergency SOS**: Critical care guides + India 108 helpline
- **RL Learning**: Q-learning from user feedback
- **Real-world Impact**: Targets 600M+ rural Indians with limited healthcare access

---

## 📄 Files

| File | Description |
|------|-------------|
| `inference.py` | FastAPI server with OpenEnv endpoints + evaluation |
| `openenv.yaml` | OpenEnv specification with tasks definition |
| `Dockerfile` | Docker configuration for deployment |
| `pyproject.toml` | Python project configuration |
| `requirements.txt` | Python dependencies |

---

## 🔐 Environment Variables (Required for LLM integration)

```bash
export API_BASE_URL="https://api.openai.com/v1"
export MODEL_NAME="gpt-4"
export HF_TOKEN="your-huggingface-token"
```

---

## ⚠️ Disclaimer

This is an AI assistant for guidance only. Always consult a qualified medical doctor for medical decisions. In emergencies, call 108 (India) or your local emergency number.

---

**Submission Deadline: 8th April 2026, 11:59 PM**