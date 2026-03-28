import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DiagnosisResult {
  final String conditionId;
  final String conditionName;
  final double confidence;
  final List<String> matchedSymptoms;
  final Map<String, double> symptomContributions;
  final String explanation;
  final RiskLevel riskLevel;
  final DateTime timestamp;

  DiagnosisResult({
    required this.conditionId,
    required this.conditionName,
    required this.confidence,
    required this.matchedSymptoms,
    required this.symptomContributions,
    required this.explanation,
    required this.riskLevel,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedConfidence => '${(confidence * 100).toStringAsFixed(0)}%';

  Map<String, dynamic> toJson() => {
    'conditionId': conditionId,
    'conditionName': conditionName,
    'confidence': confidence,
    'matchedSymptoms': matchedSymptoms,
    'symptomContributions': symptomContributions,
    'explanation': explanation,
    'riskLevel': riskLevel.name,
    'timestamp': timestamp.toIso8601String(),
  };
}

enum RiskLevel { high, medium, low }

class HealthRecord {
  final String id;
  final List<String> symptoms;
  final String? diagnosis;
  final double? confidence;
  final DateTime timestamp;
  final bool wasCorrect;

  HealthRecord({
    required this.id,
    required this.symptoms,
    this.diagnosis,
    this.confidence,
    DateTime? timestamp,
    this.wasCorrect = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'symptoms': symptoms,
    'diagnosis': diagnosis,
    'confidence': confidence,
    'timestamp': timestamp.toIso8601String(),
    'wasCorrect': wasCorrect,
  };
}

class AIBrain {
  static AIBrain? _instance;
  static AIBrain get instance => _instance ??= AIBrain._();
  AIBrain._();

  final SymptomModel _symptomModel = SymptomModel();
  final RLEnvironment _rlEnvironment = RLEnvironment(name: 'MedicalDiagnosis', description: 'RL for medical diagnosis');
  final ConfidenceSystem _confidenceSystem = ConfidenceSystem();
  final DemoMode _demoMode = DemoMode();
  bool _isInitialized = false;
  int _totalDiagnoses = 0;
  int _correctDiagnoses = 0;
  List<HealthRecord> _healthHistory = [];
  Map<String, int> _symptomFrequency = {};
  Map<String, List<String>> _conditionSymptomsMap = {};

  bool get isInitialized => _isInitialized;
  int get totalDiagnoses => _totalDiagnoses;
  int get correctDiagnoses => _correctDiagnoses;
  double get accuracy => _totalDiagnoses > 0 ? _correctDiagnoses / _totalDiagnoses : 0.0;
  SymptomModel get symptomModel => _symptomModel;
  RLEnvironment get rlEnvironment => _rlEnvironment;
  ConfidenceSystem get confidenceSystem => _confidenceSystem;
  DemoMode get demoMode => _demoMode;
  List<HealthRecord> get healthHistory => _healthHistory;

  Future<void> initialize(List<Map<String, dynamic>> conditions) async {
    if (_isInitialized) return;

    await _loadHealthHistory();

    final weights = <String, List<double>>{};
    final biases = <String, double>{};

    for (final condition in conditions) {
      final id = condition['id'] as String;
      final severity = condition['severity'] as String;
      final symptoms = condition['symptoms'] as List<String>? ?? [];
      final name = condition['name'] as String? ?? '';

      _conditionSymptomsMap[id] = symptoms;

      double severityWeight = 1.0;
      switch (severity) {
        case 'critical':
          severityWeight = 1.5;
          break;
        case 'severe':
          severityWeight = 1.3;
          break;
        case 'moderate':
          severityWeight = 1.1;
          break;
        default:
          severityWeight = 1.0;
      }

      final userAdjustedWeight = _getUserAdjustedWeight(id, severityWeight);
      
      final symptomWeights = List<double>.generate(
        symptoms.length > 10 ? 10 : symptoms.length,
        (i) => userAdjustedWeight * (1.0 - (i * 0.05)),
      );

      weights[id] = symptomWeights;
      biases[id] = userAdjustedWeight * 0.5;
    }

    _symptomModel.initialize(weights, biases);
    _rlEnvironment.reset([]);
    _isInitialized = true;
  }

  double _getUserAdjustedWeight(String conditionId, double baseWeight) {
    final correctCount = _healthHistory
        .where((r) => r.diagnosis == conditionId && r.wasCorrect)
        .length;
    final wrongCount = _healthHistory
        .where((r) => r.diagnosis == conditionId && !r.wasCorrect)
        .length;
    
    if (correctCount + wrongCount > 0) {
      final feedbackRatio = correctCount / (correctCount + wrongCount);
      return baseWeight * (0.5 + (feedbackRatio * 0.5));
    }
    return baseWeight;
  }

  DiagnosisResult diagnose(String conditionId, String conditionName, List<String> symptoms, RiskLevel riskLevel) {
    _totalDiagnoses++;
    _rlEnvironment.reset(symptoms);
    
    final contributions = <String, double>{};
    final matchedSymptoms = <String>[];
    
    for (final symptom in symptoms) {
      final normalizedSymptom = symptom.toLowerCase();
      final conditionSymptoms = _conditionSymptomsMap[conditionId] ?? [];
      
      for (final cs in conditionSymptoms) {
        if (cs.toLowerCase().contains(normalizedSymptom) || 
            normalizedSymptom.contains(cs.toLowerCase())) {
          matchedSymptoms.add(symptom);
          contributions[symptom] = (contributions[symptom] ?? 0) + 0.3;
          break;
        }
      }
    }

    final confidence = _symptomModel.predict(symptoms);
    final explanation = _generateExplanation(symptoms, conditionName, matchedSymptoms);

    _symptomModel.incrementSymptomFrequency(symptoms);

    final action = Action(diseaseId: conditionId, action: 'diagnose', confidence: confidence);
    _rlEnvironment.step(action);

    return DiagnosisResult(
      conditionId: conditionId,
      conditionName: conditionName,
      confidence: confidence.clamp(0.0, 1.0),
      matchedSymptoms: matchedSymptoms,
      symptomContributions: contributions,
      explanation: explanation,
      riskLevel: riskLevel,
    );
  }

  String _generateExplanation(List<String> userSymptoms, String conditionName, List<String> matchedSymptoms) {
    final buffer = StringBuffer();
    buffer.writeln("Why $conditionName?");
    buffer.writeln("");
    
    if (matchedSymptoms.isNotEmpty) {
      buffer.writeln("✓ Matched symptoms:");
      for (final symptom in matchedSymptoms.take(5)) {
        buffer.writeln("  • $symptom");
      }
    } else {
      buffer.writeln("• Pattern matches $conditionName symptoms");
    }
    
    buffer.writeln("");
    buffer.writeln("Analysis based on:");
    buffer.writeln("• Symptom matching algorithm");
    buffer.writeln("• Severity weighting");
    if (_healthHistory.any((r) => r.diagnosis == conditionIdFromName(conditionName))) {
      buffer.writeln("• Your previous feedback on this condition");
    }
    
    return buffer.toString();
  }

  String conditionIdFromName(String name) {
    for (final entry in _conditionSymptomsMap.entries) {
      if (entry.value.any((s) => s.toLowerCase().contains(name.toLowerCase()))) {
        return entry.key;
      }
    }
    return name.toLowerCase().replaceAll(' ', '_');
  }

  Future<void> submitFeedback(HealthRecord record, bool wasCorrect) async {
    final updatedRecord = HealthRecord(
      id: record.id,
      symptoms: record.symptoms,
      diagnosis: record.diagnosis,
      confidence: record.confidence,
      timestamp: record.timestamp,
      wasCorrect: wasCorrect,
    );

    _healthHistory.add(updatedRecord);
    
    if (wasCorrect) {
      _correctDiagnoses++;
      _symptomModel.updateWeightsOnFeedback(record.symptoms, record.diagnosis ?? '', 1);
    } else {
      _symptomModel.updateWeightsOnFeedback(record.symptoms, record.diagnosis ?? '', -1);
    }

    final action = Action(
      diseaseId: record.diagnosis ?? '', 
      action: 'feedback', 
      confidence: wasCorrect ? 1.0 : -1.0
    );
    _rlEnvironment.step(action);

    await _saveHealthHistory();
  }

  Future<void> _loadHealthHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('health_history');
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        _healthHistory = decoded.map((e) => HealthRecord(
          id: e['id'],
          symptoms: List<String>.from(e['symptoms']),
          diagnosis: e['diagnosis'],
          confidence: e['confidence']?.toDouble(),
          timestamp: DateTime.parse(e['timestamp']),
          wasCorrect: e['wasCorrect'] ?? false,
        )).toList();
      }
    } catch (e) {
      _healthHistory = [];
    }
  }

  Future<void> _saveHealthHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = json.encode(_healthHistory.map((e) => e.toJson()).toList());
    await prefs.setString('health_history', historyJson);
  }

  Map<String, int> getSymptomFrequency() {
    return _symptomModel.getSymptomFrequency();
  }

  List<Map<String, dynamic>> getChronicPatterns() {
    final patterns = <Map<String, dynamic>>[];
    final symptomCounts = <String, int>{};
    
    for (final record in _healthHistory) {
      for (final symptom in record.symptoms) {
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
      }
    }
    
    for (final entry in symptomCounts.entries) {
      if (entry.value >= 3) {
        patterns.add({
          'symptom': entry.key,
          'count': entry.value,
          'possibleCause': _suggestPossibleCause(entry.key),
        });
      }
    }
    
    return patterns;
  }

  String _suggestPossibleCause(String symptom) {
    final chronicSuggestions = {
      'headache': 'Possible chronic tension or migraine - consult doctor',
      'fever': 'Recurring fever - possible infection, get tested',
      'fatigue': 'Chronic fatigue - check anemia, thyroid',
      'cough': 'Persistent cough - possible respiratory issue',
      'body ache': 'Frequent body pain - check vitamin D, B12',
    };
    return chronicSuggestions[symptom.toLowerCase()] ?? 'Frequent symptom - monitor and consult doctor';
  }

  Map<String, dynamic> getStats() {
    return {
      'totalDiagnoses': _totalDiagnoses,
      'correctDiagnoses': _correctDiagnoses,
      'accuracy': accuracy,
      'isInitialized': _isInitialized,
      'healthHistoryCount': _healthHistory.length,
      'chronicPatterns': getChronicPatterns(),
      'rlStats': _rlEnvironment.getStats(),
    };
  }
}

