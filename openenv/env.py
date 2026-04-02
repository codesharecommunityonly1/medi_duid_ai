"""MediGuide AI - OpenEnv Medical Environment"""

from typing import Dict, List, Tuple, Any, Optional
import uuid


class MedicalEnv:
    """OpenEnv-compatible medical diagnosis environment"""

    def __init__(self):
        self.episode_id = ""
        self.step_count = 0
        self.max_steps = 100
        self.total_reward = 0.0
        self._init_knowledge()

    def _init_knowledge(self):
        """Initialize medical knowledge base"""
        self.DISEASES = {
            "malaria": {
                "symptoms": [
                    "fever",
                    "chills",
                    "headache",
                    "sweating",
                    "nausea",
                    "vomiting",
                    "muscle pain",
                    "fatigue",
                ],
                "severity": "HIGH",
                "confidence": 72,
            },
            "dengue": {
                "symptoms": [
                    "high fever",
                    "severe headache",
                    "eye pain",
                    "joint pain",
                    "rash",
                    "bleeding",
                    "fatigue",
                ],
                "severity": "HIGH",
                "confidence": 65,
            },
            "typhoid": {
                "symptoms": [
                    "prolonged fever",
                    "stomach pain",
                    "headache",
                    "diarrhea",
                    "weakness",
                    "loss of appetite",
                ],
                "severity": "MODERATE",
                "confidence": 58,
            },
            "cholera": {
                "symptoms": [
                    "severe diarrhea",
                    "vomiting",
                    "dehydration",
                    "leg cramps",
                    "weakness",
                    "watery stool",
                ],
                "severity": "CRITICAL",
                "confidence": 80,
            },
            "pneumonia": {
                "symptoms": [
                    "high fever",
                    "cough",
                    "chest pain",
                    "difficulty breathing",
                    "chills",
                    "fatigue",
                ],
                "severity": "HIGH",
                "confidence": 70,
            },
            "heart_attack": {
                "symptoms": [
                    "chest pain",
                    "chest pressure",
                    "arm pain",
                    "jaw pain",
                    "shortness of breath",
                    "sweating",
                    "nausea",
                ],
                "severity": "CRITICAL",
                "confidence": 85,
            },
            "snake_bite": {
                "symptoms": [
                    "bite marks",
                    "swelling",
                    "pain",
                    "numbness",
                    "nausea",
                    "dizziness",
                    "difficulty breathing",
                ],
                "severity": "CRITICAL",
                "confidence": 90,
            },
            "heatstroke": {
                "symptoms": [
                    "very high fever",
                    "hot dry skin",
                    "confusion",
                    "dizziness",
                    "no sweating",
                    "rapid heartbeat",
                ],
                "severity": "CRITICAL",
                "confidence": 82,
            },
        }

    def reset(self) -> Dict[str, Any]:
        """Reset environment to initial state"""
        self.episode_id = str(uuid.uuid4())
        self.step_count = 0
        self.total_reward = 0.0

        return {
            "episode_id": self.episode_id,
            "step_count": self.step_count,
            "message": "MediGuide AI ready. Use step() with symptoms to diagnose.",
            "diseases": list(self.DISEASES.keys()),
        }

    def step(
        self, action: Dict[str, Any]
    ) -> Tuple[Dict[str, Any], float, bool, Dict[str, Any]]:
        """
        Process a diagnosis action

        Args:
            action: Dict with "symptoms" (str) and optional "query_type"

        Returns:
            observation: Dict with diagnosis results
            reward: float (0.0 to 1.0)
            done: bool
            info: Dict with additional metadata
        """
        self.step_count += 1

        symptoms = action.get("symptoms", "")
        query_type = action.get("query_type", "diagnose")

        diagnoses = []
        reward = 0.0
        message = ""

        if query_type == "diagnose" and symptoms:
            diagnoses = self._diagnose(symptoms)
            reward = 0.1 if len(diagnoses) > 0 else 0.0
            message = f"Found {len(diagnoses)} conditions"

            # Bonus for critical condition detection
            for d in diagnoses:
                if d.get("severity") in ["CRITICAL", "HIGH"]:
                    reward += 0.2
                    break

        self.total_reward += reward

        # Check if episode is done
        done = self.step_count >= self.max_steps

        observation = {
            "episode_id": self.episode_id,
            "step_count": self.step_count,
            "query": symptoms,
            "diagnoses": diagnoses,
            "message": message,
        }

        info = {
            "total_reward": self.total_reward,
            "diseases_count": len(self.DISEASES),
        }

        return observation, reward, done, info

    def _diagnose(self, symptoms_text: str) -> List[Dict[str, Any]]:
        """Rule-based diagnosis engine"""
        if not symptoms_text:
            return []

        symptoms_lower = symptoms_text.lower()
        results = []

        # Emergency keywords
        emergency_keywords = [
            "chest pain",
            "bleeding",
            "difficulty breathing",
            "unconscious",
            "shortness of breath",
        ]
        has_emergency = any(kw in symptoms_lower for kw in emergency_keywords)

        for disease, data in self.DISEASES.items():
            matched = [s for s in data["symptoms"] if s in symptoms_lower]
            if matched:
                # Adjust severity for emergency cases
                severity = data["severity"]
                if has_emergency and severity == "CRITICAL":
                    severity = "CRITICAL"

                results.append(
                    {
                        "disease": disease,
                        "confidence": data["confidence"],
                        "severity": severity,
                        "matched_symptoms": matched,
                    }
                )

        # Sort by confidence and return top 5
        results.sort(key=lambda x: x["confidence"], reverse=True)
        return results[:5]

    def get_state(self) -> Dict[str, Any]:
        """Get current environment state"""
        return {
            "episode_id": self.episode_id,
            "step_count": self.step_count,
            "total_reward": self.total_reward,
            "max_steps": self.max_steps,
        }
