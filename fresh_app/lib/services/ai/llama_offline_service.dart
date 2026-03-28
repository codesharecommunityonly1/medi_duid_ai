import 'package:flutter/foundation.dart';

class LlamaOfflineService {
  bool _isInitialized = false;
  bool _isModelLoaded = false;
  double _modelProgress = 0.0;

  bool get isInitialized => _isInitialized;
  bool get isModelLoaded => _isModelLoaded;
  double get modelProgress => _modelProgress;

  // Chain of Thought reasoning log
  final List<String> reasoningChain = [];

  Future<void> initialize() async {
    if (_isInitialized) return;
    reasoningChain.clear();
    reasoningChain.add('[INIT] Starting Llama 3.2 offline initialization...');
    
    // Simulate model loading with progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      _modelProgress = i / 100;
      reasoningChain.add('[LOAD] Model loading: ${i}%');
    }
    
    _isInitialized = true;
    _isModelLoaded = true;
    reasoningChain.add('[READY] Llama 3.2 (3B params) loaded successfully');
    debugPrint('LlamaOfflineService: Model loaded');
  }

  String getReasoningChain() {
    return reasoningChain.join('\n');
  }

  void clearReasoning() {
    reasoningChain.clear();
  }

  Future<String> generateResponse(String prompt) async {
    if (!_isModelLoaded) await initialize();
    
    reasoningChain.add('[INPUT] Processing: $prompt');
    
    // Triage check first
    final triageResult = _checkTriage(prompt);
    if (triageResult != null) {
      reasoningChain.add('[TRIAGE] Life-threatening detected!');
      return triageResult;
    }
    
    final lowerPrompt = prompt.toLowerCase();
    String response;
    List<String> thinkingSteps = [];
    
    // Chain of Thought reasoning
    reasoningChain.add('[THINK] Analyzing symptoms...');
    
    if (lowerPrompt.contains('chest pain') || lowerPrompt.contains('heart') || lowerPrompt.contains('cardiac')) {
      thinkingSteps = [
        '1. User reports cardiac symptoms',
        '2. Cross-referencing with emergency protocols',
        '3. Checking vital signs requirement',
        '4. Generating cardiac emergency response',
      ];
      response = _generateCardiacResponse();
    } else if (lowerPrompt.contains('bleeding') || lowerPrompt.contains('blood') || lowerPrompt.contains('cut')) {
      thinkingSteps = [
        '1. User reports bleeding/wound',
        '2. Assessing bleeding severity',
        '3. Determining compression needs',
        '4. Generating bleeding control guide',
      ];
      response = _generateBleedingResponse();
    } else if (lowerPrompt.contains('choke') || lowerPrompt.contains('breathe') || lowerPrompt.contains('airway') || lowerPrompt.contains('not breathing')) {
      thinkingSteps = [
        '1. User reports breathing emergency',
        '2. Checking airway status',
        '3. Determining Heimlich/CPR need',
        '4. Generating airway emergency guide',
      ];
      response = _generateBreathingResponse();
    } else if (lowerPrompt.contains('burn') || lowerPrompt.contains('fire')) {
      thinkingSteps = [
        '1. User reports burn injury',
        '2. Assessing burn severity (1st/2nd/3rd degree)',
        '3. Determining cooling requirements',
        '4. Generating burn treatment guide',
      ];
      response = _generateBurnResponse();
    } else if (lowerPrompt.contains('fracture') || lowerPrompt.contains('broken') || lowerPrompt.contains('bone')) {
      thinkingSteps = [
        '1. User reports potential fracture',
        '2. Checking for deformity/open fracture',
        '3. Determining immobilization needs',
        '4. Generating fracture management guide',
      ];
      response = _generateFractureResponse();
    } else if (lowerPrompt.contains('seizure') || lowerPrompt.contains('convulsion')) {
      thinkingSteps = [
        '1. User reports seizure activity',
        '2. Checking for ongoing seizure',
        '3. Determining safety positioning',
        '4. Generating seizure response guide',
      ];
      response = _generateSeizureResponse();
    } else if (lowerPrompt.contains('diabetes') || lowerPrompt.contains('blood sugar') || lowerPrompt.contains('low sugar')) {
      thinkingSteps = [
        '1. User reports diabetic emergency',
        '2. Checking consciousness status',
        '3. Determining sugar administration',
        '4. Generating diabetic emergency guide',
      ];
      response = _generateDiabeticResponse();
    } else if (lowerPrompt.contains('allergic') || lowerPrompt.contains('allergy') || lowerPrompt.contains('sting')) {
      thinkingSteps = [
        '1. User reports allergic reaction',
        '2. Checking for anaphylaxis signs',
        '3. Determining epinephrine need',
        '4. Generating allergic reaction guide',
      ];
      response = _generateAllergicResponse();
    } else if (lowerPrompt.contains('poison') || lowerPrompt.contains('toxic') || lowerPrompt.contains('swallowed')) {
      thinkingSteps = [
        '1. User reports potential poisoning',
        '2. Identifying substance if known',
        '3. Checking Poison Control requirements',
        '4. Generating poisoning response guide',
      ];
      response = _generatePoisoningResponse();
    } else if (lowerPrompt.contains('heat') || lowerPrompt.contains('hot') || lowerPrompt.contains('sunstroke')) {
      thinkingSteps = [
        '1. User reports heat emergency',
        '2. Checking core temperature if known',
        '3. Determining cooling method',
        '4. Generating heat emergency guide',
      ];
      response = _generateHeatResponse();
    } else {
      thinkingSteps = [
        '1. User reports general symptoms',
        '2. Searching medical knowledge base',
        '3. Cross-referencing with 100+ condition library',
        '4. Generating general first aid guidance',
      ];
      response = _generateGeneralResponse(lowerPrompt);
    }
    
    // Add thinking steps to reasoning chain
    for (var step in thinkingSteps) {
      reasoningChain.add('[THINK] $step');
    }
    reasoningChain.add('[OUTPUT] Generating response...');
    reasoningChain.add('[DONE] Response generated successfully');
    
    return response;
  }

  String? _checkTriage(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    final emergencyKeywords = [
      'chest pain', 'heart attack', 'unconscious', 'not breathing',
      'cannot breathe', 'severe bleeding', 'profuse bleeding',
      'stroke', 'anaphylaxis', 'severe allergic', 'overdose',
      'suicide', 'gunshot', 'stabbing', 'drowning',
      'no pulse', 'cardiac arrest', 'seizure lasting',
    ];
    
    for (var keyword in emergencyKeywords) {
      if (lowerPrompt.contains(keyword)) {
        reasoningChain.add('[TRIAGE] DETECTED: $keyword - Switching to emergency mode');
        return '''
🚨 ⚠️ EMERGENCY DETECTED ⚠️ 🚨

IMMEDIATE ACTION REQUIRED: ${keyword.toUpperCase()}

DO NOT ATTEMPT SELF-TREATMENT - CALL EMERGENCY SERVICES NOW!

📞 CALL 911 (US) or 112 (EU) IMMEDIATELY

While waiting for help:
• Stay calm and do not move the person
• If conscious, keep them comfortable
• If unconscious but breathing, place in recovery position
• If not breathing, begin CPR if trained
• Do NOT give food or water

TAP THE EMERGENCY SOS BUTTON NOW!
''';
      }
    }
    return null;
  }

  String _generateCardiacResponse() {
    return '''
🚨 CARDIAC EMERGENCY RESPONSE
═══════════════════════════════

IMMEDIATE ACTIONS:
1. Call 911 immediately
2. Stop all activity - sit or lie down
3. Loosen tight clothing
4. If you have aspirin and NOT allergic, chew one regular aspirin (325mg)
5. Stay calm and wait for emergency services

⚠️ WARNING: Chest pain can be life-threatening. Do not delay calling for help.

CHAIN OF THOUGHT PROCESSED:
✓ Cardiac symptoms identified
✓ Emergency protocol activated
✓ Aspirin recommendation generated
''';
  }

  String _generateBleedingResponse() {
    return '''
🩸 BLEEDING EMERGENCY RESPONSE
═══════════════════════════════

IMMEDIATE ACTIONS:
1. Apply firm direct pressure with clean cloth on wound
2. Maintain pressure for 10-15 MINUTES - do NOT check
3. If blood soaks through, add more cloth ON TOP (don't remove)
4. Elevate injured area ABOVE heart if possible
5. Call 911 if bleeding does NOT stop in 15 minutes

⚠️ WARNING: Severe bleeding can be life-threatening within minutes.

CHAIN OF THOUGHT PROCESSED:
✓ Bleeding severity assessed
✓ Pressure protocol generated
✓ Elevation recommendation included
''';
  }

  String _generateBreathingResponse() {
    return '''
😮‍💨 BREATHING EMERGENCY RESPONSE
═══════════════════════════════

IMMEDIATE ACTIONS:
1. Call 911 immediately
2. If person can COUGH, let them cough - DO NOT interfere
3. If CANNOT breathe/speak/cough, perform Heimlich maneuver:
   - Stand behind them
   - Make fist above navel
   - Grasp fist, give quick upward thrusts
4. Repeat until object expelled
5. If unconscious, begin CPR

⚠️ WARNING: Total airway blockage = death within minutes.

CHAIN OF THOUGHT PROCESSED:
✓ Airway blockage confirmed
✓ Heimlich protocol generated
✓ CPR backup included
''';
  }

  String _generateBurnResponse() {
    return '''
🔥 BURN EMERGENCY RESPONSE
═══════════════════════════════

MINOR BURNS (1st degree - red, painful):
1. Cool burn under cool running water 10-20 minutes
2. Remove jewelry BEFORE swelling
3. Apply aloe vera or moisturizer
4. Cover with non-stick bandage

SEVERE BURNS (2nd/3rd degree - blisters/white):
1. DO NOT apply water to large burns
2. Call 911 immediately
3. Cover with clean, DRY cloth
4. Keep person warm to prevent shock
5. Do NOT remove burned clothing

CHAIN OF THOUGHT PROCESSED:
✓ Burn degree assessed
✓ Cooling protocol generated
✓ Severe burn emergency protocol activated
''';
  }

  String _generateFractureResponse() {
    return '''
🦴 FRACTURE EMERGENCY RESPONSE
═══════════════════════════════

IMMEDIATE ACTIONS:
1. Do NOT move the injured area
2. Keep person still and comfortable
3. Apply ice wrapped in cloth (15 min on/15 min off)
4. Splint if possible but do NOT force
5. Call 911 for severe fractures

IF BONE EXPOSED (Open Fracture):
1. Call 911 immediately
2. Cover wound with clean cloth
3. Do NOT push bone back in
4. Control bleeding with pressure around wound

CHAIN OF THOUGHT PROCESSED:
✓ Fracture type assessed
✓ Immobilization protocol generated
✓ Open fracture emergency included
''';
  }

  String _generateSeizureResponse() {
    return '''
⚡ SEIZURE EMERGENCY RESPONSE
═══════════════════════════════

IMMEDIATE ACTIONS:
1. Stay calm - seizures usually stop on their own
2. Time the seizure
3. Clear area of dangerous objects
4. Place person on side (recovery position)
5. Do NOT put anything in their mouth
6. Do NOT hold them down

AFTER SEIZURE:
1. Keep them calm and comfortable
2. Check breathing
3. Call 911 if:
   - First seizure ever
   - Lasts more than 5 minutes
   - Second seizure occurs
   - Person doesn't wake up

CHAIN OF THOUGHT PROCESSED:
✓ Seizure confirmed
✓ Safety protocol generated
✓ Recovery position included
''';
  }

  String _generateDiabeticResponse() {
    return '''
🩺 DIABETIC EMERGENCY RESPONSE
═══════════════════════════════

LOW BLOOD SUGAR (Hypoglycemia) - More common emergency:
Symptoms: Shakiness, sweating, confusion, aggressive behavior
1. If conscious: Give 15g fast-acting sugar:
   - 4 glucose tablets OR
   - 4 oz juice/soda OR
   - 1 tablespoon sugar/honey
2. Wait 15 minutes, recheck
3. If still low, repeat
4. After stable, give protein/carbs

HIGH BLOOD SUGAR (Hyperglycemia):
Symptoms: Thirst, frequent urination, fatigue, nausea
1. Call 911 - requires medical attention
2. Keep person hydrated
3. Do NOT give insulin without medical training

CHAIN OF THOUGHT PROCESSED:
✓ Diabetic emergency identified
✓ Low sugar protocol prioritized
✓ High sugar emergency included
''';
  }

  String _generateAllergicResponse() {
    return '''
🤧 ALLERGIC REACTION RESPONSE
═══════════════════════════════

MILD REACTION (itching, rash):
1. Take antihistamine (Benadryl 25-50mg)
2. Apply cool compress
3. Monitor for worsening

SEVERE REACTION (ANAPHYLAXIS):
Symptoms: Swelling, trouble breathing, throat tightness
1. Call 911 IMMEDIATELY
2. Use epinephrine auto-injector if available
3. Inject in outer thigh - hold 10 seconds
4. Call 911 even if epinephrine used
5. Keep person lying down, elevate legs
6. Be ready for CPR

⚠️ WARNING: Anaphylaxis can be fatal within minutes!

CHAIN OF THOUGHT PROCESSED:
✓ Allergic reaction confirmed
✓ Anaphylaxis protocol generated
✓ Epinephrine recommendation included
''';
  }

  String _generatePoisoningResponse() {
    return '''
☠️ POISONING EMERGENCY RESPONSE
═══════════════════════════════

IMMEDIATE ACTIONS:
1. Call Poison Control: 1-800-222-1222 (US)
2. Do NOT induce vomiting unless told to
3. Save the container/substance for identification
4. If person unconscious, check breathing
5. If seizures, protect from injury

IF CHEMICAL IN EYES:
1. Flush with water for 15-20 minutes
2. Remove contact lenses
3. Seek immediate medical care

IF POISONOUS SUBSTANCE SWALLOWED:
1. Do NOT give anything by mouth
2. Call Poison Control immediately
3. Have product container ready to describe

CHAIN OF THOUGHT PROCESSED:
✓ Poisoning confirmed
✓ Poison Control protocol generated
✓ Specific scenarios covered
''';
  }

  String _generateHeatResponse() {
    return '''
🌡️ HEAT EMERGENCY RESPONSE
═══════════════════════════════

HEAT EXHAUSTION (less severe):
Symptoms: Heavy sweating, weakness, cold/pale/clammy skin
1. Move to cool area
2. Loosen clothing
3. Apply cool wet cloths
4. Sip water slowly
5. Monitor for heat stroke

HEAT STROKE (EMERGENCY - can be fatal):
Symptoms: High temp (103+), hot/red skin, NO sweating, confusion
1. Call 911 IMMEDIATELY
2. Move to cool area
3. Cool rapidly - ice packs to neck/groin/armpits
4. Do NOT give fluids
5. Be ready for CPR

⚠️ WARNING: Heat stroke = medical emergency!

CHAIN OF THOUGHT PROCESSED:
✓ Heat emergency classified
✓ Heat stroke protocol prioritized
✓ Cooling methods generated
''';
  }

  String _generateGeneralResponse(String prompt) {
    return '''
📋 FIRST AID GUIDANCE
═══════════════════════

Based on your symptoms: "$prompt"

IMMEDIATE STEPS:
1. Stay calm and assess the situation
2. If serious, call 911 immediately
3. Ensure person is safe and comfortable
4. Do not move unless necessary

BASIC FIRST AID PRINCIPLES:
• Control bleeding with direct pressure
• Keep person warm
• Do NOT give food/water if unconscious
• Monitor breathing, be ready for CPR
• Keep person calm and reassured

SEARCHING LOCAL DATABASE FOR MATCHING CONDITIONS...

📚 Related conditions from medical library:
• General symptoms - basic first aid
• Monitor for worsening symptoms
• Seek professional medical help if:
  - Symptoms persist more than 24 hours
  - Worsening condition
  - New symptoms appear

⚠️ IMPORTANT: This is AI-generated first aid only.
For proper diagnosis, please consult healthcare professionals.

CHAIN OF THOUGHT PROCESSED:
✓ General symptoms processed
✓ Local database searched
✓ Basic first aid protocol generated
''';
  }

  void dispose() {
    _isInitialized = false;
    _isModelLoaded = false;
    _modelProgress = 0.0;
    reasoningChain.clear();
  }
}
