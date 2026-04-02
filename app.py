"""
MediGuide AI - Meta + Hugging Face Hackathon 2026
Minimal working Gradio app for HF Spaces
"""

import gradio as gr
import os
from typing import Tuple, List, Dict, Any

# ─────────────────────────────────────────────
# SECURE TOKEN HANDLING
# ─────────────────────────────────────────────
HF_TOKEN = os.getenv("HF_TOKEN", "")
MODEL_NAME = os.getenv("MODEL_NAME", "google/gemma-2b-it")

# Model configuration (for future LLM integration)
# Currently using rule-based diagnosis engine - no model needed
MODEL_NAME = os.getenv("MODEL_NAME", "google/gemma-2b-it")

# Note: InferenceClient is available if HF_TOKEN is set
# but not needed - we use rule-based diagnosis for reliability

# ─────────────────────────────────────────────
# MEDICAL KNOWLEDGE BASE (Offline RL Engine)
# ─────────────────────────────────────────────

DISEASES = {
    "malaria": {
        "hindi": "मलेरिया",
        "symptoms": [
            "fever",
            "chills",
            "headache",
            "sweating",
            "nausea",
            "vomiting",
            "muscle pain",
            "fatigue",
        ],
        "severity": "HIGH",
        "badge_color": "#FF4444",
        "emergency_steps": [
            "Take antimalarial medication (Chloroquine/Artemisinin)",
            "Stay hydrated - drink ORS or clean water every hour",
            "Use paracetamol 500mg for fever (NOT aspirin)",
            "Go to nearest PHC/hospital within 24 hours",
        ],
        "emergency_number": "108",
    },
    "dengue": {
        "hindi": "डेंगू",
        "symptoms": [
            "high fever",
            "severe headache",
            "eye pain",
            "joint pain",
            "rash",
            "bleeding",
            "fatigue",
            "nausea",
        ],
        "severity": "HIGH",
        "badge_color": "#FF6600",
        "emergency_steps": [
            "Go to hospital IMMEDIATELY - platelet count must be checked",
            "Drink 2-3 litres of fluids (ORS, coconut water, juices)",
            "Take paracetamol ONLY for fever - NO aspirin, ibuprofen",
            "Rest completely - no physical activity",
        ],
        "emergency_number": "108",
    },
    "typhoid": {
        "hindi": "टाइफाइड",
        "symptoms": [
            "prolonged fever",
            "stomach pain",
            "headache",
            "diarrhea",
            "constipation",
            "weakness",
            "loss of appetite",
        ],
        "severity": "MODERATE",
        "badge_color": "#FF9900",
        "emergency_steps": [
            "Widal test / blood culture - confirm diagnosis at lab",
            "Take prescribed antibiotics (Ciprofloxacin/Azithromycin) for full course",
            "Eat only boiled/soft food - khichdi, daliya, rice",
            "Rest for minimum 2 weeks",
        ],
        "emergency_number": "102",
    },
    "cholera": {
        "hindi": "हैजा",
        "symptoms": [
            "severe diarrhea",
            "vomiting",
            "dehydration",
            "leg cramps",
            "weakness",
            "watery stool",
        ],
        "severity": "CRITICAL",
        "badge_color": "#CC0000",
        "emergency_steps": [
            "⚠ CALL 108 IMMEDIATELY - life threatening dehydration",
            "Start ORS (Oral Rehydration Solution) RIGHT NOW",
            "Mix: 1 litre boiled water + 6 tsp sugar + 1/2 tsp salt",
            "Rush to hospital for IV fluids",
        ],
        "emergency_number": "108",
    },
    "pneumonia": {
        "hindi": "निमोनिया",
        "symptoms": [
            "high fever",
            "cough",
            "chest pain",
            "difficulty breathing",
            "chills",
            "fatigue",
            "shortness of breath",
        ],
        "severity": "HIGH",
        "badge_color": "#FF4444",
        "emergency_steps": [
            "Go to hospital - needs X-ray and blood test",
            "Take prescribed antibiotics for full course (7-14 days)",
            "Sit upright to ease breathing",
            "Call 108 if lips turn blue or breathing very fast",
        ],
        "emergency_number": "108",
    },
    "heart_attack": {
        "hindi": "दिल का दौरा",
        "symptoms": [
            "chest pain",
            "chest pressure",
            "arm pain",
            "jaw pain",
            "shortness of breath",
            "sweating",
            "nausea",
            "dizziness",
        ],
        "severity": "CRITICAL",
        "badge_color": "#CC0000",
        "emergency_steps": [
            "🚨 CALL 108 / 112 IMMEDIATELY - every minute counts!",
            "Make patient sit/lie down in comfortable position",
            "Loosen tight clothing (shirt collar, belt)",
            "Give aspirin 325mg to chew (if not allergic, if conscious)",
            "Start CPR if patient becomes unconscious",
        ],
        "emergency_number": "108",
    },
    "snake_bite": {
        "hindi": "सांप का काटना",
        "symptoms": [
            "bite marks",
            "swelling",
            "pain",
            "numbness",
            "nausea",
            "dizziness",
            "difficulty breathing",
            "bleeding",
        ],
        "severity": "CRITICAL",
        "badge_color": "#CC0000",
        "emergency_steps": [
            "🚨 CALL 108 IMMEDIATELY - anti-venom needed urgently!",
            "Keep patient COMPLETELY STILL - movement spreads venom",
            "Immobilize bitten limb at heart level or below",
            "Remove jewellery/tight items near bite",
        ],
        "emergency_number": "108",
    },
    "heatstroke": {
        "hindi": "लू लगना",
        "symptoms": [
            "very high fever",
            "hot dry skin",
            "confusion",
            "dizziness",
            "no sweating",
            "rapid heartbeat",
            "unconsciousness",
        ],
        "severity": "CRITICAL",
        "badge_color": "#CC0000",
        "emergency_steps": [
            "🚨 CALL 108 - medical emergency!",
            "Move to shade or cool area IMMEDIATELY",
            "Remove excess clothing",
            "Apply cold water / ice packs to neck, armpits, groin",
            "If conscious, give cool water to drink slowly",
        ],
        "emergency_number": "108",
    },
}

