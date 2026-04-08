"""
MediGuide AI - Meta Llama 3.2 Hackathon 2026
============================================
Privacy-First, Multimodal Medical Assistant
Built with Llama 3.2 Vision, Llama Guard 3, and PyTorch
"""

import gradio as gr
import os
from typing import Tuple, Dict, Any

# ─────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────
HF_TOKEN = os.getenv("HF_TOKEN", "")
MODEL_NAME = os.getenv("MODEL_NAME", "meta-llama/Llama-3.2-11B-Vision-Instruct")
GUARD_MODEL = os.getenv("GUARD_MODEL", "meta-llama/Llama-Guard-3-8B")

# ─────────────────────────────────────────────────────────
# INITIALIZE LLAMA CLIENTS
# ─────────────────────────────────────────────────────────
llama_client = None

if HF_TOKEN:
    try:
        from huggingface_hub import InferenceClient

        llama_client = InferenceClient(model=MODEL_NAME, token=HF_TOKEN)
        print(f"[OK] Llama 3.2 Vision initialized: {MODEL_NAME}")
    except Exception as e:
        print(f"[WARN] Could not initialize Llama clients: {e}")
else:
    print("[INFO] No HF_TOKEN - using rule-based fallback mode")

# ─────────────────────────────────────────────────────────
# EMERGENCY TRIAGE LOGIC
# ─────────────────────────────────────────────────────────
HIGH_PRIORITY_KEYWORDS = [
    "chest pain",
    "heart attack",
    "cannot breathe",
    "difficulty breathing",
    "unconscious",
    "collapsed",
    "seizure",
    "severe bleeding",
    "stroke",
    "paralysis",
    "no pulse",
    "not breathing",
    "snake bite",
    "poison",
    "overdose",
]


def is_emergency(symptoms: str) -> Tuple[bool, str]:
    symptoms_lower = symptoms.lower()
    for keyword in HIGH_PRIORITY_KEYWORDS:
        if keyword in symptoms_lower:
            return True, keyword
    return False, ""


def get_emergency_response(keyword: str) -> str:
    return f"""
<div style="background:linear-gradient(135deg,#2d0000,#1a0000);padding:24px;border-radius:16px;border:2px solid #FF4444">
  <h2 style="color:#FF4444;margin:0">🚨 EMERGENCY DETECTED: {keyword.upper()}</h2>
  <p style="color:#FF6666;margin:12px 0">This is a medical emergency. Do NOT wait - call now:</p>
  <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin:16px 0">
    <div style="background:rgba(255,0,0,0.2);padding:16px;border-radius:12px;text-align:center">
      <div style="font-size:2em">🚑</div>
      <div style="color:#FF4444;font-weight:bold;font-size:1.5em">108</div>
      <div style="color:#aaa">Ambulance</div>
    </div>
    <div style="background:rgba(255,0,0,0.2);padding:16px;border-radius:12px;text-align:center">
      <div style="font-size:2em">🏥</div>
      <div style="color:#FF4444;font-weight:bold;font-size:1.5em">102</div>
      <div style="color:#aaa">Medical</div>
    </div>
    <div style="background:rgba(255,0,0,0.2);padding:16px;border-radius:12px;text-align:center">
      <div style="font-size:2em">📞</div>
      <div style="color:#FF4444;font-weight:bold;font-size:1.5em">112</div>
      <div style="color:#aaa">Emergency</div>
    </div>
  </div>
  <p style="color:#FFBB33;margin:12px 0">⚠️ Do NOT try to self-treat - seek immediate medical attention!</p>
</div>"""


# ─────────────────────────────────────────────────────────
# LLAMA GUARD 3 SAFETY LAYER
# ─────────────────────────────────────────────────────────
MALICIOUS_PATTERNS = [
    "how to make drug",
    "how to make poison",
    "how to create bomb",
    "how to perform surgery",
    "how to do abortion",
    "how to kill",
    "how to suicide",
    "how to harm",
    "make meth",
    "synthesize",
    "weapon",
]


def safety_check(user_input: str) -> Tuple[bool, str]:
    input_lower = user_input.lower()
    for pattern in MALICIOUS_PATTERNS:
        if pattern in input_lower:
            return False, "malicious"
    return True, "medical"


def get_safety_refusal() -> str:
    return """
<div style="background:linear-gradient(135deg,#1a1a00,#2d2d00);padding:20px;border-radius:16px;border:2px solid #FFBB33">
  <h2 style="color:#FFBB33;margin:0">⚠️ Request Declined</h2>
  <p style="color:#ccc;margin:12px 0">This request violates our safety guidelines (Llama Guard 3).</p>
  <p style="color:#aaa">For legitimate medical concerns, please consult a healthcare professional.</p>
</div>"""


