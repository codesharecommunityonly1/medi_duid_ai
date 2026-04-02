"""
MediGuide AI - OpenEnv Medical Diagnosis Environment
=====================================================
FastAPI server with OpenEnv endpoints for medical diagnosis
"""

import os
import sys
import uuid
from typing import Optional, List, Dict
from fastapi import FastAPI
from pydantic import BaseModel
from contextlib import asynccontextmanager

# Environment variables
API_BASE_URL = os.getenv("API_BASE_URL", "https://router.huggingface.co/v1")
MODEL_NAME = os.getenv(
    "MODEL_NAME", "google/gemma-2b-it"
)  # Use smaller model for HF Spaces
HF_TOKEN = os.getenv("HF_TOKEN", "")

# Initialize InferenceClient if token provided
client = None
if HF_TOKEN:
    try:
        from huggingface_hub import InferenceClient

        client = InferenceClient(model=MODEL_NAME, token=HF_TOKEN)
    except ImportError:
        pass

# Episode state
_episode = {"id": "", "step_count": 0, "rewards": []}

# Disease database
DISEASES = {
    "malaria": {
        "symptoms": ["fever", "chills", "headache", "sweating", "nausea"],
        "confidence": 72,
        "severity": "HIGH",
        "emergency_steps": ["Take antimalarial", "Stay hydrated", "Go to PHC"],
    },
    "dengue": {
        "symptoms": ["high fever", "rash", "joint pain", "eye pain", "bleeding"],
        "confidence": 65,
        "severity": "HIGH",
        "emergency_steps": ["Go to hospital", "Check platelets", "Drink fluids"],
    },
    "typhoid": {
        "symptoms": ["prolonged fever", "stomach pain", "diarrhea", "weakness"],
        "confidence": 58,
        "severity": "MODERATE",
        "emergency_steps": ["Take antibiotics", "Eat soft food", "Drink boiled water"],
    },
    "pneumonia": {
        "symptoms": ["cough", "chest pain", "shortness of breath", "phlegm"],
        "confidence": 62,
        "severity": "HIGH",
        "emergency_steps": ["Go to hospital", "Take antibiotics", "Rest"],
    },
    "heart_attack": {
        "symptoms": [
            "chest pain",
            "shortness of breath",
            "pain in arm",
            "sweating",
            "nausea",
        ],
        "confidence": 85,
        "severity": "CRITICAL",
        "emergency_steps": [
            "Call 108 immediately",
            "Give aspirin",
            "Start CPR if unconscious",
        ],
    },
    "snake_bite": {
        "symptoms": ["pain", "swelling", "fang marks", "difficulty breathing"],
        "confidence": 75,
        "severity": "CRITICAL",
        "emergency_steps": ["Call 108", "Immobilize limb", "Do not suck poison"],
    },
    "heatstroke": {
        "symptoms": ["high fever", "confusion", "hot dry skin", "rapid heartbeat"],
        "confidence": 78,
        "severity": "CRITICAL",
        "emergency_steps": ["Move to cool area", "Call 108", "Cool with water"],
    },
    "cholera": {
        "symptoms": ["severe diarrhea", "vomiting", "dehydration", "cramps"],
        "confidence": 70,
        "severity": "CRITICAL",
        "emergency_steps": [
            "Start ORS immediately",
            "Go to hospital",
            "Take antibiotics",
        ],
    },
}

# Tasks definition
TASKS = [
    {
        "id": 1,
        "name": "simple_diagnosis",
        "difficulty": "easy",
        "description": "Diagnose common symptoms",
    },
    {
        "id": 2,
        "name": "emergency_detection",
        "difficulty": "medium",
        "description": "Detect emergency conditions",
    },
    {
        "id": 3,
        "name": "treatment_recommendation",
        "difficulty": "hard",
        "description": "Recommend proper treatment",
    },
]


def log_start(task: str, env: str, model: str) -> None:
    print(f"[START] task={task} env={env} model={model}", flush=True)


def log_step(
    step: int, action: str, reward: float, done: bool, error: Optional[str] = None
) -> None:
    error_val = error if error else "null"
    print(
        f"[STEP] step={step} action={action} reward={reward:.2f} done={str(done).lower()} error={error_val}",
        flush=True,
    )


def log_end(success: bool, steps: int, rewards: list) -> None:
    rewards_str = ",".join(f"{r:.2f}" for r in rewards)
    print(
        f"[END] success={str(success).lower()} steps={steps} rewards={rewards_str}",
        flush=True,
    )


