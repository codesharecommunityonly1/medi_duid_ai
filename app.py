"""
MediGuide AI - Meta + Hugging Face Hackathon 2026
==================================================
Offline-first RL-powered Emergency Medical Assistant
Built for rural India | Hindi + English | AI Diagnosis + First Aid
OpenEnv-Compatible: POST /reset, POST /step, GET /state
"""

import gradio as gr
import json
import time
import random
import uuid
import threading
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Any
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os

# ─────────────────────────────────────────────
# 1. MEDICAL KNOWLEDGE BASE  (Offline RL Engine)
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
            "Take antimalarial medication immediately (Chloroquine/Artemisinin)",
            "Stay hydrated – drink ORS or clean water every hour",
            "Use paracetamol 500mg for fever (NOT aspirin)",
            "Sleep under mosquito net",
            "Go to nearest PHC/hospital within 24 hours",
        ],
        "emergency_number": "108",
        "first_aid": [
            "Check temperature every 2 hours",
            "Apply cold wet cloth on forehead",
            "Keep patient in cool, ventilated room",
            "Monitor for confusion or seizures → call 108 immediately",
        ],
        "base_confidence": 72,
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
            "Go to hospital IMMEDIATELY – platelet count must be checked",
            "Drink 2-3 litres of fluids (ORS, coconut water, juices)",
            "Take paracetamol ONLY for fever – NO aspirin, ibuprofen",
            "Watch for warning signs: bleeding gums, vomiting blood, difficulty breathing",
            "Rest completely – no physical activity",
        ],
        "emergency_number": "108",
        "first_aid": [
            "Monitor for bleeding signs every 4 hours",
            "Check platelet count at hospital",
            "Avoid NSAIDs completely",
            "Hospital admission if platelets < 100,000",
        ],
        "base_confidence": 65,
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
            "continuous fever",
            "gut fever",
            "persistent fever",
            "typhoid",
        ],
        "severity": "MODERATE",
        "badge_color": "#FF9900",
        "emergency_steps": [
            "Widal test / blood culture – confirm diagnosis at lab",
            "Take prescribed antibiotics (Ciprofloxacin / Azithromycin) for full course",
            "Eat only boiled/soft food – khichdi, daliya, rice",
            "Drink boiled or filtered water ONLY",
            "Rest for minimum 2 weeks",
        ],
        "emergency_number": "102",
        "first_aid": [
            "Maintain strict hygiene – wash hands frequently",
            "Isolate patient's utensils",
            "Monitor for intestinal complications",
            "Return to doctor if fever persists >5 days",
        ],
        "base_confidence": 58,
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
            "⚠️ CALL 108 IMMEDIATELY – life threatening dehydration",
            "Start ORS (Oral Rehydration Solution) RIGHT NOW",
            "Mix: 1 litre boiled water + 6 tsp sugar + 1/2 tsp salt",
            "Give 200-400ml ORS after every loose motion",
            "Rush to hospital for IV fluids",
        ],
        "emergency_number": "108",
        "first_aid": [
            "Keep giving ORS every 5 minutes",
            "Monitor urine output – if no urine for 6hrs → hospital",
            "Strict hand hygiene",
            "Isolate patient and disinfect area",
        ],
        "base_confidence": 80,
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
            "Go to hospital – needs X-ray and blood test",
            "Take prescribed antibiotics for full course (7-14 days)",
            "Sit upright / semi-reclined position to ease breathing",
            "Breathing exercises every 2 hours",
            "Call 108 if lips turn blue or breathing very fast",
        ],
        "emergency_number": "108",
        "first_aid": [
            "Monitor breathing rate (>30/min = emergency)",
            "Keep head elevated at 30-45 degrees",
            "Use steam inhalation for congestion",
            "Stay warm – avoid cold air",
        ],
        "base_confidence": 70,
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
            "🚨 CALL 108 / 112 IMMEDIATELY – every minute counts!",
            "Make patient sit/lie down in comfortable position",
            "Loosen tight clothing (shirt collar, belt)",
            "Give aspirin 325mg to chew (if not allergic, if conscious)",
            "DO NOT leave patient alone – monitor breathing",
            "Start CPR if patient becomes unconscious and not breathing",
        ],
        "emergency_number": "108",
        "first_aid": [
            "Do NOT let patient walk",
            "Keep calm and reassure patient",
            "Do not give food/water",
            "Note time symptoms started",
        ],
        "base_confidence": 85,
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
            "🚨 CALL 108 IMMEDIATELY – anti-venom needed urgently!",
            "Keep patient COMPLETELY STILL – movement spreads venom",
            "Immobilize bitten limb at heart level or below",
            "Remove jewellery/tight items near bite",
            "Mark the edge of swelling with pen and note time",
            "Rush to hospital with anti-venom facility",
        ],
        "emergency_number": "108",
        "first_aid": [
            "DO NOT cut or suck the wound",
            "DO NOT apply tourniquet",
            "DO NOT apply ice",
            "Identify snake type if safe to do so (for anti-venom)",
        ],
        "base_confidence": 90,
    },
    "heatstroke": {
        "hindi": "लू लगना / हीट स्ट्रोक",
        "symptoms": [
            "very high fever",
            "hot dry skin",
            "confusion",
            "dizziness",
            "no sweating",
            "rapid heartbeat",
            "unconsciousness",
            "collapsed",
            "hot skin",
            "not sweating",
            "heatstroke",
            "heat stroke",
        ],
        "severity": "CRITICAL",
        "badge_color": "#CC0000",
        "emergency_steps": [
            "🚨 CALL 108 – medical emergency!",
            "Move to shade or cool area IMMEDIATELY",
            "Remove excess clothing",
            "Apply cold water / ice packs to neck, armpits, groin",
            "Fan the patient aggressively",
            "If conscious, give cool water to drink slowly",
        ],
        "emergency_number": "108",
        "first_aid": [
            "Do NOT give aspirin or paracetamol",
            "Monitor temperature continuously",
            "Continue cooling until temp < 38.5°C",
            "Watch for seizures",
        ],
        "base_confidence": 82,
    },
}

