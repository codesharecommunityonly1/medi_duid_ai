# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.

"""
Data models for the MediGuide Environment.

Medical diagnosis environment for rural India.
"""

try:
    from openenv.core.env_server.types import Action, Observation
except ImportError:
    from pydantic import BaseModel

    class Action(BaseModel):
        pass

    class Observation(BaseModel):
        pass


from typing import List, Dict, Optional
from pydantic import Field


class MediGuideAction(Action):
    """Action for the MediGuide environment - patient symptoms."""

    symptoms: str = Field(default="", description="Patient symptoms")
    query_type: str = Field(default="diagnose", description="Type of query")


class MediGuideObservation(Observation):
    """Observation from the MediGuide environment - diagnosis results."""

    episode_id: str = Field(default="", description="Unique episode identifier")
    step_count: int = Field(default=0, description="Number of steps taken")
    query: str = Field(default="", description="User's symptom input")
    diagnoses: List[Dict] = Field(
        default_factory=list, description="List of possible diseases"
    )
    emergency_steps: List[str] = Field(
        default_factory=list, description="Emergency guidance"
    )
    message: str = Field(default="", description="Status message")


# Backwards compatibility aliases
MediguideAction = MediGuideAction
MediguideObservation = MediGuideObservation
