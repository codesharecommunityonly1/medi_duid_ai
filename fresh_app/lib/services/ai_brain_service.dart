import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiagnosisResult {
  final String conditionId;
  final String conditionName;
  final String conditionNameHi;
  final double confidence;
  final int matchedSymptoms;
  final int totalSymptoms;
  final String severity;
  final bool isEmergency;
  final List<String> matchedSymptomsList;
  final List<String> firstAid;
  final List<String> firstAidHi;

  DiagnosisResult({
    required this.conditionId,
    required this.conditionName,
    required this.conditionNameHi,
    required this.confidence,
    required this.matchedSymptoms,
    required this.totalSymptoms,
    required this.severity,
    required this.isEmergency,
    required this.matchedSymptomsList,
    required this.firstAid,
    required this.firstAidHi,
  });

  Map<String, dynamic> toJson() => {
    'conditionId': conditionId,
    'conditionName': conditionName,
    'conditionNameHi': conditionNameHi,
    'confidence': confidence,
    'matchedSymptoms': matchedSymptoms,
    'totalSymptoms': totalSymptoms,
    'severity': severity,
    'isEmergency': isEmergency,
    'matchedSymptomsList': matchedSymptomsList,
    'firstAid': firstAid,
    'firstAidHi': firstAidHi,
  };
}

class UserFeedback {
  final String id;
  final String conditionId;
  final List<String> symptoms;
  final bool wasCorrect;
  final DateTime timestamp;