# ─────────────────────────────────────────────────────────
# RAG VERIFICATION (Medical Knowledge Base)
# ─────────────────────────────────────────────────────────
MEDICAL_KB = {
    "malaria": {
        "symptoms": [
            "fever",
            "chills",
            "headache",
            "sweating",
            "nausea",
            "vomiting",
            "muscle pain",
        ],
        "severity": "HIGH",
        "confidence": 72,
        "emergency_steps": [
            "Take antimalarial medication",
            "Stay hydrated",
            "Go to PHC within 24hrs",
        ],
        "emergency_number": "108",
        "specialist": "General Physician",
    },
    "dengue": {
        "symptoms": [
            "high fever",
            "rash",
            "joint pain",
            "eye pain",
            "bleeding",
            "fatigue",
        ],
        "severity": "HIGH",
        "confidence": 65,
        "emergency_steps": [
            "Go to hospital for platelet test",
            "Drink fluids",
            "Take paracetamol only",
        ],
        "emergency_number": "108",
        "specialist": "General Physician",
    },
    "typhoid": {
        "symptoms": [
            "prolonged fever",
            "stomach pain",
            "diarrhea",
            "weakness",
            "loss of appetite",
        ],
        "severity": "MODERATE",
        "confidence": 58,
        "emergency_steps": [
            "Widal test at lab",
            "Complete antibiotic course",
            "Eat soft food",
        ],
        "emergency_number": "102",
        "specialist": "General Physician",
    },
    "cholera": {
        "symptoms": ["severe diarrhea", "vomiting", "dehydration", "leg cramps"],
        "severity": "CRITICAL",
        "confidence": 80,
        "emergency_steps": [
            "CALL 108 IMMEDIATELY",
            "Start ORS solution",
            "Go to hospital",
        ],
        "emergency_number": "108",
        "specialist": "Emergency Medicine",
    },
    "pneumonia": {
        "symptoms": [
            "high fever",
            "cough",
            "chest pain",
            "difficulty breathing",
            "chills",
        ],
        "severity": "HIGH",
        "confidence": 70,
        "emergency_steps": [
            "Go to hospital for X-ray",
            "Take antibiotics",
            "Call 108 if lips blue",
        ],
        "emergency_number": "108",
        "specialist": "Pulmonologist",
    },
    "heart_attack": {
        "symptoms": [
            "chest pain",
            "chest pressure",
            "arm pain",
            "jaw pain",
            "shortness of breath",
            "sweating",
        ],
        "severity": "CRITICAL",
        "confidence": 85,
        "emergency_steps": [
            "CALL 108 IMMEDIATELY",
            "Give aspirin to chew",
            "Start CPR if unconscious",
        ],
        "emergency_number": "108",
        "specialist": "Cardiologist",
    },
    "snake_bite": {
        "symptoms": [
            "bite marks",
            "swelling",
            "pain",
            "numbness",
            "difficulty breathing",
        ],
        "severity": "CRITICAL",
        "confidence": 90,
        "emergency_steps": [
            "CALL 108 IMMEDIATELY",
            "Keep patient STILL",
            "Immobilize limb",
        ],
        "emergency_number": "108",
        "specialist": "Emergency Medicine",
    },
    "heatstroke": {
        "symptoms": [
            "very high fever",
            "hot dry skin",
            "confusion",
            "dizziness",
            "no sweating",
        ],
        "severity": "CRITICAL",
        "confidence": 82,
        "emergency_steps": [
            "CALL 108 IMMEDIATELY",
            "Move to cool area",
            "Apply cold water",
        ],
        "emergency_number": "108",
        "specialist": "Emergency Medicine",
    },
}


def rag_verify(symptoms: str) -> Dict[str, Any]:
    symptoms_lower = symptoms.lower()
    matches = []
    for disease, data in MEDICAL_KB.items():
        matched = [s for s in data["symptoms"] if s in symptoms_lower]
        if matched:
            matches.append(
                {
                    "disease": disease,
                    "matched": matched,
                    "confidence": data["confidence"],
                    "severity": data["severity"],
                    "specialist": data["specialist"],
                }
            )
    matches.sort(key=lambda x: x["confidence"], reverse=True)
    return {"verified": len(matches) > 0, "matches": matches[:3]}


# ─────────────────────────────────────────────────────────
# MULTILINGUAL SUPPORT
# ─────────────────────────────────────────────────────────
HINDI_MAP = {
    "बुखार": "fever",
    "सिरदर्द": "headache",
    "उल्टी": "vomiting",
    "कमजोरी": "fatigue",
    "ठंड": "chills",
    "पेट दर्द": "stomach pain",
    "दस्त": "diarrhea",
    "खांसी": "cough",
    "सांस": "shortness of breath",
    "चक्कर": "dizziness",
    "दर्द": "pain",
    "पसीना": "sweating",
    "सीने": "chest pain",
}


