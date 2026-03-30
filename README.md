---
title: MediGuide AI
emoji: 🏥
colorFrom: red
colorTo: blue
sdk: gradio
app_port: 7860
short_description: Offline RL Emergency Medical Assistant for rural India
tags:
  - openenv
  - medical
  - healthcare
  - emergency
  - hindi
  - hackathon
pinned: false
disable_guest: true
---

# 🏥 MediGuide AI

**Offline RL-Powered Emergency Medical Assistant for Rural India**

> Meta + Hugging Face Hackathon 2026 · OpenEnv Track

---

## 🚀 What It Does

MediGuide AI is a **fully OpenEnv-compatible reinforcement learning environment** that acts as an emergency medical assistant for rural India — where internet is scarce and doctors are far away.

The AI diagnoses symptoms, provides emergency first-aid steps, and **learns in real-time from user feedback** using a Q-learning style weight update system.

---

## ⚙️ OpenEnv HTTP API

This Space exposes a full OpenEnv-compatible HTTP API:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/reset` | Start a new episode |
| `POST` | `/step`  | Diagnose symptoms / submit feedback |
| `GET`  | `/state` | Get current episode state |
| `GET`  | `/health`| Health check |
| `GET`  | `/docs`  | Interactive Swagger UI |

### Example Usage

```python
import requests

BASE = "https://vinayakkuma-med-guid-ai.hf.space"

# 1. Reset the environment
r = requests.post(f"{BASE}/reset")
print(r.json()["observation"]["message"])

# 2. Diagnose symptoms
r = requests.post(f"{BASE}/step", json={"symptoms": "fever chills headache sweating"})
obs = r.json()["observation"]
print(obs["diagnoses"][0]["disease"], obs["diagnoses"][0]["confidence"])

# 3. Submit RL feedback (teach the AI)
r = requests.post(f"{BASE}/step", json={
    "query_type": "feedback",
    "feedback_disease": "malaria",
    "feedback_correct": True
})

# 4. Check state
r = requests.get(f"{BASE}/state")
print(r.json())
```

---

## 🧠 Technical Architecture

```
┌─────────────────────────────────────────────────────────┐
│               MediGuide AI — Docker Container           │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │    FastAPI Server  (port 7860)                  │   │
│  │    ┌─ POST /reset  ─── new episode              │   │
│  │    ├─ POST /step   ─── diagnose / feedback      │   │
│  │    ├─ GET  /state  ─── episode metadata         │   │
│  │    └─ GET  /health ─── health check             │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │    RL Medical Engine                            │   │
│  │    State   = Symptom tokens                     │   │
│  │    Action  = Disease prediction                 │   │
│  │    Reward  = +1.0 correct / -0.5 wrong          │   │
│  │    Update  = Q-learning weight adjustment       │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │    Gradio Web UI  (port 7861, served at /ui)    │   │
│  │    13 demo scenarios · Hindi support            │   │
│  │    Confidence bars · Severity badges            │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 🌍 Features

| Feature | Details |
|---------|---------|
| **8 Diseases** | Malaria, Dengue, Typhoid, Cholera, Pneumonia, Heart Attack, Snake Bite, Heatstroke |
| **RL Learning** | Real-time Q-learning from user feedback |
| **Hindi Support** | Full Hindi symptom input + translations |
| **Emergency SOS** | Quick critical care guides + India helpline numbers |
| **OpenEnv API** | Full POST /reset, POST /step, GET /state compliance |
| **Offline-First** | No external API calls — 100% self-contained |
| **Confidence Bars** | Percentage confidence + severity badges per diagnosis |
| **Flutter App** | Full mobile app in `fresh_app/` (BLoC, Hive, offline) |

---

## 🇮🇳 Impact

- Targets **600M+ rural Indians** with limited healthcare access
- Works **without internet** — all logic runs locally
- Emergency guidance in **Hindi** (local language)
- Covers the most common **life-threatening conditions** in rural India
- Real-time **RL learning** improves accuracy with each use

---

## ⚠️ Disclaimer

This is an AI assistant for guidance only. Always consult a qualified medical doctor for any medical decisions. In emergencies, call **108** (Ambulance) or **112** (National Emergency).