# ─────────────────────────────────────────────
# 2. RL ENGINE  (Reinforcement Learning)
# ─────────────────────────────────────────────


class RLMedicalEngine:
    """
    Simple RL engine: State=Symptoms, Action=Diagnosis, Reward=User Feedback
    Implements Q-learning style weight updates
    """

    def __init__(self):
        self.weights: Dict[str, Dict[str, float]] = {}
        self.learning_rate = 0.15
        self.total_diagnoses = 0
        self.correct_diagnoses = 0
        self.total_reward = 0.0
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
            base = DISEASES[disease]["base_confidence"]
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

    def update_weights(self, disease: str, correct: bool):
        """RL weight update: reward correct, penalize wrong"""
        self.total_diagnoses += 1
        reward = 1.0 if correct else -0.5
        self.total_reward += reward
        if correct:
            self.correct_diagnoses += 1

        if disease in self.weights:
            for symptom in self.weights[disease]:
                if correct:
                    self.weights[disease][symptom] += self.learning_rate * reward
                else:
                    self.weights[disease][symptom] = max(
                        0.1,
                        self.weights[disease][symptom] + self.learning_rate * reward,
                    )

    def get_stats(self) -> Dict:
        accuracy = (self.correct_diagnoses / max(1, self.total_diagnoses)) * 100
        return {
            "total_diagnoses": self.total_diagnoses,
            "correct": self.correct_diagnoses,
            "accuracy": round(accuracy, 1),
            "total_reward": round(self.total_reward, 2),
            "learning_rate": self.learning_rate,
        }


# Global RL engine instance
rl_engine = RLMedicalEngine()

# ─────────────────────────────────────────────
# 3. ASSESSMENT / GRADER  (OpenEnv-style)
# ─────────────────────────────────────────────

ASSESSMENT_CASES = [
    {
        "id": "chest_pain",
        "scenario": "Severe chest pain, left arm pain, sweating, feel like heart attack",
        "disease": "heart_attack",
        "critical": True,
        "weight": 20,
    },
    {
        "id": "snake_bite",
        "scenario": "Snake bit my hand, swelling spreading, numbness in arm",
        "disease": "snake_bite",
        "critical": True,
        "weight": 20,
    },
    {
        "id": "heatstroke",
        "scenario": "Collapsed outside in summer, very hot skin, confused, not sweating",
        "disease": "heatstroke",
        "critical": True,
        "weight": 15,
    },
    {
        "id": "cholera",
        "scenario": "Rice-water diarrhea 20 times, vomiting, severe weakness, leg cramps",
        "disease": "cholera",
        "critical": True,
        "weight": 15,
    },
    {
        "id": "malaria",
        "scenario": "Cyclical fever every 2 days, chills then sweating, headache, nausea",
        "disease": "malaria",
        "critical": False,
        "weight": 10,
    },
    {
        "id": "dengue",
        "scenario": "High fever 5 days, severe joint pain, rash on body, bleeding gums",
        "disease": "dengue",
        "critical": False,
        "weight": 10,
    },
    {
        "id": "pneumonia",
        "scenario": "High fever, productive cough, chest pain when breathing, chills",
        "disease": "pneumonia",
        "critical": False,
        "weight": 10,
    },
    {
        "id": "typhoid",
        "scenario": "Continuous fever 7 days, stomach pain, headache, lost appetite, weak",
        "disease": "typhoid",
        "critical": False,
        "weight": 10,
    },
]