class SymptomModel {
  final Map<String, List<double>> _weights;
  final Map<String, double> _biases;
  bool _isInitialized = false;

  SymptomModel()
      : _weights = {},
        _biases = {};

  bool get isInitialized => _isInitialized;

  void initialize(Map<String, List<double>> weights, Map<String, double> biases) {
    _weights.clear();
    _weights.addAll(weights);
    _biases.clear();
    _biases.addAll(biases);
    _isInitialized = true;
  }

  double predict(List<String> symptoms) {
    if (!_isInitialized || symptoms.isEmpty) return 0.0;

    double score = 0.0;
    final normalizedSymptoms = symptoms.map((s) => s.toLowerCase()).toList();

    for (final entry in _weights.entries) {
      final diseaseId = entry.key;
      final weights = entry.value;
      double diseaseScore = 0.0;

      for (int i = 0; i < weights.length && i < normalizedSymptoms.length; i++) {
        diseaseScore += weights[i] * 1.0;
      }

      diseaseScore += _biases[diseaseId] ?? 0.0;
      score = max(score, diseaseScore);
    }

    return score.clamp(0.0, 1.0);
  }

  Map<String, double> predictAll(Map<String, List<String>> diseaseSymptoms, List<String> userSymptoms) {
    final results = <String, double>{};
    final normalizedUserSymptoms = userSymptoms.map((s) => s.toLowerCase()).toList();

    for (final entry in diseaseSymptoms.entries) {
      final diseaseId = entry.key;
      final diseaseSymptomList = entry.value.map((s) => s.toLowerCase()).toList();

      double score = 0.0;
      int matches = 0;

      for (final userSymptom in normalizedUserSymptoms) {
        for (final diseaseSymptom in diseaseSymptomList) {
          if (diseaseSymptom.contains(userSymptom) || userSymptom.contains(diseaseSymptom)) {
            matches++;
            break;
          }
        }
      }

      if (matches > 0) {
        score = matches / max(normalizedUserSymptoms.length, 1);
        final weight = _weights[diseaseId];
        if (weight != null) {
          score *= (weight.reduce((a, b) => a + b) / max(weight.length, 1));
        }
        score = score.clamp(0.0, 1.0);
      }

      results[diseaseId] = score;
    }

    return results;
  }