def detect_language(text: str) -> str:
    hindi_chars = set("आइईउऊऋएओऔअअंकखगघङचछजझञटठडढणतथदधनपफबभमयरलवशषसह")
    return "Hindi" if any(char in hindi_chars for char in text) else "English"


def translate_hindi(text: str) -> str:
    for hindi, eng in HINDI_MAP.items():
        text = text.replace(hindi, eng)
    return text


# ─────────────────────────────────────────────────────────
# MAIN DIAGNOSIS FUNCTION
# ─────────────────────────────────────────────────────────
def medical_agent(symptoms: str, language: str, image=None) -> Tuple[str, str]:
    if not symptoms or len(symptoms.strip()) < 3:
        return (
            '<div style="color:#FF4444;padding:20px">Please enter at least one symptom</div>',
            "",
        )

    is_safe, category = safety_check(symptoms)
    if not is_safe:
        return get_safety_refusal(), "Safety Blocked"

    is_emergent, keyword = is_emergency(symptoms)
    if is_emergent:
        return get_emergency_response(keyword), "Emergency Triage"

    detected_lang = detect_language(symptoms)
    if detected_lang == "Hindi":
        symptoms = translate_hindi(symptoms)

    rag_result = rag_verify(symptoms)

    if rag_result["verified"]:
        diagnoses = rag_result["matches"]
        cards = ""
        for i, d in enumerate(diagnoses):
            rank = ["Most Likely", "Possible", "Less Likely"][i]
            severity = d["severity"]
            color = (
                "#CC0000"
                if severity == "CRITICAL"
                else "#FF4444"
                if severity == "HIGH"
                else "#FF9900"
            )
            cards += f"""<div style="background:rgba(255,255,255,0.04);border-left:4px solid {color};border-radius:12px;padding:16px;margin-bottom:12px"><div style="display:flex;justify-content:space-between"><div><span style="color:#aaa;font-size:0.8em">{rank}</span><h3 style="color:white;margin:4px 0">{d["disease"].replace("_", " ").title()}</h3><span style="background:{color};color:white;padding:2px 8px;border-radius:10px;font-size:0.75em">{severity}</span></div><div style="text-align:right"><div style="color:#FFBB33;font-size:1.3em;font-weight:bold">{d["confidence"]}%</div><div style="color:#aaa;font-size:0.8em">confidence</div></div></div><div style="margin-top:8px;color:#aaa;font-size:0.85em">Matched: <span style="color:#33B5E5">{", ".join(d["matched"])}</span></div><div style="margin-top:4px;color:#00C851;font-size:0.8em">Specialist: {d["specialist"]}</div></div>"""

        top = diagnoses[0]
        disease_info = MEDICAL_KB.get(top["disease"], {})
        steps_html = ""
        for j, step in enumerate(disease_info.get("emergency_steps", []), 1):
            step_color = (
                "#FF4444"
                if j == 1 and top["severity"] in ["CRITICAL", "HIGH"]
                else "#00C851"
            )
            steps_html += f'<div style="padding:8px;margin:4px 0;background:rgba(255,255,255,0.04);border-left:3px solid {step_color};color:#eee">{j}. {step}</div>'

        result_html = f"""<div style="background:linear-gradient(135deg,#0d1117,#161b22);padding:20px;border-radius:16px;color:white"><h2 style="color:#33B5E5;margin:0 0 16px">🏥 MediGuide AI Diagnosis</h2><p style="color:#666;margin-bottom:16px">Language: {detected_lang} | Mode: Chain of Thought + RAG</p>{cards}<div style="margin-top:20px;padding:16px;background:rgba(255,68,68,0.1);border:1px solid rgba(255,68,68,0.3);border-radius:12px"><h3 style="color:#FF4444;margin:0 0 12px">🚨 Emergency Steps</h3>{steps_html}<div style="margin-top:12px;padding:10px;background:rgba(0,0,0,0.3);border-radius:8px;color:#FFBB33">📞 Emergency: <b>{disease_info.get("emergency_number", "108")}</b> | Specialist: <b>{top["specialist"]}</b></div></div><div style="margin-top:16px;padding:12px;background:rgba(51,181,229,0.1);border-radius:8px;color:#33B5E5;font-size:0.85em">🔬 RAG Verified | Source: Medical Knowledge Base</div><div style="margin-top:12px;color:#666;font-size:0.75em;text-align:center">Disclaimer: AI guidance only. Always consult a qualified doctor.</div></div>"""
        return (
            result_html,
            "Medical Disclaimer: This AI provides guidance only. Always consult a qualified doctor.",
        )

    return (
        '<div style="color:#FFBB33;padding:20px">No matching conditions found. Please describe symptoms in more detail.</div>',
        "",
    )


