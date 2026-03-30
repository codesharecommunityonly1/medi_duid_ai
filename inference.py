"""
MediGuide AI - OpenEnv-Compatible Medical Diagnosis Environment
==============================================================
RL-powered Emergency Medical Assistant for Rural India
Compatible with OpenEnv validation: POST /reset, POST /step, GET /state
"""

import json
import uuid
import time
import threading
from dataclasses import dataclass, field, asdict
from typing import Any, Dict, List, Optional

import gradio as gr
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel

# ─────────────────────────────────────────────────────────────
# 1. MEDICAL KNOWLEDGE BASE
# ─────────────────────────────────────────────────────────────

DISEASES: Dict[str, Dict] = {
    "malaria": {
        "hindi": "मलेरिया",
        "symptoms": [
            "fever",
            "chills",
            "headache",
            "sweating",
            "nausea",
            "vomiting",
            "muscle pain",
            "fatigue",
            "cyclical fever",
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
            "high fever",
            "severe headache",
            "eye pain",
            "joint pain",
            "rash",
            "bleeding",
            "fatigue",
            "nausea",
            "platelet drop",
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
            "Hospital admission if platelets < 100,000",
        ],
        "emergency_number": "108",
        "base_confidence": 65,
    },
    "typhoid": {
        "hindi": "टाइफाइड",
        "symptoms": [
            "prolonged fever",
            "stomach pain",
            "headache",
            "diarrhea",
            "constipation",
            "weakness",
            "loss of appetite",
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
        "emergency_number": "108",
        "base_confidence": 58,
    },
    "cholera": {
        "hindi": "हैजा",
        "symptoms": [
            "severe diarrhea",
            "vomiting",
            "dehydration",
            "cramps",
            "low blood pressure",
            "rapid heartbeat",
        ],
        "severity": "CRITICAL",
        "emergency_steps": [
            "Start ORS solution immediately — 1 litre water + 6 tsp sugar + 1/2 tsp salt",
            "Go to hospital immediately — cholera can kill within hours",
            "Keep drinking ORS while transporting",
            "Zinc supplementation for children",
            "Antibiotics: Doxycycline or Azithromycin",
        ],
        "first_aid": [
            "Do NOT stop diarrhea/vomiting — it's the body's way of clearing infection",
            "Replace fluids constantly with ORS",
            "Watch for signs of severe dehydration",
            "Clean all surfaces with chlorine bleach",
        ],
        "emergency_number": "108",
        "base_confidence": 70,
    },
    "pneumonia": {
        "hindi": "निमोनिया",
        "symptoms": [
            "cough",
            "fever",
            "chest pain",
            "shortness of breath",
            "phlegm",
            "fatigue",
            "confusion",
        ],
        "severity": "HIGH",
        "emergency_steps": [
            "Go to hospital immediately — pneumonia can be fatal",
            "Start antibiotics (Amoxicillin / Azithromycin) if prescribed",
            "Use supplemental oxygen if available",
            "Keep patient semi-upright to ease breathing",
            "Encourage deep breathing exercises",
        ],
        "first_aid": [
            "Monitor breathing every 2 hours",
            "Keep patient warm and hydrated",
            "Use paracetamol for fever",
            "Watch for blue lips/fingertips → emergency",
        ],
        "emergency_number": "108",
        "base_confidence": 62,
    },
    "heart_attack": {
        "hinditype": "हार्ट अटैक",
        "symptoms": [
            "chest pain",
            "shortness of breath",
            "pain in arm",
            "sweating",
            "nausea",
            "lightheadedness",
            "jaw pain",
        ],
        "severity": "CRITICAL",
        "emergency_steps": [
            "Call 108 immediately — every minute counts",
            "Give aspirin (300mg) if not allergic — chew it slowly",
            "Make patient sit or lie down — reduce heart workload",
            "If unconscious, start CPR if trained",
            "Do NOT let patient walk or exert themselves",
        ],
        "first_aid": [
            "Monitor pulse and breathing",
            "Keep patient calm and reassure",
            "Loosen tight clothing",
            "Be prepared for cardiac arrest",
        ],
        "emergency_number": "108",
        "base_confidence": 85,
    },
    "snake_bite": {
        "hindi": "सांप काटना",
        "symptoms": [
            "pain",
            "swelling",
            "fang marks",
            "nausea",
            "blurred vision",
            "difficulty breathing",
            "paralysis",
        ],
        "severity": "CRITICAL",
        "emergency_steps": [
            "Call 108 immediately — rush to hospital",
            "Keep patient calm and immobilize the bitten limb",
            "Do NOT cut the wound or suck poison",
            "Do NOT apply tourniquet or ice",
            "Note snake appearance for identification",
        ],
        "first_aid": [
            "Keep bitten limb below heart level",
            "Remove rings/watch before swelling",
            "Monitor for breathing difficulty",
            "Anti-venom is the only treatment",
        ],
        "emergency_number": "108",
        "base_confidence": 75,
    },
    "heatstroke": {
        "hindi": "लू लगना",
        "symptoms": [
            "high fever",
            "confusion",
            "hot dry skin",
            "rapid heartbeat",
            "headache",
            "nausea",
            "no sweating",
        ],
        "severity": "CRITICAL",
        "emergency_steps": [
            "Move patient to cool area immediately",
            "Call 108 — heatstroke is life-threatening",
            "Cool patient rapidly: cold water bath or ice packs to neck, armpits, groin",
            "Give cool water if conscious",
            "Do NOT give aspirin or paracetamol",
        ],
        "first_aid": [
            "Remove excess clothing",
            "Fan while misting skin with water",
            "Monitor temperature until < 38°C",
            "Watch for seizures or unconsciousness",
        ],
        "emergency_number": "108",
        "base_confidence": 78,
    },
}

# Hindi to English symptom mapping
HINDI_SYMPTOMS = {
    "बुखार": "fever",
    "तेज बुखार": "high fever",
    "ठंड": "chills",
    "सिरदर्द": "headache",
    "पसीना": "sweating",
    "मतली": "nausea",
    "उल्टी": "vomiting",
    "मांसपेशियों में दर्द": "muscle pain",
    "थकान": "fatigue",
    "पेट दर्द": "stomach pain",
    "दस्त": "diarrhea",
    "कब्ज": "constipation",
    "भूख न लगना": "loss of appetite",
    "खांसी": "cough",
    "सीने में दर्द": "chest pain",
    "सांस फुलना": "shortness of breath",
    "बहार": "phlegm",
    "बांह में दर्द": "pain in arm",
    "पसीना आना": "sweating",
    "चक्कर आना": "lightheadedness",
    "जबड़े में दर्द": "jaw pain",
    "दर्द": "pain",
    "सूजन": "swelling",
    "नेत्र में दर्द": "eye pain",
    "जोड़ों में दर्द": "joint pain",
    "दाने": "rash",
    "खून बहना": "bleeding",
    "उपस": "confusion",
    "दिमाग में भारीपन": "confusion",
}

# Emergency numbers by country
EMERGENCY_NUMBERS = {
    "India": "108",
    "USA": "911",
    "UK": "999",
    "EU": "112",
    "China": "120",
    "Japan": "119",
    "Australia": "000",
}

# ─────────────────────────────────────────────────────────────
# 2. RL ENGINE (Q-learning style weight updates)
# ─────────────────────────────────────────────────────────────


class RLDiagnosisEngine:
    def __init__(self):
        self.weights: Dict[str, Dict[str, float]] = {}
        self.total_diagnoses = 0
        self.correct_diagnoses = 0
        self.total_reward = 0.0
        self.learning_rate = 0.15
        self._init_weights()

    def _init_weights(self):
        for disease, data in DISEASES.items():
            self.weights[disease] = {}
            for symptom in data["symptoms"]:
                self.weights[disease][symptom] = 1.0

    def diagnose(self, symptoms: str) -> List[Dict]:
        self.total_diagnoses += 1
        symptoms_lower = symptoms.lower()
        matched_symptoms = set()

        for eng, hindi in HINDI_SYMPTOMS.items():
            if eng in symptoms_lower or hindi in symptoms_lower:
                matched_symptoms.add(eng)
                matched_symptoms.add(hindi)

        tokens = symptoms_lower.replace(",", " ").replace(".", " ").split()
        tokens = [t.strip() for t in tokens if t.strip()]

        for token in tokens:
            if token in HINDI_SYMPTOMS:
                matched_symptoms.add(HINDI_SYMPTOMS[token])
            matched_symptoms.add(token)

        scores = []
        for disease, data in DISEASES.items():
            score = 0
            disease_matched = []

            for symptom in data["symptoms"]:
                weight = self.weights.get(disease, {}).get(symptom, 1.0)
                if symptom in tokens or symptom in matched_symptoms:
                    score += weight
                    disease_matched.append(symptom)

            base_conf = data.get("base_confidence", 50)
            confidence = min(
                99,
                int((score / max(len(data["symptoms"]), 1)) * 100 * (base_conf / 50)),
            )
            confidence = max(confidence, base_conf - 20)

            scores.append(
                {
                    "disease": disease,
                    "confidence": confidence,
                    "severity": data["severity"],
                    "hindi_name": data.get("hindi", ""),
                    "matched_symptoms": disease_matched,
                    "emergency_steps": data["emergency_steps"],
                    "first_aid": data["first_aid"],
                    "emergency_number": data["emergency_number"],
                }
            )

        scores.sort(key=lambda x: x["confidence"], reverse=True)
        return scores[:5]

    def update_weights(self, disease: str, correct: bool):
        if disease not in DISEASES:
            return

        reward = 1.0 if correct else -0.5
        self.total_reward += reward

        if correct:
            self.correct_diagnoses += 1

        for symptom in DISEASES[disease]["symptoms"]:
            if disease in self.weights and symptom in self.weights[disease]:
                delta = self.learning_rate * reward
                self.weights[disease][symptom] = max(
                    0.1, min(2.0, self.weights[disease][symptom] + delta)
                )

    def get_stats(self) -> Dict:
        acc = (self.correct_diagnoses / max(self.total_diagnoses, 1)) * 100
        return {
            "total_diagnoses": self.total_diagnoses,
            "correct_diagnoses": self.correct_diagnoses,
            "accuracy": round(acc, 1),
            "total_reward": round(self.total_reward, 2),
            "learning_rate": self.learning_rate,
            "diseases_known": len(DISEASES),
        }


rl_engine = RLDiagnosisEngine()

# ─────────────────────────────────────────────────────────────
# 3. FASTAPI APP (OpenEnv-compatible)
# ─────────────────────────────────────────────────────────────

app = FastAPI(
    title="MediGuide AI - OpenEnv Medical Diagnosis",
    description="Offline RL-powered Emergency Medical Assistant",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── OpenEnv Models ─────────────────────────────────────────


class MedicalAction(BaseModel):
    symptoms: Optional[str] = None
    query_type: Optional[str] = "diagnose"
    feedback_disease: Optional[str] = None
    feedback_correct: Optional[bool] = None


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
    episode_id: str
    step_count: int
    query: str
    diagnoses: List[DiagnosisEntry]
    rl_stats: Dict
    message: str
    success: bool
    reward: float
    done: bool


class StepResult(BaseModel):
    observation: MedicalObservation
    reward: float
    done: bool
    info: Dict[str, Any] = {}


# ── Episode State ─────────────────────────────────────────

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


def _build_observation(
    query: str,
    diagnoses: List[Dict],
    reward: float,
    message: str,
    success: bool,
    done: bool = False,
) -> MedicalObservation:
    entries = []
    for d in diagnoses:
        entries.append(
            DiagnosisEntry(
                disease=d["disease"],
                confidence=d["confidence"],
                severity=d["severity"],
                hindi_name=d.get("hindi_name", ""),
                matched_symptoms=d.get("matched_symptoms", []),
                emergency_steps=d.get("emergency_steps", []),
                first_aid=d.get("first_aid", []),
                emergency_number=d.get("emergency_number", "108"),
            )
        )

    return MedicalObservation(
        episode_id=_episode["id"],
        step_count=_episode["step_count"],
        query=query,
        diagnoses=entries,
        rl_stats=rl_engine.get_stats(),
        message=message,
        success=success,
        reward=reward,
        done=done,
    )


# ── OpenEnv Endpoints ───────────────────────────────────────


@app.post("/reset", response_model=StepResult, tags=["OpenEnv"])
async def reset():
    """OpenEnv reset() — start a new episode."""
    _new_episode()
    obs = _build_observation(
        query="",
        diagnoses=[],
        reward=0.0,
        message="MediGuide AI ready. POST /step with {'symptoms': 'fever chills'} to diagnose.",
        success=True,
        done=False,
    )
    return StepResult(
        observation=obs,
        reward=0.0,
        done=False,
        info={
            "diseases_supported": list(DISEASES.keys()),
            "rl_engine": "Q-learning weight updates",
        },
    )


@app.post("/step", response_model=StepResult, tags=["OpenEnv"])
async def step(action: MedicalAction):
    """OpenEnv step() — diagnose symptoms or submit feedback."""
    with _lock:
        _episode["step_count"] += 1

    reward = 0.0
    done = False
    message = ""
    diagnoses = []

    if action.query_type == "diagnose" and action.symptoms:
        diagnoses = rl_engine.diagnose(action.symptoms)
        message = f"Diagnosis complete. Found {len(diagnoses)} possible conditions."
        reward = 0.1

    elif action.query_type == "feedback" and action.feedback_disease:
        disease_key = action.feedback_disease.lower().replace(" ", "_")
        rl_engine.update_weights(disease_key, action.feedback_correct or False)
        message = f"Feedback recorded for {action.feedback_disease}"
        reward = 1.0 if action.feedback_correct else -0.5

    _episode["episode_reward"] += reward

    obs = _build_observation(
        query=action.symptoms or "",
        diagnoses=diagnoses,
        reward=reward,
        message=message,
        success=True,
        done=done,
    )

    return StepResult(
        observation=obs,
        reward=reward,
        done=done,
        info={"rl_engine": "Q-learning active", "diseases": len(DISEASES)},
    )


@app.get("/state", tags=["OpenEnv"])
async def state():
    """Get current episode state."""
    return {
        "episode_id": _episode["id"],
        "step_count": _episode["step_count"],
        "episode_reward": _episode["episode_reward"],
        "rl_stats": rl_engine.get_stats(),
    }


@app.get("/health", tags=["System"])
async def health():
    """Health check."""
    return {
        "status": "healthy",
        "service": "MediGuide AI",
        "version": "2.0.0",
        "openenv_compatible": True,
        "diseases_loaded": len(DISEASES),
    }


@app.get("/", tags=["System"])
async def root():
    """Root endpoint."""
    return {
        "name": "MediGuide AI",
        "description": "OpenEnv-compatible Medical Diagnosis Environment",
        "openenv_endpoints": {
            "reset": "POST /reset",
            "step": "POST /step",
            "state": "GET /state",
        },
        "web_ui": "/ui",
    }


# ─────────────────────────────────────────────────────────────
# 4. GRADIO UI
# ─────────────────────────────────────────────────────────────

CUSTOM_CSS = """
body { background: #0d1117 !important; color: #e6edf3 !important; }
.gr-button-primary { background: linear-gradient(135deg,#00C851,#007E33)!important; }
h1, h2, h3 { color: #fff !important; }
"""

HEADER_HTML = """
<div style="text-align:center;padding:20px;background:linear-gradient(135deg,#1a1a2e,#16213e);border-radius:15px;margin-bottom:20px">
  <h1 style="margin:0;font-size:2.5em">🏥 MediGuide AI</h1>
  <p style="color:#aaa;margin:10px 0">OpenEnv-Compatible Medical Diagnosis • RL-Powered</p>
  <div style="display:flex;justify-content:center;gap:10px;margin-top:15px">
    <span style="background:rgba(0,200,81,0.2);color:#00C851;padding:5px 15px;border-radius:20px">🤖 AI Diagnosis</span>
    <span style="background:rgba(255,187,51,0.2);color:#FFBB33;padding:5px 15px;border-radius:20px">🇮🇳 Hindi</span>
    <span style="background:rgba(255,68,68,0.2);color:#FF4444;padding:5px 15px;border-radius:20px">🚨 Emergency</span>
  </div>
</div>
"""


def diagnose_symptoms(symptoms: str, language: str):
    if not symptoms.strip():
        return (
            "<div style='color:#FF4444;padding:20px'>⚠️ Please enter symptoms</div>",
            "",
        )

    translated = symptoms
    if language == "Hindi / हिंदी":
        for hindi, eng in HINDI_SYMPTOMS.items():
            if hindi in symptoms:
                translated = symptoms.replace(hindi, eng)

    diagnoses = rl_engine.diagnose(translated)
    stats = rl_engine.get_stats()

    result_html = f"""
    <div style="background:linear-gradient(135deg,#0d1117,#161b22);padding:20px;border-radius:15px;border:1px solid #30363d">
      <h3 style="color:#fff;margin:0 0 15px">🔍 Diagnosis Results</h3>
    """

    for i, d in enumerate(diagnoses):
        severity_color = (
            "#FF4444"
            if d["severity"] == "CRITICAL"
            else "#FF6600"
            if d["severity"] == "HIGH"
            else "#33B5E5"
        )
        result_html += f"""
        <div style="margin:15px 0;padding:15px;background:rgba(255,255,255,0.03);border-radius:10px;border-left:4px solid {severity_color}">
          <div style="display:flex;justify-content:space-between;align-items:center">
            <h4 style="margin:0;color:#fff;font-size:1.2em">{i + 1}. {d["disease"].replace("_", " ").title()}</h4>
            <span style="background:{severity_color};color:#fff;padding:3px 10px;border-radius:10px;font-size:0.8em">{d["confidence"]}%</span>
          </div>
          <p style="color:#aaa;margin:5px 0">🇮🇳 {d.get("hindi_name", "")} | Severity: {d["severity"]}</p>
          <p style="color:#888;font-size:0.9em">Matched: {", ".join(d.get("matched_symptoms", []))}</p>
        </div>
        """

    result_html += f"""
      <div style="margin-top:15px;padding:10px;background:rgba(51,181,233,0.1);border-radius:8px">
        <small style="color:#33B5E5">📊 RL Stats: {stats["total_diagnoses"]} diagnoses | {stats["accuracy"]}% accuracy</small>
      </div>
    </div>
    """

    first_aid = diagnoses[0] if diagnoses else {}
    first_aid_html = ""
    if first_aid:
        first_aid_html = f"""
        <div style="background:linear-gradient(135deg,#1a1a2e,#16213e);padding:20px;border-radius:15px;border:1px solid #30363d">
          <h3 style="color:#fff;margin:0 0 15px">🏥 Emergency Steps</h3>
          <p style="color:#FF4444;font-size:1.1em">📞 Emergency: {first_aid.get("emergency_number", "108")}</p>
          <ol style="color:#ccc;line-height:1.8">
            {"".join(f"<li>{s}</li>" for s in first_aid.get("emergency_steps", []))}
          </ol>
          <h4 style="color:#00C851;margin:15px 0 10px">💊 First Aid</h4>
          <ul style="color:#aaa;line-height:1.6">
            {"".join(f"<li>{s}</li>" for s in first_aid.get("first_aid", []))}
          </ul>
        </div>
        """

    return result_html, first_aid_html


DEMO_SCENARIOS = [
    {"label": "Malaria Test", "symptoms": "fever chills headache sweating nausea"},
    {
        "label": "Dengue Test",
        "symptoms": "high fever severe headache eye pain rash fatigue",
    },
    {
        "label": "Heart Attack Test",
        "symptoms": "chest pain shortness of breath pain in arm sweating",
    },
    {
        "label": "Snake Bite Test",
        "symptoms": "pain swelling fang marks nausea difficulty breathing",
    },
    {
        "label": "Pneumonia Test",
        "symptoms": "cough fever chest pain shortness of breath phlegm",
    },
]


def load_demo(label: str) -> str:
    for s in DEMO_SCENARIOS:
        if s["label"] == label:
            return s["symptoms"]
    return ""


# Build Gradio UI
with gr.Blocks(title="MediGuide AI", css=CUSTOM_CSS) as demo:
    gr.HTML(HEADER_HTML)

    with gr.Tabs():
        with gr.TabItem("🩺 Diagnosis"):
            with gr.Row():
                with gr.Column(scale=1):
                    gr.Markdown("### Enter Symptoms")
                    language = gr.Radio(
                        ["English", "Hindi / हिंदी"], value="English", label="Language"
                    )
                    symptoms = gr.Textbox(
                        label="Describe symptoms",
                        placeholder="fever, headache, chills...",
                        lines=4,
                    )
                    diagnose_btn = gr.Button("🔍 Diagnose", variant="primary")
                    gr.Markdown("### Demo")
                    demo_dd = gr.Dropdown(
                        [s["label"] for s in DEMO_SCENARIOS], label="Load Scenario"
                    )
                    load_btn = gr.Button("▶️ Load")
                with gr.Column(scale=2):
                    result = gr.HTML(label="Result")
                    first_aid = gr.HTML(label="First Aid")

        with gr.TabItem("📊 Stats"):
            stats = gr.HTML()
            refresh_btn = gr.Button("🔄 Refresh")

        with gr.TabItem("ℹ️ About"):
            gr.HTML("""
            <div style="padding:20px">
              <h2>MediGuide AI</h2>
              <p>OpenEnv-compatible Medical Diagnosis Environment</p>
              <h3>API Endpoints</h3>
              <ul>
                <li>POST /reset - Reset environment</li>
                <li>POST /step - Diagnose or give feedback</li>
                <li>GET /state - Get current state</li>
              </ul>
            </div>
            """)

    diagnose_btn.click(
        diagnose_symptoms, inputs=[symptoms, language], outputs=[result, first_aid]
    )
    load_btn.click(load_demo, inputs=[demo_dd], outputs=[symptoms])
    refresh_btn.click(
        lambda: f"<pre>{json.dumps(rl_engine.get_stats(), indent=2)}</pre>",
        outputs=[stats],
    )


# ─────────────────────────────────────────────────────────────
# 5. ENTRYPOINT
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import threading

    def run_gradio():
        demo.launch(server_name="0.0.0.0", server_port=7861, share=False)

    t = threading.Thread(target=run_gradio, daemon=True)
    t.start()

    uvicorn.run(app, host="0.0.0.0", port=7860)