  final Map<String, int> _symptomFrequency = {};

  void incrementSymptomFrequency(List<String> symptoms) {
    for (final symptom in symptoms) {
      _symptomFrequency[symptom] = (_symptomFrequency[symptom] ?? 0) + 1;
    }
  }

  Map<String, int> getSymptomFrequency() {
    final sorted = _symptomFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  void updateWeightsOnFeedback(List<String> symptoms, String conditionId, int feedback) {
    if (!_weights.containsKey(conditionId)) return;
    
    final weights = _weights[conditionId]!;
    final adjustment = feedback * 0.1;

    for (int i = 0; i < weights.length && i < symptoms.length; i++) {
      weights[i] = (weights[i] + adjustment).clamp(0.1, 2.0);
    }

    _biases[conditionId] = (_biases[conditionId] ?? 1.0) + (adjustment * 0.5);
  }
}

class RLEnvironment {
  final String name;
  final String description;
  late RLState _currentState;
  late Action _currentAction;
  late Reward _currentReward;
  int _stepCount = 0;
  bool _done = false;
  final List<Transition> _history = [];

  RLEnvironment({required this.name, required this.description});

  RLState getState() => _currentState;
  Action getAction() => _currentAction;
  Reward getReward() => _currentReward;
  bool isDone() => _done;
  int getStepCount() => _stepCount;
  List<Transition> getHistory() => _history;

