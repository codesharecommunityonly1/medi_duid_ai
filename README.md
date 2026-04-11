---
title: MediGuide AI
emoji: 🏥
colorFrom: red
colorTo: blue
sdk: gradio
app_port: 7860
python_version: "3.10"
short_description: Privacy-First Multimodal Medical Assistant with Llama 3.2
tags:
  - healthcare
  - medical
  - llama
  - hackathon
  - meta-hackathon-2026
  - multimodal
pinned: false
---

# 🏥 MediGuide AI

**Privacy-First, Multimodal Medical Assistant for Rural India**

> Meta + Hugging Face Hackathon 2026 · Healthcare Track

---

## 🚀 Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
python app.py

# Run inference evaluation
python inference.py
```

---

## 🛠️ Built With

- **Llama 3.2 11B Vision** - Multimodal medical reasoning
- **Llama Guard 3** - Safety filtering  
- **FastAPI + Gradio** - Web serving
- **OpenEnv** - RL environment for evaluation

---

## 🎯 Features

| Feature | Description |
|---------|-------------|
| Multimodal Analysis | Text + image symptom input |
| Emergency Detection | Instant 108/102/112 SOS |
| Safety Protocol | Llama Guard 3 filtering |
| Hindi/English | Full multilingual support |
| RAG Verification | Medical knowledge base |
| Tool Calling | Pharmacy/Hospital lookup APIs |

---

## 📁 Project Structure

```
.
├── app.py              # Gradio UI + FastAPI
├── inference.py        # OpenEnv evaluation script
├── openenv/
│   └── env.py        # RL environment
├── tools.py          # Agentic tools
├── eval_suite.py     # 50 test cases + Llama-as-a-Judge
├── requirements.txt  # Dependencies
└── README.md        # This file
```

---

## ⚙️ Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HF_TOKEN` | - | HuggingFace API token |
| `MODEL_NAME` | meta-llama/Llama-3.2-11B-Vision-Instruct | Model to use |
| `PORT` | 7860 | Server port |

---

## 🏥 Emergency Numbers (India)

- **108** - Ambulance
- **102** - Medical Emergency  
- **112** - National Emergency

---

## ⚠️ Disclaimer

This AI provides guidance only. Always consult a qualified doctor for medical decisions. In emergencies, call 108 immediately.

---

## 📝 License

MIT License - Meta + Hugging Face Hackathon 2026