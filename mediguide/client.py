# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.

"""Mediguide Environment Client."""

from typing import Dict, Optional

try:
    from openenv.core import EnvClient
    from openenv.core.client_types import StepResult
    from openenv.core.env_server.types import State
except ImportError:
    EnvClient = object
    from dataclasses import dataclass

    @dataclass
    class StepResult:
        observation: any
        reward: Optional[float] = None
        done: bool = False

    @dataclass
    class State:
        episode_id: str = ""
        step_count: int = 0


from .models import MediGuideAction, MediGuideObservation


class MediguideEnv(
    EnvClient[MediGuideAction, MediGuideObservation, State]
    if "EnvClient" in dir()
    else object
):
    """
    Client for the MediGuide Environment.

    Medical diagnosis environment for rural India.
    """

    def _step_payload(self, action: MediGuideAction) -> Dict:
        """Convert MediGuideAction to JSON payload."""
        return {
            "symptoms": action.symptoms,
            "query_type": action.query_type,
        }

    def _parse_result(self, payload: Dict) -> StepResult:
        """Parse server response into StepResult[MediGuideObservation]."""
        obs_data = payload.get("observation", {})
        observation = MediGuideObservation(
            episode_id=obs_data.get("episode_id", ""),
            step_count=obs_data.get("step_count", 0),
            query=obs_data.get("query", ""),
            diagnoses=obs_data.get("diagnoses", []),
            emergency_steps=obs_data.get("emergency_steps", []),
            message=obs_data.get("message", ""),
            done=payload.get("done", False),
            reward=payload.get("reward", 0.0),
        )

        return StepResult(
            observation=observation,
            reward=payload.get("reward", 0.0),
            done=payload.get("done", False),
        )

    def _parse_state(self, payload: Dict) -> State:
        """Parse server response into State object."""
        return State(
            episode_id=payload.get("episode_id", ""),
            step_count=payload.get("step_count", 0),
        )


# Backwards compatibility
MediguideEnv = MediguideEnv
