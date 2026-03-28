import 'dart:math';
import '../../data/medical_library.dart';

class AISimulationService {
  static final AISimulationService _instance = AISimulationService._internal();
  factory AISimulationService() => _instance;
  AISimulationService._internal();

  final Random _random = Random();
  List<SimulationResult> _trainingHistory = [];
  double _currentAccuracy = 0.0;
  int _totalSimulations = 0;
  bool _isTraining = false;

  double get accuracy => _currentAccuracy;
  int get totalSimulations => _totalSimulations;
  bool get isTraining => _isTraining;
  List<SimulationResult> get history => List.unmodifiable(_trainingHistory);

  Future<SimulationResult> runDiagnosisSimulation({
    required String patientCase,
    required String correctDiagnosis,
  }) async {
    _isTraining = true;
    
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));

    final similarityScore = _calculateSimilarity(patientCase, correctDiagnosis);
    final baseAccuracy = 0.75 + (_random.nextDouble() * 0.20);
    
    final predictedDiagnosis = _generatePrediction(patientCase, correctDiagnosis, similarityScore);
    final isCorrect = predictedDiagnosis.toLowerCase() == correctDiagnosis.toLowerCase() ||
                     _checkDiagnosisMatch(predictedDiagnosis, correctDiagnosis);
    
    final confidenceScore = baseAccuracy + (similarityScore * 0.05);
    final accuracyBoost = isCorrect ? 0.02 : -0.01;

    _currentAccuracy = (_currentAccuracy * 0.7) + (accuracyBoost * 0.3);
    _currentAccuracy = _currentAccuracy.clamp(0.5, 0.99);
    _totalSimulations++;

    final result = SimulationResult(
      patientCase: patientCase,
      correctDiagnosis: correctDiagnosis,
      predictedDiagnosis: predictedDiagnosis,
      isCorrect: isCorrect,
      confidenceScore: confidenceScore,
      accuracyAfter: _currentAccuracy,
      timestamp: DateTime.now(),
    );

    _trainingHistory.add(result);
    if (_trainingHistory.length > 100) {
      _trainingHistory.removeAt(0);
    }

    _isTraining = false;
    return result;
  }

  Future<List<SimulationResult>> runBatchSimulation({
    int cases = 10,
  }) async {
    final results = <SimulationResult>[];
    final conditions = MedicalProblemLibrary.problems;
    
    for (int i = 0; i < cases && i < conditions.length; i++) {
      final condition = conditions[_random.nextInt(conditions.length)];
      final result = await runDiagnosisSimulation(
        patientCase: condition.name,
        correctDiagnosis: '${condition.organicSolution} | ${condition.chemicalSolution}',
      );
      results.add(result);
    }
    
    return results;
  }

  Future<void> trainWithAllCases() async {
    final conditions = MedicalProblemLibrary.problems;
    
    for (final condition in conditions) {
      await runDiagnosisSimulation(
        patientCase: '${condition.name} - ${condition.symptoms.join(", ")}',
        correctDiagnosis: '${condition.organicSolution} | ${condition.chemicalSolution}',
      );
    }
  }

  double _calculateSimilarity(String case1, String case2) {
    final words1 = case1.toLowerCase().split(' ');
    final words2 = case2.toLowerCase().split(' ');
    
    int matches = 0;
    for (final word in words1) {
      if (words2.contains(word) && word.length > 3) {
        matches++;
      }
    }
    
    return (matches / words1.length).clamp(0.0, 1.0);
  }

  String _generatePrediction(String patientCase, String correctDiagnosis, double similarity) {
    if (similarity > 0.8) {
      return correctDiagnosis;
    }
    
    final conditions = MedicalProblemLibrary.problems;
    final similar = conditions.where((c) => 
      c.name.toLowerCase().contains(_extractKeyword(patientCase))
    ).toList();
    
    if (similar.isNotEmpty) {
      final c = similar.first;
      return '${c.organicSolution} | ${c.chemicalSolution}';
    }
    
    if (_random.nextDouble() > 0.7) {
      final c = conditions[_random.nextInt(conditions.length)];
      return '${c.organicSolution} | ${c.chemicalSolution}';
    }
    
    return correctDiagnosis;
  }

  String _extractKeyword(String text) {
    final keywords = ['pain', 'fever', 'cold', 'headache', 'cough', 'nausea', 'rash', 'injury'];
    for (final keyword in keywords) {
      if (text.toLowerCase().contains(keyword)) {
        return keyword;
      }
    }
    return text.split(' ').first;
  }

  bool _checkDiagnosisMatch(String predicted, String correct) {
    final predKeywords = predicted.toLowerCase().split(' ');
    final corrKeywords = correct.toLowerCase().split(' ');
    
    int matches = 0;
    for (final word in predKeywords) {
      if (corrKeywords.contains(word) && word.length > 3) {
        matches++;
      }
    }
    
    return matches >= corrKeywords.length ~/ 2;
  }

  Map<String, dynamic> getPerformanceMetrics() {
    if (_trainingHistory.isEmpty) {
      return {
        'totalSimulations': 0,
        'currentAccuracy': 0.0,
        'correctPredictions': 0,
        'averageConfidence': 0.0,
        'improvementTrend': 'N/A',
      };
    }

    final correct = _trainingHistory.where((r) => r.isCorrect).length;
    final avgConfidence = _trainingHistory.map((r) => r.confidenceScore).reduce((a, b) => a + b) / _trainingHistory.length;
    
    final recentHistory = _trainingHistory.length > 10 
        ? _trainingHistory.sublist(_trainingHistory.length - 10) 
        : _trainingHistory;
    final recentCorrect = recentHistory.where((r) => r.isCorrect).length / recentHistory.length;
    final olderCorrect = _trainingHistory.length > 20 
        ? _trainingHistory.sublist(0, 10).where((r) => r.isCorrect).length / 10 
        : recentCorrect;
    
    String trend = 'Stable';
    if (recentCorrect > olderCorrect + 0.1) {
      trend = 'Improving 📈';
    } else if (recentCorrect < olderCorrect - 0.1) {
      trend = 'Declining 📉';
    }

    return {
      'totalSimulations': _totalSimulations,
      'currentAccuracy': _currentAccuracy,
      'correctPredictions': correct,
      'averageConfidence': avgConfidence,
      'improvementTrend': trend,
    };
  }

  void resetTraining() {
    _trainingHistory.clear();
    _currentAccuracy = 0.75;
    _totalSimulations = 0;
  }
}

class SimulationResult {
  final String patientCase;
  final String correctDiagnosis;
  final String predictedDiagnosis;
  final bool isCorrect;
  final double confidenceScore;
  final double accuracyAfter;
  final DateTime timestamp;

  SimulationResult({
    required this.patientCase,
    required this.correctDiagnosis,
    required this.predictedDiagnosis,
    required this.isCorrect,
    required this.confidenceScore,
    required this.accuracyAfter,
    required this.timestamp,
  });

  String get statusIcon => isCorrect ? '✅' : '❌';
  String get confidencePercentage => '${(confidenceScore * 100).toInt()}%';
}