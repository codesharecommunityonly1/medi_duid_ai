"""
MediGuide AI - Inference Script
===================================
Meta + Hugging Face Hackathon 2026
Medical Diagnosis Environment

MANDATORY:
- Uses OpenAI Client for LLM calls
- Emits [START], [STEP], [END] to stdout
- Score in [0, 1]
"""

import os
import textwrap
from typing import List, Optional

from openai import OpenAI

# Environment variables
API_BASE_URL = os.getenv("API_BASE_URL", "https://router.huggingface.co/v1")
MODEL_NAME = os.getenv("MODEL_NAME", "meta-llama/Llama-3.2-11B-Vision-Instruct")
HF_TOKEN = os.getenv("HF_TOKEN", "")

# Task configuration
TASK_NAME = os.getenv("TASK_NAME", "medical_diagnosis")
BENCHMARK = os.getenv("BENCHMARK", "mediguide_ai")
MAX_STEPS = int(os.getenv("MAX_STEPS", "10"))
TEMPERATURE = float(os.getenv("TEMPERATURE", "0.7"))
MAX_TOKENS = int(os.getenv("MAX_TOKENS", "512"))

# Success threshold
SUCCESS_SCORE_THRESHOLD = 0.1

# Import our medical environment
from openenv.env import MedicalEnv

# System prompt for medical diagnosis
SYSTEM_PROMPT = textwrap.dedent(
    """
    You are MediGuide AI, a medical diagnosis assistant.
    Your task is to analyze symptoms and provide diagnosis with confidence scores.
    
    Guidelines:
    - Analyze the symptoms provided
    - Return a valid diagnosis with severity (CRITICAL/HIGH/MODERATE/LOW)
    - Provide emergency steps if severity is CRITICAL or HIGH
    - Always recommend seeing a doctor
    
    Output format: Return diagnosis in JSON format with disease name, confidence, and severity.
    """
).strip()


def log_start(task: str, env: str, model: str) -> None:
    """Log episode start"""
    print(f"[START] task={task} env={env} model={model}", flush=True)


def log_step(
    step: int, action: str, reward: float, done: bool, error: Optional[str]
) -> None:
    """Log each step"""
    error_val = error if error else "null"
    done_val = str(done).lower()
    print(
        f"[STEP] step={step} action={action} reward={reward:.2f} done={done_val} error={error_val}",
        flush=True,
    )


def log_end(success: bool, steps: int, score: float, rewards: List[float]) -> None:
    """Log episode end"""
    rewards_str = ",".join(f"{r:.2f}" for r in rewards)
    print(
        f"[END] success={str(success).lower()} steps={steps} score={score:.3f} rewards={rewards_str}",
        flush=True,
    )


def get_model_diagnosis(client: OpenAI, symptoms: str) -> str:
    """Get LLM diagnosis for symptoms"""
    if not client:
        return ""

    try:
        completion = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": f"Diagnose these symptoms: {symptoms}"},
            ],
            temperature=TEMPERATURE,
            max_tokens=MAX_TOKENS,
            stream=False,
        )
        return (completion.choices[0].message.content or "").strip()
    except Exception as e:
        print(f"[DEBUG] Model request failed: {e}", flush=True)
        return ""


def main():
    """Main inference loop"""
    # Initialize OpenAI client
    client = None
    if HF_TOKEN:
        client = OpenAI(base_url=API_BASE_URL, api_key=HF_TOKEN)

    # Initialize environment
    env = MedicalEnv()

    # Run episode
    history = []
    rewards = []
    steps_taken = 0
    score = 0.0
    success = False

    # Log start
    log_start(task=TASK_NAME, env=BENCHMARK, model=MODEL_NAME)

    try:
        # Reset environment
        result = env.reset()
        last_observation = str(result)
        last_reward = 0.0

        # Test cases for different medical scenarios
        test_cases = [
            {
                "symptoms": "fever chills headache sweating nausea",
                "query_type": "diagnose",
            },
            {
                "symptoms": "chest pain shortness of breath arm pain",
                "query_type": "diagnose",
            },
            {
                "symptoms": "high fever rash joint pain bleeding",
                "query_type": "diagnose",
            },
            {
                "symptoms": "severe diarrhea vomiting dehydration",
                "query_type": "diagnose",
            },
            {"symptoms": "bite marks swelling pain numbness", "query_type": "diagnose"},
        ]

        # Run up to MAX_STEPS or test cases
        for step in range(1, MAX_STEPS + 1):
            # Get test case for this step
            action = test_cases[(step - 1) % len(test_cases)]
            symptoms = action["symptoms"]

            # Get LLM diagnosis (if available)
            llm_diagnosis = ""
            if client:
                llm_diagnosis = get_model_diagnosis(client, symptoms)

            # Take step in environment
            result = env.step(action)
            observation = result[0]
            reward = result[1]
            done = result[2]
            info = result[3]

            # Format action string for logging
            action_str = f"diagnose('{symptoms[:30]}...')"

            # Track rewards
            if reward is None:
                reward = 0.0
            rewards.append(reward)
            steps_taken = step
            last_observation = str(observation)
            last_reward = reward

            # Log step
            log_step(step=step, action=action_str, reward=reward, done=done, error=None)

            history.append(f"Step {step}: {action_str} -> reward {reward:+.2f}")

            if done:
                break

        # Calculate final score (normalize to [0, 1])
        # Max possible reward per step is 0.5 (0.1 base + 0.2 emergency bonus + 0.2 critical bonus)
        max_possible_reward = MAX_STEPS * 0.5
        if max_possible_reward > 0:
            score = sum(rewards) / max_possible_reward
        score = min(max(score, 0.0), 1.0)  # clamp to [0, 1]

        success = score >= SUCCESS_SCORE_THRESHOLD

    except Exception as e:
        print(f"[DEBUG] Episode error: {e}", flush=True)
        success = False
        steps_taken = 0
        score = 0.0
        rewards = []

    finally:
        # Log end
        log_end(success=success, steps=steps_taken, score=score, rewards=rewards)


if __name__ == "__main__":
    main()
