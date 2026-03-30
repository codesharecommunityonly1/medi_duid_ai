"""
MediGuide AI - OpenEnv-Compatible Inference Server
===================================================
FastAPI server implementing the full OpenEnv spec:
  POST /reset   → reset environment, return initial observation
  POST /step    → take a step with an action (medical query)
  GET  /state   → current episode state
  GET  /health  → health check

Also serves a full Gradio web UI at /ui for human interaction.

Meta + Hugging Face Hackathon 2026 — India Track
"""

from __future__ import annotations

import json
import uuid
import time
import threading
from dataclasses import dataclass, field, asdict
from typing import Any, Dict, List, Optional

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel

# ─────────────────────────────────────────────────────────────
# 1.  MEDICAL KNOWLEDGE BASE  (Offline RL Engine)
# ─────────────────────────────────────────────────────────────

DISEASES: Dict[str, Dict] = {
    "malaria": {
        "hindi": "मलेरिया",
        "symptoms": [
            "fever", "chills", "headache", "sweating", "nausea",
            "vomiting", "muscle pain", "fatigue", "cyclical fever",
        ],
        "severity": "HIGH",
        "emergency_steps": [
            "Take antimalarial medication immediately (Chloroquine / Artemisinin)",
            "Stay hydrated — drink ORS or clean water every hour",
            "Use paracetamol 500 mg for fever (NOT aspirin)",
            "Sleep under a mosquito net",
            "Go to the nearest PHC/hospital within 24 hours",
        ],
        "first_aid": [
            "Check temperature every 2 hours",
            "Apply a cold wet cloth on forehead",
            "Keep patient in a cool, ventilated room",
            "Monitor for confusion or seizures → call 108 immediately",
        ],
        "emergency_number": "108",
        "base_confidence": 72,
    },
    "dengue": {
        "hindi": "डेंगू",
        "symptoms": [
            "high fever", "severe headache", "eye pain", "joint pain",
            "rash", "bleeding", "fatigue", "nausea", "platelet drop",
        ],
        "severity": "HIGH",
        "emergency_steps": [
            "Go to hospital IMMEDIATELY — platelet count must be checked",
            "Drink 2–3 litres of fluids (ORS, coconut water, juices)",
            "Take paracetamol ONLY for fever — NO aspirin or ibuprofen",
            "Watch for warning signs: bleeding gums, vomiting blood, difficulty breathing",
            "Rest completely — no physical activity",
        ],
        "first_aid": [
            "Monitor for bleeding signs every 4 hours",
            "Check platelet count at hospital",
            "Avoid NSAIDs completely",
            "Hospital admission if platelets < 100 000",
        ],
        "emergency_number": "108",
        "base_confidence": 65,
    },
    "typhoid": {
        "hindi": "टाइफाइड",
        "symptoms": [
            "prolonged fever", "stomach pain", "headache", "diarrhea",
            "constipation", "weakness", "loss of appetite",
            "continuous fever", "persistent fever",
        ],
        "severity": "MODERATE",
        "emergency_steps": [
            "Widal test / blood culture — confirm diagnosis at lab",
            "Take prescribed antibiotics (Ciprofloxacin / Azithromycin) for full course",
            "Eat only boiled/soft food — khichdi, daliya, rice",
            "Drink boiled or filtered water ONLY",
            "Rest for minimum 2 weeks",
        ],
        "first_aid": [
            "Maintain strict hygiene — wash hands frequently",
            "Isolate patient's utensils",
            "Monitor for intestinal complications",
            "Return to doctor if fever persists > 5 days",
        ],
        "emergency_number": "102",
        "base_confidence": 58,
    },
    "cholera": {
        "hindi": "हैजा",
        "symptoms": [
            "severe diarrhea", "vomiting", "dehydration", "leg cramps",
            "weakness", "watery stool", "rice water stool",
        ],
        "severity": "CRITICAL",
        "emergency_steps": [
            "⚠️ CALL 108 IMMEDIATELY — life-threatening dehydration",
            "Start ORS (Oral Rehydration Solution) RIGHT NOW",
            "Mix: 1 litre boiled water + 6 tsp sugar + 0.5 tsp salt",
            "Give 200–400 ml ORS after every loose motion",
            "Rush to hospital for IV fluids",
        ],
        "first_aid": [
            "Keep giving ORS every 5 minutes",
            "Monitor urine output — if no urine for 6 h → hospital",
            "Strict hand hygiene",
            "Isolate patient and disinfect area",
        ],
        "emergency_number": "108",
        "base_confidence": 80,
    },
    "pneumonia": {
        "hindi": "निमोनिया",
        "symptoms": [
            "high fever", "cough", "chest pain", "difficulty breathing",
            "chills", "fatigue", "shortness of breath", "productive cough",
        ],
        "severity": "HIGH",
        "emergency_steps": [
            "Go to hospital — needs X-ray and blood test",
            "Take prescribed antibiotics for full course (7–14 days)",
            "Sit upright / semi-reclined position to ease breathing",
            "Breathing exercises every 2 hours",
            "Call 108 if lips turn blue or breathing very fast",
        ],
        "first_aid": [
            "Monitor breathing rate (> 30 / min = emergency)",
            "Keep head elevated at 30–45 degrees",
            "Use steam inhalation for congestion",
            "Stay warm — avoid cold air",
        ],
        "emergency_number": "108",
        "base_confidence": 70,
    },
    "heart_attack": {
        "hindi": "दिल का दौरा",
        "symptoms": [
            "chest pain", "chest pressure", "arm pain", "jaw pain",
            "shortness of breath", "sweating", "nausea", "dizziness",
            "left arm pain",
        ],
        "severity": "CRITICAL",
        "emergency_steps": [
            "🚨 CALL 108 / 112 IMMEDIATELY — every minute counts!",
            "Make patient sit/lie down in a comfortable position",
            "Loosen tight clothing (shirt collar, belt)",
            "Give aspirin 325 mg to chew (if not allergic, if conscious)",
            "DO NOT leave patient alone — monitor breathing",
            "Start CPR if patient becomes unconscious and not breathing",
        ],
        "first_aid": [
            "Do NOT let patient walk",
            "Keep calm and reassure patient",
            "Do not give food / water",
            "Note the time symptoms started",
        ],
        "emergency_number": "108",
        "base_confidence": 85,
    },
    "snake_bite": {
        "hindi": "सांप का काटना",
        "symptoms": [
            "bite marks", "swelling", "pain", "numbness", "nausea",
            "dizziness", "difficulty breathing", "bleeding", "fang marks",
        ],
        "severity": "CRITICAL",
        "emergency_steps": [
            "🚨 CALL 108 IMMEDIATELY — anti-venom needed urgently!",
            "Keep patient COMPLETELY STILL — movement spreads venom",
            "Immobilise bitten limb at heart level or below",
            "Remove jewellery/tight items near bite",
            "Mark the edge of swelling with pen and note time",
            "Rush to hospital with anti-venom facility",
        ],
        "first_aid": [
            "DO NOT cut or suck the wound",
            "DO NOT apply tourniquet",
            "DO NOT apply ice",
            "Identify snake type if safe to do so (for anti-venom)",
        ],
        "emergency_number": "108",
        "base_confidence": 90,
    },
    "heatstroke": {
        "hindi": "लू लगना / हीट स्ट्रोक",
        "symptoms": [
            "very high fever", "hot dry skin", "confusion", "dizziness",
            "no sweating", "rapid heartbeat", "unconsciousness",
            "collapsed", "not sweating", "hot skin", "summer collapse",
        ],
        "severity": "CRITICAL",
        "emergency_steps": [
            "🚨 CALL 108 — medical emergency!",
            "Move to shade or cool area IMMEDIATELY",
            "Remove excess clothing",
            "Apply cold water / ice packs to neck, armpits, groin",
            "Fan the patient aggressively",
            "If conscious, give cool water to drink slowly",
        ],
        "first_aid": [
            "Do NOT give aspirin or paracetamol",
            "Monitor temperature continuously",
            "Continue cooling until temp < 38.5 °C",
            "Watch for seizures",
        ],
        "emergency_number": "108",
        "base_confidence": 82,
    },
}

