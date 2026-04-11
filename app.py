"""
MediGuide AI - Meta Llama 3.2 Hackathon 2026
"""

import gradio as gr
import os

# Config
HF_TOKEN = os.getenv("HF_TOKEN", "")

# Medical KB
MEDICAL_KB = {
    "malaria": {
        "symptoms": ["fever", "chills", "headache"],
        "severity": "HIGH",
        "confidence": 72,
        "emergency": "108",
        "specialist": "General Physician",
    },
    "dengue": {
        "symptoms": ["high fever", "rash", "joint pain"],
        "severity": "HIGH",
        "confidence": 65,
        "emergency": "108",
        "specialist": "General Physician",
    },
    "heart_attack": {
        "symptoms": ["chest pain", "arm pain", "shortness of breath"],
        "severity": "CRITICAL",
        "confidence": 85,
        "emergency": "108",
        "specialist": "Cardiologist",
    },
}

HIGH_PRIORITY = [
    "chest pain",
    "heart attack",
    "cannot breathe",
    "unconscious",
    "severe bleeding",
    "stroke",
]


def is_emergency(symptoms):
    s = symptoms.lower()
    for kw in HIGH_PRIORITY:
        if kw in s:
            return True, kw
    return False, ""


def safety_check(user_input):
    for p in ["how to make drug", "how to kill", "bomb", "weapon"]:
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
                    "specialist": data["specialist"],
                    "emergency": data["emergency"],
                }
            )
    matches.sort(key=lambda x: x["confidence"], reverse=True)
    return {"verified": len(matches) > 0, "matches": matches[:3]}


def medical_agent(symptoms, language, image=None):
    if not symptoms or len(symptoms.strip()) < 3:
        return '<div style="color:#FF4444;padding:20px">Please enter symptoms</div>', ""

    if not safety_check(symptoms):
        return '<div style="color:#FFBB33;padding:20px">Request blocked</div>', ""

    is_emergent, keyword = is_emergency(symptoms)
    if is_emergent:
        return (
            f'<div style="background:#2d0000;padding:24px;border-radius:16px;border:2px solid #FF4444"><h2 style="color:#FF4444">EMERGENCY: {keyword.upper()}</h2><p>Call 108 immediately!</p></div>',
            "Emergency",
        )

    result = rag_verify(symptoms)

    if result["verified"]:
        cards = ""
        for d in result["matches"]:
            color = "#CC0000" if d["severity"] == "CRITICAL" else "#FF4444"
            cards += f'<div style="background:rgba(255,255,255,0.04);border-left:4px solid {color};padding:16px;margin:8px 0"><h3 style="color:white">{d["disease"]}</h3><span style="background:{color};color:white;padding:2px 8px">{d["severity"]}</span> <span style="color:#FFBB33">{d["confidence"]}%</span></div>'

        top = result["matches"][0]
        return (
            f'<div style="background:#0d1117;padding:20px;border-radius:16px;color:white"><h2>MediGuide AI</h2>{cards}<p>Emergency: {top["emergency"]}</p></div>',
            "Medical Disclaimer",
        )

    return (
        '<div style="color:#FFBB33;padding:20px">No match. Describe more symptoms.</div>',
        "",
    )


# Gradio UI - simple version
with gr.Blocks(title="MediGuide AI") as demo:
    gr.Markdown("# 🏥 MediGuide AI")

    with gr.Row():
        with gr.Column():
            gr.Markdown("### Enter Symptoms")
            language = gr.Radio(["English", "Hindi"], value="English")
            symptoms = gr.Textbox(
                label="Symptoms", placeholder="fever, headache...", lines=5
            )
            image = gr.Image(label="Image", type="pil")
            btn = gr.Button("Analyze", variant="primary")

        with gr.Column():
            result = gr.HTML(label="Result")
            disclaimer = gr.Textbox(label="Disclaimer", lines=2)

    btn.click(
        fn=medical_agent,
        inputs=[symptoms, language, image],
        outputs=[result, disclaimer],
    )

    gr.Markdown("**108** - Ambulance | **102** - Medical | **112** - Emergency")

# Launch
demo.launch(server_name="0.0.0.0", server_port=7860)
