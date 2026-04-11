"""
MediGuide AI - FastAPI Entry Point
Meta + Llama 3.2 Hackathon 2026
"""

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import uvicorn
import os
from inference import MedicalAgent

app = FastAPI()
agent = MedicalAgent()


@app.get("/", response_class=HTMLResponse)
async def root():
    return "<h1>🩺 MED_GUID_AI is Online</h1><p>Status: Healthy</p>"


@app.get("/health")
async def health():
    return {"status": "ready"}


@app.post("/predict")
async def predict(user_input: str):
    result = agent.get_response(user_input)
    return result


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 7860))
    uvicorn.run(app, host="0.0.0.0", port=port)
