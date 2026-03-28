import '../../domain/entities/medical_entities.dart';

class InjuryAnalysisService {
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool get isInitialized => _isInitialized;
  bool get isAnalyzing => _isAnalyzing;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await Future.delayed(const Duration(milliseconds: 500));
    _isInitialized = true;
  }

  Future<InjuryAnalysis> analyzeInjury(String imagePath) async {
    if (!_isInitialized) await initialize();
    _isAnalyzing = true;
    await Future.delayed(const Duration(seconds: 2));
    _isAnalyzing = false;
    return InjuryAnalysis(
      imagePath: imagePath, 
      description: 'Analysis complete. See recommendations below.', 
      severity: SymptomSeverity.moderate, 
      findings: ['Clean wound gently with water', 'Apply antiseptic', 'Cover with bandage'], 
      recommendation: 'Clean wound gently with water, apply antiseptic, and cover with bandage. Monitor for infection signs.',
      timestamp: DateTime.now(),
    );
  }

  List<String> getEmergencyWarnings(SymptomSeverity severity) {
    switch (severity) {
      case SymptomSeverity.severe: return ['Seek immediate medical attention', 'Call 911', 'Watch for shock'];
      case SymptomSeverity.moderate: return ['Seek medical attention within 24 hours', 'Keep wound clean'];
      default: return ['Keep wound clean and dry', 'Watch for infection signs'];
    }
  }

  void dispose() { _isInitialized = false; }
}
