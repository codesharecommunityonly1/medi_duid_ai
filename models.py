"""
MediGuide AI - OpenEnv Models
==============================
Type definitions for Action, Observation, State
Following OpenEnv 3-component pattern (module-4)
"""

from typing import List, Optional
from openenv.core.env_server import Action, Observation, State


class MediGuideAction(Action):
    """Action: symptoms input for diagnosis"""

    symptoms: str = ""
    query_type: str = "diagnose"


class MediGuideObservation(Observation):
    """Observation: diagnosis results"""

    episode_id: str = ""
    step_count: int = 0
    query: str = ""
    diagnoses: List[dict] = []
    emergency_steps: List[str] = []
    message: str = ""


class MediGuideState(State):
    """State: episode tracking"""

    episode_id: str = ""
    step_count: int = 0
    target_disease: Optional[str] = None
    max_steps: int = 100