# ─────────────────────────────────────────────────────────────
# 2.  RL ENGINE  (Q-learning style weight updates)
# ─────────────────────────────────────────────────────────────

HINDI_MAP = {
    "बुखार": "fever", "सिरदर्द": "headache", "उल्टी": "vomiting",
    "कमजोरी": "fatigue", "ठंड": "chills", "पेट दर्द": "stomach pain",
    "दस्त": "diarrhea", "खांसी": "cough", "सांस": "shortness of breath",
    "चक्कर": "dizziness", "दर्द": "pain", "पसीना": "sweating",
    "सीने": "chest pain", "हाथ में दर्द": "arm pain",
    "तकलीफ": "difficulty breathing", "भूख": "loss of appetite",
}


class RLMedicalEngine:
    """Offline RL engine: State=Symptoms, Action=Diagnosis, Reward=Feedback"""

    learning_rate: float = 0.15

    def __init__(self) -> None:
        self.weights: Dict[str, Dict[str, float]] = {}
        self.total_diagnoses: int = 0
        self.correct_diagnoses: int = 0
        self.total_reward: float = 0.0
        self._init_weights()

    def _init_weights(self) -> None:
        for disease, data in DISEASES.items():
            self.weights[disease] = {s: 1.0 for s in data["symptoms"]}

    def _tokenize(self, text: str) -> List[str]:
        text = text.lower()
        for h, e in HINDI_MAP.items():
            text = text.replace(h, e)
        found = []
        for disease, data in DISEASES.items():
            for symptom in data["symptoms"]:
                if symptom in text:
                    found.append(symptom)
        return list(set(found))

    def diagnose(self, symptoms_text: str) -> List[Dict]:
        tokens = self._tokenize(symptoms_text)
        if not tokens:
            return []
        scores: Dict[str, Dict] = {}
        for disease, sw in self.weights.items():
            score = sum(sw.get(t, 0) for t in tokens)
            matched = [t for t in tokens if t in sw]
            if score > 0:
                scores[disease] = {"score": score, "matched": matched}
        if not scores:
            return []
        total = sum(v["score"] for v in scores.values())
        results = []
        for disease, data in sorted(scores.items(), key=lambda x: -x[1]["score"])[:3]:
            base = DISEASES[disease]["base_confidence"]
            conf = min(95, int((data["score"] / total) * 100 * 1.5 + base * 0.3))
            results.append({
                "disease": disease,
                "confidence": conf,
                "matched_symptoms": data["matched"],
                **DISEASES[disease],
            })
        return results

    def update_weights(self, disease: str, correct: bool) -> None:
        self.total_diagnoses += 1
        reward = 1.0 if correct else -0.5
        self.total_reward += reward
        if correct:
            self.correct_diagnoses += 1
        if disease in self.weights:
            for s in self.weights[disease]:
                delta = self.learning_rate * reward
                self.weights[disease][s] = max(0.1, self.weights[disease][s] + delta)

    @property
    def accuracy(self) -> float:
        return round(self.correct_diagnoses / max(1, self.total_diagnoses) * 100, 1)

    def stats(self) -> Dict:
        return {
            "total_diagnoses": self.total_diagnoses,
            "correct_diagnoses": self.correct_diagnoses,
            "accuracy_pct": self.accuracy,
            "total_reward": round(self.total_reward, 3),
            "learning_rate": self.learning_rate,
            "diseases_known": len(DISEASES),
        }


