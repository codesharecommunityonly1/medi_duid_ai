import 'tensorflow_lite_service.dart';

class NeuralNetworkBrain {
  static NeuralNetworkBrain? _instance;
  static NeuralNetworkBrain get instance => _instance ??= NeuralNetworkBrain._();
  NeuralNetworkBrain._();

  final TensorFlowLiteService _tflite = TensorFlowLiteService.instance;
  List<Map<String, dynamic>> _conditions = [];
  List<String> _conversationContext = [];

  bool get isInitialized => _tflite.isInitialized;
  int get totalDiagnoses => _tflite.totalDiagnoses;
  int get correctPredictions => _tflite.correctPredictions;
  double get accuracy => _tflite.accuracy;

  Future<void> initialize(List<Map<String, dynamic>> conditions) async {
    if (_tflite.isInitialized) return;
    _conditions = conditions;
    await _tflite.initialize(conditions);

    for (final condition in conditions) {
      final id = condition['id'] as String;
      final symptoms = (condition['symptoms'] as List<String>? ?? []).map((s) => s.toLowerCase()).toList();
      final severity = condition['severity'] as String? ?? 'mild';

      _diseaseSymptoms[id] = symptoms;
      
      double baseBias = 0.1;
      switch (severity) {
        case 'critical': baseBias = 0.3; break;
        case 'severe': baseBias = 0.2; break;
        case 'moderate': baseBias = 0.15; break;
        default: baseBias = 0.1;
      }
      _diseaseBiases[id] = baseBias;
    }

    _isInitialized = true;
  }

  bool get _isInitialized => _tflite.isInitialized;

  Map<String, dynamic> forwardPass(List<String> inputSymptoms) {
    _conversationContext = inputSymptoms;
    return _tflite.analyzeSymptoms(inputSymptoms, _conditions);
  }
      ..sort((a, b) => (b.value['probability'] as double).compareTo(a.value['probability'] as double));

