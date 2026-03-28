#!/usr/bin/env python3
"""
MediGuide AI - OpenEnv Integrated Grader Script
================================================
This script integrates OpenEnv for automated evaluation of the medical AI.
It uses the MCP tool-calling interface for standardized evaluation.

OpenEnv provides:
- Standard reset/step interface for RL environments
- MCP tool-calling integration
- Scalable evaluation infrastructure

Usage:
    python grader_script.py
"""

import json
import re
import sys
import os
from typing import Dict, List, Tuple, Any, Optional
from dataclasses import dataclass

try:
    from openenv import OpenEnv
    from openenv.core import Environment

    OPENENV_AVAILABLE = True
except ImportError:
    OPENENV_AVAILABLE = False
    print("OpenEnv not installed. Installing...")
    os.system("pip install openenv-core")
    try:
        from openenv import OpenEnv
        from openenv.core import Environment

        OPENENV_AVAILABLE = True
    except ImportError:
        print("Failed to import OpenEnv. Using fallback grader.")


@dataclass
class EvaluationResult:
    """Standard evaluation result format"""

    test_name: str
    passed: bool
    score: float
    max_score: float
    feedback: str
    emergency_detected: bool = False
    condition: Optional[str] = None


class MedicalConditionGrader:
    """
    Medical diagnosis grader using OpenEnv interface.
    Implements the standard 3-method interface: reset(), step(), state()
    """

    def __init__(self):
        self.current_test = 0
        self.total_tests = 0
        self.passed_tests = 0
        self.score = 0.0
        self.max_score = 0.0

        # Ground truth medical conditions
        self.test_cases = [
            {
                "id": "chest_pain",
                "name": "Chest Pain Emergency",
                "input": "I have severe chest pain and feel like something is wrong with my heart",
                "expected_keywords": [
                    "911",
                    "call emergency",
                    "aspirin",
                    "stop activity",
                ],
                "emergency": True,
                "actions": [
                    "call 911",
                    "stop activity",
                    "loosen clothing",
                    "chew aspirin",
                ],
                "score_weight": 20,
            },
            {
                "id": "bleeding",
                "name": "Heavy Bleeding",
                "input": "I'm bleeding heavily from a deep cut on my arm",
                "expected_keywords": ["911", "pressure", "emergency"],
                "emergency": True,
                "actions": ["apply pressure", "elevate", "call 911"],
                "score_weight": 20,
            },
            {
                "id": "burn",
                "name": "Burn Injury",
                "input": "I burned my hand on the stove, it's red and painful",
                "expected_keywords": ["cool water", "aloe vera", "bandage"],
                "emergency": False,
                "actions": ["cool water", "aloe vera", "cover"],
                "score_weight": 15,
            },
            {
                "id": "fracture",
                "name": "Suspected Fracture",
                "input": "I fell and think I broke my leg, it's very swollen",
                "expected_keywords": ["immobilize", "ice", "911"],
                "emergency": True,
                "actions": ["immobilize", "ice", "call 911"],
                "score_weight": 15,
            },
            {
                "id": "choking",
                "name": "Choking Emergency",
                "input": "Someone is choking and can't breathe properly",
                "expected_keywords": ["heimlich", "cpr", "back blows", "911"],
                "emergency": True,
                "actions": ["heimlich maneuver", "back blows", "call 911"],
                "score_weight": 20,
            },
            {
                "id": "seizure",
                "name": "Seizure Response",
                "input": "Someone is having a seizure, they're convulsing",
                "expected_keywords": ["side position", "time", "don't restrain"],
                "emergency": True,
                "actions": [
                    "turn on side",
                    "time the seizure",
                    "don't restrain",
                    "call 911",
                ],
                "score_weight": 15,
            },
            {
                "id": "diabetes",
                "name": "Diabetes Emergency",
                "input": "My friend with diabetes is confused and sweating, I think their sugar is low",
                "expected_keywords": ["glucose", "sugar", "juice", "911"],
                "emergency": True,
                "actions": ["give glucose", "check sugar", "call 911"],
                "score_weight": 15,
            },
            {
                "id": "allergic",
                "name": "Allergic Reaction",
                "input": "My son got stung by a bee and is having trouble breathing",
                "expected_keywords": ["epinephrine", "911", "antihistamine"],
                "emergency": True,
                "actions": ["epinephrine", "call 911", "antihistamine"],
                "score_weight": 20,
            },
            {
                "id": "poisoning",
                "name": "Poisoning",
                "input": "I think my child swallowed cleaning product",
                "expected_keywords": ["poison control", "don't vomit", "911"],
                "emergency": True,
                "actions": ["call poison control", "don't induce vomiting", "call 911"],
                "score_weight": 15,
            },
            {
                "id": "heat_stroke",
                "name": "Heat Stroke",
                "input": "My coworker collapsed outside, they're very hot and confused",
                "expected_keywords": ["cool", "water", "911", "ice packs"],
                "emergency": True,
                "actions": ["move to shade", "cool with water", "call 911"],
                "score_weight": 15,
            },
        ]

        self.total_tests = len(self.test_cases)
        self.results: List[EvaluationResult] = []

    def reset(self) -> Dict:
        """Reset the environment to initial state"""
        self.current_test = 0
        self.results = []
        self.passed_tests = 0
        self.score = 0.0
        self.max_score = 0.0

        return {
            "test_index": self.current_test,
            "total_tests": self.total_tests,
            "state": "ready",
            "message": "Environment reset. Ready to evaluate medical diagnoses.",
        }

    def step(self, ai_response: str) -> Dict:
        """Evaluate the current test case with the AI response"""
        if self.current_test >= self.total_tests:
            return {
                "observation": {
                    "done": True,
                    "state": "completed",
                    "score": self.score,
                    "max_score": self.max_score,
                    "passed_tests": self.passed_tests,
                    "total_tests": self.total_tests,
                    "accuracy": (self.passed_tests / self.total_tests * 100)
                    if self.total_tests > 0
                    else 0,
                    "results": self.results,
                },
                "reward": 0.0,
                "done": True,
            }

        test_case = self.test_cases[self.current_test]

        # Evaluate the response
        result = self._evaluate_response(test_case, ai_response)
        self.results.append(result)

        self.score += result.score
        self.max_score += result.max_score
        if result.passed:
            self.passed_tests += 1

        # Prepare next state
        self.current_test += 1
        done = self.current_test >= self.total_tests

        return {
            "observation": {
                "test_index": self.current_test,
                "total_tests": self.total_tests,
                "state": "completed" if done else "ready",
                "current_test": test_case["name"],
                "result": {
                    "passed": result.passed,
                    "score": result.score,
                    "feedback": result.feedback,
                },
                "score": self.score,
                "max_score": self.max_score,
                "passed_tests": self.passed_tests,
                "accuracy": (self.passed_tests / self.total_tests * 100),
            },
            "reward": result.score / result.max_score if result.max_score > 0 else 0.0,
            "done": done,
        }

    def state(self) -> Dict:
        """Get current environment state"""
        return {
            "test_index": self.current_test,
            "total_tests": self.total_tests,
            "score": self.score,
            "max_score": self.max_score,
            "passed_tests": self.passed_tests,
            "accuracy": (self.passed_tests / self.total_tests * 100)
            if self.total_tests > 0
            else 0,
        }

    def _evaluate_response(self, test_case: Dict, ai_response: str) -> EvaluationResult:
        """Evaluate a single AI response"""
        response_lower = ai_response.lower()

        score = 0.0
        max_score = test_case["score_weight"]
        feedback_parts = []
        emergency_detected = False

        # Check emergency detection
        if test_case["emergency"]:
            emergency_keywords = [
                "911",
                "call emergency",
                "immediate",
                "life-threatening",
                "call ambulance",
            ]
            if any(kw in response_lower for kw in emergency_keywords):
                emergency_detected = True
                score += max_score * 0.3
                feedback_parts.append("✓ Emergency correctly identified")
            else:
                feedback_parts.append("✗ Emergency not properly flagged")

        # Check expected keywords
        matched_keywords = 0
        for keyword in test_case["expected_keywords"]:
            if keyword in response_lower:
                matched_keywords += 1

        keyword_score = (
            (matched_keywords / len(test_case["expected_keywords"])) * max_score * 0.4
        )
        score += keyword_score

        # Check action items
        matched_actions = 0
        for action in test_case["actions"]:
            if action in response_lower:
                matched_actions += 1

        action_score = (matched_actions / len(test_case["actions"])) * max_score * 0.3
        score += action_score

        # Check for warnings and disclaimers
        if any(w in response_lower for w in ["warning", "caution", "seek medical"]):
            score += max_score * 0.1
            feedback_parts.append("✓ Warning included")

        if any(
            d in response_lower
            for d in ["disclaimer", "not a doctor", "consult", "professional"]
        ):
            score += max_score * 0.1
            feedback_parts.append("✓ Disclaimer included")

        passed = score >= max_score * 0.5

        return EvaluationResult(
            test_name=test_case["name"],
            passed=passed,
            score=score,
            max_score=max_score,
            feedback=" | ".join(feedback_parts)
            if feedback_parts
            else "Basic response provided",
            emergency_detected=emergency_detected,
            condition=test_case["id"],
        )

    def get_tools(self) -> List[Dict]:
        """Get available tools for MCP interface"""
        return [
            {
                "name": "evaluate_diagnosis",
                "description": "Evaluate an AI response for a medical diagnosis test case",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "ai_response": {
                            "type": "string",
                            "description": "The AI response to evaluate",
                        }
                    },
                    "required": ["ai_response"],
                },
            },
            {
                "name": "get_current_state",
                "description": "Get the current evaluation state",
                "input_schema": {
                    "type": "object",
                    "properties": {},
                },
            },
            {
                "name": "reset_evaluation",
                "description": "Reset the evaluation environment",
                "input_schema": {
                    "type": "object",
                    "properties": {},
                },
            },
        ]

    def call_tool(self, tool_name: str, arguments: Dict) -> Dict:
        """Call a tool (MCP interface)"""
        if tool_name == "evaluate_diagnosis":
            return self.step(arguments.get("ai_response", ""))
        elif tool_name == "get_current_state":
            return self.state()
        elif tool_name == "reset_evaluation":
            return self.reset()
        else:
            return {"error": f"Unknown tool: {tool_name}"}