# Singleton RL engine
_engine = RLMedicalEngine()

# ─────────────────────────────────────────────────────────────
# 3.  OPENENV DATA MODELS  (Pydantic)
# ─────────────────────────────────────────────────────────────

class MedicalAction(BaseModel):
    """Action submitted by an RL agent or user."""
    symptoms: str = ""
    feedback_disease: Optional[str] = None   # for RL reward updates
    feedback_correct: Optional[bool] = None  # True / False
    query_type: str = "diagnose"             # "diagnose" | "feedback" | "emergency"


class DiagnosisEntry(BaseModel):
    disease: str
    confidence: int
    severity: str
    hindi_name: str
    matched_symptoms: List[str]
    emergency_steps: List[str]
    first_aid: List[str]
    emergency_number: str


class MedicalObservation(BaseModel):
    """Observation returned after reset() or step()."""
    episode_id: str
    step_count: int
    query: str
    diagnoses: List[DiagnosisEntry]
    rl_stats: Dict[str, Any]
    message: str
    success: bool
    reward: float = 0.0
    done: bool = False


class EpisodeState(BaseModel):
    """Lightweight episode state (GET /state)."""
    episode_id: str
    step_count: int
    total_reward: float
    rl_accuracy_pct: float
    total_diagnoses: int
    status: str


class StepResult(BaseModel):
    observation: MedicalObservation
    reward: float
    done: bool
    info: Dict[str, Any] = {}


# ─────────────────────────────────────────────────────────────
# 4.  EPISODE STATE  (thread-safe)
# ─────────────────────────────────────────────────────────────

_lock = threading.Lock()
_episode: Dict[str, Any] = {
    "id": str(uuid.uuid4()),
    "step_count": 0,
    "episode_reward": 0.0,
    "started_at": time.time(),
}


def _new_episode() -> None:
    global _episode
    with _lock:
        _episode = {
            "id": str(uuid.uuid4()),
            "step_count": 0,
            "episode_reward": 0.0,
            "started_at": time.time(),
        }


