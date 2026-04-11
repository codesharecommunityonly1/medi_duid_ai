#!/usr/bin/env python3
"""
MediGuide AI - Inference Script
Meta + Hugging Face Hackathon 2026
"""

import os
import sys
import json

API_BASE_URL = os.getenv("API_BASE_URL", "https://router.huggingface.co/v1")
MODEL_NAME = os.getenv("MODEL_NAME", "meta-llama/Llama-3.2-11B-Vision-Instruct")
HF_TOKEN = os.getenv("HF_TOKEN")
TASK_NAME = os.getenv("TASK_NAME", "medical_diagnosis")
BENCHMARK = os.getenv("BENCHMARK", "mediguide_ai")
MAX_STEPS = int(os.getenv("MAX_STEPS", "10"))
SUCCESS_SCORE_THRESHOLD = 0.1

# Don't import app.py - avoid any server conflicts
from openenv.env import MedicalEnv


def log_start(task, env, model):
    print(f"[START] task={task} env={env} model={model}", flush=True)


def log_step(step, action, reward, done, error=None):
    err = error if error else "null"
    print(
        f"[STEP] step={step} action={action} reward={reward:.2f} done={str(done).lower()} error={err}",
        flush=True,
    )


def log_end(success, steps, score, rewards):
    r = ",".join(f"{x:.2f}" for x in rewards)
    print(
        f"[END] success={str(success).lower()} steps={steps} score={score:.3f} rewards={r}",
        flush=True,
    )


def main():
    log_start(TASK_NAME, BENCHMARK, MODEL_NAME)

    try:
        env = MedicalEnv()
    except Exception as e:
        print(f"[DEBUG] Env init error: {e}", flush=True)
        log_end(False, 0, 0.0, [])
        return

    rewards = []
    steps_taken = 0
    success = False

    try:
        env.reset()

        test_cases = [
            {"symptoms": "fever chills headache", "query_type": "diagnose"},
            {"symptoms": "chest pain cannot breathe", "query_type": "diagnose"},
            {"symptoms": "mild headache", "query_type": "diagnose"},
        ]

        for step in range(1, MAX_STEPS + 1):
            case = test_cases[(step - 1) % len(test_cases)]

            try:
                env_result = env.step(case)
                reward = env_result.reward if hasattr(env_result, "reward") else 0.0
                done = (
                    env_result.done
                    if hasattr(env_result, "done")
                    else (step >= MAX_STEPS)
                )

                log_step(step, "diagnose", reward, done)
                rewards.append(reward)
                steps_taken = step

                if done:
                    break
            except Exception as e:
                log_step(step, "error", 0.0, True, str(e))
                break

        max_possible = MAX_STEPS * 0.5
        score = sum(rewards) / max_possible if max_possible > 0 else 0
        score = min(max(score, 0.0), 1.0)
        success = score >= SUCCESS_SCORE_THRESHOLD

    except Exception as e:
        print(f"[DEBUG] Episode error: {e}", flush=True)

    finally:
        try:
            env.close()
        except:
            pass
        log_end(success, steps_taken, score, rewards)


if __name__ == "__main__":
    main()
