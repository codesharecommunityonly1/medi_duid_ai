"""
MediGuide AI - OpenEnv-Compatible Medical Diagnosis
================================================
Simple FastAPI server with OpenEnv endpoints
"""

import uuid
from fastapi import FastAPI
from pydantic import BaseModel
from typing import Optional, List, Dict, Any

app = FastAPI(title="MediGuide AI - OpenEnv")

# Episode state
_episode = {"id": str(uuid.uuid4()), "step_count": 0, "reward": 0.0}

# Simple disease database
DISEASES = {
    "malaria": {"symptoms": ["fever", "chills", "headache"], "confidence": 72},
    "dengue": {"symptoms": ["high fever", "rash", "joint pain"], "confidence": 65},
    "typhoid": {"symptoms": ["prolonged fever", "stomach pain"], "confidence": 58},
    "pneumonia": {
        "symptoms": ["cough", "chest pain", "shortness of breath"],
        "confidence": 62,
    },
    "heart_attack": {
        "symptoms": ["chest pain", "shortness of breath", "pain in arm"],
        "confidence": 85,
    },
    "snake_bite": {"symptoms": ["pain", "swelling", "fang marks"], "confidence": 75},
    "heatstroke": {
        "symptoms": ["high fever", "confusion", "hot dry skin"],
        "confidence": 78,
    },
    "cholera": {
        "symptoms": ["severe diarrhea", "vomiting", "dehydration"],
        "confidence": 70,
    },
}


class Action(BaseModel):
    symptoms: Optional[str] = None
    query_type: Optional[str] = "diagnose"


@app.post("/reset")
def reset():
    global _episode
    _episode = {"id": str(uuid.uuid4()), "step_count": 0, "reward": 0.0}
    return {
        "observation": {
            "episode_id": _episode["id"],
            "message": "MediGuide AI ready. POST /step with symptoms.",
        },
        "reward": 0.0,
        "done": False,
        "info": {"diseases": list(DISEASES.keys())},
    }


@app.post("/step")
def step(action: Action):
    global _episode
    _episode["step_count"] += 1

    diagnoses = []
    if action.symptoms:
        for disease, data in DISEASES.items():
            diagnoses.append(
                {
                    "disease": disease,
                    "confidence": data["confidence"],
                    "severity": "HIGH" if data["confidence"] > 70 else "MODERATE",
                }
            )
        diagnoses.sort(key=lambda x: x["confidence"], reverse=True)

    return {
        "observation": {
            "episode_id": _episode["id"],
            "step_count": _episode["step_count"],
            "query": action.symptoms or "",
            "diagnoses": diagnoses[:5],
        },
        "reward": 0.1,
        "done": False,
        "info": {"rl_active": True},
    }


@app.get("/state")
def state():
    return _episode


@app.get("/health")
def health():
    return {"status": "healthy", "openenv": True, "diseases": len(DISEASES)}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=7860)