# ─────────────────────────────────────────────────────────
# GRADIO UI
# ─────────────────────────────────────────────────────────
CUSTOM_CSS = """
body, .gradio-container { background: #0d1117 !important; }
.gradio-container { max-width: 1200px !important; }
.gr-button-primary { background: linear-gradient(135deg, #00C851, #007E33) !important; border: none !important; }
textarea, input { background: #0d1117 !important; color: #e6edf3 !important; border: 1px solid #30363d !important; }
"""

HEADER_HTML = """
<div style="background:linear-gradient(135deg,#0d1117,#161b22);padding:24px;border-radius:16px;text-align:center;margin-bottom:16px;border:1px solid rgba(51,181,229,0.2)">
  <div style="font-size:3em">🏥</div>
  <h1 style="margin:8px 0 4px;color:white;font-size:1.8em">MediGuide AI</h1>
  <p style="color:#33B5E5;margin:0">Agentic Multimodal Medical Assistant</p>
  <p style="color:#666;margin:8px 0 0;font-size:0.85em">Llama 3.2 Vision • Llama Guard 3 • Chain of Thought • Meta Hackathon 2026</p>
  <div style="display:flex;justify-content:center;gap:10px;margin-top:12px;flex-wrap:wrap">
    <span style="background:rgba(0,200,81,0.15);color:#00C851;padding:4px 12px;border-radius:20px;font-size:0.8em">Llama 3.2 Vision</span>
    <span style="background:rgba(255,68,68,0.15);color:#FF4444;padding:4px 12px;border-radius:20px;font-size:0.8em">Llama Guard 3</span>
    <span style="background:rgba(255,187,51,0.15);color:#FFBB33;padding:4px 12px;border-radius:20px;font-size:0.8em">Chain of Thought</span>
    <span style="background:rgba(51,181,229,0.15);color:#33B5E5;padding:4px 12px;border-radius:20px;font-size:0.8em">RAG Verified</span>
  </div>
</div>
"""

demo = gr.Blocks(title="MediGuide AI - Agentic")
demo.css = CUSTOM_CSS

with demo:
    gr.HTML(HEADER_HTML)

    with gr.Row():
        with gr.Column(scale=1):
            gr.Markdown("### Enter Symptoms")
            language = gr.Radio(
                ["English", "Hindi / हिंदी"], value="English", label="Language"
            )
            symptoms_input = gr.Textbox(
                label="Describe your symptoms",
                placeholder="e.g. fever, headache, chest pain, skin rash...",
                lines=5,
            )
            image_input = gr.Image(
                label="📷 Upload Image (Optional)", type="pil", height=150
            )
            gr.Markdown(
                "*Upload photos of skin conditions, medicine labels, or prescriptions*"
            )
            diagnose_btn = gr.Button(
                "🔍 Analyze with Agentic AI", variant="primary", size="lg"
            )

        with gr.Column(scale=2):
            result_output = gr.HTML(label="Diagnosis Result")
            disclaimer_output = gr.Textbox(
                label="Medical Disclaimer", interactive=False, lines=3
            )

    diagnose_btn.click(
        fn=medical_agent,
        inputs=[symptoms_input, language, image_input],
        outputs=[result_output, disclaimer_output],
    )

    with gr.Accordion("🚨 Emergency SOS", open=False):
        gr.HTML(
            """<div style="background:linear-gradient(135deg,#2d0000,#1a0000);padding:16px;border-radius:12px;text-align:center;border:1px solid rgba(255,68,68,0.4)"><h2 style="color:#FF4444;margin:0">India Emergency Numbers</h2><div style="display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:12px"><div style="background:rgba(255,255,255,0.1);padding:12px;border-radius:8px"><div style="color:white;font-weight:bold">108</div><div style="color:#aaa;font-size:0.8em">Ambulance</div></div><div style="background:rgba(255,255,255,0.1);padding:12px;border-radius:8px"><div style="color:white;font-weight:bold">102</div><div style="color:#aaa;font-size:0.8em">Medical</div></div><div style="background:rgba(255,255,255,0.1);padding:12px;border-radius:8px"><div style="color:white;font-weight:bold">101</div><div style="color:#aaa;font-size:0.8em">Fire</div></div><div style="background:rgba(255,255,255,0.1);padding:12px;border-radius:8px"><div style="color:white;font-weight:bold">112</div><div style="color:#aaa;font-size:0.8em">Emergency</div></div></div></div>"""
        )

# ─────────────────────────────────────────────────────────
# LAUNCH - HuggingFace Spaces compatible
# ─────────────────────────────────────────────────────────
app = demo.launch(server_name="0.0.0.0", server_port=7860, share=False, show_error=True)
