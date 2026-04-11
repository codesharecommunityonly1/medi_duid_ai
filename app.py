"""
MediGuide AI - Meta Llama 3.2 Hackathon 2026
"""

import gradio as gr
import os

# Medical KB
MEDICAL_KB = {
    "malaria": {
        "symptoms": ["fever", "chills", "headache"],
        "severity": "HIGH",
        "confidence": 72,
        "emergency": "108",
    },
    "dengue": {
        "symptoms": ["high fever", "rash", "joint pain"],
        "severity": "HIGH",
        "confidence": 65,
        "emergency": "108",
    },
    "heart_attack": {
        "symptoms": ["chest pain", "arm pain", "shortness of breath"],
        "severity": "CRITICAL",
        "confidence": 85,
        "emergency": "108",
    },
}

HIGH_PRIORITY = [
    "chest pain",
    "heart attack",
    "cannot breathe",
    "unconscious",
    "severe bleeding",
]


def is_emergency(symptoms):
    s = symptoms.lower()
    for kw in HIGH_PRIORITY:
        if kw in s:
            return True, kw
    return False, ""


def safety_check(user_input):
    for p in ["how to make drug", "how to kill", "bomb"]:
        if p in user_input.lower():
            return False
    return True


def rag_verify(symptoms):
    s = symptoms.lower()
    matches = []
    for disease, data in MEDICAL_KB.items():
        matched = [sym for sym in data["symptoms"] if sym in s]
        if matched:
            matches.append(
                {
                    "disease": disease,
                    "confidence": data["confidence"],
                    "severity": data["severity"],
                    "emergency": data["emergency"],
                }
            )
    matches.sort(key=lambda x: x["confidence"], reverse=True)
    return {"verified": len(matches) > 0, "matches": matches[:3]}


def medical_agent(symptoms, language, image=None):
    if not symptoms or len(symptoms.strip()) < 3:
        return '<div style="color:#FF4444">Please enter symptoms</div>', ""

    if not safety_check(symptoms):
        return '<div style="color:#FFBB33">Request blocked</div>', ""

    is_emergent, keyword = is_emergency(symptoms)
    if is_emergent:
        return (
            f'<div style="background:#200"><h2>EMERGENCY: {keyword.upper()}</h2><p>Call 108!</p></div>',
            "Emergency",
        )

    result = rag_verify(symptoms)

    if result["verified"]:
        cards = ""
        for d in result["matches"]:
            color = "#C00" if d["severity"] == "CRITICAL" else "#F44"
            cards += f'<div style="border-left:4px solid {color};padding:8px;margin:4px 0"><b>{d["disease"]}</b> {d["confidence"]}% - {d["severity"]}</div>'

        top = result["matches"][0]
        return (
            f'<div style="background:#111;padding:16px;color:white"><h2>MediGuide AI</h2>{cards}<p>Emergency: {top["emergency"]}</p></div>',
            "Medical Disclaimer",
        )

    return '<div style="color:#FB4">No match</div>', ""


# Gradio UI
demo = gr.Blocks(title="MediGuide AI")

with demo:
    gr.Markdown("# 🏥 MediGuide AI")
    with gr.Row():
        with gr.Column():
            gr.Markdown("### Symptoms")
            language = gr.Radio(["English", "Hindi"], value="English")
            symptoms = gr.Textbox(label="", placeholder="fever, headache...", lines=5)
            btn = gr.Button("Analyze", variant="primary")
        with gr.Column():
            result = gr.HTML()

    btn.click(fn=medical_agent, inputs=[symptoms, language], outputs=[result])
    gr.Markdown("**108** Ambulance | **102** Medical")

# HF Spaces - don't launch here, just expose demo
# HF Spaces will automatically start the server
app = demo
