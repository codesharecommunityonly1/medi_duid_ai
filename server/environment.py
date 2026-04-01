"""
MediGuide AI - OpenEnv Environment
===================================
Environment implementation following OpenEnv 3-component pattern
"""

import uuid
from typing import Optional, Dict, Any


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


class MediGuideEnvironment:
    """OpenEnv medical diagnosis environment"""

    SUPPORTS_CONCURRENT_SESSIONS = True
    MAX_STEPS = 100

    def __init__(self):
        self._episode_id = ""
        self._step_count = 0
        self._diagnoses = []
        self._emergency_steps = []

    def reset(self, seed=None, episode_id=None, **kwargs) -> Dict[str, Any]:
        """Reset environment to initial state"""
        self._episode_id = episode_id or str(uuid.uuid4())
        self._step_count = 0
        self._diagnoses = []
        self._emergency_steps = []

        return {
            "done": False,
            "reward": None,
            "episode_id": self._episode_id,
            "step_count": 0,
            "query": "",
            "diagnoses": [],
            "emergency_steps": [],
            "message": "MediGuide AI ready. Submit symptoms for diagnosis.",
        }

    def step(self, action, timeout_s=None, **kwargs) -> Dict[str, Any]:
        """Process symptoms and return diagnosis"""
        symptoms = getattr(action, "symptoms", "") or ""
        self._step_count += 1

        result = self._diagnose(symptoms)
        self._diagnoses = result["diagnoses"]
        self._emergency_steps = result["emergency_steps"]

        reward = 0.1 if len(self._diagnoses) > 0 else 0.0
        done = self._step_count >= self.MAX_STEPS

        return {
            "done": done,
            "reward": reward,
            "episode_id": self._episode_id,
            "step_count": self._step_count,
            "query": symptoms,
            "diagnoses": self._diagnoses,
            "emergency_steps": self._emergency_steps,
            "message": result["message"],
        }

    @property
    def state(self) -> Dict[str, Any]:
        """Return current state"""
        return {
            "episode_id": self._episode_id,
            "step_count": self._step_count,
            "diagnoses_count": len(self._diagnoses),
            "emergency_steps_count": len(self._emergency_steps),
        }

    def _diagnose(self, symptoms: str) -> dict:
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
            for d in diagnoses:
                if d["severity"] == "CRITICAL":
                    emergency_steps.extend(
                        DISEASES[d["disease"]]["emergency_steps"][:2]
                    )
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