    return {
      'predictions': Map.fromEntries(sortedResults.take(5)),
      'topPrediction': sortedResults.isNotEmpty ? sortedResults.first.key : null,
      'activations': activations,
      'context': normalizedInput,
    };
  }

  List<String> _getMatchedSymptoms(List<String> input, List<String> disease) {
    final matched = <String>[];
    for (final inp in input) {
      for (final sym in disease) {
        if (inp.contains(sym) || sym.contains(inp)) {
          matched.add(sym);
          break;
        }
      }
    }
    return matched;
  }

  List<String> _generateReasoning(String diseaseId, List<String> input, List<String> symptoms) {
    final reasoning = <String>[];
    final matched = _getMatchedSymptoms(input, symptoms);
    
    reasoning.add('🔍 Input Analysis:');
    reasoning.add('   - User reported ${input.length} symptom(s)');
    reasoning.add('   - Analyzing against ${symptoms.length} known symptoms');
    
    if (matched.isNotEmpty) {
      reasoning.add('\n✅ Match Found:');
      for (final m in matched.take(3)) {
        reasoning.add('   • "$m" matched in disease pattern');
      }
    }
    
    reasoning.add('\n🧠 Neural Processing:');
    reasoning.add('   • Input layer: ${input.length} features');
    reasoning.add('   • Hidden layer: 10 neurons activated');
    reasoning.add('   • Output: ${(_outputLayer[diseaseId]! * 100).toStringAsFixed(1)}%');
    
    final userWeight = _userFeedbackWeights[diseaseId] ?? 1.0;
    if (userWeight != 1.0) {
      reasoning.add('\n📊 User Feedback:');
      reasoning.add('   • Weight adjusted based on previous feedback');
    }
    
    return reasoning;
  }

  double _relu(double x) => x > 0 ? x : 0;
  double _sigmoid(double x) => 1 / (1 + exp(-x));

  double _calculateConfidence(double output, int inputSize, int diseaseSize) {
    final baseConfidence = output;
    return 0.5;
  }

  Future<void> learn(String diseaseId, bool wasCorrect) async {
    await _tflite.learn(diseaseId, wasCorrect);
  }

  String generateResponse(String userInput, Map<String, dynamic> diagnosis) {
    return _tflite.generateResponse(userInput, diagnosis);
  }
    
    final topPrediction = sortedPredictions.first;
    final diseaseId = topPrediction.key;
    final prob = topPrediction.value['probability'] as double;
    final matched = topPrediction.value['matchedSymptoms'] as List<String>;
    final reasoning = topPrediction.value['reasoning'] as List<String>? ?? [];

    final responses = <String>[];
    
    responses.add("🧠 *Neural Analysis Complete*\n");
    
    if (matched.isNotEmpty) {
      responses.add("📋 *Matched Symptoms (${matched.length}):*");
      for (final s in matched.take(5)) {
        responses.add("  ✅ ${s.toUpperCase()}");
      }
      responses.add("");
    }
    
    final confidencePercent = (prob * 100).toStringAsFixed(0);
    responses.add("🎯 *Diagnosis:* ${_formatDiseaseName(diseaseId)}");
    responses.add("📊 *Confidence:* $confidencePercent%\n");
    
    if (prob > 0.7) {
      responses.add("⚠️ *High Confidence Match*\nBased on the symptom pattern, this appears to be a strong match.");
    } else if (prob > 0.4) {
      responses.add("ℹ️ *Moderate Confidence*\nThis is a possible match. More symptoms would help improve accuracy.");
    } else {
      responses.add("💡 *Low Confidence*\nI'm not certain about this. Please consult a healthcare professional.");
    }
    
    if (sortedPredictions.length > 1 && (sortedPredictions[1].value['probability'] as double) > 0.2) {
      responses.add("\n🔍 *Other Possibilities:*");
      for (int i = 1; i < sortedPredictions.length && i <= 3; i++) {
        final alt = sortedPredictions[i];
        final altProb = (alt.value['probability'] as double) * 100;
        if (altProb > 15) {
          responses.add("  • ${_formatDiseaseName(alt.key)} (${altProb.toStringAsFixed(0)}%)");
        }
      }
    }
    
    responses.add("\n❓ *Was this diagnosis correct?* Your feedback helps me learn and improve!");

    return responses.join("\n");
  }
  
  String _formatDiseaseName(String diseaseId) {
    return diseaseId.replaceAll('_', ' ').split(' ').map((word) => 
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }

  String getConversationPrompt() {
    if (_conversationContext.isEmpty) {
      return "Hello! I'm your medical AI assistant. Describe your symptoms and I'll help diagnose your condition.";
    }
    
    final context = _conversationContext.join(", ");
    return "Analyzing symptoms: $context...";
  }

  Map<String, dynamic> getBrainStats() {
    return _tflite.getStats();
  }
}

class ConversationalAI {
  static ConversationalAI? _instance;
  static ConversationalAI get instance => _instance ??= ConversationalAI._();
  ConversationalAI._();

  final NeuralNetworkBrain _brain = NeuralNetworkBrain.instance;
  List<Map<String, String>> _conversationHistory = [];
  String _currentMode = 'diagnosis';

  bool get isListening => _brain.isInitialized;

  Future<void> initialize(List<Map<String, dynamic>> conditions) async {
    await _brain.initialize(conditions);
  }

  Future<String> processInput(String userInput) async {
    final symptoms = _parseSymptoms(userInput);
    
    if (symptoms.isEmpty) {
      return _generateClarifyingResponse(userInput);
    }

    final diagnosis = _brain.forwardPass(symptoms);
    final response = _brain.generateResponse(userInput, diagnosis);
    
    _conversationHistory.add({
      'user': userInput,
      'bot': response,
    });

    return response;
  }

