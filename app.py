"""
MediGuide AI - FastAPI Entry Point
Meta + Llama 3.2 Hackathon 2026
"""

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

try:
    from inference import MedicalAgent
except ImportError:

    class MedicalAgent:
        def get_response(self, x):
            return {"response": "Logic Error"}


app = FastAPI()
agent = MedicalAgent()


class UserQuery(BaseModel):
    user_input: str


@app.get("/", response_class=HTMLResponse)
async def root():
    return "<html><body><h1>MED_GUID_AI</h1><p>Status: Online</p></body></html>"


@app.get("/health")
async def health():
    return {"status": "ready"}


@app.post("/predict")
async def predict(query: UserQuery):
    try:
        result = agent.get_response(query.user_input)
        return result
    except Exception as e:
        return {"response": f"Error: {str(e)}", "action": "error"}


# Don't start server - HF Spaces handles this automatically
# app variable is used by HF Spaces to mount the server
