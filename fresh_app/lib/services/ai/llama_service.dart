import 'package:flutter/foundation.dart';

class LlamaService {
  bool _isInitialized = false;
  bool _isModelLoaded = false;

  bool get isInitialized => _isInitialized;
  bool get isModelLoaded => _isModelLoaded;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint('LlamaService: Initialized');
  }

  Future<bool> loadModel(String path) async {
    if (!_isInitialized) await initialize();
    try {
      debugPrint('LlamaService: Loading model from $path');
      await Future.delayed(const Duration(seconds: 1));
      _isModelLoaded = true;
      return true;
    } catch (e) {
      debugPrint('LlamaService: Failed to load model: $e');
      return false;
    }
  }

  Stream<String> generateResponse(String prompt) async* {
    if (!_isModelLoaded) {
      yield 'Error: Model not loaded';
      return;
    }
    
    final lowerPrompt = prompt.toLowerCase();
    String response;
    
    if (lowerPrompt.contains('chest pain') || lowerPrompt.contains('heart')) {
      response = 'IMMEDIATE ACTIONS:\n1. Call 911 immediately\n2. Stop all activity, sit or lie down\n3. Loosen tight clothing\n4. If you have aspirin and not allergic, chew one regular aspirin\n5. Stay calm and wait for emergency services\n\nWARNING: Chest pain can be life-threatening. Do not delay calling for help.';
    } else if (lowerPrompt.contains('bleeding') || lowerPrompt.contains('blood')) {
      response = 'BLEEDING RESPONSE:\n1. Apply firm pressure with clean cloth directly on wound\n2. Maintain pressure for 10-15 minutes - do not check\n3. If blood soaks through, add more cloth on top\n4. Elevate injured area above heart if possible\n5. Call 911 if bleeding does not stop\n\nWARNING: Severe bleeding can be life-threatening.';
    } else if (lowerPrompt.contains('choke') || lowerPrompt.contains('breathe') || lowerPrompt.contains('airway')) {
      response = 'CHOKING EMERGENCY:\n1. Call 911 immediately\n2. If person can cough, let them cough\n3. If cannot breathe/speak/cough, perform Heimlich:\n   - Stand behind them\n   - Make fist above navel\n   - Grasp fist, give quick upward thrusts\n4. Repeat until object expelled\n5. If unconscious, begin CPR';
    } else if (lowerPrompt.contains('burn')) {
      response = 'BURN FIRST AID:\n1. Cool burn under cool running water 10-20 minutes\n2. Remove jewelry before swelling\n3. Apply aloe vera or moisturizer\n4. Cover with non-stick bandage\n\nFOR SEVERE BURNS:\n- Call 911 immediately\n- Do NOT apply water to large burns\n- Cover with clean, dry cloth\n- Keep person warm to prevent shock';
    } else {
      response = 'IMMEDIATE STEPS:\n1. Stay calm and assess the situation\n2. If serious, call 911\n3. Ensure person is safe and comfortable\n4. Do not move unless necessary\n\nBASIC FIRST AID:\n- Control bleeding with direct pressure\n- Keep person warm\n- Do not give food/water if unconscious\n- Monitor breathing, be ready for CPR\n\nIMPORTANT: Seek professional medical help for proper evaluation.';
    }

    final words = response.split(' ');
    for (var i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      yield words[i] + (i < words.length - 1 ? ' ' : '');
    }
  }

  void dispose() {
    _isInitialized = false;
    _isModelLoaded = false;
  }
}
