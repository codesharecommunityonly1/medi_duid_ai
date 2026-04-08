"""MediGuide AI - OpenEnv Server Entry Point"""

from openenv.env import MedicalEnv
import json


def main():
    """Main entry point for OpenEnv validation"""
    print("=" * 50)
    print("MediGuide AI - OpenEnv Server")
    print("=" * 50)

    env = MedicalEnv()

    result = env.reset()
    print(f"\n[RESET] Episode: {result.observation.episode_id}")
    print(f"  Message: {result.observation.message}")
    print(f"  Diseases: {len(result.observation.diseases)}")

    test_cases = [
        {"symptoms": "fever chills headache sweating nausea", "query_type": "diagnose"},
        {
            "symptoms": "chest pain shortness of breath arm pain",
            "query_type": "diagnose",
        },
        {"symptoms": "high fever rash joint pain bleeding", "query_type": "diagnose"},
    ]

    for i, action in enumerate(test_cases, 1):
        print(f"\n--- Episode {i} ---")
        step_result = env.step(action)

        print(f"[STEP {i}] Action: {action['symptoms'][:50]}...")
        print(f"  Step: {step_result.observation.step_count}")
        print(f"  Reward: {step_result.reward:.2f}")
        print(f"  Done: {step_result.done}")

    final_state = env.get_state()
    print(f"\n[FINAL STATE]")
    print(f"  Episode: {final_state['episode_id']}")
    print(f"  Steps: {final_state['step_count']}")
    print(f"  Total reward: {final_state['total_reward']}")

    print("\n" + "=" * 50)
    print("OpenEnv validation COMPLETE")
    print("=" * 50)


if __name__ == "__main__":
    main()
