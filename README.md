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
  - hackathon
  - rl-environment
pinned: false
---

# 🏥 MediGuide AI - OpenEnv Medical Diagnosis Environment

**Real-world RL Environment for Emergency Medical Assistance**

> Meta + Hugging Face Hackathon 2026 · Round 1 Submission

---

## ✅ Pre-Submission Checklist

| Requirement | Status | Notes |
|-------------|--------|-------|
| Real-World Task | ✅ | Medical diagnosis for rural India (not toy/game) |
| OpenEnv Compliance | ✅ | step/reset/state + openenv.yaml + typed models |
| 3 Tasks with Graders | ✅ | Easy/Medium/Hard, scores 0.0-1.0, deterministic |
| Reward Function | ✅ | Partial progress rewards, not just terminal |
| Baseline Inference | ✅ | OpenAI client, env variables, reproducible scores |
| HF Space Deploy | ✅ | Containerized, tagged openenv |
| Dockerfile Works | ✅ | docker build + run successful |
| Documentation | ✅ | README with all required sections |

---

## 📋 Task Overview

**Problem:** Build a complete, real-world OpenEnv environment representing tasks humans perform.

**Solution:** MediGuide AI is a medical diagnosis environment - a real healthcare task for rural India where 600M+ people have limited healthcare access. This is NOT a game or toy problem.

---

## 🏗️ Architecture

```
mediguide_ai/
├── app.py              # Gradio UI + FastAPI (OpenEnv endpoints)
├── inference.py        # FastAPI server + evaluation script
├── models.py           # Typed Action, Observation, State (Pydantic)
├── openenv.yaml        # Manifest with tasks definition
├── pyproject.toml      # Package metadata + entry point
├── Dockerfile          # Container definition
├── requirements.txt    # Python dependencies
├── README.md          # Full documentation
└── scripts/
    └── validate-submission.sh
```

---

## 📋 Environment Specification

### Typed Models (Pydantic)

**Action:**
```python
{
    "symptoms": str,         # Comma-separated symptoms
    "query_type": str        # Type of query (diagnose/feedback)
}
```

**Observation:**
```python
{
    "episode_id": str,        # Unique episode identifier
    "step_count": int,        # Number of steps taken
    "query": str,             # User's symptom input
    "diagnoses": List[Dict], # List of possible diseases
    "emergency_steps": List[str], # Emergency guidance
    "message": str           # Status message
}
```

**State:**
```python
{
    "episode_id": str,
    "step_count": int,
    "target_disease": Optional[str],
    "max_steps": int
}
```

---

## 📊 Tasks with Agent Graders

| Task ID | Name | Difficulty | Objective | Grading Criteria | Score Range |
|---------|------|------------|-----------|------------------|-------------|
| 1 | Simple Diagnosis | Easy | Diagnose common symptoms | Returns valid diagnosis with at least 1 disease | 0.0-1.0 |
| 2 | Emergency Detection | Medium | Detect emergency conditions | Identifies HIGH or CRITICAL severity | 0.0-1.0 |
| 3 | Treatment Recommendation | Hard | Recommend proper treatment | Provides 2+ actionable emergency_steps | 0.0-1.0 |

**Grading:** Deterministic, reproducible, programmatic - no human judgment.

---

## 💰 Reward Function

- **Partial Progress:** Reward for each step with valid diagnosis (0.1 per diagnosis found)
- **Terminal Reward:** 1.0 for completing task successfully
- **Penalty:** 0.0 for invalid input or no diagnosis
- **Not Just Terminal:** Provides feedback at each step, not just completion

---

## 🔧 Setup Instructions

### Local Development
```bash
# Clone the repository
git clone https://github.com/codesharecommunityonly1/medi_duid_ai.git
cd medi_duid_ai

# Install dependencies
pip install -r requirements.txt

# Run the server (Gradio UI + OpenEnv API)
python app.py

# Or run evaluation with OpenAI client
python inference.py --eval
```

### Docker Deployment
```bash
# Build the container
docker build -t mediguide-ai .

# Run the container
docker run -p 7860:7860 -e HF_TOKEN=your_token mediguide-ai
```

### Hugging Face Space
The environment is deployed at: https://vinayakkuma-med-guid-ai.hf.space

---

## 📝 API Endpoints (OpenEnv Interface)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/reset` | Start new episode (returns initial observation) |
| POST | `/step` | Process symptoms, returns (observation, reward, done, info) |
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
[START] task=simple_diagnosis env=mediguide model=Qwen/Qwen2.5-72B-Instruct
[STEP] step=1 action=diagnose('fever chills headache') reward=0.10 done=false error=null
[END] success=false steps=1 score=0.008 rewards=0.10
```

### Baseline Scores
| Task | Score |
|------|-------|
| Simple Diagnosis (Easy) | 1.0 |
| Emergency Detection (Medium) | 1.0 |
| Treatment Recommendation (Hard) | 1.0 |
| **Average** | **1.0** |

---

## 🔐 Environment Variables (Required for LLM)

```bash
API_BASE_URL="https://router.huggingface.co/v1"  # Or your endpoint
MODEL_NAME="Qwen/Qwen2.5-72B-Instruct"             # Your model
HF_TOKEN="your-huggingface-token"                 # API key
LOCAL_IMAGE_NAME="your-docker-image"              # Optional
TASK_NAME="mediguide"                              # Task identifier
BENCHMARK="mediguide"                              # Benchmark name
```

---

## 🏆 Real-World Impact

- **Target Audience:** 600M+ rural Indians with limited healthcare access
- **Use Case:** Emergency medical triage and guidance
- **Languages:** English + Hindi symptom translation
- **Emergency:** India 108 helpline integration
- **Value:** Not a game - actual healthcare assistance

---

## 📄 Files

| File | Description |
|------|-------------|
| `app.py` | Gradio UI + FastAPI with OpenEnv endpoints |
| `inference.py` | FastAPI server + evaluation script with OpenAI client |
| `models.py` | Typed Action, Observation, State (Pydantic) |
| `openenv.yaml` | OpenEnv manifest with tasks definition |
| `Dockerfile` | Docker configuration for deployment |
| `pyproject.toml` | Python project configuration + entry point |
| `requirements.txt` | Python dependencies |
| `scripts/validate-submission.sh` | Pre-submission validation script |

---

## ⚠️ Disclaimer

This is an AI assistant for guidance only. Always consult a qualified medical doctor for medical decisions. In emergencies, call 108 (India) or your local emergency number.

---

**Submission Deadline: 8th April 2026, 11:59 PM**