  RLState reset(List<String> symptoms) {
    _currentState = RLState(symptoms: symptoms, step: 0);
    _currentAction = Action(diseaseId: '', action: '');
    _currentReward = Reward(value: 0.0, feedback: '');
    _stepCount = 0;
    _done = false;
    _history.clear();
    return _currentState;
  }

  Transition step(Action action) {
    _currentAction = action;
    _stepCount++;

    final reward = _calculateReward(action);
    _currentReward = reward;

    final transition = Transition(
      state: _currentState,
      action: action,
      reward: reward,
      nextState: _currentState,
    );

    _history.add(transition);

    if (_stepCount >= 10) {
      _done = true;
    }

    return transition;
  }

  Reward _calculateReward(Action action) {
    if (_currentState.symptoms.isEmpty) {
      return Reward(value: 0.0, feedback: 'No symptoms provided');
    }

    if (action.diseaseId.isEmpty) {
      return Reward(value: -0.5, feedback: 'No action taken');
    }

    double rewardValue = 0.5;

    final criticalSymptoms = ['chest pain', 'difficulty breathing', 'unconscious', 'severe bleeding'];
    final hasCritical = _currentState.symptoms.any((s) => 
      criticalSymptoms.any((c) => s.toLowerCase().contains(c))
    );

    if (hasCritical && action.diseaseId.contains('emergency')) {
      rewardValue = 1.0;
    } else if (hasCritical && !action.diseaseId.contains('emergency')) {
      rewardValue = -0.5;
    }

    return Reward(value: rewardValue, feedback: 'Action evaluated');
  }

  Map<String, dynamic> getStats() {
    final totalReward = _history.fold(0.0, (sum, t) => sum + t.reward.value);
    final avgReward = _history.isEmpty ? 0.0 : totalReward / _history.length;

    return {
      'name': name,
      'description': description,
      'totalSteps': _stepCount,
      'totalReward': totalReward,
      'averageReward': avgReward,
      'isDone': _done,
      'historyLength': _history.length,
    };
  }
}

class RLState {
  final List<String> symptoms;
  final int step;
  final Map<String, dynamic>? metadata;

  RLState({
    required this.symptoms,
    required this.step,
    this.metadata,
  });

  String get stateVector => symptoms.join('|');

  Map<String, dynamic> toJson() => {
    'symptoms': symptoms,
    'step': step,
    'stateVector': stateVector,
    'metadata': metadata,
  };
}

class Action {
  final String diseaseId;
  final String action;
  final double confidence;

  Action({
    required this.diseaseId,
    required this.action,
    this.confidence = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'diseaseId': diseaseId,
    'action': action,
    'confidence': confidence,
  };
}

class Reward {
  final double value;
  final String feedback;

  Reward({
    required this.value,
    required this.feedback,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    'feedback': feedback,
  };
}

class Transition {
  final RLState state;
  final Action action;
  final Reward reward;
  final RLState? nextState;

  Transition({
    required this.state,
    required this.action,
    required this.reward,
    this.nextState,
  });

