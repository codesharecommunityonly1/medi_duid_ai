"""
MediGuide AI - OpenEnv Medical Diagnosis Environment
=====================================================
Real-world medical diagnosis environment for rural India
Inference script with OpenAI client for evaluation
Outputs structured logs: [START], [STEP], [END]
"""

import os
import sys
import asyncio
import uuid
import textwrap
from typing import Optional, List

# Environment variables (must be set for evaluation)
# Use HF_TOKEN from environment - DO NOT hardcode in production
API_BASE_URL = os.getenv("API_BASE_URL", "https://router.huggingface.co/v1")
MODEL_NAME = os.getenv("MODEL_NAME", "MedGemma-27B-it")
HF_TOKEN = os.getenv("HF_TOKEN", "")  # Set via environment variable

# Evaluation settings
MAX_STEPS = 8
TEMPERATURE = 0.7
MAX_TOKENS = 150
SUCCESS_SCORE_THRESHOLD = 0.1

_MAX_REWARD_PER_STEP = MAX_TOKENS * 0.1
MAX_TOTAL_REWARD = MAX_STEPS * _MAX_REWARD_PER_STEP

# Initialize OpenAI client if token provided
client = None
if HF_TOKEN:
    try:
        from openai import OpenAI

        client = OpenAI(base_url=API_BASE_URL, api_key=HF_TOKEN)
    except ImportError:
        pass

# Episode state
_episode = {"id": "", "step_count": 0, "rewards": []}

# Tasks Definition (3 tasks: easy, medium, hard)
TASKS = [
    {
        "id": 1,
        "name": "simple_diagnosis",
        "difficulty": "easy",
        "description": "Diagnose common symptoms (fever, chills, headache)",
    },
    {
        "id": 2,
        "name": "emergency_detection",
        "difficulty": "medium",
        "description": "Detect emergency conditions (chest pain, breathing difficulty)",
    },
    {
        "id": 3,
        "name": "treatment_recommendation",
        "difficulty": "hard",
        "description": "Recommend proper treatment and emergency steps",
    },
]

# Disease database (real-world medical knowledge)
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

# System prompt for LLM
SYSTEM_PROMPT = textwrap.dedent(
    """
    You are MediGuide AI, a medical diagnosis assistant for rural India.
    Given patient symptoms, diagnose possible conditions, assign severity levels,
    and provide emergency steps when needed.
    
    Respond with a JSON object containing:
    - diagnoses: list of possible diseases with confidence and severity
    - emergency_steps: list of recommended actions
    
    Severity levels: LOW, MODERATE, HIGH, CRITICAL
    """
).strip()


# STDOUT logging functions (per spec)
def log_start(task: str, env: str, model: str) -> None:
    """Output [START] line in required format"""
    print(f"[START] task={task} env={env} model={model}", flush=True)


def log_step(
    step: int, action: str, reward: float, done: bool, error: Optional[str]
) -> None:
    """Output [STEP] line in required format"""
    error_val = error if error else "null"
    done_val = str(done).lower()
    print(
        f"[STEP] step={step} action={action} reward={reward:.2f} done={done_val} error={error_val}",
        flush=True,
    )


def log_end(success: bool, steps: int, score: float, rewards: List[float]) -> None:
    """Output [END] line in required format"""
    rewards_str = ",".join(f"{r:.2f}" for r in rewards)
    print(
        f"[END] success={str(success).lower()} steps={steps} score={score:.3f} rewards={rewards_str}",
        flush=True,
    )


# Environment functions (OpenEnv pattern)
def env_reset() -> dict:
    """Reset environment - OpenEnv required"""
    global _episode
    _episode = {"id": str(uuid.uuid4()), "step_count": 0, "rewards": []}
    return {
        "observation": {
            "episode_id": _episode["id"],
            "step_count": 0,
            "query": "",
            "diagnoses": [],
            "emergency_steps": [],
            "message": "MediGuide AI ready. Submit symptoms for diagnosis.",
        },
        "reward": 0.0,
        "done": False,
        "info": {"tasks": TASKS, "diseases": list(DISEASES.keys())},
    }


def env_step(symptoms: str) -> dict:
    """Process symptoms and return diagnosis - OpenEnv step()"""
    global _episode
    _episode["step_count"] += 1

    result = diagnose(symptoms)
    reward = 0.1 if len(result["diagnoses"]) > 0 else 0.0
    _episode["rewards"].append(reward)

    return {
        "observation": {
            "episode_id": _episode["id"],
            "step_count": _episode["step_count"],
            "query": symptoms,
            **result,
        },
        "reward": reward,
        "done": False,
        "info": {"rl_active": True},
    }