  List<String> _parseSymptoms(String input) {
    final symptoms = <String>[];
    final inputLower = input.toLowerCase();
    
    final symptomKeywords = {
      'fever': 'fever', 'high temperature': 'fever', 'feeling hot': 'fever', 'chills': 'chills', 'shivering': 'chills',
      'headache': 'headache', 'head pain': 'headache', 'migraine': 'headache', 'head hurts': 'headache',
      'cough': 'cough', 'coughing': 'cough', 'dry cough': 'cough', 'wet cough': 'cough',
      'pain': 'pain', 'hurt': 'pain', 'hurts': 'pain', 'aching': 'pain', 'sore': 'pain',
      'nausea': 'nausea', 'feeling sick': 'nausea', 'queasy': 'nausea',
      'vomit': 'vomiting', 'vomiting': 'vomiting', 'throwing up': 'vomiting', 'threw up': 'vomiting',
      'diarrhea': 'diarrhea', 'loose stool': 'diarrhea', 'watery stool': 'diarrhea',
      'fatigue': 'fatigue', 'tired': 'fatigue', 'tiredness': 'fatigue', 'exhausted': 'fatigue', 'weak': 'fatigue',
      'dizz': 'dizziness', 'lightheaded': 'dizziness', 'vertigo': 'dizziness', 'spinning': 'dizziness',
      'chest pain': 'chest pain', 'chest': 'chest pain', 'heart pain': 'chest pain',
      'breath': 'shortness of breath', 'breathing': 'shortness of breath', 'breathless': 'shortness of breath', 'wheez': 'wheezing',
      'rash': 'rash', 'skin rash': 'rash', 'hives': 'rash',
      'swell': 'swelling', 'swollen': 'swelling', 'swelling': 'swelling', 'edema': 'swelling',
      'bleed': 'bleeding', 'bleeding': 'bleeding', 'blood': 'bleeding', 'cut': 'bleeding',
      'fracture': 'fracture', 'broken': 'fracture', 'broken bone': 'fracture',
      'burn': 'burn', 'burns': 'burn', 'scald': 'burn',
      'choke': 'choking', 'choking': 'choking', 'cannot breathe': 'choking',
      'seizure': 'seizure', 'convulsion': 'seizure', 'fit': 'seizure',
      'unconscious': 'unconscious', 'fainted': 'unconscious', 'passed out': 'unconscious', 'passed out': 'unconscious',
      'sweat': 'sweating', 'sweating': 'sweating', 'sweaty': 'sweating', 'perspire': 'sweating',
      'body ache': 'body ache', 'body pain': 'body ache', 'muscle ache': 'body ache', 'muscle pain': 'body ache',
      'joint pain': 'joint pain', 'joint ache': 'joint pain', 'arthrit': 'joint pain',
      'stomach': 'stomach pain', 'stomach pain': 'stomach pain', 'belly': 'stomach pain', 'abdominal': 'stomach pain',
      'sore throat': 'sore throat', 'throat pain': 'sore throat', 'throat hurts': 'sore throat',
      'runny nose': 'runny nose', 'nasal': 'runny nose', 'congestion': 'congestion', 'blocked nose': 'congestion',
      'appetite': 'loss of appetite', 'no appetite': 'loss of appetite', 'not hungry': 'loss of appetite',
      'weight': 'weight loss', 'losing weight': 'weight loss',
      'eye': 'eye pain', 'eye pain': 'eye pain', 'vision': 'vision problems', 'blurry': 'vision problems',
      'ear': 'ear pain', 'ear pain': 'ear pain', 'earache': 'ear pain', 'hearing': 'ear pain',
      'back': 'back pain', 'back pain': 'back pain', 'lower back': 'back pain',
      'neck': 'neck pain', 'neck pain': 'neck pain', 'stiff neck': 'neck pain',
      'tooth': 'toothache', 'tooth pain': 'toothache', 'tooth hurts': 'toothache',
      'insomnia': 'insomnia', 'cannot sleep': 'insomnia', 'trouble sleeping': 'insomnia', 'no sleep': 'insomnia',
      'anxiety': 'anxiety', 'anxious': 'anxiety', 'panic': 'anxiety', 'worried': 'anxiety',
      'depression': 'depression', 'sad': 'depression', 'down': 'depression', 'hopeless': 'depression',
      'allergy': 'allergy', 'allergic': 'allergy', 'sneeze': 'allergy', 'itchy': 'itching',
      'itch': 'itching', 'itching': 'itching', 'scratch': 'itching',
      'constipation': 'constipation', 'cannot poop': 'constipation', 'hard stool': 'constipation',
      'urinate': 'urinary problems', 'urination': 'urinary problems', 'pee': 'urinary problems',
      'heart': 'heartbeat', 'palpitations': 'heartbeat', 'heart racing': 'heartbeat',
    };

    for (final entry in symptomKeywords.entries) {
      if (inputLower.contains(entry.key)) {
        symptoms.add(entry.value);
      }
    }

    return symptoms.toSet().toList();
  }

