"""
MediGuide AI - OpenEnv Server
==============================
FastAPI app with OpenEnv endpoints
"""

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from environment import MediGuideEnvironment

env = MediGuideEnvironment()

app = FastAPI(title="MediGuide AI - OpenEnv")


@app.post("/reset")
def reset():
    """Reset environment - OpenEnv required"""
    return env.reset()


@app.post("/step")
def step(action: dict):
    """Process symptoms and return diagnosis - OpenEnv step()"""

    class Action:
        def __init__(self, d):
            self.symptoms = d.get("symptoms", "")

    return env.step(Action(action))


@app.get("/state")
def state():
    """Get current episode state - OpenEnv state()"""
    return env.state


@app.get("/health")
def health():
    return {"status": "healthy", "openenv": True, "diseases": 8, "tasks": 3}


def main():
    """Server entry point for pyproject.toml"""
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=7860)


if __name__ == "__main__":
    main()
