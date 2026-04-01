"""
MediGuide AI - OpenEnv Models
==============================
Type definitions for Action, Observation, State
"""

from dataclasses import dataclass
from typing import List, Optional


@dataclass
class MediGuideAction:
    """Action: symptoms input for diagnosis"""

    symptoms: str = ""
    query_type: str = "diagnose"


@dataclass
class MediGuideObservation:
    """Observation: diagnosis results"""

    done: bool = False
    reward: Optional[float] = None
    episode_id: str = ""
    step_count: int = 0
    query: str = ""
    diagnoses: List[dict] = None
    emergency_steps: List[str] = None
    message: str = ""

    def __post_init__(self):
        if self.diagnoses is None:
            self.diagnoses = []
        if self.emergency_steps is None:
            self.emergency_steps = []


@dataclass
class MediGuideState:
    """State: episode tracking"""

    episode_id: Optional[str] = None
    step_count: int = 0
    target_disease: Optional[str] = None
    max_steps: int = 100
