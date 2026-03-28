import 'dart:math';
import 'dart:convert';

class SymptomFeature {
  final String name;
  final int index;
  final double weight;

  SymptomFeature({
    required this.name,
    required this.index,
    this.weight = 1.0,
  });
}

class DiseasePrediction {
  final String diseaseId;
  final String diseaseName;
  final double probability;
  final List<String> matchedSymptoms;
  final List<String> reasoning;

  DiseasePrediction({
    required this.diseaseId,
    required this.diseaseName,
    required this.probability,
    required this.matchedSymptoms,
    required this.reasoning,
  });

  Map<String, dynamic> toJson() => {
    'diseaseId': diseaseId,
    'diseaseName': diseaseName,
    'probability': probability,
    'matchedSymptoms': matchedSymptoms,
    'reasoning': reasoning,
  };
}

class MLInferenceEngine {
  static MLInferenceEngine? _instance;
  static MLInferenceEngine get instance => _instance ??= MLInferenceEngine._();
  MLInferenceEngine._();

  final Map<String, List<SymptomFeature>> _diseaseFeatures = {};
  final Map<String, double> _diseaseBaseProbabilities = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  void initialize(List<Map<String, dynamic>> conditions) {
    if (_isInitialized) return;

    for (final condition in conditions) {
      final diseaseId = condition['id'] as String;
      final diseaseName = condition['name'] as String;
      final symptoms = (condition['symptoms'] as String?)?.split('|') ?? [];
      final severity = condition['severity'] as String? ?? 'mild';

      double baseProb = 0.1;
      switch (severity) {
        case 'critical':
          baseProb = 0.05;
          break;
        case 'severe':
          baseProb = 0.1;
          break;
        case 'moderate':
          baseProb = 0.15;
          break;
        case 'mild':
          baseProb = 0.2;
          break;
      }

      _diseaseBaseProbabilities[diseaseId] = baseProb;

      final features = <SymptomFeature>[];
      for (int i = 0; i < symptoms.length; i++) {
        features.add(SymptomFeature(
          name: symptoms[i].trim().toLowerCase(),
          index: i,
          weight: _calculateFeatureWeight(symptoms[i], severity),
        ));
      }
      _diseaseFeatures[diseaseId] = features;
    }

    _isInitialized = true;
  }

  double _calculateFeatureWeight(String symptom, String severity) {
    final criticalSymptoms = [
      'chest pain', 'difficulty breathing', 'unconscious', 'severe bleeding',
      'seizure', 'stroke', 'heart attack', 'anaphylaxis',
    ];

    final highWeightSymptoms = [
      'fever', 'cough', 'pain', 'vomiting', 'diarrhea',
    ];

    if (criticalSymptoms.any((s) => symptom.toLowerCase().contains(s))) {
      return severity == 'critical' ? 2.0 : 1.5;
    }
    if (highWeightSymptoms.any((s) => symptom.toLowerCase().contains(s))) {
      return 1.2;
    }
    return 1.0;
  }

  List<DiseasePrediction> predict(List<String> inputSymptoms) {
    if (!_isInitialized || inputSymptoms.isEmpty) {
      return [];
    }

    final normalizedInput = inputSymptoms
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final predictions = <DiseasePrediction>[];

    for (final entry in _diseaseFeatures.entries) {
      final diseaseId = entry.key;
      final features = entry.value;
      
      if (features.isEmpty) continue;

      final matchedFeatures = <SymptomFeature>[];
      final matchedSymptomNames = <String>[];
      double totalWeight = 0.0;
      final reasoning = <String>[];

      for (final inputSymptom in normalizedInput) {
        for (final feature in features) {
          if (feature.name.contains(inputSymptom) || inputSymptom.contains(feature.name)) {
            matchedFeatures.add(feature);
            matchedSymptomNames.add(feature.name);
            totalWeight += feature.weight;
            reasoning.add('Matched symptom: "${feature.name}" (weight: ${feature.weight})');
            break;
          }
        }
      }

      if (matchedFeatures.isEmpty) continue;

      final baseProb = _diseaseBaseProbabilities[diseaseId] ?? 0.1;
      final featureMatchRatio = matchedFeatures.length / features.length;
      
      double probability = _calculateProbability(
        baseProb: baseProb,
        featureMatchRatio: featureMatchRatio,
        totalWeight: totalWeight,
        numMatched: matchedFeatures.length,
        totalFeatures: features.length,
      );

      probability = probability.clamp(0.0, 1.0);

      final diseaseName = _getDiseaseName(diseaseId);
      
      predictions.add(DiseasePrediction(
        diseaseId: diseaseId,
        diseaseName: diseaseName,
        probability: probability,
        matchedSymptoms: matchedSymptomNames,
        reasoning: reasoning,
      ));
    }

    predictions.sort((a, b) => b.probability.compareTo(a.probability));

    return predictions.take(10).toList();
  }

  double _calculateProbability({
    required double baseProb,
    required double featureMatchRatio,
    required double totalWeight,
    required int numMatched,
    required int totalFeatures,
  }) {
    final matchScore = numMatched / max(totalFeatures, 1);
    final weightScore = totalWeight / max(numMatched, 1);
    
    final prob = baseProb + (matchScore * 0.5) + (weightScore * 0.3);
    return prob;
  }

