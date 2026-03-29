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
    _conditions = conditions;
    await _tflite.initialize(conditions);
  }

  Future<Map<String, dynamic>> forwardPass(List<String> inputSymptoms) async {
    _conversationContext = inputSymptoms;
    return await _tflite.analyzeSymptoms(inputSymptoms, _conditions);
  }

  Future<void> learn(String diseaseId, bool wasCorrect) async {
    await _tflite.learn(diseaseId, wasCorrect);
  }

  String generateResponse(String userInput, Map<String, dynamic> diagnosis) {
    return _tflite.generateResponse(userInput, diagnosis);
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

  bool get isListening => _brain.isInitialized;

  Future<void> initialize(List<Map<String, dynamic>> conditions) async {
    await _brain.initialize(conditions);
  }

  Future<String> processInput(String userInput) async {
    final symptoms = _parseSymptoms(userInput);
    
    if (symptoms.isEmpty) {
      return _generateClarifyingResponse(userInput);
    }

    final diagnosis = await _brain.forwardPass(symptoms);
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
      'fever': 'fever', 'high temperature': 'fever', 'chills': 'chills', 'shivering': 'chills',
      'headache': 'headache', 'head pain': 'headache', 'migraine': 'headache',
      'cough': 'cough', 'coughing': 'cough', 'dry cough': 'cough',
      'pain': 'pain', 'hurt': 'pain', 'aching': 'pain', 'sore': 'pain',
      'nausea': 'nausea', 'feeling sick': 'nausea', 'queasy': 'nausea',
      'vomit': 'vomiting', 'vomiting': 'vomiting', 'throwing up': 'vomiting',
      'diarrhea': 'diarrhea', 'loose stool': 'diarrhea',
      'fatigue': 'fatigue', 'tired': 'fatigue', 'exhausted': 'fatigue', 'weak': 'fatigue',
      'dizz': 'dizziness', 'lightheaded': 'dizziness', 'vertigo': 'dizziness',
      'chest pain': 'chest pain', 'chest': 'chest pain',
      'breath': 'shortness of breath', 'breathing': 'shortness of breath', 'wheez': 'wheezing',
      'rash': 'rash', 'skin rash': 'rash', 'hives': 'rash',
      'swell': 'swelling', 'swollen': 'swelling',
      'bleed': 'bleeding', 'bleeding': 'bleeding', 'blood': 'bleeding',
      'fracture': 'fracture', 'broken': 'fracture', 'broken bone': 'fracture',
      'burn': 'burn', 'burns': 'burn',
      'choke': 'choking', 'choking': 'choking',
      'seizure': 'seizure', 'convulsion': 'seizure',
      'unconscious': 'unconscious', 'fainted': 'unconscious', 'passed out': 'unconscious',
      'sweat': 'sweating', 'sweating': 'sweating',
      'body ache': 'body ache', 'body pain': 'body ache', 'muscle ache': 'body ache',
      'joint pain': 'joint pain', 'joint ache': 'joint pain',
      'stomach': 'stomach pain', 'stomach pain': 'stomach pain', 'belly': 'stomach pain',
      'sore throat': 'sore throat', 'throat pain': 'sore throat',
      'runny nose': 'runny nose', 'congestion': 'congestion', 'blocked nose': 'congestion',
      'appetite': 'loss of appetite', 'no appetite': 'loss of appetite',
      'weight loss': 'weight loss',
      'eye': 'eye pain', 'vision': 'vision problems', 'blurry': 'vision problems',
      'ear': 'ear pain', 'earache': 'ear pain',
      'back pain': 'back pain', 'lower back': 'back pain',
      'neck': 'neck pain', 'stiff neck': 'neck pain',
      'tooth': 'toothache', 'tooth pain': 'toothache',
      'insomnia': 'insomnia', 'cannot sleep': 'insomnia', 'trouble sleeping': 'insomnia',
      'anxiety': 'anxiety', 'anxious': 'anxiety', 'panic': 'anxiety',
      'depression': 'depression', 'sad': 'depression',
      'allergy': 'allergy', 'allergic': 'allergy', 'sneeze': 'allergy',
      'itch': 'itching', 'itchy': 'itching',
      'constipation': 'constipation',
      'urinate': 'urinary problems', 'urination': 'urinary problems',
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
    
    if (inputLower.contains('hello') || inputLower.contains('hi') || inputLower.contains('hey')) {
      return "Hello! I'm MedAI, your offline medical assistant. Describe your symptoms and I'll help diagnose your condition. For example: 'I have fever and headache'";
    }
    
    if (inputLower.contains('help') || inputLower.contains('what can you do')) {
      return "I can help you with:\n• Symptom diagnosis\n• First aid guidance\n• Emergency assistance\n\nJust tell me what symptoms you're experiencing!";
    }
    
    if (inputLower.contains('thank')) {
      return "You're welcome! Is there anything else I can help you with?";
    }
    
    if (inputLower.contains('emergency') || inputLower.contains('urgent')) {
      return "For emergencies, please call your local emergency number immediately or go to the nearest hospital.";
    }

    final clarifyingQuestions = [
      "I need more information to help you. Could you describe your symptoms?",
      "What are you feeling exactly? For example: fever, headache, pain, etc.",
    ];
    
    return clarifyingQuestions[DateTime.now().millisecond % clarifyingQuestions.length];
  }

  void submitFeedback(String diagnosis, bool wasCorrect) {
    _brain.learn(diagnosis, wasCorrect);
    _conversationHistory.add({
      'user': 'Feedback: $diagnosis was ${wasCorrect ? "correct" : "incorrect"}',
      'bot': wasCorrect 
          ? "Thank you! My neural network will learn from this feedback." 
          : "I'll adjust my weights to improve future accuracy.",
    });
  }

  List<Map<String, String>> getHistory() => _conversationHistory;

  void clearHistory() => _conversationHistory.clear();

  Map<String, dynamic> getStats() => _brain.getBrainStats();
}
