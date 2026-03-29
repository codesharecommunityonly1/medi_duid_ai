"""
MediGuide AI - Inference Server
Offline Emergency Medical Assistant
Meta + Hugging Face Hackathon 2026

Exposes:
  POST /reset    - Reset environment state (required by OpenEnv)
  POST /predict  - Run medical diagnosis inference
  GET  /health   - Health check
  GET  /         - App info
"""

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn
import threading

# ── App ──────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="MediGuide AI",
    description="Offline Emergency Medical Assistant - Meta + HF Hackathon 2026",
    version="1.0.0"
)

# ── State ────────────────────────────────────────────────────────────────────
state = {
    "session_id": None,
    "history": [],
    "model_ready": True
}

# ── Symptom → Diagnosis Engine ───────────────────────────────────────────────
SYMPTOM_DB = {
    "fever":       {"Malaria": 72, "Dengue": 18, "Typhoid": 10},
    "headache":    {"Migraine": 60, "Dengue": 25, "Hypertension": 15},
    "vomiting":    {"Food Poisoning": 55, "Dengue": 30, "Malaria": 15},
    "cough":       {"TB": 40, "Pneumonia": 35, "Common Cold": 25},
    "chest pain":  {"Heart Attack": 50, "Angina": 30, "Gastritis": 20},
    "diarrhea":    {"Cholera": 45, "Food Poisoning": 40, "IBS": 15},
    "rash":        {"Dengue": 50, "Chickenpox": 30, "Allergy": 20},
    "fatigue":     {"Anemia": 45, "Malaria": 35, "Typhoid": 20},
}

RISK_LEVELS = {
    "Heart Attack": "CRITICAL",
    "Cholera": "CRITICAL",
    "TB": "HIGH",
    "Malaria": "HIGH",
    "Dengue": "HIGH",
    "Pneumonia": "HIGH",
    "Typhoid": "MODERATE",
    "Food Poisoning": "MODERATE",
    "Migraine": "MODERATE",
    "Anemia": "MODERATE",
    "Common Cold": "LOW",
    "Allergy": "LOW",
    "IBS": "LOW",
}

EMERGENCY_STEPS = {
    "CRITICAL": ["Call 108 immediately", "Do not leave patient alone", "Keep patient calm and still"],
    "HIGH":     ["Seek medical help today", "Stay hydrated", "Take paracetamol for fever"],
    "MODERATE": ["Rest and monitor symptoms", "Stay hydrated", "Consult doctor if worsens"],
    "LOW":      ["Rest at home", "Take OTC medication", "Monitor for 24 hours"],
}


def run_diagnosis(symptoms: str) -> dict:
    symptoms_lower = symptoms.lower()
    matched = {}

    for keyword, conditions in SYMPTOM_DB.items():
        if keyword in symptoms_lower:
            for condition, confidence in conditions.items():
                if condition in matched:
                    matched[condition] = min(99, matched[condition] + confidence // 2)
                else:
                    matched[condition] = confidence

    if not matched:
        matched = {"Unknown Condition": 100}

    # Sort by confidence
    sorted_conditions = sorted(matched.items(), key=lambda x: x[1], reverse=True)[:3]

    top_condition = sorted_conditions[0][0]
    risk = RISK_LEVELS.get(top_condition, "MODERATE")
    steps = EMERGENCY_STEPS.get(risk, EMERGENCY_STEPS["MODERATE"])

    return {
        "symptoms": symptoms,
        "conditions": [{"name": c, "confidence": p} for c, p in sorted_conditions],
        "risk_level": risk,
        "emergency_steps": steps,
        "emergency_number": "108",
    }


# ── Request / Response Models ─────────────────────────────────────────────────
class PredictRequest(BaseModel):
    symptoms: str
    session_id: str = None


class ResetRequest(BaseModel):
    session_id: str = None


# ── Routes ───────────────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {
        "app": "MediGuide AI",
        "version": "1.0.0",
        "status": "running",
        "description": "Offline Emergency Medical Assistant",
        "endpoints": {
            "POST /reset":   "Reset environment state",
            "POST /predict": "Run medical diagnosis",
            "GET  /health":  "Health check",
        }
    }


@app.get("/health")
def health():
    return {"status": "ok", "model_ready": state["model_ready"]}


@app.post("/reset")
def reset(body: ResetRequest = None):
    """
    OpenEnv reset endpoint.
    Clears session history and resets model state.
    """
    state["session_id"] = body.session_id if body else None
    state["history"] = []
    state["model_ready"] = True
    return {
        "status": "ok",
        "message": "Environment reset successfully",
        "session_id": state["session_id"],
    }


@app.post("/predict")
def predict(body: PredictRequest):
    """
    Run medical diagnosis inference on provided symptoms.
    """
    if not body.symptoms or not body.symptoms.strip():
        return JSONResponse(status_code=400, content={"error": "symptoms field is required"})

    result = run_diagnosis(body.symptoms)

    # Log to history
    state["history"].append({
        "symptoms": body.symptoms,
        "top_condition": result["conditions"][0]["name"],
        "risk_level": result["risk_level"],
    })

    return {"status": "ok", "result": result}


# ── Entry Point ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run("inference:app", host="0.0.0.0", port=7860, reload=False)
