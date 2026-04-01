"""
MediGuide AI - OpenEnv Medical Diagnosis Environment
====================================================
Inference script with OpenAI client for evaluation
Outputs structured logs: [START], [STEP], [END]
"""

import os
import sys
import json
import time
import uuid
from datetime import datetime

# Environment variables (must be set for evaluation)
API_BASE_URL = os.environ.get("API_BASE_URL", "https://api.openai.com/v1")
MODEL_NAME = os.environ.get("MODEL_NAME", "gpt-4")
HF_TOKEN = os.environ.get("HF_TOKEN", "")

# Initialize OpenAI client if token provided
client = None
if HF_TOKEN:
    try:
        from openai import OpenAI

        client = OpenAI(api_key=HF_TOKEN, base_url=API_BASE_URL)
    except ImportError:
        pass

# Episode state
_episode = {"id": "", "step_count": 0, "start_time": ""}

# Tasks definition (3 tasks: easy, medium, hard)
TASKS = [
    {
        "id": 1,
        "name": "simple_diagnosis",
        "difficulty": "easy",
        "description": "Diagnose common symptoms (fever, chills, headache)",
        "grading": {
            "min_score": 0.0,
            "max_score": 1.0,
            "criteria": "Returns valid diagnosis",
        },
    },
    {
        "id": 2,
        "name": "emergency_detection",
        "difficulty": "medium",
        "description": "Detect emergency conditions (chest pain, breathing difficulty)",
        "grading": {
            "min_score": 0.0,
            "max_score": 1.0,
            "criteria": "Identifies HIGH/CRITICAL severity",
        },
    },
    {
        "id": 3,
        "name": "treatment_recommendation",
        "difficulty": "hard",
        "description": "Recommend proper treatment and emergency steps",
        "grading": {
            "min_score": 0.0,
            "max_score": 1.0,
            "criteria": "Provides actionable emergency_steps",
        },
    },
]

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


def log_event(event_type: str, data: dict):
    """Output structured log in required format"""
    timestamp = datetime.utcnow().isoformat() + "Z"
    output = {"timestamp": timestamp, "event": event_type, **data}
    print(f"[{event_type}] {json.dumps(output)}", flush=True)


def grade_task(task_id: int, response: dict) -> float:
    """Grade task completion (0.0 to 1.0)"""
    diagnoses = response.get("diagnoses", [])

    if task_id == 1:  # Easy: valid diagnosis
        return 1.0 if len(diagnoses) > 0 else 0.0
    elif task_id == 2:  # Medium: emergency detected
        has_emergency = any(
            d.get("severity") in ["CRITICAL", "HIGH"] for d in diagnoses
        )
        return 1.0 if has_emergency else 0.0
    else:  # Hard: treatment recommended
        has_treatment = len(response.get("emergency_steps", [])) >= 2
        return 1.0 if has_treatment else 0.0


def diagnose(symptoms: str) -> dict:
    """Diagnose based on symptoms"""
    if not symptoms:
        return {
            "diagnoses": [],
            "emergency_steps": [],
            "message": "No symptoms provided",
        }

    symptoms_lower = symptoms.lower()

    # Check for emergency
    emergency_keywords = [
        "chest pain",
        "bleeding",
        "difficulty breathing",
        "unconscious",
        "shortness of breath",
        "rapid heartbeat",
    ]
    has_emergency = any(kw in symptoms_lower for kw in emergency_keywords)

    # Match diseases
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
                    "hindi_name": data.get("hindi", ""),
                }
            )

    # Emergency steps
    if has_emergency:
        emergency_steps = ["Call 108 immediately", "Go to nearest hospital"]
        for d in diagnoses:
            if d["severity"] == "CRITICAL":
                emergency_steps.extend(DISEASES[d["disease"]]["emergency_steps"][:2])
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


# FastAPI app
from fastapi import FastAPI
from pydantic import BaseModel
from typing import Optional

app = FastAPI(title="MediGuide AI - OpenEnv")


class Action(BaseModel):
    symptoms: Optional[str] = None
    query_type: Optional[str] = "diagnose"


@app.post("/reset")
def reset():
    """Reset environment - OpenEnv required"""
    global _episode
    _episode = {"id": str(uuid.uuid4()), "step_count": 0, "start_time": time.time()}

    log_event(
        "START",
        {
            "episode_id": _episode["id"],
            "message": "MediGuide AI ready. POST /step with symptoms.",
            "tasks": [t["name"] for t in TASKS],
            "diseases": list(DISEASES.keys()),
        },
    )

    return {
        "observation": {
            "episode_id": _episode["id"],
            "message": "MediGuide AI ready. Use step() with symptoms.",
        },
        "reward": 0.0,
        "done": False,
        "info": {"tasks": TASKS, "diseases": list(DISEASES.keys())},
    }


@app.post("/step")
def step(action: Action):
    """Process symptoms and return diagnosis"""
    global _episode
    _episode["step_count"] += 1

    result = diagnose(action.symptoms or "")

    log_event(
        "STEP",
        {
            "step": _episode["step_count"],
            "episode_id": _episode["id"],
            "query": action.symptoms or "",
            "diagnoses_count": len(result["diagnoses"]),
            "emergency_steps_count": len(result["emergency_steps"]),
        },
    )

    return {
        "observation": {
            "episode_id": _episode["id"],
            "step_count": _episode["step_count"],
            "query": action.symptoms or "",
            **result,
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
    return {
        "status": "healthy",
        "openenv": True,
        "diseases": len(DISEASES),
        "tasks": len(TASKS),
    }


if __name__ == "__main__":
    import uvicorn

    # Run baseline evaluation if called directly
    if len(sys.argv) > 1 and sys.argv[1] == "--eval":
        print("Running baseline evaluation...", flush=True)

        # Task 1: Simple diagnosis
        print("\n=== Task 1: Simple Diagnosis (Easy) ===", flush=True)
        r = reset()
        result = step(Action(symptoms="fever chills headache"))
        score1 = grade_task(1, result["observation"])
        log_event(
            "END",
            {
                "task": "simple_diagnosis",
                "score": score1,
                "status": "PASS" if score1 > 0 else "FAIL",
            },
        )

        # Task 2: Emergency detection
        print("\n=== Task 2: Emergency Detection (Medium) ===", flush=True)
        r = reset()
        result = step(Action(symptoms="chest pain shortness of breath"))
        score2 = grade_task(2, result["observation"])
        log_event(
            "END",
            {
                "task": "emergency_detection",
                "score": score2,
                "status": "PASS" if score2 > 0 else "FAIL",
            },
        )

        # Task 3: Treatment recommendation
        print("\n=== Task 3: Treatment Recommendation (Hard) ===", flush=True)
        r = reset()
        result = step(Action(symptoms="high fever severe headache rash"))
        score3 = grade_task(3, result["observation"])
        log_event(
            "END",
            {
                "task": "treatment_recommendation",
                "score": score3,
                "status": "PASS" if score3 > 0 else "FAIL",
            },
        )

        # Summary
        avg_score = (score1 + score2 + score3) / 3
        print(f"\n=== Final Results ===", flush=True)
        print(f"Task 1 (Easy): {score1}", flush=True)
        print(f"Task 2 (Medium): {score2}", flush=True)
        print(f"Task 3 (Hard): {score3}", flush=True)
        print(f"Average Score: {avg_score:.2f}", flush=True)
        log_event(
            "END", {"total_tasks": 3, "average_score": avg_score, "status": "COMPLETED"}
        )
    else:
        uvicorn.run(app, host="0.0.0.0", port=7860)