# Hindi symptom translation
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
    "हाथ में दर्द": "arm pain",
}


def translate_hindi(text: str) -> str:
    for hindi, english in HINDI_MAP.items():
        text = text.replace(hindi, english)
    return text


# ─────────────────────────────────────────────
# RULE-BASED DIAGNOSIS ENGINE
# ─────────────────────────────────────────────


class MedicalEngine:
    def __init__(self):
        self.weights = {}
        self.learning_rate = 0.15
        self.total_diagnoses = 0
        self.correct_diagnoses = 0
        self._init_weights()

    def _init_weights(self):
        for disease, data in DISEASES.items():
            self.weights[disease] = {}
            for symptom in data["symptoms"]:
                self.weights[disease][symptom] = 1.0

    def _tokenize(self, text: str) -> List[str]:
        text = text.lower()
        tokens = []
        for disease, data in DISEASES.items():
            for symptom in data["symptoms"]:
                if symptom in text:
                    tokens.append(symptom)
        return list(set(tokens))

    def diagnose(self, symptoms_text: str) -> List[Dict]:
        tokens = self._tokenize(symptoms_text)
        if not tokens:
            return []

        scores = {}
        for disease, symptom_weights in self.weights.items():
            score = 0
            matched = []
            for token in tokens:
                if token in symptom_weights:
                    score += symptom_weights[token]
                    matched.append(token)
            if score > 0:
                scores[disease] = {"score": score, "matched": matched}

        if not scores:
            return []

        total = sum(v["score"] for v in scores.values())
        results = []
        for disease, data in sorted(scores.items(), key=lambda x: -x[1]["score"])[:3]:
            base = (
                DISEASES[disease]["base_confidence"]
                if "base_confidence" in DISEASES[disease]
                else 70
            )
            confidence = min(95, int((data["score"] / total) * 100 * 1.5 + base * 0.3))
            results.append(
                {
                    "disease": disease,
                    "confidence": confidence,
                    "matched_symptoms": data["matched"],
                    **DISEASES[disease],
                }
            )
        return results


# Global engine
medical_engine = MedicalEngine()

# ─────────────────────────────────────────────
# GRADIO UI
# ─────────────────────────────────────────────

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
  <p style="color:#33B5E5;margin:0">Offline RL-Powered Emergency Medical Assistant</p>
  <p style="color:#666;margin:8px 0 0;font-size:.85em">Rural India • Hindi + English • Meta + Hugging Face Hackathon 2026</p>
