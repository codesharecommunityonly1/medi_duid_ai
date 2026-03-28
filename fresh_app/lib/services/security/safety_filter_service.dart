class SafetyFilterService {
  static final SafetyFilterService _instance = SafetyFilterService._internal();
  factory SafetyFilterService() => _instance;
  SafetyFilterService._internal();

  static const double MIN_CONFIDENCE_THRESHOLD = 0.80;

  static const List<String> CRITICAL_KEYWORDS = [
    'suicide', 'kill myself', 'end my life', 'want to die',
    'heart attack', 'cardiac arrest', 'not breathing',
    'severe bleeding', 'blood loss', 'choking',
    'stroke', 'paralysis', 'unconscious',
    'overdose', 'poison', 'toxic',
    'drowning', 'electrocution',
    'seizure', 'convulsion',
    ' anaphylaxis', 'allergic reaction severe',
    'gunshot', 'stabbing', 'major trauma',
    ' miscarriage', 'labor', 'childbirth',
  ];

  static const List<String> HIGH_RISK_KEYWORDS = [
    'chest pain', 'difficulty breathing', 'shortness of breath',
    'severe headache', 'migraine', 'high fever',
    'vomiting blood', 'blood in stool', 'internal bleeding',
    'broken bone', 'fracture', 'sprain',
    'burn', 'scald', 'electric shock',
    'animal bite', 'snake bite', 'dog bite',
    'insect sting', 'allergy', 'rash',
    'dehydration', 'heat stroke', 'hypothermia',
    'diabetes', 'low sugar', 'high sugar',
    'blood pressure', 'heart rate',
    'pregnancy', 'contraction',
  ];

  static const List<String> MENTAL_HEALTH_KEYWORDS = [
    'depression', 'anxiety', 'panic',
    'self harm', 'cutting', 'harm yourself',
    'hopeless', 'worthless', 'alone',
    'trauma', 'ptsd', 'nightmare',
  ];

  SafetyResult analyzeInput(String input) {
    final lowerInput = input.toLowerCase();
    final List<String> matchedKeywords = [];
    RiskLevel riskLevel = RiskLevel.low;
    double confidenceScore = 1.0;

    for (final keyword in CRITICAL_KEYWORDS) {
      if (lowerInput.contains(keyword)) {
        matchedKeywords.add(keyword);
        riskLevel = RiskLevel.critical;
        confidenceScore = 0.95;
        break;
      }
    }

    if (riskLevel != RiskLevel.critical) {
      for (final keyword in HIGH_RISK_KEYWORDS) {
        if (lowerInput.contains(keyword)) {
          matchedKeywords.add(keyword);
          if (riskLevel != RiskLevel.critical) {
            riskLevel = RiskLevel.high;
            confidenceScore = 0.85;
          }
          break;
        }
      }
    }

    if (riskLevel == RiskLevel.low) {
      for (final keyword in MENTAL_HEALTH_KEYWORDS) {
        if (lowerInput.contains(keyword)) {
          matchedKeywords.add(keyword);
          riskLevel = RiskLevel.medium;
          confidenceScore = 0.75;
          break;
        }
      }
    }

    return SafetyResult(
      isSafe: riskLevel == RiskLevel.low || riskLevel == RiskLevel.medium,
      riskLevel: riskLevel,
      matchedKeywords: matchedKeywords,
      confidenceScore: confidenceScore,
      recommendation: _getRecommendation(riskLevel, confidenceScore),
      shouldShowEmergency: riskLevel == RiskLevel.critical,
      shouldConsultDoctor: confidenceScore < MIN_CONFIDENCE_THRESHOLD,
    );
  }

  String _getRecommendation(RiskLevel level, double confidence) {
    if (level == RiskLevel.critical) {
      return 'EMERGENCY: This appears to be a life-threatening situation. Call emergency services immediately (911/112).';
    } else if (level == RiskLevel.high) {
      return 'High-risk situation detected. Seek medical attention promptly.';
    } else if (level == RiskLevel.medium) {
      return 'Consider consulting a healthcare professional for proper evaluation.';
    } else if (confidence < MIN_CONFIDENCE_THRESHOLD) {
      return 'I am not fully confident about this situation. Please consult a human doctor for accurate diagnosis.';
    }
    return 'Continue with standard first-aid guidance.';
  }

  String getEmergencyGuidance(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    
    if (lowerKeyword.contains('suicide') || lowerKeyword.contains('kill myself') || lowerKeyword.contains('want to die')) {
      return '🚨 SUICIDE CRISIS HELP\n\n'
          'National Suicide Prevention Lifeline: 988 (US)\n'
          'Crisis Text Line: Text HOME to 741741\n'
          'International Association for Suicide Prevention: https://www.iasp.info/resources/Crisis_Centres/\n\n'
          'Please reach out to someone immediately. You are not alone.';
    }
    
    if (lowerKeyword.contains('heart attack') || lowerKeyword.contains('cardiac')) {
      return '🚨 HEART ATTACK EMERGENCY\n\n'
          '1. Call 911/112 immediately\n'
          '2. Have person sit or lie down\n'
          '3. Loosen tight clothing\n'
          '4. If conscious, give aspirin\n'
          '5. If no pulse, start CPR\n'
          '6. Use AED if available';
    }
    
    if (lowerKeyword.contains('choking')) {
      return '🚨 CHOKING EMERGENCY\n\n'
          '1. Encourage coughing\n'
          '2. For adults: Heimlich maneuver\n'
          '3. For infants: Back blows\n'
          '4. Call 911 if unsuccessful\n'
          '5. Start CPR if unconscious';
    }
    
    if (lowerKeyword.contains('stroke')) {
      return '🚨 STROKE EMERGENCY (FAST)\n\n'
          'F - Face drooping\n'
          'A - Arm weakness\n'
          'S - Speech difficulty\n'
          'T - Time to call 911\n\n'
          'Note when symptoms started. Do not give food/water.';
    }
    
    if (lowerKeyword.contains('overdose') || lowerKeyword.contains('poison')) {
      return '🚨 POISON/OVERDOSE EMERGENCY\n\n'
          '1. Call Poison Control: 1-800-222-1222 (US)\n'
          '2. Do NOT induce vomiting\n'
          '3. Identify the substance\n'
          '4. Save container for reference\n'
          '5. Call 911 if severe';
    }
    
    if (lowerKeyword.contains('seizure') || lowerKeyword.contains('convulsion')) {
      return '🚨 SEIZURE EMERGENCY\n\n'
          '1. Clear area around person\n'
          '2. Do NOT restrain them\n'
          '3. Put them on their side\n'
          '4. Time the seizure\n'
          '5. Call 911 if >5 minutes\n'
          '6. Stay with them until help arrives';
    }
    
    return '';
  }
}

enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

class SafetyResult {
  final bool isSafe;
  final RiskLevel riskLevel;
  final List<String> matchedKeywords;
  final double confidenceScore;
  final String recommendation;
  final bool shouldShowEmergency;
  final bool shouldConsultDoctor;

  SafetyResult({
    required this.isSafe,
    required this.riskLevel,
    required this.matchedKeywords,
    required this.confidenceScore,
    required this.recommendation,
    required this.shouldShowEmergency,
    required this.shouldConsultDoctor,
  });

  String getConfidencePercentage() => '${(confidenceScore * 100).toInt()}%';

  bool get isConfident => confidenceScore >= SafetyFilterService.MIN_CONFIDENCE_THRESHOLD;
}