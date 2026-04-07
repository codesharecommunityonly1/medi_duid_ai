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

**Privacy-First, Multimodal Medical Assistant**

> Meta + Hugging Face Hackathon 2026 · Healthcare Track

---

## Built With

- **Llama 3.2 11B Vision** - Multimodal medical reasoning
- **Llama Guard 3** - Safety filtering
- **PyTorch** - Deep learning framework
- **Gradio** - UI for HuggingFace Spaces

---

## The Problem

Solving the "Healthcare Desert" in rural India via localized AI. 
600M+ Indians lack access to doctors - this assistant provides instant 
medical guidance in Hindi/English with emergency detection.

---

## Features

- **Multimodal Analysis** - Text symptoms + image uploads (skin rashes, medicine labels)
- **Medical Reasoning Chain** - Analyze → Verify (RAG) → Guard (Llama Guard)
- **Safety Protocol** - Integrated Llama-Stack safety filters to prevent misinformation
- **Emergency Detection** - Instant SOS with 108, 102, 112 contacts
- **Hindi + English** - Full multilingual support for Indian demographic
- **RAG Verification** - Medical knowledge base lookup (Merck Manual simulation)

---

## Safety Protocol

This AI includes multiple safety layers:

1. **Llama Guard 3** - Filters harmful content
2. **Emergency Keywords** - Detects critical conditions
3. **Medical Disclaimer** - Always recommends professional consultation
4. **SOS Integration** - Instant access to India's emergency numbers

---

## Usage

1. Enter symptoms in text or upload an image
2. Select language (English or Hindi)
3. Click "Analyze with Llama 3.2"
4. View diagnosis with confidence scores and emergency steps

---

## Environment Variables

- `HF_TOKEN` - HuggingFace token for Llama 3.2 API (optional)
- `MODEL_NAME` - Model to use (default: meta-llama/Llama-3.2-11B-Vision-Instruct)
- `GUARD_MODEL` - Safety model (default: meta-llama/Llama-Guard-3-8B)

---

## Disclaimer

This AI provides guidance only. Always consult a qualified doctor for medical decisions.
In emergencies, call 108 (India) immediately.