  Map<String, dynamic> toJson() => {
    'state': state.toJson(),
    'action': action.toJson(),
    'reward': reward.toJson(),
    'nextState': nextState?.toJson(),
  };
}

class ConfidenceSystem {
  static Map<String, double> calculateConfidence(
    Map<String, List<String>> diseaseSymptoms,
    List<String> userSymptoms,
  ) {
    final results = <String, double>{};
    final normalizedUserSymptoms = userSymptoms.map((s) => s.toLowerCase()).toList();

    for (final entry in diseaseSymptoms.entries) {
      final diseaseId = entry.key;
      final diseaseSymptomList = entry.value.map((s) => s.toLowerCase()).toList();

      int matchCount = 0;
      final matchedSymptoms = <String>[];

      for (final userSymptom in normalizedUserSymptoms) {
        for (final diseaseSymptom in diseaseSymptomList) {
          if (diseaseSymptom.contains(userSymptom) || userSymptom.contains(diseaseSymptom)) {
            matchCount++;
            matchedSymptoms.add(diseaseSymptom);
            break;
          }
        }
      }

      if (matchCount > 0) {
        double confidence = matchCount / normalizedUserSymptoms.length;
        
        final severityBonus = _getSeverityBonus(diseaseId);
        confidence = (confidence * (1 + severityBonus)).clamp(0.0, 1.0);
        
        results[diseaseId] = confidence;
      }
    }

    final sortedEntries = results.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  static double _getSeverityBonus(String diseaseId) {
    final criticalDiseases = [
      'heart_attack', 'stroke', 'choking', 'drowning', 'poisoning',
      'snake_bite', 'heat_stroke', 'seizure', 'bleeding', 'allergy',
    ];
    
    final severeDiseases = [
      'malaria', 'dengue', 'typhoid', 'asthma', 'diabetes',
      'hypertension', 'fracture', 'burn', 'hypothermia',
    ];

    if (criticalDiseases.any((d) => diseaseId.contains(d))) {
      return 0.2;
    } else if (severeDiseases.any((d) => diseaseId.contains(d))) {
      return 0.1;
    }
    return 0.0;
  }

  static String formatConfidence(double confidence) {
    return '${(confidence * 100).toStringAsFixed(0)}%';
  }

  static Map<String, double> calculateConfidenceWithWeights(SymptomModel model, List<String> userSymptoms) {
    final results = <String, double>{};
    final normalizedUserSymptoms = userSymptoms.map((s) => s.toLowerCase()).toList();

    for (final entry in model._weights.entries) {
      final diseaseId = entry.key;
      final weights = entry.value;

      int matchCount = 0;
      double weightSum = 0.0;

      for (int i = 0; i < weights.length && i < normalizedUserSymptoms.length; i++) {
        matchCount++;
        weightSum += weights[i];
      }

      if (matchCount > 0) {
        double baseConfidence = matchCount / normalizedUserSymptoms.length;
        double weightedConfidence = baseConfidence * (weightSum / weights.length);
        
        final severityBonus = _getSeverityBonus(diseaseId);
        weightedConfidence = (weightedConfidence * (1 + severityBonus)).clamp(0.0, 1.0);
        
        results[diseaseId] = weightedConfidence;
      }
    }

    final sortedEntries = results.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }
}

class DemoMode {
  final List<DemoScenario> scenarios;