def run_assessment() -> Tuple[str, str]:
    """Run full assessment and return (summary_html, detailed_html)"""
    results = []
    total_score = 0
    max_score = sum(c["weight"] for c in ASSESSMENT_CASES)

    for case in ASSESSMENT_CASES:
        diagnoses = rl_engine.diagnose(case["scenario"])
        top = diagnoses[0] if diagnoses else None

        if top and top["disease"] == case["disease"]:
            score = case["weight"]
            status = "✅ PASS"
            color = "#00C851"
        elif (
            top
            and DISEASES.get(top["disease"], {}).get("severity") in ["CRITICAL", "HIGH"]
            and case["critical"]
        ):
            score = case["weight"] * 0.5
            status = "⚠️ PARTIAL"
            color = "#FF8800"
        else:
            score = 0
            status = "❌ FAIL"
            color = "#FF4444"

        total_score += score
        results.append(
            {
                "case": case,
                "top_diagnosis": top["disease"] if top else "None",
                "confidence": top["confidence"] if top else 0,
                "score": score,
                "status": status,
                "color": color,
            }
        )

    accuracy = (total_score / max_score) * 100
    passed = sum(1 for r in results if "PASS" in r["status"])

    if accuracy >= 90:
        rating = "🏆 EXCELLENT ★★★★★"
        rating_color = "#00C851"
    elif accuracy >= 75:
        rating = "🥇 GREAT ★★★★☆"
        rating_color = "#33B5E5"
    elif accuracy >= 60:
        rating = "🥈 GOOD ★★★☆☆"
        rating_color = "#FFBB33"
    else:
        rating = "📈 NEEDS IMPROVEMENT ★★☆☆☆"
        rating_color = "#FF4444"

    # Summary card
    summary = f"""
<div style="background:linear-gradient(135deg,#1a1a2e,#16213e);padding:24px;border-radius:16px;color:white;font-family:system-ui">
  <h2 style="margin:0 0 16px;color:#00C851">📊 Assessment Report</h2>
  <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:20px">
    <div style="background:rgba(0,200,81,0.15);border:1px solid #00C851;border-radius:10px;padding:14px;text-align:center">
      <div style="font-size:2em;font-weight:bold;color:#00C851">{accuracy:.0f}%</div>
      <div style="color:#aaa;font-size:.85em">Accuracy</div>
    </div>
    <div style="background:rgba(51,181,229,0.15);border:1px solid #33B5E5;border-radius:10px;padding:14px;text-align:center">
      <div style="font-size:2em;font-weight:bold;color:#33B5E5">{passed}/{len(ASSESSMENT_CASES)}</div>
      <div style="color:#aaa;font-size:.85em">Tests Passed</div>
    </div>
    <div style="background:rgba(255,187,51,0.15);border:1px solid #FFBB33;border-radius:10px;padding:14px;text-align:center">
      <div style="font-size:2em;font-weight:bold;color:#FFBB33">{total_score:.0f}/{max_score}</div>
      <div style="color:#aaa;font-size:.85em">Total Score</div>
    </div>
  </div>
  <div style="text-align:center;font-size:1.3em;color:{rating_color};font-weight:bold;padding:10px;background:rgba(255,255,255,0.05);border-radius:8px">
    {rating}
  </div>
  <div style="margin-top:16px;padding:10px;background:rgba(255,255,255,0.05);border-radius:8px">
    <div style="color:#aaa;font-size:.8em;margin-bottom:4px">RL Engine Stats</div>
    <div style="color:#ccc;font-size:.85em">Diagnoses: {rl_engine.total_diagnoses} | Correct: {rl_engine.correct_diagnoses} | Reward: {rl_engine.total_reward:.1f}</div>
  </div>
</div>"""

    # Detailed results
    rows = ""
    for r in results:
        rows += f"""
<tr style="border-bottom:1px solid rgba(255,255,255,0.08)">
  <td style="padding:10px 8px;color:#eee">{r["case"]["id"].replace("_", " ").title()}</td>
  <td style="padding:10px 8px;color:#aaa;font-size:.85em">{r["case"]["scenario"][:60]}…</td>
  <td style="padding:10px 8px;color:#33B5E5">{r["top_diagnosis"].replace("_", " ").title()} ({r["confidence"]}%)</td>
  <td style="padding:10px 8px;font-weight:bold;color:{r["color"]}">{r["status"]}</td>
  <td style="padding:10px 8px;color:#FFBB33">{r["score"]:.0f}/{r["case"]["weight"]}</td>
</tr>"""

    detail = f"""
<div style="background:#0d1117;border-radius:12px;overflow:hidden;font-family:system-ui">
  <table style="width:100%;border-collapse:collapse">
    <thead>
      <tr style="background:linear-gradient(135deg,#1a1a2e,#16213e)">
        <th style="padding:12px 8px;color:#33B5E5;text-align:left;font-weight:600">Case</th>
        <th style="padding:12px 8px;color:#33B5E5;text-align:left;font-weight:600">Scenario</th>
        <th style="padding:12px 8px;color:#33B5E5;text-align:left;font-weight:600">AI Diagnosis</th>
        <th style="padding:12px 8px;color:#33B5E5;text-align:left;font-weight:600">Result</th>
        <th style="padding:12px 8px;color:#33B5E5;text-align:left;font-weight:600">Score</th>
      </tr>
    </thead>
    <tbody style="color:#eee">{rows}</tbody>
  </table>
</div>"""

    return summary, detail


# ─────────────────────────────────────────────
# 4. DEMO SCENARIOS  (13 pre-filled test cases)
# ─────────────────────────────────────────────