</div>
"""


def diagnose_symptoms(symptoms: str, language: str) -> Tuple[str, str]:
    """Main diagnosis function"""
    if not symptoms or len(symptoms.strip()) < 3:
        return (
            '<div style="color:#FF4444;padding:20px;text-align:center">⚠️ Please enter at least one symptom</div>',
            "",
        )

    processed = translate_hindi(symptoms) if language == "Hindi / हिंदी" else symptoms
    diagnoses = medical_engine.diagnose(processed)

    if not diagnoses:
        return (
            '<div style="color:#FFBB33;padding:20px;text-align:center">🔍 No matching conditions found. Please describe your symptoms in more detail.</div>',
            "",
        )

    cards = ""
    for i, d in enumerate(diagnoses):
        severity = d["severity"]
        badge_color = d["badge_color"]
        bar_width = d["confidence"]
        hindi_name = d.get("hindi", "")
        matched = (
            ", ".join(d["matched_symptoms"])
            if d["matched_symptoms"]
            else "General match"
        )
        rank_label = ["🥇 Most Likely", "🥈 Possible", "🥉 Less Likely"][i]

        cards += f"""
<div style="background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.1);
            border-left:4px solid {badge_color};border-radius:12px;padding:16px;margin-bottom:12px">
  <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:8px">
    <div>
      <span style="color:#aaa;font-size:.8em">{rank_label}</span>
      <h3 style="margin:4px 0;color:white;font-size:1.2em">{d["disease"].replace("_", " ").title()}</h3>
      <div style="color:#aaa;font-size:.85em">{hindi_name}</div>
    </div>
    <div style="text-align:right">
      <span style="background:{badge_color};color:white;padding:3px 10px;border-radius:20px;font-size:.75em;font-weight:bold">
        ⚠️ {severity}
      </span>
      <div style="color:#FFBB33;font-size:1.3em;font-weight:bold;margin-top:4px">{d["confidence"]}%</div>
    </div>
  </div>
  <div style="margin-top:10px">
    <div style="background:rgba(255,255,255,0.1);border-radius:6px;height:8px;overflow:hidden">
      <div style="background:linear-gradient(90deg,{badge_color},{badge_color}88);width:{bar_width}%;height:100%;border-radius:6px"></div>
    </div>
  </div>
  <div style="margin-top:8px;color:#aaa;font-size:.8em">Matched: <span style="color:#33B5E5">{matched}</span></div>
</div>"""

    top = diagnoses[0]
    steps_html = ""
    for j, step in enumerate(top["emergency_steps"], 1):
        color = "#FF4444" if j == 1 and top["severity"] == "CRITICAL" else "#00C851"
        steps_html += f'<div style="padding:8px 12px;margin:4px 0;background:rgba(255,255,255,0.04);border-radius:8px;border-left:3px solid {color};color:#eee;font-size:.9em"><b>{j}.</b> {step}</div>'

    result_html = f"""
<div style="background:linear-gradient(135deg,#0d1117,#161b22);padding:20px;border-radius:16px;font-family:system-ui;color:white">
  <h2 style="margin:0 0 16px;color:#33B5E5">🧠 AI Diagnosis Report</h2>
  {cards}
  <div style="margin-top:20px;padding:16px;background:rgba(255,68,68,0.1);border:1px solid rgba(255,68,68,0.3);border-radius:12px">
    <h3 style="margin:0 0 12px;color:#FF4444">🚨 Emergency Steps</h3>
    {steps_html}
    <div style="margin-top:12px;padding:10px;background:rgba(0,0,0,0.3);border-radius:8px;color:#FFBB33;font-size:.9em">
      📞 Emergency Helpline: <b>{top["emergency_number"]}</b>
    </div>
  </div>
  <div style="margin-top:12px;color:#666;font-size:.75em;text-align:center">
    ⚠️ Disclaimer: This is AI guidance only. Always consult a qualified doctor.
  </div>
</div>"""

    return result_html, ""


# Build Gradio app
with gr.Blocks(title="MediGuide AI", css=CUSTOM_CSS) as demo:
    gr.HTML(HEADER_HTML)

    with gr.Row():
        with gr.Column(scale=1):
            gr.Markdown("### Enter Symptoms")
            language = gr.Radio(
                ["English", "Hindi / हिंदी"], value="English", label="Language"
            )
            symptoms_input = gr.Textbox(
                label="Describe your symptoms",
                placeholder="e.g. fever, headache, chills, nausea...",
                lines=4,
            )
            diagnose_btn = gr.Button("🔍 Diagnose Now", variant="primary", size="lg")

        with gr.Column(scale=2):
            result_output = gr.HTML(label="Diagnosis Result")

    diagnose_btn.click(
        fn=diagnose_symptoms,
        inputs=[symptoms_input, language],
        outputs=[result_output],
    )

# ─────────────────────────────────────────────
# LAUNCH
# ─────────────────────────────────────────────
demo.launch(server_name="0.0.0.0", server_port=7860)