def _build_observation(query: str, diagnoses: List[Dict], reward: float,
                       message: str, success: bool, done: bool = False) -> MedicalObservation:
    entries = []
    for d in diagnoses:
        entries.append(DiagnosisEntry(
            disease=d["disease"],
            confidence=d["confidence"],
            severity=d["severity"],
            hindi_name=d.get("hindi", ""),
            matched_symptoms=d.get("matched_symptoms", []),
            emergency_steps=d.get("emergency_steps", []),
            first_aid=d.get("first_aid", []),
            emergency_number=d.get("emergency_number", "108"),
        ))
    return MedicalObservation(
        episode_id=_episode["id"],
        step_count=_episode["step_count"],
        query=query,
        diagnoses=entries,
        rl_stats=_engine.stats(),
        message=message,
        success=success,
        reward=reward,
        done=done,
    )


# ─────────────────────────────────────────────────────────────
# 5.  FASTAPI APPLICATION
# ─────────────────────────────────────────────────────────────

app = FastAPI(
    title="MediGuide AI — OpenEnv Environment",
    description=(
        "Offline RL-powered Emergency Medical Assistant for rural India. "
        "OpenEnv-compatible: POST /reset, POST /step, GET /state. "
        "Meta + Hugging Face Hackathon 2026."
    ),
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── OpenEnv Core Endpoints ─────────────────────────────────

@app.post("/reset", response_model=StepResult, tags=["OpenEnv"])
async def reset():
    """
    OpenEnv reset() — start a new episode.
    Returns the initial observation with an empty diagnosis list and
    a welcome message. The RL engine weights are preserved across
    episodes (they represent long-term learned knowledge).
    """
    _new_episode()
    obs = _build_observation(
        query="",
        diagnoses=[],
        reward=0.0,
        message=(
            "MediGuide AI environment ready. "
            "POST /step with {'symptoms': '<your symptoms>'} to diagnose. "
            "Covers: Malaria, Dengue, Typhoid, Cholera, Pneumonia, "
            "Heart Attack, Snake Bite, Heatstroke. Hindi supported."
        ),
        success=True,
        done=False,
    )
    return StepResult(observation=obs, reward=0.0, done=False, info={
        "diseases_supported": list(DISEASES.keys()),
        "rl_engine": "Q-learning weight updates",
        "offline": True,
        "hindi_support": True,
    })


@app.post("/step", response_model=StepResult, tags=["OpenEnv"])
async def step(action: MedicalAction):
    """
    OpenEnv step() — send an action (medical query or feedback).

    **diagnose** (default):
    ```json
    {"symptoms": "fever chills headache sweating"}
    ```

    **feedback** (RL reward update):
    ```json
    {"query_type": "feedback", "feedback_disease": "malaria", "feedback_correct": true}
    ```

    **emergency** (quick SOS guide):
    ```json
    {"query_type": "emergency", "symptoms": "chest pain"}
    ```
    """
    with _lock:
        _episode["step_count"] += 1

    reward = 0.0
    done = False

    # ── Feedback / RL update ──────────────────────────────
    if action.query_type == "feedback":
        if action.feedback_disease and action.feedback_correct is not None:
            _engine.update_weights(action.feedback_disease, action.feedback_correct)
            reward = 1.0 if action.feedback_correct else -0.5
            with _lock:
                _episode["episode_reward"] += reward
            obs = _build_observation(
                query=f"feedback:{action.feedback_disease}",
                diagnoses=[],
                reward=reward,
                message=(
                    f"RL weight update applied for '{action.feedback_disease}'. "
                    f"Reward: {reward:+.1f}. "
                    f"New accuracy: {_engine.accuracy}%"
                ),
                success=True,
            )
            return StepResult(observation=obs, reward=reward, done=done,
                              info={"rl_stats": _engine.stats()})
        raise HTTPException(status_code=422,
                            detail="feedback requires 'feedback_disease' and 'feedback_correct'")

    # ── Emergency guide ───────────────────────────────────
    if action.query_type == "emergency":
        critical = [d for d, v in DISEASES.items() if v["severity"] == "CRITICAL"]
        obs = _build_observation(
            query="emergency_guide",
            diagnoses=[],
            reward=0.0,
            message=(
                "🚨 EMERGENCY NUMBERS INDIA: Ambulance 108 | National 112 | "
                "Police 100 | Fire 101. "
                f"Critical conditions: {', '.join(critical)}. "
                "Seek immediate medical help."
            ),
            success=True,
        )
        return StepResult(observation=obs, reward=0.0, done=done, info={
            "emergency_numbers": {"ambulance": "108", "national": "112",
                                  "police": "100", "fire": "101"},
            "critical_conditions": critical,
        })

    # ── Diagnosis ─────────────────────────────────────────
    symptoms = (action.symptoms or "").strip()
    if not symptoms:
        raise HTTPException(status_code=422,
                            detail="'symptoms' field is required for query_type='diagnose'")

    diagnoses = _engine.diagnose(symptoms)

    if not diagnoses:
        obs = _build_observation(
            query=symptoms,
            diagnoses=[],
            reward=0.0,
            message=(
                "No matching condition found. Please describe symptoms in more detail. "
                "Example: 'fever chills headache sweating nausea'"
            ),
            success=False,
        )
        return StepResult(observation=obs, reward=0.0, done=done, info={})

    top = diagnoses[0]
    reward = round(top["confidence"] / 100.0, 3)
    with _lock:
        _episode["episode_reward"] += reward
    _engine.total_diagnoses += 1

    obs = _build_observation(
        query=symptoms,
        diagnoses=diagnoses,
        reward=reward,
        message=(
            f"Top diagnosis: {top['disease'].replace('_', ' ').title()} "
            f"({top['confidence']}% confidence, severity: {top['severity']}). "
            f"Emergency number: {top['emergency_number']}."
        ),
        success=True,
    )
    return StepResult(observation=obs, reward=reward, done=done, info={
        "top_disease": top["disease"],
        "top_confidence": top["confidence"],
        "matched_symptoms": top["matched_symptoms"],
    })


@app.get("/state", response_model=EpisodeState, tags=["OpenEnv"])
async def state():
    """OpenEnv state() — current episode metadata."""
    with _lock:
        ep = dict(_episode)
    return EpisodeState(
        episode_id=ep["id"],
        step_count=ep["step_count"],
        total_reward=round(ep["episode_reward"], 3),
        rl_accuracy_pct=_engine.accuracy,
        total_diagnoses=_engine.total_diagnoses,
        status="running",
    )


# ── Health & Info ─────────────────────────────────────────

@app.get("/health", tags=["System"])
async def health():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "MediGuide AI",
        "version": "2.0.0",
        "openenv_compatible": True,
        "rl_engine": "active",
        "diseases_loaded": len(DISEASES),
    }


