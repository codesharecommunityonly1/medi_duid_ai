"""
MediGuide AI - FastAPI Entry Point
Meta + Llama 3.2 Hackathon 2026
"""

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import uvicorn
import os

try:
    from inference import MedicalAgent
except ImportError:

    class MedicalAgent:
        def get_response(self, x):
            return {"response": "Logic Error: inference.py not found."}


app = FastAPI()
agent = MedicalAgent()


class UserQuery(BaseModel):
    user_input: str


@app.get("/", response_class=HTMLResponse)
async def root():
    return """
    <html>
        <head>
            <title>MED_GUID_AI | Status</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; text-align: center; background-color: #f4f7f9; color: #333; padding-top: 100px; }
                .card { background: white; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); display: inline-block; padding: 40px; max-width: 500px; }
                .status-dot { height: 12px; width: 12px; background-color: #28a745; border-radius: 50%; display: inline-block; margin-right: 8px; }
                h1 { color: #0078d4; margin-bottom: 10px; }
                p { color: #666; font-size: 1.1em; }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>🩺 MED_GUID_AI</h1>
                <p><span class="status-dot"></span> <b>Status:</b> System Online</p>
                <p><b>Model:</b> Llama-3.2-Vision (Agentic)</p>
                <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="font-size: 0.9em;">Ready for Meta OpenEnv Evaluation Phase.</p>
            </div>
        </body>
    </html>
    """


@app.get("/health")
async def health():
    return {"status": "ready", "health": "100%"}


@app.post("/predict")
async def predict(query: UserQuery):
    try:
        result = agent.get_response(query.user_input)
        return result
    except Exception as e:
        return {"response": f"Internal Error: {str(e)}", "action": "error"}


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 0))
    if port == 0:
        # Auto-select available port
        import socket

        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(("", 0))
            port = s.getsockname()[1]
    uvicorn.run("app:app", host="0.0.0.0", port=port, reload=False)
