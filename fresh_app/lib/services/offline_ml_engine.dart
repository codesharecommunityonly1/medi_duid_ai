import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RLState {
  final List<String> symptoms;
  final Map<String, double> symptomFeatures;
  final DateTime timestamp;

  RLState({
    required this.symptoms,
    required this.symptomFeatures,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'symptoms': symptoms,
    'symptomFeatures': symptomFeatures,
    'timestamp': timestamp.toIso8601String(),
  };

  String get stateVector => symptoms.join('|');
}

class RLAction {
  final String diseaseId;
  final String diseaseName;
  final double confidence;

  RLAction({
    required this.diseaseId,
    required this.diseaseName,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'diseaseId': diseaseId,
    'diseaseName': diseaseName,
    'confidence': confidence,
  };
}

class RLReward {
  final double reward;
  final bool isCorrect;
  final String feedback;
  final double confidence;

  RLReward({
    required this.reward,
    required this.isCorrect,
    required this.feedback,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'reward': reward,
    'isCorrect': isCorrect,
    'feedback': feedback,
    'confidence': confidence,
  };
}

class RLTransition {
  final RLState state;
  final RLAction action;
  final RLReward reward;
  final RLState? nextState;
  final DateTime timestamp;

  RLTransition({
    required this.state,
    required this.action,
    required this.reward,
    this.nextState,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'state': state.toJson(),
    'action': action.toJson(),
    'reward': reward.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };
}

class OfflineMLEngine {
  static OfflineMLEngine? _instance;
  static OfflineMLEngine get instance => _instance ??= OfflineMLEngine._();
  OfflineMLEngine._();

  Database? _database;
  Map<String, List<double>> _diseaseWeights = {};
  Map<String, String> _diseaseNames = {};
  Map<String, double> _diseaseBaseProbabilities = {};
  bool _isInitialized = false;
  List<RLTransition> _experienceReplay = [];
  
  static const int MAX_EXPERIENCE_REPLAY = 1000;
  static const double LEARNING_RATE = 0.1;
  static const double DISCOUNT_FACTOR = 0.9;

  bool get isInitialized => _isInitialized;
  List<RLTransition> get experienceReplay => _experienceReplay;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _initDatabase();
    await _initializeMLModel();
    _isInitialized = true;
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medai_rl.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE disease_weights (
            disease_id TEXT PRIMARY KEY,
            weights TEXT,
            base_probability REAL DEFAULT 0.1,
            confirmation_count INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE rl_experiences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            state TEXT,
            action TEXT,
            reward REAL,
            is_correct INTEGER,
            timestamp TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE diagnosis_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            symptoms TEXT,
            predicted_disease TEXT,
            actual_disease TEXT,
            confidence REAL,
            was_confirmed INTEGER,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  Future<void> _initializeMLModel() async {
    final conditions = _getMedicalConditions();
    
    for (final condition in conditions) {
      final diseaseId = condition['id'];
      final diseaseName = condition['name'];
      final symptoms = (condition['symptoms'] as String).split('|');
      final severity = condition['severity'];

      double baseProb = 0.1;
      switch (severity) {
        case 'critical': baseProb = 0.05; break;
        case 'severe': baseProb = 0.1; break;
        case 'moderate': baseProb = 0.15; break;
        case 'mild': baseProb = 0.2; break;
      }

      _diseaseNames[diseaseId] = diseaseName;
      _diseaseBaseProbabilities[diseaseId] = baseProb;

      final weights = <double>[];
      for (int i = 0; i < symptoms.length; i++) {
        double weight = 1.0;
        final symptom = symptoms[i].toLowerCase();
        
        if (_isCriticalSymptom(symptom)) {
          weight = severity == 'critical' ? 2.0 : 1.5;
        }
        
        weights.add(weight);
      }
      
      _diseaseWeights[diseaseId] = weights;
    }

    await _loadLearnedWeights();
  }

  bool _isCriticalSymptom(String symptom) {
    final criticalSymptoms = [
      'chest pain', 'difficulty breathing', 'unconscious', 'severe bleeding',
      'seizure', 'stroke', 'heart attack', 'anaphylaxis', 'cannot breathe',
      'stopped breathing', 'no pulse', 'severe burn', 'poisoning',
    ];
    return criticalSymptoms.any((s) => symptom.contains(s));
  }

  List<Map<String, dynamic>> _getMedicalConditions() {
    return [
      {'id': 'flu', 'name': 'Influenza (Flu)', 'symptoms': 'fever|cough|body ache|fatigue|headache|sore throat|runny nose', 'severity': 'moderate'},
      {'id': 'cold', 'name': 'Common Cold', 'symptoms': 'runny nose|sneezing|sore throat|cough|mild fever', 'severity': 'mild'},
      {'id': 'fever', 'name': 'Fever', 'symptoms': 'high temperature|chills|sweating|headache|body ache|weakness', 'severity': 'moderate'},
      {'id': 'malaria', 'name': 'Malaria', 'symptoms': 'fever|chills|sweating|headache|body ache|nausea|vomiting', 'severity': 'severe'},
      {'id': 'dengue', 'name': 'Dengue Fever', 'symptoms': 'high fever|severe headache|eye pain|joint pain|muscle pain|rash', 'severity': 'severe'},
      {'id': 'typhoid', 'name': 'Typhoid', 'symptoms': 'prolonged fever|weakness|headache|stomach pain|constipation|diarrhea', 'severity': 'severe'},
      {'id': 'diabetes', 'name': 'Diabetes', 'symptoms': 'frequent urination|excessive thirst|hunger|fatigue|blurred vision', 'severity': 'moderate'},
      {'id': 'hypertension', 'name': 'Hypertension', 'symptoms': 'headache|shortness of breath|nosebleeds|chest pain|dizziness', 'severity': 'moderate'},
      {'id': 'asthma', 'name': 'Asthma', 'symptoms': 'shortness of breath|wheezing|coughing|chest tightness', 'severity': 'moderate'},
      {'id': 'chest_pain', 'name': 'Chest Pain', 'symptoms': 'chest pain|pressure|shortness of breath|sweating|nausea|arm pain', 'severity': 'critical'},
      {'id': 'heart_attack', 'name': 'Heart Attack', 'symptoms': 'chest pain|arm pain|shortness of breath|sweating|nausea|dizziness', 'severity': 'critical'},
      {'id': 'stroke', 'name': 'Stroke', 'symptoms': 'face drooping|arm weakness|slurred speech|confusion|vision loss|severe headache', 'severity': 'critical'},
      {'id': 'bleeding', 'name': 'Severe Bleeding', 'symptoms': 'heavy bleeding|blood spurting|cannot stop bleeding|dizziness|pale skin', 'severity': 'critical'},
      {'id': 'burn', 'name': 'Burn Injury', 'symptoms': 'red skin|blistering|pain|swelling|charred skin', 'severity': 'moderate'},
      {'id': 'fracture', 'name': 'Fracture', 'symptoms': 'severe pain|swelling|deformity|cannot move|bruising', 'severity': 'moderate'},
      {'id': 'choking', 'name': 'Choking', 'symptoms': 'cannot breathe|gasping|blue lips|panicked|hand to throat', 'severity': 'critical'},
      {'id': 'drowning', 'name': 'Drowning', 'symptoms': 'no breathing|blue lips|unconscious|cold skin|water in mouth', 'severity': 'critical'},
      {'id': 'poisoning', 'name': 'Poisoning', 'symptoms': 'nausea|vomiting|confusion|seizures|difficulty breathing', 'severity': 'critical'},
      {'id': 'snake_bite', 'name': 'Snake Bite', 'symptoms': 'puncture wounds|swelling|pain|nausea|blurred vision|breathing difficulty', 'severity': 'critical'},
      {'id': 'heat_stroke', 'name': 'Heat Stroke', 'symptoms': 'high temperature|confusion|delirium|hot dry skin|rapid pulse', 'severity': 'critical'},
      {'id': 'hypothermia', 'name': 'Hypothermia', 'symptoms': 'shivering|confusion|slow speech|loss of coordination|drowsiness', 'severity': 'severe'},
      {'id': 'seizure', 'name': 'Seizure', 'symptoms': 'convulsions|unconscious|stiffening|jerking|confusion after', 'severity': 'critical'},
      {'id': 'allergy', 'name': 'Allergic Reaction', 'symptoms': 'swelling|hives|itching|difficulty breathing|wheezing|throat tightness', 'severity': 'critical'},
      {'id': 'food_poisoning', 'name': 'Food Poisoning', 'symptoms': 'nausea|vomiting|diarrhea|stomach cramps|fever|weakness', 'severity': 'moderate'},
      {'id': 'headache', 'name': 'Headache', 'symptoms': 'head pain|pressure|sensitivity to light|nausea|dizziness', 'severity': 'mild'},
      {'id': 'cough', 'name': 'Cough', 'symptoms': 'coughing|throat irritation|phlegm|chest pain|shortness of breath', 'severity': 'mild'},
      {'id': 'diarrhea', 'name': 'Diarrhea', 'symptoms': 'loose stools|abdominal cramps|nausea|urgency|dehydration', 'severity': 'mild'},
      {'id': 'vomiting', 'name': 'Vomiting', 'symptoms': 'nausea|throwing up|stomach pain|headache|fever', 'severity': 'moderate'},
    ];
  }

  List<Map<String, dynamic>> getConditions() => _getMedicalConditions();

  RLState createState(List<String> symptoms) {
    final features = <String, double>{};
    
    for (final symptom in symptoms) {
      features[symptom.toLowerCase()] = 1.0;
    }

    return RLState(symptoms: symptoms, symptomFeatures: features);
  }

  List<RLAction> forwardPass(RLState state) {
    final actions = <RLAction>[];
    final normalizedSymptoms = state.symptoms.map((s) => s.toLowerCase()).toList();

    for (final entry in _diseaseWeights.entries) {
      final diseaseId = entry.key;
      final weights = entry.value;
      final baseProb = _diseaseBaseProbabilities[diseaseId] ?? 0.1;
      final diseaseName = _diseaseNames[diseaseId] ?? diseaseId;

      int matchCount = 0;
      double totalWeight = 0.0;

      for (final symptom in normalizedSymptoms) {
        for (int i = 0; i < weights.length; i++) {
          final diseaseSymptom = _getMedicalConditions()
              .firstWhere((c) => c['id'] == diseaseId, orElse: () => {'symptoms': ''})['symptoms']!
              .split('|');
          
          if (i < diseaseSymptom.length && 
              (diseaseSymptom[i].contains(symptom) || symptom.contains(diseaseSymptom[i]))) {
            matchCount++;
            totalWeight += weights[i];
            break;
          }
        }
      }

      if (matchCount > 0) {
        final confidence = _calculateConfidence(baseProb, matchCount, totalWeight, normalizedSymptoms.length);
        
        actions.add(RLAction(
          diseaseId: diseaseId,
          diseaseName: diseaseName,
          confidence: confidence,
        ));
      }
    }

    actions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return actions.take(10).toList();
  }

  double _calculateConfidence(double baseProb, int matches, double totalWeight, int totalSymptoms) {
    final matchRatio = matches / max(totalSymptoms, 1);
    final weightScore = totalWeight / max(matches, 1);
    
    double confidence = baseProb + (matchRatio * 0.5) + (weightScore * 0.2);
    return confidence.clamp(0.0, 1.0);
  }

  RLReward computeReward(RLAction action, String actualDisease) {
    final isCorrect = action.diseaseId == actualDisease;
    
    double reward;
    String feedback;

    if (isCorrect) {
      reward = 1.0;
      feedback = 'Correct diagnosis! The AI predicted correctly.';
    } else {
      reward = -0.5;
      feedback = 'Incorrect. The actual condition was different.';
    }

    return RLReward(
      reward: reward,
      isCorrect: isCorrect,
      feedback: feedback,
      confidence: action.confidence,
    );
  }

  Future<void> updateWeights(RLAction action, RLReward reward) async {
    if (!_diseaseWeights.containsKey(action.diseaseId)) return;

    final weights = _diseaseWeights[action.diseaseId]!;
    
    if (reward.isCorrect) {
      for (int i = 0; i < weights.length; i++) {
        weights[i] = (weights[i] + LEARNING_RATE).clamp(0.5, 3.0);
      }
      _diseaseBaseProbabilities[action.diseaseId] = 
          (_diseaseBaseProbabilities[action.diseaseId]! + 0.05).clamp(0.01, 0.5);
    } else {
      for (int i = 0; i < weights.length; i++) {
        weights[i] = (weights[i] - LEARNING_RATE * 0.5).clamp(0.5, 3.0);
      }
      _diseaseBaseProbabilities[action.diseaseId] = 
          (_diseaseBaseProbabilities[action.diseaseId]! - 0.02).clamp(0.01, 0.5);
    }

    _diseaseWeights[action.diseaseId] = weights;
    await _saveLearnedWeights(action.diseaseId);
  }

  void storeTransition(RLTransition transition) {
    _experienceReplay.add(transition);
    
    if (_experienceReplay.length > MAX_EXPERIENCE_REPLAY) {
      _experienceReplay.removeAt(0);
    }
  }

  Future<void> _saveLearnedWeights(String diseaseId) async {
    if (_database == null) return;
    
    await _database!.insert('disease_weights', {
      'disease_id': diseaseId,
      'weights': jsonEncode(_diseaseWeights[diseaseId]),
      'base_probability': _diseaseBaseProbabilities[diseaseId],
      'confirmation_count': (_diseaseWeights[diseaseId]?.length ?? 0),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _loadLearnedWeights() async {
    if (_database == null) return;
    
    final results = await _database!.query('disease_weights');
    for (final row in results) {
      final diseaseId = row['disease_id'] as String;
      final weightsJson = row['weights'] as String?;
      
      if (weightsJson != null) {
        final weights = (jsonDecode(weightsJson) as List).cast<double>();
        _diseaseWeights[diseaseId] = weights;
      }
      
      _diseaseBaseProbabilities[diseaseId] = row['base_probability'] as double;
    }
  }

  Map<String, dynamic> getModelStats() {
    return {
      'modelType': 'Offline Symptom-Disease Classifier',
      'algorithm': 'Weighted Feature Matching with RL Learning',
      'totalDiseases': _diseaseWeights.length,
      'totalParameters': _diseaseWeights.values.fold(0, (sum, w) => sum + w.length),
      'experienceReplaySize': _experienceReplay.length,
      'learningRate': LEARNING_RATE,
      'offline': true,
      'accuracy': _calculateAccuracy(),
      'version': '2.0.0-RL',
    };
  }

  double _calculateAccuracy() {
    if (_experienceReplay.isEmpty) return 0.0;
    
    final correct = _experienceReplay.where((t) => t.reward.isCorrect).length;
    return correct / _experienceReplay.length;
  }

  Future<void> resetLearning() async {
    _experienceReplay.clear();
    _diseaseWeights.clear();
    _diseaseBaseProbabilities.clear();
    
    await _initializeMLModel();
    
    if (_database != null) {
      await _database!.delete('disease_weights');
      await _database!.delete('rl_experiences');
    }
  }
}

class MedAIRLEnvironment {
  final OfflineMLEngine _mlEngine = OfflineMLEngine.instance;
  
  RLState? _currentState;
  RLAction? _currentAction;
  int _episodeCount = 0;
  int _totalReward = 0;
  bool _done = false;

  Map<String, dynamic> reset(List<String> symptoms) {
    _currentState = _mlEngine.createState(symptoms);
    _currentAction = null;
    _done = false;
    _episodeCount++;

    return {
      'episode': _episodeCount,
      'state': _currentState!.toJson(),
      'actions': _mlEngine.forwardPass(_currentState!).map((a) => a.toJson()).toList(),
      'done': _done,
      'totalReward': _totalReward,
    };
  }

  Map<String, dynamic> step(String predictedDiseaseId, String actualDiseaseId) {
    if (_currentState == null) {
      return {'error': 'Environment not initialized. Call reset() first.'};
    }

    final availableActions = _mlEngine.forwardPass(_currentState!);
    final predictedAction = availableActions.firstWhere(
      (a) => a.diseaseId == predictedDiseaseId,
      orElse: () => availableActions.first,
    );

    final reward = _mlEngine.computeReward(predictedAction, actualDiseaseId);
    _totalReward += reward.reward.round();

    _mlEngine.updateWeights(predictedAction, reward);

    final transition = RLTransition(
      state: _currentState!,
      action: predictedAction,
      reward: reward,
    );
    _mlEngine.storeTransition(transition);

    _currentAction = predictedAction;
    _done = true;

    return {
      'episode': _episodeCount,
      'state': _currentState!.toJson(),
      'action': predictedAction.toJson(),
      'reward': reward.toJson(),
      'done': _done,
      'totalReward': _totalReward,
      'modelStats': _mlEngine.getModelStats(),
    };
  }

  Map<String, dynamic> state() {
    return {
      'episode': _episodeCount,
      'state': _currentState?.toJson(),
      'action': _currentAction?.toJson(),
      'done': _done,
      'totalReward': _totalReward,
    };
  }

  List<RLAction> getActions() {
    if (_currentState == null) return [];
    return _mlEngine.forwardPass(_currentState!);
  }

  Map<String, dynamic> getStats() {
    return {
      'episodeCount': _episodeCount,
      'totalReward': _totalReward,
      'averageReward': _episodeCount > 0 ? _totalReward / _episodeCount : 0,
      'modelStats': _mlEngine.getModelStats(),
    };
  }
}