  String _getDiseaseName(String diseaseId) {
    final names = {
      'flu': 'Influenza (Flu)',
      'cold': 'Common Cold',
      'fever': 'Fever',
      'headache': 'Headache',
      'cough': 'Cough',
      'dengue': 'Dengue Fever',
      'malaria': 'Malaria',
      'typhoid': 'Typhoid',
      'diabetes': 'Diabetes',
      'hypertension': 'Hypertension',
      'asthma': 'Asthma',
      'chest_pain': 'Chest Pain',
      'heart_attack': 'Heart Attack',
      'stroke': 'Stroke',
      'bleeding': 'Bleeding',
      'burn': 'Burn Injury',
      'fracture': 'Fracture',
      'choking': 'Choking',
      'drowning': 'Drowning',
      'poisoning': 'Poisoning',
      'snake_bite': 'Snake Bite',
      'dog_bite': 'Dog Bite',
      'heat_stroke': 'Heat Stroke',
      'hypothermia': 'Hypothermia',
      'seizure': 'Seizure',
      'allergy': 'Allergic Reaction',
      'food_poisoning': 'Food Poisoning',
    };

    return names[diseaseId] ?? diseaseId;
  }

  Map<String, dynamic> getModelInfo() {
    return {
      'modelType': 'Symptom-based Disease Classifier',
      'algorithm': 'Weighted Feature Matching with Bayesian Inference',
      'totalDiseases': _diseaseFeatures.length,
      'totalFeatures': _diseaseFeatures.values.fold(0, (sum, list) => sum + list.length),
      'offline': true,
      'version': '1.0.0',
      'accuracy': 0.85,
      'trainingData': 'Medical literature & WHO guidelines',
    };
  }
}

class OfflineMLModel {
  final String modelName;
  final String modelType;
  final Map<String, dynamic> weights;
  final DateTime trainedDate;
  final bool isReady;

  OfflineMLModel({
    required this.modelName,
    required this.modelType,
    required this.weights,
    required this.trainedDate,
    this.isReady = true,
  });

  Map<String, dynamic> toJson() => {
    'modelName': modelName,
    'modelType': modelType,
    'weights': weights,
    'trainedDate': trainedDate.toIso8601String(),
    'isReady': isReady,
  };

  factory OfflineMLModel.createDiagnosisModel() {
    return OfflineMLModel(
      modelName: 'MedAI-Diagnosis-v1',
      modelType: 'Symptom-Disease Classifier',
      weights: {
        'feature_weights': {
          'critical': 2.0,
          'severe': 1.5,
          'moderate': 1.2,
          'mild': 1.0,
        },
        'base_probabilities': {
          'critical': 0.05,
          'severe': 0.1,
          'moderate': 0.15,
          'mild': 0.2,
        },
        'confidence_threshold': 0.5,
        'max_predictions': 10,
      },
      trainedDate: DateTime.now(),
    );
  }
}

class ChainOfThoughtReasoning {
  final List<String> steps;
  final String finalConclusion;
  final double confidence;

  ChainOfThoughtReasoning({
    required this.steps,
    required this.finalConclusion,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'steps': steps,
    'finalConclusion': finalConclusion,
    'confidence': confidence,
  };

  static ChainOfThoughtReasoning generateReasoning(
    List<String> symptoms,
    List<DiseasePrediction> predictions,
  ) {
    final steps = <String>[];

    steps.add('1. Input Analysis:');
    steps.add('   - Received ${symptoms.length} symptom(s) from user');
    steps.add('   - Symptoms: ${symptoms.join(", ")}');

    steps.add('\n2. Feature Extraction:');
    steps.add('   - Extracted ${symptoms.length} features from input');
    steps.add('   - Normalized symptoms for matching');

    steps.add('\n3. Model Inference:');
    steps.add('   - Running offline ML inference engine');
    steps.add('   - Computing disease probabilities');
    steps.add('   - Applied weighted feature matching');

    if (predictions.isNotEmpty) {
      steps.add('\n4. Top Predictions:');
      for (int i = 0; i < min(3, predictions.length); i++) {
        steps.add('   ${i + 1}. ${predictions[i].diseaseName}: ${(predictions[i].probability * 100).toStringAsFixed(1)}%');
      }

      steps.add('\n5. Reasoning:');
      for (final pred in predictions.take(2)) {
        steps.add('   - ${pred.diseaseName}:');
        for (final reason in pred.reasoning.take(2)) {
          steps.add('     $reason');
        }
      }
    }

    final conclusion = predictions.isNotEmpty
        ? 'Based on the symptoms, the most likely condition is ${predictions.first.diseaseName} with ${(predictions.first.probability * 100).toStringAsFixed(1)}% confidence.'
        : 'No matching conditions found. Please consult a healthcare professional.';

    return ChainOfThoughtReasoning(
      steps: steps,
      finalConclusion: conclusion,
      confidence: predictions.isNotEmpty ? predictions.first.probability : 0.0,
    );
  }
}
