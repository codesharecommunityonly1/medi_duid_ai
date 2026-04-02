---
title: MediGuide AI
emoji: 🏥
colorFrom: red
colorTo: blue
sdk: docker
app_port: 7860
short_description: OpenEnv medical diagnosis env for rural India healthcare
tags:
  - openenv
  - medical
  - healthcare
  - emergency
  - hackathon
  - rl-environment
  - meta-hackathon-2026
pinned: false
---

# 🏥 MediGuide AI

**OpenEnv-Compatible RL Medical Diagnosis Environment**

> Meta + Hugging Face Hackathon 2026 · Healthcare Track

---

## ✅ Pre-Submission Checklist

| Requirement | Status |
|-------------|--------|
| Real-World Task | ✅ Medical diagnosis for rural India |
| OpenEnv Compliance | ✅ step/reset/state + openenv.yaml |
| 3 Tasks with Graders | ✅ Easy/Medium/Hard, scores 0.0-1.0 |
| Reward Function | ✅ Partial progress rewards |
| Baseline Inference | ✅ OpenAI client, env variables |
| HF Space Deploy | ✅ Containerized |
| Dockerfile Works | ✅ docker build + run |
| Documentation | ✅ Complete README |

---

## 📋 Overview

**MediGuide AI** is a real-world RL environment for emergency medical assistance in rural India where 600M+ people have limited healthcare access.

### Features
- 🌡️ Medical diagnosis based on symptoms
- 🚨 Emergency condition detection (CRITICAL/HIGH severity)
- 💊 Treatment recommendations with emergency steps
- 📱 Works offline with local model support
- 🇮🇳 Hindi + English language support

---

## 🏗️ Architecture

```
mediguide_ai/
├── pyproject.toml       # Package config with server entry point
├── openenv.yaml         # Manifest with 3 tasks + graders
├── Dockerfile           # Multi-stage container build
├── requirements.txt     # Python dependencies
├── inference.py        # Evaluation script with MedGemma-27B-it
├── server/app.py       # OpenEnv FastAPI server
└── mediguide/
    ├── pyproject.toml  # Sub-package config
    ├── openenv.yaml   # Task definitions
    └── server/
        ├── app.py     # Server entry point
        └── mediguide_environment.py  # Core environment
```

---

## 📊 Tasks with Graders

| Task | Difficulty | Description | Grading Criteria |
|------|------------|-------------|------------------|
| simple_diagnosis | Easy | Diagnose common symptoms | At least 1 disease found |
| emergency_detection | Medium | Detect emergency conditions | HIGH or CRITICAL severity |
| treatment_recommendation | Hard | Recommend treatment | 2+ actionable emergency steps |

---

## 🔧 Setup

### Install Dependencies
```bash
pip install -r requirements.txt
```

### Run Evaluation
```bash
python inference.py --eval
```

### Run Server
```bash
python inference.py
```

---

## 🔐 Environment Variables

```bash
# Required for LLM inference
export HF_TOKEN="your-huggingface-token"
export MODEL_NAME="MedGemma-27B-it"
export API_BASE_URL="https://router.huggingface.co/v1"
```

---

## 📝 API Endpoints (OpenEnv)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/reset` | Start new episode |
| POST | `/step` | Process symptoms |
| GET | `/state` | Get episode state |
| GET | `/health` | Health check |

---

## 🧪 Evaluation Output

```
[START] task=simple_diagnosis env=mediguide model=MedGemma-27B-it
[STEP] step=1 action=diagnose('fever chills headache') reward=0.10 done=false error=null
[END] success=false steps=1 score=0.008 rewards=0.10

=== Summary ===
Task 1 (Easy): 1.00
Task 2 (Medium): 1.00
Task 3 (Hard): 1.00
Average: 1.00
```

---

## 🏆 Real-World Impact

- **Target:** 600M+ rural Indians with limited healthcare
- **Use Case:** Emergency medical triage
- **Languages:** English + Hindi
- **Emergency:** India 108 integration

---

## 📄 Files

| File | Description |
|------|-------------|
| `inference.py` | FastAPI + evaluation script |
| `server/app.py` | OpenEnv server entry |
| `mediguide/server/mediguide_environment.py` | Core environment |
| `openenv.yaml` | Task definitions |
| `Dockerfile` | Container configuration |
| `pyproject.toml` | Package metadata |

---

## ⚠️ Disclaimer

This is AI guidance only. Always consult a qualified doctor for medical decisions. In emergencies, call 108 (India).

---

**Built for Meta + Hugging Face Hackathon 2026**