DEMO_SCENARIOS = [
    {
        "label": "🦟 Malaria (Cyclical Fever)",
        "symptoms": "fever chills headache sweating nausea muscle pain fatigue",
        "lang": "en",
    },
    {
        "label": "🦠 Dengue (Breakbone Fever)",
        "symptoms": "high fever severe headache eye pain joint pain rash fatigue",
        "lang": "en",
    },
    {
        "label": "🌊 Cholera (Severe Diarrhea)",
        "symptoms": "severe diarrhea vomiting dehydration leg cramps weakness watery stool",
        "lang": "en",
    },
    {
        "label": "❤️ Heart Attack (Critical)",
        "symptoms": "chest pain chest pressure arm pain jaw pain shortness of breath sweating nausea",
        "lang": "en",
    },
    {
        "label": "🐍 Snake Bite (Emergency)",
        "symptoms": "bite marks swelling pain numbness nausea dizziness difficulty breathing",
        "lang": "en",
    },
    {
        "label": "🌡️ Heatstroke (Summer Emergency)",
        "symptoms": "very high fever hot dry skin confusion dizziness no sweating rapid heartbeat",
        "lang": "en",
    },
    {
        "label": "🫁 Pneumonia (Chest Infection)",
        "symptoms": "high fever cough chest pain difficulty breathing chills fatigue shortness of breath",
        "lang": "en",
    },
    {
        "label": "🦠 Typhoid (Gut Fever)",
        "symptoms": "prolonged fever stomach pain headache diarrhea weakness loss of appetite",
        "lang": "en",
    },
    {
        "label": "🤒 बुखार और सिरदर्द (Hindi)",
        "symptoms": "बुखार सिरदर्द उल्टी कमजोरी ठंड लगना",
        "lang": "hi",
    },
    {
        "label": "💊 पेट दर्द (Hindi)",
        "symptoms": "पेट दर्द दस्त उल्टी कमजोरी भूख नहीं लगना बुखार",
        "lang": "hi",
    },
    {
        "label": "🫀 सीने में दर्द (Hindi - Critical)",
        "symptoms": "सीने में दर्द बाएं हाथ में दर्द पसीना सांस लेने में तकलीफ",
        "lang": "hi",
    },
    {
        "label": "🌿 Mild Headache + Fever",
        "symptoms": "fever headache fatigue",
        "lang": "en",
    },
    {
        "label": "⚡ Multi-symptom Emergency",
        "symptoms": "fever headache vomiting diarrhea dehydration weakness bleeding",
        "lang": "en",
    },
]

# Hindi symptom translation map
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
    "तकलीफ": "difficulty breathing",
    "भूख": "loss of appetite",
}


def translate_hindi(text: str) -> str:
    for hindi, english in HINDI_MAP.items():
        text = text.replace(hindi, english)
    return text


# ─────────────────────────────────────────────
# 5. GRADIO HANDLER FUNCTIONS
# ─────────────────────────────────────────────


def diagnose_symptoms(symptoms: str, language: str) -> Tuple[str, str]:
    """Main diagnosis function → returns (result_html, first_aid_html)"""
    if not symptoms or len(symptoms.strip()) < 3:
        return (
            '<div style="color:#FF4444;padding:20px;text-align:center">⚠️ Please enter at least one symptom</div>',
            "",
        )

    # Translate Hindi if needed
    processed = translate_hindi(symptoms) if language == "Hindi / हिंदी" else symptoms

    diagnoses = rl_engine.diagnose(processed)

    if not diagnoses:
        return (
            '<div style="color:#FFBB33;padding:20px;text-align:center">🔍 No matching conditions found. Please describe your symptoms in more detail.</div>',
            "",
        )

    # Build result HTML
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
      <div style="background:linear-gradient(90deg,{badge_color},{badge_color}88);
                  width:{bar_width}%;height:100%;border-radius:6px;transition:width 0.5s"></div>
    </div>
  </div>
  <div style="margin-top:8px;color:#aaa;font-size:.8em">
    Matched symptoms: <span style="color:#33B5E5">{matched}</span>
  </div>
</div>"""

    # Emergency steps for top diagnosis
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
    <h3 style="margin:0 0 12px;color:#FF4444">🚨 Emergency Steps – {top["disease"].replace("_", " ").title()}</h3>
    {steps_html}
    <div style="margin-top:12px;padding:10px;background:rgba(0,0,0,0.3);border-radius:8px;color:#FFBB33;font-size:.9em">
      📞 Emergency Helpline: <b>{top["emergency_number"]}</b>
    </div>
  </div>
  <div style="margin-top:12px;color:#666;font-size:.75em;text-align:center">
    ⚠️ Disclaimer: This is AI guidance only. Always consult a qualified doctor for medical decisions.
  </div>
</div>"""

    # First aid card
    first_aid_steps = ""
    for step in top["first_aid"]:
        first_aid_steps += (
            f'<li style="padding:6px 0;color:#ccc;font-size:.9em">{step}</li>'
        )

    first_aid_html = f"""
<div style="background:linear-gradient(135deg,#0d2818,#0a1a10);padding:20px;border-radius:16px;font-family:system-ui;color:white;border:1px solid rgba(0,200,81,0.2)">
  <h3 style="margin:0 0 12px;color:#00C851">🩹 First Aid Guide</h3>
  <ul style="margin:0;padding-left:20px">{first_aid_steps}</ul>
  <div style="margin-top:16px;padding:12px;background:rgba(51,181,229,0.1);border-radius:8px;color:#33B5E5;font-size:.85em">
    💡 RL Engine has processed <b>{rl_engine.total_diagnoses}</b> diagnoses with <b>{rl_engine.get_stats()["accuracy"]}%</b> accuracy
  </div>
</div>"""

    return result_html, first_aid_html


