# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.

"""
FastAPI application for the Mediguide Environment.

This module creates an HTTP server that exposes the MediguideEnvironment
over HTTP and WebSocket endpoints, compatible with EnvClient.
"""

try:
    from openenv.core.env_server.http_server import create_app
except Exception as e:
    raise ImportError(
        "openenv is required for the web interface. Install dependencies with 'uv sync'"
    ) from e

try:
    from ..models import MediGuideAction, MediGuideObservation
    from .mediguide_environment import MediguideEnvironment
except ModuleNotFoundError:
    from models import MediGuideAction, MediGuideObservation
    from mediguide_environment import MediguideEnvironment


# Create the app with web interface and README integration
app = create_app(
    MediguideEnvironment,
    MediGuideAction,
    MediGuideObservation,
    env_name="mediguide",
    max_concurrent_envs=1,
)


def main(host: str = "0.0.0.0", port: int = 8000):
    """Entry point for direct execution."""
    import uvicorn

    uvicorn.run(app, host=host, port=port)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()
    main()
