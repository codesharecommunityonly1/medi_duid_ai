---
title: MediGuide AI
emoji: 🏥
colorFrom: red
colorTo: blue
sdk: docker
app_port: 7860
short_description: OpenEnv-Compatible RL Medical Diagnosis Environment
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

# 🏥 MediGuide AI

**OpenEnv-Compatible RL-Powered Emergency Medical Assistant**

> Meta + Hugging Face Hackathon 2026 · OpenEnv Track

---

## ⚠️ OpenEnv Validation

This Space provides **OpenEnv-compatible HTTP API** for RL environment validation:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/reset` | Start new episode (OpenEnv required) |
| `POST` | `/step` | Diagnose symptoms / submit feedback |
| `GET` | `/state` | Get episode state |
| `GET` | `/health` | Health check |

### Example Usage

```python
import requests

BASE = "https://vinayakkuma-med-guid-ai.hf.space"

# Reset environment (required for OpenEnv)
r = requests.post(f"{BASE}/reset")
print(r.json()["observation"]["message"])

# Diagnose symptoms
r = requests.post(f"{BASE}/step", json={"symptoms": "fever chills headache"})
obs = r.json()["observation"]
print(obs["diagnoses"][0]["disease"], obs["diagnoses"][0]["confidence"])

# Submit feedback (RL learning)
r = requests.post(f"{BASE}/step", json={
    "query_type": "feedback",
    "feedback_disease": "malaria",
    "feedback_correct": True
})
```

---

## 🧠 Features

- **8 Diseases**: Malaria, Dengue, Typhoid, Cholera, Pneumonia, Heart Attack, Snake Bite, Heatstroke
- **RL Learning**: Q-learning from user feedback
- **Hindi Support**: Full Hindi symptom translation
- **Emergency SOS**: Critical care guides + India 108
- **OpenEnv API**: Full /reset, /step, /state compliance

---

## 🇮🇳 Impact

Targets 600M+ rural Indians with offline AI medical diagnosis.