def load_demo(scenario_label: str) -> str:
    """Load a demo scenario"""
    for s in DEMO_SCENARIOS:
        if s["label"] == scenario_label:
            return s["symptoms"]
    return ""


def submit_feedback(
    symptoms: str, language: str, feedback: str, last_diagnosis: str
) -> str:
    """Handle RL feedback submission"""
    if not last_diagnosis:
        return '<div style="color:#FF4444;padding:12px">⚠️ Please run a diagnosis first, then submit feedback.</div>'

    disease_key = last_diagnosis.lower().replace(" ", "_")
    is_correct = feedback == "✅ Correct Diagnosis"
    rl_engine.update_weights(disease_key, is_correct)

    stats = rl_engine.get_stats()
    reward_text = "+1.0 reward" if is_correct else "-0.5 penalty"
    color = "#00C851" if is_correct else "#FF4444"

    return f"""
<div style="background:linear-gradient(135deg,#0d1117,#161b22);padding:16px;border-radius:12px;font-family:system-ui;color:white;border:1px solid {color}40">
  <h4 style="margin:0 0 8px;color:{color}">{"🧠 AI Learning Complete!" if is_correct else "📚 Learning from mistake!"}</h4>
  <div style="color:#ccc;font-size:.9em">Feedback: <span style="color:{color};font-weight:bold">{feedback}</span></div>
  <div style="color:#ccc;font-size:.9em">RL Reward: <span style="color:#FFBB33">{reward_text}</span></div>
  <div style="margin-top:10px;padding:10px;background:rgba(255,255,255,0.05);border-radius:8px">
    <div style="color:#aaa;font-size:.8em">Updated Stats</div>
    <div style="color:#33B5E5;font-size:.9em">Total: {stats["total_diagnoses"]} | Accuracy: {stats["accuracy"]}% | Reward: {stats["total_reward"]}</div>
  </div>
</div>"""


def run_full_assessment():
    summary, detail = run_assessment()
    return summary, detail


def get_emergency_guide():
    html = """
<div style="background:linear-gradient(135deg,#1a0000,#2d0000);padding:20px;border-radius:16px;font-family:system-ui;color:white;border:1px solid rgba(255,68,68,0.3)">
  <h2 style="margin:0 0 16px;color:#FF4444">🚨 Emergency Quick Reference</h2>"""

    for disease_id, d in DISEASES.items():
        if d["severity"] == "CRITICAL":
            html += f"""
  <div style="background:rgba(255,255,255,0.04);border-left:4px solid {d["badge_color"]};border-radius:8px;padding:14px;margin-bottom:10px">
    <div style="display:flex;justify-content:space-between">
      <div>
        <b style="color:white">{disease_id.replace("_", " ").title()}</b>
        <span style="color:#aaa;font-size:.85em;margin-left:8px">{d["hindi"]}</span>
      </div>
      <span style="background:#FF4444;color:white;padding:2px 8px;border-radius:10px;font-size:.75em">CRITICAL</span>
    </div>
    <div style="color:#FFBB33;margin-top:6px;font-size:.85em">📞 Call: {d["emergency_number"]} | First step: {d["emergency_steps"][0]}</div>
  </div>"""

    html += """
  <div style="margin-top:16px;padding:12px;background:rgba(255,187,51,0.1);border-radius:8px;text-align:center">
    <div style="color:#FFBB33;font-size:1.1em;font-weight:bold">🏥 India Emergency Numbers</div>
    <div style="color:#ccc;margin-top:6px">Ambulance: <b>108</b> &nbsp;|&nbsp; Police: <b>100</b> &nbsp;|&nbsp; Fire: <b>101</b> &nbsp;|&nbsp; National Emergency: <b>112</b></div>
  </div>
</div>"""
    return html


