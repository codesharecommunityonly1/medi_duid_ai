"""
MediGuide AI - Inference Class Only
Meta + Hugging Face Hackathon 2026
"""

import json


class MedicalAgent:
    def __init__(self):
        self.model_name = "meta-llama/Llama-3.2-11B-Vision-Instruct"
        self.medical_kb = {
            "malaria": {
                "symptoms": ["fever", "chills", "headache"],
                "severity": "HIGH",
                "confidence": 72,
                "emergency": "108",
            },
            "dengue": {
                "symptoms": ["high fever", "rash", "joint pain"],
                "severity": "HIGH",
                "confidence": 65,
                "emergency": "108",
            },
            "heart_attack": {
                "symptoms": ["chest pain", "arm pain", "shortness of breath"],
                "severity": "CRITICAL",
                "confidence": 85,
                "emergency": "108",
            },
        }
        self.high_priority = [
            "chest pain",
            "heart attack",
            "cannot breathe",
            "unconscious",
            "severe bleeding",
        ]

    def is_emergency(self, symptoms):
        s = symptoms.lower()
        for kw in self.high_priority:
            if kw in s:
                return True, kw
        return False, ""

    def get_response(self, user_input):
        is_emergent, keyword = self.is_emergency(user_input)
        if is_emergent:
            return {
                "response": f"EMERGENCY: {keyword.upper()}. Call 108!",
                "action": "emergency",
            }

        s = user_input.lower()
        matches = []
        for disease, data in self.medical_kb.items():
            matched = [sym for sym in data["symptoms"] if sym in s]
            if matched:
                matches.append(
                    {
                        "disease": disease,
                        "confidence": data["confidence"],
                        "severity": data["severity"],
                        "emergency": data["emergency"],
                    }
                )

        if matches:
            matches.sort(key=lambda x: x["confidence"], reverse=True)
            top = matches[0]
            return {
                "response": f"Possible {top['disease']} ({top['confidence']}%) - Emergency: {top['emergency']}",
                "action": "guidance",
            }

        return {"response": "No match. Describe symptoms.", "action": "clarify"}