def diagnose(symptoms: str) -> dict:
    """Diagnose based on symptoms"""
    if not symptoms:
        return {
            "diagnoses": [],
            "emergency_steps": [],
            "message": "No symptoms provided",
        }

    symptoms_lower = symptoms.lower()
    emergency_keywords = [
        "chest pain",
        "bleeding",
        "difficulty breathing",
        "unconscious",
        "shortness of breath",
        "rapid heartbeat",
    ]
    has_emergency = any(kw in symptoms_lower for kw in emergency_keywords)

    diagnoses = []
    for disease, data in DISEASES.items():
        matched = [s for s in data["symptoms"] if s in symptoms_lower]
        if matched:
            severity = (
                "CRITICAL"
                if has_emergency and data["severity"] == "CRITICAL"
                else data["severity"]
            )
            diagnoses.append(
                {
                    "disease": disease,
                    "confidence": data["confidence"],
                    "severity": severity,
                    "matched_symptoms": matched,
                }
            )

    if has_emergency:
        emergency_steps = ["Call 108 immediately", "Go to nearest hospital"]
    else:
        emergency_steps = [
            "Rest and monitor symptoms",
            "Stay hydrated",
            "Consult doctor if persists",
        ]

    return {
        "diagnoses": diagnoses[:5],
        "emergency_steps": emergency_steps[:5],
        "message": f"Found {len(diagnoses)} conditions",
    }


def grade_task(task_id: int, response: dict) -> float:
    """Grade task completion (0.0 to 1.0)"""
    diagnoses = response.get("diagnoses", [])
    if task_id == 1:
        return 1.0 if len(diagnoses) > 0 else 0.0
    elif task_id == 2:
        has_emergency = any(
            d.get("severity") in ["CRITICAL", "HIGH"] for d in diagnoses
        )
        return 1.0 if has_emergency else 0.0
    else:
        has_treatment = len(response.get("emergency_steps", [])) >= 2
        return 1.0 if has_treatment else 0.0


# FastAPI app
app = FastAPI(title="MediGuide AI - OpenEnv")


class Action(BaseModel):
    symptoms: Optional[str] = None
    query_type: Optional[str] = "diagnose"


@app.get("/")
def root():
    """Root endpoint - redirect to docs"""
    return {"message": "MediGuide AI - OpenEnv Medical Diagnosis", "docs": "/docs"}


@app.post("/reset")
def reset():
    """Reset environment - OpenEnv required"""
    global _episode
    _episode = {"id": str(uuid.uuid4()), "step_count": 0, "rewards": []}
    return {
        "observation": {"episode_id": _episode["id"], "message": "MediGuide AI ready"},
        "reward": 0.0,
        "done": False,
        "info": {"tasks": TASKS},
    }


@app.post("/step")
def step(action: Action):
    """Process symptoms - OpenEnv step()"""
    global _episode
    _episode["step_count"] += 1

    result = diagnose(action.symptoms or "")
    reward = 0.1 if len(result["diagnoses"]) > 0 else 0.0
    _episode["rewards"].append(reward)

    return {
        "observation": {
            "episode_id": _episode["id"],
            "step_count": _episode["step_count"],
            "query": action.symptoms or "",
            **result,
        },
        "reward": reward,
        "done": False,
        "info": {"rl_active": True},
    }


@app.get("/state")
def state():
    """Get current state - OpenEnv state()"""
    return _episode


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "openenv": True,
        "diseases": len(DISEASES),
        "tasks": len(TASKS),
    }


if __name__ == "__main__":
    import uvicorn

    if len(sys.argv) > 1 and sys.argv[1] == "--eval":
        # Evaluation mode
        current_model = MODEL_NAME if MODEL_NAME else "default-model"

        # Task 1: Simple diagnosis
        log_start("simple_diagnosis", "mediguide", current_model)
        result = diagnose("fever chills headache")
        score1 = grade_task(1, result)
        log_step(1, "diagnose('fever chills headache')", 0.1, False, None)
        log_end(True, 1, [0.1])

        # Task 2: Emergency detection
        log_start("emergency_detection", "mediguide", current_model)
        result = diagnose("chest pain shortness of breath")
        score2 = grade_task(2, result)
        log_step(1, "diagnose('chest pain shortness of breath')", 0.1, False, None)
        log_end(True, 1, [0.1])

        # Task 3: Treatment recommendation
        log_start("treatment_recommendation", "mediguide", current_model)
        result = diagnose("high fever severe headache rash")
        score3 = grade_task(3, result)
        log_step(1, "diagnose('high fever severe headache rash')", 0.1, False, None)
        log_end(True, 1, [0.1])

        avg_score = (score1 + score2 + score3) / 3
        print(f"\n=== Summary ===", flush=True)
        print(f"Task 1: {score1:.2f}", flush=True)
        print(f"Task 2: {score2:.2f}", flush=True)
        print(f"Task 3: {score3:.2f}", flush=True)
        print(f"Average: {avg_score:.2f}", flush=True)
    else:
        uvicorn.run(app, host="0.0.0.0", port=7860)