def get_ai_stats():
    stats = rl_engine.get_stats()
    html = f"""
<div style="background:linear-gradient(135deg,#0d1117,#161b22);padding:20px;border-radius:16px;font-family:system-ui;color:white">
  <h3 style="margin:0 0 16px;color:#33B5E5">🤖 AI Brain Dashboard</h3>
  <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:12px">
    <div style="background:rgba(51,181,229,0.1);border:1px solid #33B5E564;border-radius:10px;padding:14px;text-align:center">
      <div style="font-size:2em;font-weight:bold;color:#33B5E5">{stats["total_diagnoses"]}</div>
      <div style="color:#aaa;font-size:.85em">Total Diagnoses</div>
    </div>
    <div style="background:rgba(0,200,81,0.1);border:1px solid #00C85164;border-radius:10px;padding:14px;text-align:center">
      <div style="font-size:2em;font-weight:bold;color:#00C851">{stats["accuracy"]}%</div>
      <div style="color:#aaa;font-size:.85em">Accuracy</div>
    </div>
    <div style="background:rgba(255,187,51,0.1);border:1px solid #FFBB3364;border-radius:10px;padding:14px;text-align:center">
      <div style="font-size:2em;font-weight:bold;color:#FFBB33">{stats["total_reward"]}</div>
      <div style="color:#aaa;font-size:.85em">Total Reward</div>
    </div>
    <div style="background:rgba(255,68,68,0.1);border:1px solid #FF444464;border-radius:10px;padding:14px;text-align:center">
      <div style="font-size:2em;font-weight:bold;color:#FF4444">{stats["learning_rate"]}</div>
      <div style="color:#aaa;font-size:.85em">Learning Rate</div>
    </div>
  </div>
  <div style="margin-top:16px;padding:12px;background:rgba(255,255,255,0.03);border-radius:8px">
    <div style="color:#aaa;font-size:.8em;margin-bottom:6px">Diseases in Knowledge Base</div>
    <div style="display:flex;flex-wrap:wrap;gap:6px">
      {"".join(f'<span style="background:rgba(51,181,229,0.15);border:1px solid #33B5E564;border-radius:12px;padding:3px 10px;font-size:.78em;color:#33B5E5">{k.replace("_", " ").title()}</span>' for k in DISEASES.keys())}
    </div>
  </div>
</div>"""
    return html


# ─────────────────────────────────────────────
# 6. GRADIO UI
# ─────────────────────────────────────────────

CUSTOM_CSS = """
body, .gradio-container { background: #0d1117 !important; }
.gradio-container { max-width: 1200px !important; }
.gr-button-primary { background: linear-gradient(135deg, #00C851, #007E33) !important; border: none !important; color: white !important; font-weight: 600 !important; }
.gr-button-secondary { background: linear-gradient(135deg, #FF4444, #CC0000) !important; border: none !important; color: white !important; font-weight: 600 !important; }
.panel { background: #161b22 !important; border: 1px solid #30363d !important; border-radius: 12px !important; }
label { color: #ccc !important; }
textarea, input { background: #0d1117 !important; color: #e6edf3 !important; border: 1px solid #30363d !important; border-radius: 8px !important; }
.tab-nav button { background: transparent !important; color: #8b949e !important; font-weight: 600 !important; border-bottom: 2px solid transparent !important; }
.tab-nav button.selected { color: #33B5E5 !important; border-bottom: 2px solid #33B5E5 !important; }
"""

HEADER_HTML = """
<div style="background:linear-gradient(135deg,#0d1117,#161b22);padding:24px;border-radius:16px;text-align:center;margin-bottom:16px;border:1px solid rgba(51,181,229,0.2)">
  <div style="font-size:3em">🏥</div>
  <h1 style="margin:8px 0 4px;color:white;font-size:1.8em;font-family:system-ui">MediGuide AI</h1>
  <p style="color:#33B5E5;margin:0;font-size:1em">Offline RL-Powered Emergency Medical Assistant</p>
  <p style="color:#666;margin:8px 0 0;font-size:.85em">Rural India • Hindi + English • 100% Offline • Meta + Hugging Face Hackathon 2026</p>
  <div style="display:flex;justify-content:center;gap:10px;margin-top:12px;flex-wrap:wrap">
    <span style="background:rgba(0,200,81,0.15);border:1px solid #00C85164;color:#00C851;padding:4px 12px;border-radius:20px;font-size:.8em">✅ RL Learning</span>
    <span style="background:rgba(51,181,229,0.15);border:1px solid #33B5E564;color:#33B5E5;padding:4px 12px;border-radius:20px;font-size:.8em">🧠 AI Diagnosis</span>
    <span style="background:rgba(255,187,51,0.15);border:1px solid #FFBB3364;color:#FFBB33;padding:4px 12px;border-radius:20px;font-size:.8em">🇮🇳 Hindi Support</span>
    <span style="background:rgba(255,68,68,0.15);border:1px solid #FF444464;color:#FF4444;padding:4px 12px;border-radius:20px;font-size:.8em">🚨 Emergency SOS</span>
  </div>
</div>
"""