  DemoMode()
      : scenarios = [
          DemoScenario(
            id: 'demo_1',
            name: 'Fever & Headache',
            symptoms: ['fever', 'headache', 'body ache', 'fatigue'],
            expectedDiagnosis: 'Flu',
            description: 'Common flu symptoms',
            severity: 'mild',
          ),
          DemoScenario(
            id: 'demo_2',
            name: 'Chest Pain Emergency',
            symptoms: ['chest pain', 'shortness of breath', 'sweating'],
            expectedDiagnosis: 'Heart Attack',
            description: 'Cardiac emergency - critical',
            severity: 'critical',
          ),
          DemoScenario(
            id: 'demo_3',
            name: 'Burn Injury',
            symptoms: ['red skin', 'pain', 'blistering'],
            expectedDiagnosis: 'Burn',
            description: 'Thermal burn first aid',
            severity: 'moderate',
          ),
          DemoScenario(
            id: 'demo_4',
            name: 'Dengue Fever',
            symptoms: ['high fever', 'severe headache', 'joint pain', 'rash'],
            expectedDiagnosis: 'Dengue',
            description: 'Mosquito-borne disease',
            severity: 'severe',
          ),
          DemoScenario(
            id: 'demo_5',
            name: 'Snake Bite',
            symptoms: ['puncture wounds', 'swelling', 'pain'],
            expectedDiagnosis: 'Snake Bite',
            description: 'Venomous snake emergency',
            severity: 'critical',
          ),
          DemoScenario(
            id: 'demo_6',
            name: 'Heat Stroke',
            symptoms: ['high temperature', 'confusion', 'hot dry skin'],
            expectedDiagnosis: 'Heat Stroke',
            description: 'Heat-related emergency',
            severity: 'severe',
          ),
          DemoScenario(
            id: 'demo_7',
            name: 'Food Poisoning',
            symptoms: ['vomiting', 'diarrhea', 'stomach cramps', 'nausea'],
            expectedDiagnosis: 'Food Poisoning',
            description: 'Contaminated food reaction',
            severity: 'moderate',
          ),
          DemoScenario(
            id: 'demo_8',
            name: 'Asthma Attack',
            symptoms: ['shortness of breath', 'wheezing', 'coughing'],
            expectedDiagnosis: 'Asthma',
            description: 'Respiratory emergency',
            severity: 'severe',
          ),
          DemoScenario(
            id: 'demo_9',
            name: 'Diabetic Emergency',
            symptoms: ['confusion', 'sweating', 'shaking', 'fast heartbeat'],
            expectedDiagnosis: 'Hypoglycemia',
            description: 'Low blood sugar emergency',
            severity: 'critical',
          ),
          DemoScenario(
            id: 'demo_10',
            name: 'Stroke Signs (FAST)',
            symptoms: ['face drooping', 'arm weakness', 'speech difficulty', 'confusion'],
            expectedDiagnosis: 'Stroke',
            description: 'Act FAST - Time critical!',
            severity: 'critical',
          ),
          DemoScenario(
            id: 'demo_11',
            name: 'Allergic Reaction',
            symptoms: ['hives', 'swelling', 'difficulty breathing', 'dizziness'],
            expectedDiagnosis: 'Anaphylaxis',
            description: 'Severe allergic reaction',
            severity: 'critical',
          ),
          DemoScenario(
            id: 'demo_12',
            name: 'Fracture',
            symptoms: ['severe pain', 'swelling', 'unable to move', 'deformity'],
            expectedDiagnosis: 'Fracture',
            description: 'Bone break - do not move',
            severity: 'severe',
          ),
          DemoScenario(
            id: 'demo_13',
            name: 'Dehydration',
            symptoms: ['dry mouth', 'dizziness', 'dark urine', 'headache'],
            expectedDiagnosis: 'Dehydration',
            description: 'Need fluid replacement',
            severity: 'moderate',
          ),
        ];

  List<DemoScenario> getScenarios() => scenarios;
  
  DemoScenario? getScenario(String id) {
    try {
      return scenarios.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}

class DemoScenario {
  final String id;
  final String name;
  final List<String> symptoms;
  final String expectedDiagnosis;
  final String description;
  final String severity;

  DemoScenario({
    required this.id,
    required this.name,
    required this.symptoms,
    required this.expectedDiagnosis,
    required this.description,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'symptoms': symptoms,
    'expectedDiagnosis': expectedDiagnosis,
    'description': description,
    'severity': severity,
  };
}

class HospitalFinder {
  static Future<List<Map<String, dynamic>>> findNearbyHospitals(
    double latitude,
    double longitude, {
    int radiusKm = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      {
        'name': 'Government District Hospital',
        'address': 'Main Road, City Center',
        'distance': 2.5,
        'phone': '102',
        'type': 'Government',
        'emergency': true,
      },
      {
        'name': 'Primary Health Centre',
        'village': 'Nearby Village',
        'distance': 5.0,
        'phone': '',
        'type': 'PHC',
        'emergency': false,
      },
      {
        'name': 'Private Medical College',
        'address': 'Hospital Road',
        'distance': 8.0,
        'phone': '108',
        'type': 'Private',
        'emergency': true,
      },
    ];
  }

  static String getEmergencyNumber() {
    return '102';
  }

  static String getAmbulanceNumber() {
    return '108';
  }
}