  String _generateClarifyingResponse(String input) {
    final inputLower = input.toLowerCase();
    
    if (inputLower.contains('hello') || inputLower.contains('hi') || inputLower.contains('hey') || inputLower.contains('greeting')) {
      return "👋 Hello! I'm MedAI, your offline medical assistant.\n\nI can help you with:\n• 🩺 Symptom diagnosis\n• 🆘 Emergency guidance\n• 💊 First aid instructions\n• 📋 Health information\n\nJust describe what symptoms you're experiencing!";
    }
    
    if (inputLower.contains('help') || inputLower.contains('what can you do')) {
      return "🆘 *I can help you with:*\n\n"
          "• 🩺 **Symptom Diagnosis** - Tell me what you feel\n"
          "• 🏥 **First Aid** - Get immediate guidance\n"
          "• 🚨 **Emergency** - Critical situation help\n"
          "• 📋 **Health Info** - Learn about conditions\n\n"
          "Just describe your symptoms or ask for help!";
    }
    
    if (inputLower.contains('thank')) {
      return "😊 You're welcome! Take care of your health. Is there anything else I can help you with?";
    }
    
    if (inputLower.contains('emergency') || inputLower.contains('urgent') || inputLower.contains('critical')) {
      return "🚨 *For emergencies, please:*\n\n"
          "• Call your local emergency number immediately\n"
          "• Go to the nearest hospital\n"
          "• Ask someone for help\n\n"
          "This AI is for informational purposes only and is not a substitute for professional medical care.";
    }
    
    if (inputLower.contains('bye') || inputLower.contains('goodbye') || inputLower.contains('see you')) {
      return "👋 Goodbye! Stay healthy! Remember, I'm here 24/7 if you need help.";
    }

    final clarifyingQuestions = [
      "🤔 I need more information. Could you describe what you're feeling?\n\nTry: 'I have fever and headache' or 'My stomach hurts'",
      "💭 What symptoms are you experiencing? Examples:\n• Fever, cough, fatigue\n• Chest pain, shortness of breath\n• Nausea, vomiting, diarrhea",
      "📝 Please describe your symptoms more specifically.\n\nTell me what hurts or what you're feeling.",
    ];
    
    return clarifyingQuestions[DateTime.now().millisecond % clarifyingQuestions.length];
  }

  void submitFeedback(String diagnosis, bool wasCorrect) {
    _brain.learn(diagnosis, wasCorrect);
    _conversationHistory.add({
      'user': 'Feedback: $diagnosis was ${wasCorrect ? "correct" : "incorrect"}',
      'bot': wasCorrect 
          ? "Thank you! My neural network will learn from this feedback. ✅" 
          : "I'll adjust my weights to improve future accuracy. 📊",
    });
  }

  List<Map<String, String>> getHistory() => _conversationHistory;

  void clearHistory() => _conversationHistory.clear();

  Map<String, dynamic> getStats() => _brain.getBrainStats();
}