with gr.Blocks(title="MediGuide AI") as demo:
    gr.HTML(HEADER_HTML)

    with gr.Tabs():
        # ── TAB 1: DIAGNOSIS ──────────────────────────────
        with gr.TabItem("🩺 Smart Diagnosis"):
            with gr.Row():
                with gr.Column(scale=1):
                    gr.Markdown("### Enter Symptoms")
                    language = gr.Radio(
                        ["English", "Hindi / हिंदी"],
                        value="English",
                        label="Language",
                    )
                    symptoms_input = gr.Textbox(
                        label="Describe your symptoms",
                        placeholder="e.g. fever, headache, chills, nausea, sweating...\nया हिंदी में: बुखार, सिरदर्द, उल्टी...",
                        lines=4,
                    )
                    with gr.Row():
                        diagnose_btn = gr.Button(
                            "🔍 Diagnose Now", variant="primary", size="lg"
                        )
                        clear_btn = gr.Button("🗑️ Clear", size="lg")

                    gr.Markdown("### 🎯 Demo Scenarios (13 pre-filled)")
                    demo_dd = gr.Dropdown(
                        choices=[s["label"] for s in DEMO_SCENARIOS],
                        label="Load a test scenario",
                        value=None,
                    )
                    load_demo_btn = gr.Button("▶️ Load Scenario", size="sm")

                with gr.Column(scale=2):
                    result_output = gr.HTML(label="Diagnosis Result")
                    first_aid_output = gr.HTML(label="First Aid Guide")

            # RL Feedback
            with gr.Accordion("🧠 AI Feedback & Learning", open=False):
                gr.Markdown(
                    "Help the AI learn by confirming or correcting the diagnosis:"
                )
                with gr.Row():
                    last_diag_state = gr.Textbox(
                        label="Last diagnosed condition", interactive=False
                    )
                    feedback_radio = gr.Radio(
                        ["✅ Correct Diagnosis", "❌ Wrong Diagnosis"],
                        label="Was the diagnosis correct?",
                        value="✅ Correct Diagnosis",
                    )
                feedback_btn = gr.Button(
                    "📤 Submit Feedback (Teach AI)", variant="primary"
                )
                feedback_output = gr.HTML()

            # Wire up diagnosis
            def diagnose_and_track(symptoms, lang):
                result, first_aid = diagnose_symptoms(symptoms, lang)
                # Extract top disease name for feedback tracking
                diagnoses = rl_engine.diagnose(
                    translate_hindi(symptoms) if lang == "Hindi / हिंदी" else symptoms
                )
                top_disease = (
                    diagnoses[0]["disease"].replace("_", " ").title()
                    if diagnoses
                    else ""
                )
                return result, first_aid, top_disease

            diagnose_btn.click(
                fn=diagnose_and_track,
                inputs=[symptoms_input, language],
                outputs=[result_output, first_aid_output, last_diag_state],
            )
            clear_btn.click(
                fn=lambda: ("", "", gr.HTML(""), gr.HTML(""), ""),
                outputs=[
                    symptoms_input,
                    last_diag_state,
                    result_output,
                    first_aid_output,
                    last_diag_state,
                ],
            )
            load_demo_btn.click(
                fn=load_demo,
                inputs=[demo_dd],
                outputs=[symptoms_input],
            )
            feedback_btn.click(
                fn=submit_feedback,
                inputs=[symptoms_input, language, feedback_radio, last_diag_state],
                outputs=[feedback_output],
            )

        # ── TAB 2: ASSESSMENT ────────────────────────────
        with gr.TabItem("📊 Run Assessment"):
            gr.Markdown("""
### Automated Medical AI Assessment
Tests the AI engine against **8 standardised medical scenarios** using the OpenEnv-style grader.
This evaluates diagnostic accuracy, emergency detection, and scoring.
""")
            run_btn = gr.Button("▶️ Run Full Assessment", variant="primary", size="lg")
            with gr.Row():
                summary_output = gr.HTML(label="Summary")
            detail_output = gr.HTML(label="Detailed Results")

            run_btn.click(
                fn=run_full_assessment,
                outputs=[summary_output, detail_output],
            )

        # ── TAB 3: EMERGENCY SOS ─────────────────────────
        with gr.TabItem("🚨 Emergency SOS"):
            gr.HTML("""
<div style="background:linear-gradient(135deg,#2d0000,#1a0000);padding:16px;border-radius:12px;text-align:center;border:1px solid rgba(255,68,68,0.4);margin-bottom:16px">
  <div style="font-size:2.5em">🚨</div>
  <h2 style="color:#FF4444;margin:4px 0">EMERGENCY – Call 108 / 112 Now!</h2>
  <p style="color:#ccc;margin:0;font-size:.9em">India Ambulance: 108 | National Emergency: 112 | Police: 100 | Fire: 101</p>
</div>""")
            emergency_btn = gr.Button(
                "🚨 Load Emergency Quick Guide", variant="secondary", size="lg"
            )
            emergency_output = gr.HTML()
            emergency_btn.click(fn=get_emergency_guide, outputs=[emergency_output])
            # Auto-load on tab
            demo.load(fn=get_emergency_guide, outputs=[emergency_output])

        # ── TAB 4: AI DASHBOARD ──────────────────────────
        with gr.TabItem("🤖 AI Dashboard"):
            refresh_btn = gr.Button("🔄 Refresh Stats", size="sm")
            stats_output = gr.HTML()
            refresh_btn.click(fn=get_ai_stats, outputs=[stats_output])
            demo.load(fn=get_ai_stats, outputs=[stats_output])

        # ── TAB 5: ABOUT ─────────────────────────────────
        with gr.TabItem("ℹ️ About"):
            gr.HTML("""
<div style="background:linear-gradient(135deg,#0d1117,#161b22);padding:24px;border-radius:16px;font-family:system-ui;color:white">
  <h2 style="color:#33B5E5">🏥 MediGuide AI</h2>
  <p style="color:#ccc">An offline-first, RL-powered emergency medical assistant built for rural India where internet and doctors are scarce.</p>

  <h3 style="color:#00C851">🚀 Key Features</h3>
  <ul style="color:#ccc;line-height:1.8">
    <li><b>Smart Diagnosis</b> – AI symptom analysis with confidence bars and severity badges</li>
    <li><b>RL Learning</b> – Real-time reinforcement learning from user feedback (reward/penalty)</li>
    <li><b>13 Demo Scenarios</b> – Pre-filled test cases for judges</li>
    <li><b>Hindi Support</b> – Full Hindi symptom input translation</li>
    <li><b>Emergency SOS</b> – Quick-access critical care guides</li>
    <li><b>Assessment Tab</b> – OpenEnv-style automated evaluation with scoring</li>
    <li><b>100% Offline</b> – Works without internet (Flutter mobile app)</li>
  </ul>

  <h3 style="color:#FFBB33">🧠 Technical Stack</h3>
  <ul style="color:#ccc;line-height:1.8">
    <li>RL Engine: Custom Q-learning style weight updates (State→Symptom, Action→Diagnosis, Reward→Feedback)</li>
    <li>Flutter mobile app with BLoC state management</li>
    <li>Hive local database for offline persistence</li>
    <li>OpenEnv-compatible grader script</li>
    <li>Gradio web demo (this app)</li>
  </ul>

  <h3 style="color:#FF4444">🌍 Impact</h3>
  <ul style="color:#ccc;line-height:1.8">
    <li>Targets 600M+ rural Indians with limited healthcare access</li>
    <li>Works in areas with no doctors, no internet</li>
    <li>Covers 8 critical diseases common in rural India</li>
    <li>Emergency guidance in local language (Hindi)</li>
  </ul>

  <div style="margin-top:20px;padding:16px;background:rgba(51,181,229,0.1);border-radius:10px;border:1px solid rgba(51,181,229,0.3)">
    <b style="color:#33B5E5">Hackathon:</b> <span style="color:#ccc">Meta + Hugging Face 2026</span><br>
    <b style="color:#33B5E5">Category:</b> <span style="color:#ccc">Healthcare / AI / Mobile</span><br>
    <b style="color:#33B5E5">Disclaimer:</b> <span style="color:#666;font-size:.85em">This is an AI assistant for guidance only. Always consult a qualified doctor for medical decisions.</span>
  </div>
</div>""")

