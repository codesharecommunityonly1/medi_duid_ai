"""
MediGuide AI - Enhanced OpenEnv Medical Environment
===================================================
Advanced RL environment with:
- Dynamic state representation
- Symptom progression
- Nuanced rewards
- Complex medical logic
"""

from typing import Dict, List, Tuple, Any, Optional
import uuid
import random


class MedicalEnv:
    """Enhanced OpenEnv-compatible medical diagnosis environment with rich RL simulation"""

    def __init__(self):
        self.episode_id = ""
        self.step_count = 0
        self.max_steps = 10
        self.total_reward = 0.0
        self.conversation_history = []
        self.symptoms = {}
        self.visual_features = None
        self._init_knowledge()

    def _init_knowledge(self):
        """Initialize comprehensive medical knowledge base"""
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
                "should_emergency": False,
                "should_specialist": False,
            },
            "dengue": {
                "symptoms": [
                    "high fever",
                    "rash",
                    "joint pain",
                    "eye pain",
                    "bleeding",
                    "fatigue",
                ],
                "severity": "HIGH",
                "confidence": 65,
                "should_emergency": True,
                "should_specialist": False,
            },
            "typhoid": {
                "symptoms": [
                    "prolonged fever",
                    "stomach pain",
                    "diarrhea",
                    "weakness",
                    "loss of appetite",
                ],
                "severity": "MODERATE",
                "confidence": 58,
                "should_emergency": False,
                "should_specialist": True,
            },
            "cholera": {
                "symptoms": [
                    "severe diarrhea",
                    "vomiting",
                    "dehydration",
                    "leg cramps",
                    "weakness",
                ],
                "severity": "CRITICAL",
                "confidence": 80,
                "should_emergency": True,
                "should_specialist": False,
            },
            "heart_attack": {
                "symptoms": [
                    "chest pain",
                    "chest pressure",
                    "arm pain",
                    "jaw pain",
                    "shortness of breath",
                    "sweating",
                ],
                "severity": "CRITICAL",
                "confidence": 85,
                "should_emergency": True,
                "should_specialist": False,
            },
            "pneumonia": {
                "symptoms": [
                    "high fever",
                    "cough",
                    "chest pain",
                    "difficulty breathing",
                    "chills",
                ],
                "severity": "HIGH",
                "confidence": 70,
                "should_emergency": True,
                "should_specialist": False,
            },
            "snake_bite": {
                "symptoms": [
                    "bite marks",
                    "swelling",
                    "pain",
                    "numbness",
                    "difficulty breathing",
                ],
                "severity": "CRITICAL",
                "confidence": 90,
                "should_emergency": True,
                "should_specialist": False,
            },
            "heatstroke": {
                "symptoms": [
                    "very high fever",
                    "hot dry skin",
                    "confusion",
                    "dizziness",
                    "no sweating",
                ],
                "severity": "CRITICAL",
                "confidence": 82,
                "should_emergency": True,
                "should_specialist": False,
            },
            "mild_headache": {
                "symptoms": ["headache", "fatigue", "mild fever"],
                "severity": "LOW",
                "confidence": 90,
                "should_emergency": False,
                "should_specialist": False,
            },
            "skin_rash": {
                "symptoms": ["rash", "itching", "redness"],
                "severity": "LOW",
                "confidence": 75,
                "should_emergency": False,
                "should_specialist": True,
            },
        }

    def reset(self) -> Dict[str, Any]:
        """Reset environment with rich state"""
        self.episode_id = str(uuid.uuid4())
        self.step_count = 0
        self.total_reward = 0.0
        self.conversation_history = []
        self.symptoms = {}
        self.visual_features = None

        return {
            "episode_id": self.episode_id,
            "step_count": 0,
            "message": "MediGuide AI ready. Multi-turn conversation started.",
            "diseases": list(self.DISEASES.keys()),
            "conversation_history": [],
            "symptoms": {},
            "visual_features": None,
        }

    def step(
        self, action: Dict[str, Any]
    ) -> Tuple[Dict[str, Any], float, bool, Dict[str, Any]]:
        """
        Process action with dynamic state updates.

        Actions:
        - ask_clarification: Reveal new symptoms with probability
        - provide_guidance: Give medical advice
        - suggest_specialist: Recommend specialist
        - trigger_emergency: Emergency response
        """
        self.step_count += 1

        user_input = action.get("symptoms", "")
        action_type = action.get("query_type", "diagnose")

        # Update conversation history (as sequence of turns)
        self.conversation_history.append(
            {"turn": self.step_count, "user_input": user_input, "action": action_type}
        )

        # Parse symptoms
        self._update_symptoms(user_input)

        # Determine reward based on complex logic
        reward, info = self._calculate_reward(action_type)

        self.total_reward += reward

        # Dynamic symptom progression
        self._apply_symptom_progression(action_type)

        observation = {
            "episode_id": self.episode_id,
            "step_count": self.step_count,
            "query": user_input,
            "conversation_history": self.conversation_history[-5:],  # Last 5 turns
            "symptoms": self.symptoms,
            "visual_features": self.visual_features,
            "diseases": list(self.DISEASES.keys()),
        }

        done = self.step_count >= self.max_steps

        return observation, reward, done, info

    def _update_symptoms(self, user_input: str):
        """Parse and update symptoms from user input"""
        user_lower = user_input.lower()
        all_symptoms = set()

        for disease, data in self.DISEASES.items():
            for symptom in data["symptoms"]:
                if symptom in user_lower:
                    all_symptoms.add(symptom)

        self.symptoms = {s: True for s in all_symptoms}

    def set_visual_features(self, visual_features: str):
        """Set visual features from Llama Vision analysis"""
        self.visual_features = visual_features

    def _calculate_reward(self, action_type: str) -> Tuple[float, Dict[str, Any]]:
        """
        Nuanced reward calculation based on:
        - Emergency detection
        - Specialist appropriateness
        - Guidance safety and effectiveness
        """
        reward = 0.1  # Base reward for any action

        # Check current emergency status
        is_emergency = self._is_emergency_condition()
        is_specialist_appropriate = self._is_specialist_appropriate()
        is_guidance_safe = self._is_guidance_safe()
        is_guidance_effective = self._is_guidance_effective()

        # Action: Ask Clarification
        if action_type == "clarify":
            if is_emergency:
                # Negative: Should have detected emergency
                reward -= 0.5
                info = {"penalty": "asked_clarification_when_emergency"}
            elif len(self.symptoms) >= 3:
                # Slight negative: Already enough info
                reward -= 0.1
                info = {"note": "sufficient_info_for_decision"}
            else:
                reward += 0.1
                info = {"note": "appropriate_clarification"}

        # Action: Provide Guidance
        elif action_type == "guidance" or action_type == "diagnose":
            if is_emergency and not self._should_have_triggered_emergency():
                # Negative: Should have been emergency
                reward -= 1.5
                info = {"penalty": "guidance_when_emergency"}
            elif is_emergency and self._should_have_triggered_emergency():
                # Positive: Correctly handled
                reward += 1.0
                info = {"bonus": "correct_emergency_handling"}
            elif is_guidance_effective:
                # Positive: Resolved minor issue
                reward += 2.0
                info = {"bonus": "effective_guidance"}
            elif not is_guidance_safe:
                # Negative: Unsafe guidance
                reward -= 2.0
                info = {"penalty": "unsafe_guidance"}
            else:
                reward += 0.5
                info = {"note": "appropriate_guidance"}

        # Action: Suggest Specialist
        elif action_type == "specialist":
            if is_specialist_appropriate:
                # Positive: Correct specialist referral
                reward += 1.5
                info = {"bonus": "appropriate_specialist_referral"}
            elif not is_emergency and len(self.symptoms) < 3:
                # Negative: Over-referral for minor condition
                reward -= 1.0
                info = {"penalty": "unnecessary_specialist_referral"}
            else:
                reward += 0.3
                info = {"note": "specialist_referred"}

        # Action: Trigger Emergency
        elif action_type == "emergency":
            if is_emergency:
                reward += 2.0
                info = {"bonus": "correct_emergency_trigger"}
            else:
                # False positive - not actually emergency
                reward -= 0.5
                info = {"penalty": "false_emergency"}

        return reward, info

    def _is_emergency_condition(self) -> bool:
        """Check if current symptoms indicate emergency"""
        emergency_symptoms = {
            "chest pain",
            "shortness of breath",
            "severe bleeding",
            "unconscious",
            "difficulty breathing",
            "no pulse",
        }

        # Check text symptoms
        if any(s in emergency_symptoms for s in self.symptoms.keys()):
            return True

        # Check visual features for emergency indicators
        if self.visual_features:
            visual_lower = self.visual_features.lower()
            emergency_visual = [
                "severe",
                "bleeding",
                "unconscious",
                "critical",
                "stage 3",
            ]
            if any(ind in visual_lower for ind in emergency_visual):
                return True

        return False

    def _is_specialist_appropriate(self) -> bool:
        """Check if specialist referral is appropriate"""
        specialist_symptoms = {"rash", "chronic", "persistent", "specialist"}

        if any(s in specialist_symptoms for s in self.symptoms.keys()):
            return True

        if self.visual_features and "rash" in self.visual_features.lower():
            return True

        return False

    def _is_guidance_safe(self) -> bool:
        """Check if guidance is safe (not harmful)"""
        # Simple check - in production would use Llama Guard
        return True

    def _is_guidance_effective(self) -> bool:
        """Check if guidance effectively resolves issue"""
        # For minor conditions
        minor_symptoms = {"headache", "mild fever", "fatigue", "cough"}

        if any(s in minor_symptoms for s in self.symptoms.keys()):
            return True

        return False

    def _should_have_triggered_emergency(self) -> bool:
        """Check if condition should have been emergency"""
        return self._is_emergency_condition()

    def _apply_symptom_progression(self, action_type: str):
        """Dynamic symptom updates based on actions"""

        # If Ask Clarification, with probability reveal new symptom
        if action_type == "clarify" and random.random() < 0.3:
            hidden_symptoms = ["nausea", "dizziness", "weakness"]
            new_symptom = random.choice(hidden_symptoms)
            if new_symptom not in self.symptoms:
                self.symptoms[new_symptom] = True

        # If Provide Guidance for emergency-condition, state deteriorates
        if action_type == "guidance" or action_type == "diagnose":
            if self._is_emergency_condition():
                # Add more severe symptoms
                self.symptoms["worsening"] = True
                if random.random() < 0.2:
                    self.symptoms["severe"] = True

    def get_state(self) -> Dict[str, Any]:
        """Get full environment state"""
        return {
            "episode_id": self.episode_id,
            "step_count": self.step_count,
            "total_reward": self.total_reward,
            "max_steps": self.max_steps,
            "conversation_history": self.conversation_history,
            "symptoms": list(self.symptoms.keys()),
            "visual_features": self.visual_features,
        }
