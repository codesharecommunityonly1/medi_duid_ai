# MediGuide AI - Offline Emergency Medical Assistant

## Meta + Hugging Face Hackathon 2026

---

## THE PROBLEM (Rural Healthcare)

- **1 doctor per 25,000** people in rural areas
- **65%** of population has NO reliable internet access
- **Every minute**, someone dies waiting for medical help

## OUR SOLUTION

**MediGuide AI** - An offline emergency medical assistant powered by TensorFlow Lite that works without internet!

---

## KEY FEATURES

| Feature | Description |
|---------|-------------|
| **TensorFlow Lite AI** | Research-level neural network for diagnosis |
| **Smart Diagnosis** | Multi-result with confidence % (Malaria 72%, Dengue 18%) |
| **Learning System** | User feedback improves AI accuracy |
| **Confidence System** | Shows % probability with visual bars |
| **100+ Emergency Numbers** | Country-specific emergency contacts |
| **Rural Impact Mode** | AI-powered diagnosis for areas without doctors |
| **Offline** | Works without internet 100% |
| **Voice AI** | Speech-to-text + TTS |
| **Multi-language** | English, Hindi support |
| **Dark Mode** | Full dark theme support |
| **URGENT HELP** | Prominent emergency button at top |

---

## AI FEATURES

### TensorFlow Lite Neural Network
- Deep learning inference on-device
- Research-level AI feel
- Learns from user feedback
- Offline 100%

### Multi-Result Confidence Display
```
Malaria → 72% ████████████
Dengue → 18% ████
Typhoid → 10% ██
```

### Emergency Mode
- 🚨 **URGENT HELP** button at top of screen
- Risk Level indicators
- Quick Emergency Actions (Heart Attack, Choking, Stroke, Burns)
- Immediate Steps checklist

---

## SCREENS

1. **Home** - Quick actions, Smart Diagnosis, URGENT HELP button at top
2. **Smart Diagnosis** - Select symptoms → Get multi-result with confidence %
3. **Rural Emergency AI** - Symptom → Diagnosis → Learn
4. **Rural Impact Mode** - Full condition database for remote areas
5. **AI Assistant** - Chat with TensorFlow Lite AI
6. **Emergency SOS** - Quick actions, risk levels, immediate steps
7. **Settings** - Dark mode, Voice output, Country selector for emergency numbers
8. **Health History** - Your diagnosis records

---

## BUILD

```bash
cd fresh_app
flutter pub get
flutter build apk --debug
```

**APK Location:** `build/app/outputs/flutter-apk/app-debug.apk`

---

## IMPACT

- **Target**: Rural communities worldwide
- **Conditions**: 28+ medical conditions
- **Offline**: 100%
- **Languages**: English, Hindi
- **Emergency Numbers**: 100+ countries

---

## Architecture

```
lib/
├── core/
│   ├── constants/app_strings.dart
│   └── theme/app_theme.dart
├── services/
│   ├── tensorflow_lite_service.dart  # TensorFlow Lite AI
│   ├── offline_llm_brain.dart         # Neural network wrapper
│   ├── medical_diagnosis_service.dart
│   ├── emergency_numbers_service.dart # 100 countries
│   └── ...
└── presentation/
    └── screens/
        ├── home_screen.dart           # URGENT HELP at top
        ├── symptom_selector_screen.dart  # Confidence bars
        ├── emergency_screen.dart      # Risk levels
        ├── neural_llm_brain_screen.dart # TensorFlow Lite AI
        ├── rural_impact_screen.dart   # All conditions
        └── ...
```

---

## Tech Stack

- **Flutter** - UI Framework
- **TensorFlow Lite** - ML Inference
- **SQLite** - Local database
- **BLoC** - State management
- **Material Design 3** - UI

---

## LICENSE

MIT License - Open Source for Good