@app.get("/", tags=["System"])
async def root():
    """Root — returns JSON description + links."""
    return {
        "name": "MediGuide AI",
        "description": "Offline RL-powered Emergency Medical Assistant for rural India",
        "hackathon": "Meta + Hugging Face 2026",
        "openenv_endpoints": {
            "reset": "POST /reset",
            "step":  "POST /step",
            "state": "GET /state",
        },
        "web_ui": "/ui",
        "api_docs": "/docs",
        "health": "/health",
        "version": "2.0.0",
    }


# ── Gradio Web UI (served at /ui) ─────────────────────────

def _launch_gradio():
    """Launch Gradio on port 7861 then mount at /ui via redirect."""
    try:
        import gradio as gr

        CUSTOM_CSS = """
body, .gradio-container { background: #0d1117 !important; }
.gr-button-primary { background: linear-gradient(135deg,#00C851,#007E33)!important;
    border:none!important; color:white!important; font-weight:600!important; }
.gr-button-secondary { background: linear-gradient(135deg,#FF4444,#CC0000)!important;
    border:none!important; color:white!important; font-weight:600!important; }
label { color:#ccc!important; }
textarea, input { background:#0d1117!important; color:#e6edf3!important;
    border:1px solid #30363d!important; border-radius:8px!important; }
"""

        HEADER = """
<div style="background:linear-gradient(135deg,#0d1117,#161b22);padding:24px;
border-radius:16px;text-align:center;margin-bottom:16px;
border:1px solid rgba(51,181,229,0.2)">
  <div style="font-size:3em">🏥</div>
  <h1 style="margin:8px 0 4px;color:white;font-size:1.8em">MediGuide AI</h1>
  <p style="color:#33B5E5;margin:0">Offline RL-Powered Emergency Medical Assistant</p>
  <p style="color:#666;margin:8px 0 0;font-size:.85em">
    Rural India · Hindi + English · 100% Offline · Meta + HF Hackathon 2026</p>
  <div style="display:flex;justify-content:center;gap:10px;margin-top:12px;flex-wrap:wrap">
    <span style="background:rgba(0,200,81,.15);border:1px solid #00C85164;
      color:#00C851;padding:4px 12px;border-radius:20px;font-size:.8em">✅ RL Learning</span>
    <span style="background:rgba(51,181,229,.15);border:1px solid #33B5E564;
      color:#33B5E5;padding:4px 12px;border-radius:20px;font-size:.8em">🧠 AI Diagnosis</span>
    <span style="background:rgba(255,187,51,.15);border:1px solid #FFBB3364;
      color:#FFBB33;padding:4px 12px;border-radius:20px;font-size:.8em">🇮🇳 Hindi</span>
    <span style="background:rgba(255,68,68,.15);border:1px solid #FF444464;
      color:#FF4444;padding:4px 12px;border-radius:20px;font-size:.8em">🚨 Emergency SOS</span>
    <span style="background:rgba(138,43,226,.15);border:1px solid #8a2be264;
      color:#bf7fff;padding:4px 12px;border-radius:20px;font-size:.8em">⚙️ OpenEnv API</span>
  </div>
</div>"""

        DEMO_SCENARIOS = [
            ("🦟 Malaria",         "fever chills headache sweating nausea muscle pain"),
            ("🦠 Dengue",          "high fever severe headache eye pain joint pain rash"),
            ("🌊 Cholera",         "severe diarrhea vomiting dehydration leg cramps watery stool"),
            ("❤️ Heart Attack",    "chest pain chest pressure arm pain jaw pain shortness of breath sweating"),
            ("🐍 Snake Bite",      "bite marks swelling pain numbness nausea dizziness bleeding"),
            ("🌡️ Heatstroke",      "very high fever hot dry skin confusion dizziness not sweating collapsed"),
            ("🫁 Pneumonia",       "high fever cough chest pain difficulty breathing chills fatigue"),
            ("🦠 Typhoid",         "prolonged fever stomach pain headache diarrhea weakness loss of appetite"),
            ("🤒 Hindi – बुखार",   "बुखार सिरदर्द उल्टी कमजोरी ठंड लगना"),
            ("💊 Hindi – पेट दर्द","पेट दर्द दस्त उल्टी कमजोरी भूख नहीं"),
            ("⚡ Multi-symptom",   "fever headache vomiting diarrhea dehydration weakness"),
        ]

        def diagnose_ui(symptoms, language):
            if not symptoms or len(symptoms.strip()) < 3:
                return ('<div style="color:#FF4444;padding:20px;text-align:center">'
                        '⚠️ Please enter at least one symptom.</div>', "")
            results = _engine.diagnose(symptoms)
            if not results:
                return ('<div style="color:#FFBB33;padding:20px;text-align:center">'
                        '🔍 No matching condition found. Please add more detail.</div>', "")
            cards = ""
            for i, d in enumerate(results):
                sev_color = {"CRITICAL": "#CC0000", "HIGH": "#FF4444",
                             "MODERATE": "#FF9900"}.get(d["severity"], "#FFBB33")
                rank = ["🥇 Most Likely", "🥈 Possible", "🥉 Less Likely"][i]
                matched = ", ".join(d["matched_symptoms"]) or "general match"
                steps_html = "".join(
                    f'<li style="color:#eee;font-size:.88em;padding:3px 0">{s}</li>'
                    for s in d["emergency_steps"]
                )
                cards += f"""
<div style="background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.1);
  border-left:4px solid {sev_color};border-radius:12px;padding:16px;margin-bottom:12px">
  <div style="display:flex;justify-content:space-between;flex-wrap:wrap;gap:8px">
    <div>
      <span style="color:#aaa;font-size:.8em">{rank}</span>
      <h3 style="margin:4px 0;color:white">{d['disease'].replace('_',' ').title()}</h3>
      <div style="color:#aaa;font-size:.85em">{d.get('hindi','')}</div>
    </div>
    <div style="text-align:right">
      <span style="background:{sev_color};color:white;padding:3px 10px;
        border-radius:20px;font-size:.75em">{d['severity']}</span>
      <div style="color:#FFBB33;font-size:1.3em;font-weight:bold;margin-top:4px">
        {d['confidence']}%</div>
    </div>
  </div>
  <div style="background:rgba(255,255,255,.1);border-radius:6px;height:8px;
    overflow:hidden;margin:10px 0">
    <div style="background:linear-gradient(90deg,{sev_color},{sev_color}88);
      width:{d['confidence']}%;height:100%;border-radius:6px"></div>
  </div>
  <div style="color:#aaa;font-size:.8em">
    Matched: <span style="color:#33B5E5">{matched}</span></div>
  <details style="margin-top:10px">
    <summary style="color:#FF4444;cursor:pointer;font-size:.88em">
      🚨 Emergency Steps</summary>
    <ol style="margin:8px 0;padding-left:20px">{steps_html}</ol>
    <div style="color:#FFBB33;font-size:.85em;margin-top:4px">
      📞 Call: <b>{d['emergency_number']}</b></div>
  </details>
</div>"""
            top = results[0]
            fa = "".join(
                f'<li style="color:#ccc;font-size:.88em;padding:3px 0">{s}</li>'
                for s in top["first_aid"]
            )
            first_aid = f"""
<div style="background:linear-gradient(135deg,#0d2818,#0a1a10);padding:20px;
  border-radius:16px;color:white;border:1px solid rgba(0,200,81,.2)">
  <h3 style="margin:0 0 10px;color:#00C851">🩹 First Aid – {top['disease'].replace('_',' ').title()}</h3>
  <ul style="margin:0;padding-left:20px">{fa}</ul>
  <div style="margin-top:12px;padding:10px;background:rgba(51,181,229,.1);
    border-radius:8px;color:#33B5E5;font-size:.85em">
    💡 RL Engine: {_engine.total_diagnoses} diagnoses · {_engine.accuracy}% accuracy
  </div>
</div>"""
            result_html = f"""
<div style="background:linear-gradient(135deg,#0d1117,#161b22);padding:20px;
  border-radius:16px;color:white">
  <h2 style="margin:0 0 16px;color:#33B5E5">🧠 AI Diagnosis Report</h2>
  {cards}
  <div style="color:#666;font-size:.75em;text-align:center;margin-top:8px">
    ⚠️ AI guidance only — always consult a qualified doctor.</div>
</div>"""
            return result_html, first_aid

        def load_scenario(label):
            for lbl, syms in DEMO_SCENARIOS:
                if lbl == label:
                    return syms
            return ""

        def submit_feedback(disease, correct):
            if not disease:
                return '<div style="color:#FF4444">⚠️ Run a diagnosis first.</div>'
            _engine.update_weights(disease.lower().replace(" ", "_"), correct == "✅ Correct")
            color = "#00C851" if correct == "✅ Correct" else "#FF4444"
            return f"""
<div style="background:#0d1117;padding:14px;border-radius:10px;
  border:1px solid {color}40;color:white">
  <b style="color:{color}">{'🧠 AI Learned!' if correct=='✅ Correct' else '📚 Noted!'}</b>
  <div style="color:#ccc;font-size:.9em;margin-top:6px">
    Accuracy now: <b>{_engine.accuracy}%</b> ·
    Total reward: <b>{round(_engine.total_reward,2)}</b>
  </div>
</div>"""

        def api_docs_html():
            return """
<div style="background:#0d1117;padding:20px;border-radius:14px;color:white;font-family:monospace">
  <h3 style="color:#33B5E5">⚙️ OpenEnv HTTP API</h3>
  <p style="color:#aaa">Your Space exposes a full OpenEnv-compatible HTTP API:</p>
  <div style="background:#161b22;padding:14px;border-radius:8px;margin:8px 0">
    <span style="color:#FFBB33">POST</span>
    <span style="color:#33B5E5"> /reset</span>
    <span style="color:#666"> — start new episode</span>
  </div>
  <div style="background:#161b22;padding:14px;border-radius:8px;margin:8px 0">
    <span style="color:#FFBB33">POST</span>
    <span style="color:#33B5E5"> /step</span>
    <span style="color:#666"> — diagnose: </span>
    <span style="color:#ccc">{"symptoms": "fever chills"}</span>
  </div>
  <div style="background:#161b22;padding:14px;border-radius:8px;margin:8px 0">
    <span style="color:#00C851">GET</span>
    <span style="color:#33B5E5"> /state</span>
    <span style="color:#666"> — current episode state</span>
  </div>
  <div style="background:#161b22;padding:14px;border-radius:8px;margin:8px 0">
    <span style="color:#00C851">GET</span>
    <span style="color:#33B5E5"> /health</span>
    <span style="color:#666"> — health check</span>
  </div>
  <div style="background:#161b22;padding:14px;border-radius:8px;margin:8px 0">
    <span style="color:#00C851">GET</span>
    <span style="color:#33B5E5"> /docs</span>
    <span style="color:#666"> — interactive Swagger UI</span>
  </div>
  <div style="margin-top:16px;color:#aaa;font-size:.85em">
    Replace <code style="color:#FFBB33">YOUR_SPACE_URL</code> with
    <code style="color:#33B5E5">https://vinayakkuma-med-guid-ai.hf.space</code>
  </div>
</div>"""

        with gr.Blocks(theme=gr.themes.Base(), css=CUSTOM_CSS,
                       title="MediGuide AI") as demo:
            gr.HTML(HEADER)

            with gr.Tabs():
                # ── Diagnosis Tab ──────────────────────────
                with gr.TabItem("🩺 Smart Diagnosis"):
                    with gr.Row():
                        with gr.Column(scale=1):
                            gr.Markdown("### Enter Symptoms")
                            language = gr.Radio(["English", "Hindi / हिंदी"],
                                                value="English", label="Language")
                            symptoms_in = gr.Textbox(
                                label="Describe your symptoms",
                                placeholder="e.g. fever, headache, chills, nausea…",
                                lines=4,
                            )
                            with gr.Row():
                                diag_btn = gr.Button("🔍 Diagnose Now", variant="primary", size="lg")
                                clr_btn  = gr.Button("🗑️ Clear", size="lg")
                            gr.Markdown("### 🎯 Demo Scenarios")
                            demo_dd  = gr.Dropdown([lbl for lbl, _ in DEMO_SCENARIOS],
                                                   label="Load test scenario", value=None)
                            load_btn = gr.Button("▶️ Load", size="sm")
                        with gr.Column(scale=2):
                            result_out   = gr.HTML()
                            first_aid_out = gr.HTML()

                    with gr.Accordion("🧠 RL Feedback", open=False):
                        last_disease = gr.Textbox(label="Last diagnosis", interactive=False)
                        fb_radio = gr.Radio(["✅ Correct", "❌ Wrong"], value="✅ Correct",
                                            label="Was it correct?")
                        fb_btn   = gr.Button("📤 Submit Feedback", variant="primary")
                        fb_out   = gr.HTML()

                    def _diag(syms, lang):
                        r, fa = diagnose_ui(syms, lang)
                        ds = _engine.diagnose(syms)
                        top = ds[0]["disease"].replace("_", " ").title() if ds else ""
                        return r, fa, top

                    diag_btn.click(_diag, [symptoms_in, language],
                                   [result_out, first_aid_out, last_disease])
                    clr_btn.click(lambda: ("", "", gr.HTML(""), gr.HTML(""), ""),
                                  outputs=[symptoms_in, last_disease,
                                           result_out, first_aid_out, last_disease])
                    load_btn.click(load_scenario, [demo_dd], [symptoms_in])
                    fb_btn.click(submit_feedback, [last_disease, fb_radio], [fb_out])

                # ── Emergency SOS ──────────────────────────
                with gr.TabItem("🚨 Emergency SOS"):
                    sos_out = gr.HTML()
                    def _sos():
                        rows = ""
                        for did, d in DISEASES.items():
                            if d["severity"] == "CRITICAL":
                                rows += f"""
<div style="background:rgba(255,255,255,.04);border-left:4px solid #CC0000;
  border-radius:8px;padding:14px;margin-bottom:10px">
  <b style="color:white">{did.replace('_',' ').title()}</b>
  <span style="color:#aaa;font-size:.85em;margin-left:8px">{d['hindi']}</span>
  <span style="background:#FF4444;color:white;padding:2px 8px;border-radius:10px;
    font-size:.75em;float:right">CRITICAL</span>
  <div style="color:#FFBB33;font-size:.85em;margin-top:6px">
    📞 {d['emergency_number']} · {d['emergency_steps'][0]}</div>
</div>"""
                        return f"""
<div style="background:linear-gradient(135deg,#2d0000,#1a0000);padding:20px;
  border-radius:16px;color:white;border:1px solid rgba(255,68,68,.3)">
  <h2 style="color:#FF4444;text-align:center">🚨 Emergency Guide</h2>
  {rows}
  <div style="margin-top:16px;padding:12px;background:rgba(255,187,51,.1);
    border-radius:8px;text-align:center">
    <b style="color:#FFBB33">🏥 India Emergency Numbers</b><br>
    <span style="color:#ccc">Ambulance: <b>108</b> · National: <b>112</b>
     · Police: <b>100</b> · Fire: <b>101</b></span>
  </div>
</div>"""
                    demo.load(_sos, outputs=[sos_out])
                    gr.Button("🔄 Refresh", size="sm").click(_sos, outputs=[sos_out])

                # ── API Docs Tab ───────────────────────────
                with gr.TabItem("⚙️ OpenEnv API"):
                    api_out = gr.HTML()
                    demo.load(api_docs_html, outputs=[api_out])

        demo.launch(server_name="0.0.0.0", server_port=7861,
                    share=False, quiet=True)
    except Exception as exc:
        print(f"[Gradio] Failed to start UI: {exc}")


# Redirect /ui → Gradio
@app.get("/ui", tags=["UI"])
async def ui_redirect():
    return HTMLResponse(
        '<meta http-equiv="refresh" content="0;url=http://localhost:7861">',
        status_code=200,
    )


# ─────────────────────────────────────────────────────────────
# 6.  ENTRYPOINT
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    # Launch Gradio in background thread
    t = threading.Thread(target=_launch_gradio, daemon=True)
    t.start()

    # Start FastAPI (OpenEnv HTTP server) on 7860
    uvicorn.run(app, host="0.0.0.0", port=7860, log_level="info")