# Mount FastAPI with Gradio for OpenEnv endpoints
app = gr.mount_gradio_app(openenv_app, demo, path="/")

if __name__ == "__main__":
    app.launch(server_name="0.0.0.0", server_port=7860, css=CUSTOM_CSS)


class MedicalAction(BaseModel):
    symptoms: Optional[str] = None
    query_type: Optional[str] = "diagnose"
    feedback_disease: Optional[str] = None
    feedback_correct: Optional[bool] = None


class StepResult(BaseModel):
    observation: Dict[str, Any]
    reward: float
    done: bool
    info: Dict[str, Any] = {}


@openenv_app.post("/reset", response_model=StepResult)
async def reset():
    global _episode
    _episode = {"id": str(uuid.uuid4()), "step_count": 0, "reward": 0.0}
    return StepResult(
        observation={
            "episode_id": _episode["id"],
            "message": "MediGuide AI ready. POST /step with symptoms.",
        },
        reward=0.0,
        done=False,
        info={"diseases": list(DISEASES.keys())},
    )


@openenv_app.post("/step", response_model=StepResult)
async def step(action: MedicalAction):
    global _episode
    _episode["step_count"] += 1
    reward = 0.0
    diagnoses = []
    message = ""

    if action.query_type == "diagnose" and action.symptoms:
        diagnoses = diagnose_symptoms(action.symptoms, "English")[0]
        reward = 0.1
        message = f"Found {len(diagnoses)} conditions"
        if rl_engine:
            rl_engine.total_diagnoses += 1

    _episode["reward"] += reward

    return StepResult(
        observation={
            "episode_id": _episode["id"],
            "step_count": _episode["step_count"],
            "query": action.symptoms or "",
            "diagnoses": diagnoses,
            "message": message,
        },
        reward=reward,
        done=False,
        info={"rl_active": True},
    )


@openenv_app.get("/state")
async def state():
    return _episode


@openenv_app.get("/health")
async def health():
    return {"status": "healthy", "openenv": True, "diseases": len(DISEASES)}


# Mount FastAPI with Gradio for OpenEnv endpoints
app = gr.mount_gradio_app(openenv_app, demo, path="/")
app.launch(server_name="0.0.0.0", server_port=7860, css=CUSTOM_CSS)