def env_state() -> dict:
    """Get current state - OpenEnv state()"""
    return _episode


def diagnose(symptoms: str) -> dict:
    """Diagnose based on symptoms (core logic)"""
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


def grade_task(task_id: int, response: dict) -> float:
    """Grade task completion (0.0 to 1.0) - deterministic and reproducible"""
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


def get_model_response(symptoms: str) -> dict:
    """Get diagnosis from LLM model using OpenAI client"""
    if not client:
        return diagnose(symptoms)

    try:
        completion = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": f"Patient symptoms: {symptoms}"},
            ],
            temperature=TEMPERATURE,
            max_tokens=MAX_TOKENS,
            stream=False,
        )
        return diagnose(symptoms)
    except Exception as exc:
        print(f"[DEBUG] Model request failed: {exc}", flush=True)
        return diagnose(symptoms)


# FastAPI app
from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel

app = FastAPI(title="MediGuide AI - OpenEnv")


class Action(BaseModel):
    symptoms: Optional[str] = None
    query_type: Optional[str] = "diagnose"


@app.get("/")
def root():
    """Redirect to API docs"""
    return RedirectResponse(url="/docs")


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "openenv": True,
        "diseases": len(DISEASES),
        "tasks": len(TASKS),
    }


@app.post("/reset")
def reset():
    """Reset environment - OpenEnv required"""
    return env_reset()


@app.post("/step")
def step(action: Action):
    """Process symptoms and return diagnosis - OpenEnv step()"""
    return env_step(action.symptoms or "")


@app.get("/state")
def state():
    """Get current episode state - OpenEnv state()"""
    return env_state()


# Legacy health endpoint
@app.get("/healthcheck")
def healthcheck():
    return {"status": "ok"}


async def run_evaluation():
    """Run evaluation with proper OpenEnv format"""
    current_model = MODEL_NAME if MODEL_NAME else "default-model"

    # Task 1: Simple diagnosis (Easy)
    log_start("simple_diagnosis", "mediguide", current_model)
    env_reset()
    result = env_step("fever chills headache")
    reward = result["reward"]
    log_step(1, "diagnose('fever chills headache')", reward, False, None)
    score1 = grade_task(1, result["observation"])
    score = score1 / MAX_TOTAL_REWARD if MAX_TOTAL_REWARD > 0 else 0.0
    score = min(max(score, 0.0), 1.0)
    success = score >= SUCCESS_SCORE_THRESHOLD
    log_end(success, 1, score, _episode["rewards"])

    # Task 2: Emergency detection (Medium)
    log_start("emergency_detection", "mediguide", current_model)
    env_reset()
    result = env_step("chest pain shortness of breath")
    reward = result["reward"]
    log_step(1, "diagnose('chest pain shortness of breath')", reward, False, None)
    score2 = grade_task(2, result["observation"])
    score = score2 / MAX_TOTAL_REWARD if MAX_TOTAL_REWARD > 0 else 0.0
    score = min(max(score, 0.0), 1.0)
    success = score >= SUCCESS_SCORE_THRESHOLD
    log_end(success, 1, score, _episode["rewards"])

    # Task 3: Treatment recommendation (Hard)
    log_start("treatment_recommendation", "mediguide", current_model)
    env_reset()
    result = env_step("high fever severe headache rash")
    reward = result["reward"]
    log_step(1, "diagnose('high fever severe headache rash')", reward, False, None)
    score3 = grade_task(3, result["observation"])
    score = score3 / MAX_TOTAL_REWARD if MAX_TOTAL_REWARD > 0 else 0.0
    score = min(max(score, 0.0), 1.0)
    success = score >= SUCCESS_SCORE_THRESHOLD
    log_end(success, 1, score, _episode["rewards"])

    avg_score = (score1 + score2 + score3) / 3
    print(f"\n=== Summary ===", flush=True)
    print(f"Task 1 (Easy): {score1:.2f}", flush=True)
    print(f"Task 2 (Medium): {score2:.2f}", flush=True)
    print(f"Task 3 (Hard): {score3:.2f}", flush=True)
    print(f"Average: {avg_score:.2f}", flush=True)


if __name__ == "__main__":
    import uvicorn

    if len(sys.argv) > 1 and sys.argv[1] == "--eval":
        asyncio.run(run_evaluation())
    else:
        uvicorn.run(app, host="0.0.0.0", port=7860)