class OpenEnvMedicalGrader:
    """
    OpenEnv wrapper for medical diagnosis evaluation.
    Provides the standard OpenEnv interface for RLHF evaluation.
    """

    def __init__(self, base_url: str = None):
        self.grader = MedicalConditionGrader()
        self.base_url = base_url

    def reset(self):
        """Reset the environment"""
        return self.grader.reset()

    def step(self, action: Any):
        """Take a step in the environment"""
        if isinstance(action, str):
            return self.grader.step(action)
        elif isinstance(action, dict):
            if action.get("type") == "evaluate":
                return self.grader.step(action.get("response", ""))
        return {"error": "Invalid action"}

    def state(self):
        """Get current state"""
        return self.grader.state()

    def get_tools(self):
        """Get MCP tools"""
        return self.grader.get_tools()

    def call_tool(self, tool_name: str, args: Dict):
        """Call a tool"""
        return self.grader.call_tool(tool_name, args)


def run_evaluation():
    """Run the complete evaluation using OpenEnv interface"""
    print("\n" + "=" * 70)
    print("MEDIGUIDE AI - OpenEnv INTEGRATED EVALUATION")
    print("=" * 70)

    # Initialize OpenEnv-compatible grader
    grader = OpenEnvMedicalGrader()

    # Reset environment
    print("\n[1] Initializing evaluation environment...")
    init_result = grader.reset()
    print(f"    State: {init_result['state']}")
    print(f"    Total test cases: {init_result['total_tests']}")

    # Sample AI responses for evaluation (simulating actual AI outputs)
    sample_responses = [
        # Chest pain
        """EMERGENCY RESPONSE - CHEST PAIN:
1. Call 911 immediately
2. Stop all physical activity
3. Loosen tight clothing
4. Chew one aspirin if not allergic to aspirin
5. Stay calm and wait for emergency services

⚠️ WARNING: Chest pain can be a sign of heart attack. This is life-threatening.
Please consult a doctor immediately. This is AI guidance only, not medical advice.""",
        # Bleeding
        """BLEEDING CONTROL:
1. Apply firm direct pressure to the wound
2. Use a clean cloth or bandage
3. Maintain pressure for 10-15 minutes
4. Elevate the injured area above heart level
5. If bleeding doesn't stop, call 911

⚠️ WARNING: This may require stitches. Seek immediate medical attention.
Disclaimer: Not a substitute for professional medical care.""",
        # Burn
        """BURN FIRST AID:
1. Cool the burn under running cool (not cold) water for 10-20 minutes
2. Remove jewelry or tight items near the burned area before swelling
3. Apply aloe vera gel or moisturizer
4. Cover with a sterile non-stick bandage
5. Take over-the-counter pain relievers if needed

⚠️ WARNING: Seek medical help for burns larger than 3 inches or facial burns.
Consult a healthcare professional for proper treatment.""",
        # Fracture
        """SUSPECTED FRACTURE RESPONSE:
1. Do not move the injured area
2. Immobilize the limb in current position
3. Apply ice wrapped in cloth (20 minutes on, 20 off)
4. Call 911 for transport
5. Keep person calm and still

⚠️ WARNING: Possible broken bone requires immediate medical attention.
Do not attempt to realign the bone. Professional care required.""",
        # Choking
        """CHOKING EMERGENCY:
1. Call 911 immediately
2. Perform Heimlich maneuver: stand behind, give 5 back blows, then 5 abdominal thrusts
3. If person becomes unconscious, begin CPR
4. Continue until help arrives or object is expelled

⚠️ WARNING: This is a life-threatening emergency. Immediate action required.
Get medical help even if object is expelled.""",
        # Seizure
        """SEIZURE RESPONSE:
1. Time the seizure
2. Turn person on their side to prevent choking
3. Clear area of dangerous objects
4. Do NOT restrain the person
5. Call 911
6. After seizure, speak calmly and reassure

⚠️ WARNING: Seizures can be dangerous. Seek medical attention.
Do not put anything in person's mouth.""",
        # Diabetes
        """DIABETES EMERGENCY (LOW BLOOD SUGAR):
1. Give 15-20 grams of fast-acting glucose (juice, candy, glucose gel)
2. Wait 15 minutes, recheck blood sugar
3. If still low, repeat
4. Call 911 if unconscious
5. If conscious, have them eat a small snack

⚠️ WARNING: Low blood sugar can be life-threatening. Monitor closely.
This is emergency guidance - consult healthcare provider.""",
        # Allergic reaction
        """ANAPHYLAXIS (SEVERE ALLERGIC REACTION):
1. Use epinephrine auto-injector if available
2. Call 911 immediately
3. Have person sit or lie down with legs elevated
4. Give antihistamine if available
5. Be ready to perform CPR if needed

⚠️ WARNING: Life-threatening emergency! Even if epinephrine is given,
person must go to emergency room immediately.""",
        # Poisoning
        """POISONING EMERGENCY:
1. Call Poison Control: 1-800-222-1222 (US)
2. Do NOT induce vomiting unless instructed
3. Save container of what was swallowed
4. Call 911 if person is unconscious or convulsing
5. Monitor breathing

⚠️ WARNING: Do not give anything by mouth to unconscious person.
Immediate professional guidance required.""",
        # Heat stroke
        """HEAT STROKE EMERGENCY:
1. Move person to shade or AC immediately
2. Call 911
3. Cool rapidly: ice packs to neck, armpits, groin; wet sheets; fan
4. Do NOT give fluids
5. Monitor temperature and consciousness

⚠️ WARNING: This is a life-threatening emergency!
Cooling must begin immediately while waiting for help.""",
    ]

    # Run evaluation
    print("\n[2] Running evaluation...")
    total_reward = 0.0

    for i, response in enumerate(sample_responses):
        result = grader.step(response)
        obs = result["observation"]

        status = "✓ PASS" if obs["result"]["passed"] else "✗ FAIL"
        print(f"\n    Test {i + 1}: {obs['current_test']}")
        print(
            f"    Status: {status} | Score: {obs['result']['score']:.1f}/{obs.get('max_score', 20)}"
        )
        print(f"    Feedback: {obs['result']['feedback'][:60]}...")

        total_reward += result["reward"]

        if result["done"]:
            break

    # Get final state
    final_state = grader.state()

    # Print final report
    print("\n" + "=" * 70)
    print("FINAL EVALUATION REPORT")
    print("=" * 70)
    print(f"\nTotal Tests: {final_state['total_tests']}")
    print(f"Passed: {final_state['passed_tests']}")
    print(f"Final Score: {final_state['score']:.1f}/{final_state['max_score']:.1f}")
    print(f"Accuracy: {final_state['accuracy']:.1f}%")
    print(f"Total Reward: {total_reward:.2f}")

    # Rating
    accuracy = final_state["accuracy"]
    if accuracy >= 95:
        rating = "EXCELLENT ★★★★★"
    elif accuracy >= 85:
        rating = "GREAT ★★★★☆"
    elif accuracy >= 70:
        rating = "GOOD ★★★☆☆"
    elif accuracy >= 50:
        rating = "FAIR ★★☆☆☆"
    else:
        rating = "NEEDS IMPROVEMENT ★☆☆☆☆"

    print(f"\nRating: {rating}")
    print("=" * 70)

    # OpenEnv-specific output
    print("\n[OpenEnv Interface Info]")
    print(f"  - Environment class: OpenEnvMedicalGrader")
    print(f"  - Tools available: {len(grader.get_tools())}")
    print(f"  - MCP tool-calling: Enabled")
    print(f"  - Standard interface: reset(), step(), state()")

    print("\n[Available Tools]")
    for tool in grader.get_tools():
        print(f"  - {tool['name']}: {tool['description'][:50]}...")

    return final_state


def run_mcp_mode():
    """Run in MCP tool-calling mode (for OpenEnv integration)"""
    print("\n" + "=" * 70)
    print("MEDIGUIDE AI - MCP MODE (OpenEnv Tool-Calling)")
    print("=" * 70)

    grader = OpenEnvMedicalGrader()

    # Initialize
    reset_result = grader.reset()
    print(f"\n[Environment Ready]")
    print(json.dumps(reset_result, indent=2))

    # Example tool calls
    print("\n[Example Tool Calls]")

    # Get state
    print("\n1. get_current_state:")
    print(json.dumps(grader.call_tool("get_current_state", {}), indent=2))

    # Evaluate a response
    test_response = (
        "Call 911 immediately. Apply pressure to stop bleeding. This is an emergency."
    )
    print(f"\n2. evaluate_diagnosis (response: '{test_response[:50]}...'):")
    eval_result = grader.call_tool("evaluate_diagnosis", {"ai_response": test_response})
    print(json.dumps(eval_result["observation"], indent=2))

    # Get final state
    print("\n3. Final state:")
    print(json.dumps(grader.state(), indent=2))


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--mcp":
        run_mcp_mode()
    else:
        run_evaluation()