  UserFeedback({
    required this.id,
    required this.conditionId,
    required this.symptoms,
    required this.wasCorrect,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'conditionId': conditionId,
    'symptoms': symptoms,
    'wasCorrect': wasCorrect,
    'timestamp': timestamp.toIso8601String(),
  };

  factory UserFeedback.fromJson(Map<String, dynamic> json) => UserFeedback(
    id: json['id'],
    conditionId: json['conditionId'],
    symptoms: List<String>.from(json['symptoms']),
    wasCorrect: json['wasCorrect'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class ConditionWeight {
  String conditionId;
  double weight;
  int confirmationCount;

  ConditionWeight({
    required this.conditionId,
    this.weight = 1.0,
    this.confirmationCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'conditionId': conditionId,
    'weight': weight,
    'confirmationCount': confirmationCount,
  };
}

class AIBrainService {
  static AIBrainService? _instance;
  static AIBrainService get instance => _instance ??= AIBrainService._();
  AIBrainService._();

  Database? _database;
  Map<String, ConditionWeight> _conditionWeights = {};
  List<UserFeedback> _feedbackHistory = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<UserFeedback> get feedbackHistory => _feedbackHistory;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _initDatabase();
    await _loadWeights();
    await _loadFeedback();
    _isInitialized = true;
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_brain.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE condition_weights (
            condition_id TEXT PRIMARY KEY,
            weight REAL DEFAULT 1.0,
            confirmation_count INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE user_feedback (
            id TEXT PRIMARY KEY,
            condition_id TEXT,
            symptoms TEXT,
            was_correct INTEGER,
            timestamp TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE diagnosis_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            symptoms TEXT,
            result_id TEXT,
            confidence REAL,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  Future<void> _loadWeights() async {
    if (_database == null) return;
    final results = await _database!.query('condition_weights');
    for (final row in results) {
      _conditionWeights[row['condition_id'] as String] = ConditionWeight(
        conditionId: row['condition_id'] as String,
        weight: row['weight'] as double,
        confirmationCount: row['confirmation_count'] as int,
      );
    }
  }

  Future<void> _loadFeedback() async {
    if (_database == null) return;
    final results = await _database!.query('user_feedback', orderBy: 'timestamp DESC', limit: 100);
    _feedbackHistory = results.map((row) => UserFeedback(
      id: row['id'] as String,
      conditionId: row['condition_id'] as String,
      symptoms: (row['symptoms'] as String).split('|'),
      wasCorrect: (row['was_correct'] as int) == 1,
      timestamp: DateTime.parse(row['timestamp'] as String),
    )).toList();
  }

  double _getConditionWeight(String conditionId) {
    return _conditionWeights[conditionId]?.weight ?? 1.0;
  }

  DiagnosisResult _createDiagnosisResult(
    Map<String, dynamic> condition,
    int matchCount,
    int totalSymptoms,
    List<String> matchedSymptoms,
  ) {
    final baseConfidence = (matchCount / totalSymptoms) * 100;
    final weight = _getConditionWeight(condition['id']);
    final confidence = (baseConfidence * weight).clamp(0, 100);

    final severity = condition['severity'] as String? ?? 'mild';
    final isEmergency = severity == 'critical' || severity == 'severe';

    return DiagnosisResult(
      conditionId: condition['id'] as String,
      conditionName: condition['name'] as String,
      conditionNameHi: condition['nameHi'] as String? ?? '',
      confidence: confidence.toDouble(),
      matchedSymptoms: matchCount,
      totalSymptoms: totalSymptoms,
      severity: severity,
      isEmergency: isEmergency,
      matchedSymptomsList: matchedSymptoms,
      firstAid: (condition['firstAid'] as String?)?.split('|') ?? [],
      firstAidHi: (condition['firstAidHi'] as String?)?.split('|') ?? [],
    );
  }

  List<DiagnosisResult> diagnose({
    required List<Map<String, dynamic>> conditions,
    required List<String> userSymptoms,
    bool enableLearning = true,
  }) {
    if (userSymptoms.isEmpty) return [];

    final normalizedUserSymptoms = userSymptoms
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final results = <DiagnosisResult>[];

    for (final condition in conditions) {
      final conditionSymptoms = (condition['symptoms'] as String?)
              ?.toLowerCase()
              .split('|')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [];

      int matchCount = 0;
      final matchedSymptoms = <String>[];

      for (final userSymptom in normalizedUserSymptoms) {
        for (final conditionSymptom in conditionSymptoms) {
          if (conditionSymptom.contains(userSymptom) || userSymptom.contains(conditionSymptom)) {
            matchCount++;
            matchedSymptoms.add(conditionSymptom);
            break;
          }
        }
      }

      if (matchCount > 0) {
        results.add(_createDiagnosisResult(
          condition,
          matchCount,
          normalizedUserSymptoms.length,
          matchedSymptoms,
        ));
      }
    }

    results.sort((a, b) {
      final severityOrder = {'critical': 0, 'severe': 1, 'moderate': 2, 'mild': 3};
      final severityCompare = (severityOrder[a.severity] ?? 4).compareTo(severityOrder[b.severity] ?? 4);
      if (severityCompare != 0) return severityCompare;
      return b.confidence.compareTo(a.confidence);
    });

    return results.take(10).toList();
  }

  Future<void> submitFeedback({
    required String conditionId,
    required List<String> symptoms,
    required bool wasCorrect,
  }) async {
    final feedback = UserFeedback(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conditionId: conditionId,
      symptoms: symptoms,
      wasCorrect: wasCorrect,
      timestamp: DateTime.now(),
    );

    _feedbackHistory.insert(0, feedback);

    if (_database != null) {
      await _database!.insert('user_feedback', {
        'id': feedback.id,
        'condition_id': feedback.conditionId,
        'symptoms': feedback.symptoms.join('|'),
        'was_correct': feedback.wasCorrect ? 1 : 0,
        'timestamp': feedback.timestamp.toIso8601String(),
      });
    }

    if (wasCorrect) {
      final currentWeight = _conditionWeights[conditionId];
      final newWeight = (currentWeight?.weight ?? 1.0) + 0.1;
      final newCount = (currentWeight?.confirmationCount ?? 0) + 1;

      _conditionWeights[conditionId] = ConditionWeight(
        conditionId: conditionId,
        weight: newWeight.clamp(0.5, 2.0),
        confirmationCount: newCount,
      );

      if (_database != null) {
        await _database!.insert('condition_weights', {
          'condition_id': conditionId,
          'weight': newWeight.clamp(0.5, 2.0),
          'confirmation_count': newCount,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Map<String, dynamic> getAIStats() {
    final totalDiagnoses = _feedbackHistory.length;
    final correctCount = _feedbackHistory.where((f) => f.wasCorrect).length;
    final accuracy = totalDiagnoses > 0 ? (correctCount / totalDiagnoses) * 100 : 0.0;

    final conditionAccuracy = <String, double>{};
    for (final feedback in _feedbackHistory) {
      final cond = feedback.conditionId;
      final double total = conditionAccuracy[cond] != null ? (conditionAccuracy[cond]! * 10 + (feedback.wasCorrect ? 1 : 0)) / 11 : (feedback.wasCorrect ? 100.0 : 0.0);
      conditionAccuracy[cond] = total;
    }

    return {
      'totalDiagnoses': totalDiagnoses,
      'correctPredictions': correctCount,
      'accuracy': accuracy,
      'conditionWeights': _conditionWeights.map((k, v) => MapEntry(k, v.toJson())),
      'recentFeedback': _feedbackHistory.take(10).map((f) => f.toJson()).toList(),
    };
  }

  Future<void> resetLearning() async {
    _conditionWeights.clear();
    _feedbackHistory.clear();
    if (_database != null) {
      await _database!.delete('condition_weights');
      await _database!.delete('user_feedback');
    }
  }
}

class EmergencyIntelligence {
  static final Map<String, List<String>> emergencyKeywords = {
    'breathing_difficulty': ['shortness of breath', 'cannot breathe', 'choking', 'drowning', 'asthma attack'],
    'cardiac': ['chest pain', 'heart attack', 'palpitations', 'irregular heartbeat', 'left arm pain'],
    'bleeding': ['heavy bleeding', 'severe bleeding', 'bleeding wont stop', 'arterial bleeding'],
    'stroke': ['face drooping', 'arm weakness', 'slurred speech', 'stroke symptoms', 'one side weak'],
    'seizure': ['seizure', 'convulsion', 'fitting', 'uncontrolled movement'],
    'unconscious': ['unconscious', 'unresponsive', 'fainted', 'collapsed', 'not waking up'],
    'allergic': ['anaphylaxis', 'throat swelling', 'severe allergic', 'bee sting reaction'],
    'poisoning': ['poison', 'toxic', 'overdose', 'swallowed poison', 'chemical burn'],
    'burns': ['severe burn', 'electrical burn', 'chemical burn', 'large area burn'],
    'fracture': ['broken bone', 'open fracture', 'spine injury', 'neck injury'],
  };

  static final Map<String, int> severityScores = {
    'critical': 100,
    'severe': 75,
    'moderate': 50,
    'mild': 25,
  };

  static EmergencyAssessment assessEmergency(List<String> symptoms) {
    final normalizedSymptoms = symptoms.map((s) => s.toLowerCase()).toList();
    
    int maxScore = 0;
    String? emergencyType;
    List<String> matchedKeywords = [];

    for (final entry in emergencyKeywords.entries) {
      for (final keyword in entry.value) {
        if (normalizedSymptoms.any((s) => s.contains(keyword))) {
          final score = severityScores[entry.key] ?? 50;
          if (score > maxScore) {
            maxScore = score;
            emergencyType = entry.key;
            matchedKeywords.add(keyword);
          }
        }
      }
    }

    return EmergencyAssessment(
      isEmergency: maxScore >= 50,
      severity: maxScore >= 75 ? 'critical' : (maxScore >= 50 ? 'severe' : (maxScore > 0 ? 'moderate' : 'none')),
      score: maxScore,
      emergencyType: emergencyType,
      matchedKeywords: matchedKeywords,
      recommendation: _getRecommendation(emergencyType, maxScore),
    );
  }

  static String _getRecommendation(String? type, int score) {
    if (score >= 75) {
      return 'IMMEDIATE EMERGENCY: Call 911/102 immediately. Do not wait.';
    } else if (score >= 50) {
      return 'URGENT: Seek medical attention within the hour.';
    } else if (score > 0) {
      return 'Monitor closely. Seek help if symptoms worsen.';
    }
    return 'Continue with standard first aid.';
  }
}

class EmergencyAssessment {
  final bool isEmergency;
  final String severity;
  final int score;
  final String? emergencyType;
  final List<String> matchedKeywords;
  final String recommendation;

  EmergencyAssessment({
    required this.isEmergency,
    required this.severity,
    required this.score,
    required this.emergencyType,
    required this.matchedKeywords,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
    'isEmergency': isEmergency,
    'severity': severity,
    'score': score,
    'emergencyType': emergencyType,
    'matchedKeywords': matchedKeywords,
    'recommendation': recommendation,
  };
}

class RLEnvironment {
  final AIBrainService _aiBrain = AIBrainService.instance;
  List<Map<String, dynamic>> _conditions = [];
  int _currentEpisode = 0;
  List<String> _currentSymptoms = [];
  bool _done = false;

  void setConditions(List<Map<String, dynamic>> conditions) {
    _conditions = conditions;
  }

  Map<String, dynamic> reset() {
    _currentEpisode = 0;
    _done = false;
    return {
      'episode': _currentEpisode,
      'state': _currentSymptoms,
      'done': _done,
    };
  }

  Map<String, dynamic> step(String predictedConditionId, String actualConditionId) {
    if (_done) {
      return _getFinalState();
    }

    final isCorrect = predictedConditionId == actualConditionId;
    final reward = isCorrect ? 1.0 : 0.0;

    _done = true;

    return {
      'episode': _currentEpisode,
      'state': _currentSymptoms,
      'action': predictedConditionId,
      'reward': reward,
      'done': _done,
      'info': {
        'predicted': predictedConditionId,
        'actual': actualConditionId,
        'correct': isCorrect,
      },
    };
  }

  Map<String, dynamic> state() {
    return {
      'episode': _currentEpisode,
      'state': _currentSymptoms,
      'done': _done,
    };
  }

  Map<String, dynamic> _getFinalState() {
    return {
      'episode': _currentEpisode,
      'state': _currentSymptoms,
      'reward': 0.0,
      'done': true,
    };
  }

  void nextEpisode() {
    _currentEpisode++;
    _done = false;
  }
}
