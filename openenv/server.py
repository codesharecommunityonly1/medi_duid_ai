"""MediGuide AI - OpenEnv Server Entry Point"""

from openenv.env import MedicalEnv
import json


def main():
    """Main entry point for OpenEnv validation"""
    print("=" * 50)
    print("MediGuide AI - OpenEnv Server")
    print("=" * 50)

    # Initialize environment
    env = MedicalEnv()

    # Reset to initial state
    state = env.reset()
    print(f"\n[RESET] Episode: {state['episode_id']}")
    print(f"  Message: {state['message']}")
    print(f"  Diseases: {len(state['diseases'])}")

    # Run sample episodes
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
        observation, reward, done, info = env.step(action)

        print(f"[STEP {i}] Action: {action['symptoms'][:50]}...")
        print(f"  Diagnoses found: {len(observation['diagnoses'])}")

        if observation["diagnoses"]:
            top = observation["diagnoses"][0]
            print(
                f"  Top diagnosis: {top['disease']} ({top['confidence']}%) - {top['severity']}"
            )

        print(f"  Reward: {reward:.2f}")
        print(f"  Total reward: {info['total_reward']:.2f}")
        print(f"  Done: {done}")

    # Final state
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
