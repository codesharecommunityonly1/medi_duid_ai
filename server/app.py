"""
MediGuide AI - OpenEnv Server
==============================
FastAPI app with OpenEnv endpoints
"""

try:
    from openenv.core.env_server import create_fastapi_app
    from environment import MediGuideEnvironment
    from models import MediGuideAction, MediGuideObservation

    app = create_fastapi_app(
        MediGuideEnvironment, MediGuideAction, MediGuideObservation
    )
except ImportError:
    from fastapi import FastAPI
    from environment import MediGuideEnvironment

    env = MediGuideEnvironment()
    app = FastAPI(title="MediGuide AI - OpenEnv")

    @app.post("/reset")
    def reset():
        return env.reset()

    @app.post("/step")
    def step(action: dict):
        class Action:
            def __init__(self, d):
                self.symptoms = d.get("symptoms", "")

        return env.step(Action(action))

    @app.get("/state")
    def state():
        return env.state

    @app.get("/health")
    def health():
        return {"status": "healthy", "openenv": True}


def main():
    """Server entry point for pyproject.toml"""
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=7860)


if __name__ == "__main__":
    main()
