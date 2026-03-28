import '../../domain/entities/medical_entities.dart';

class RagService {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await Future.delayed(const Duration(milliseconds: 100));
    _isInitialized = true;
  }

  List<MedicalGuideline> getGuidelinesByCategory(EmergencyType category) {
    return MedicalDatabase.guidelines.where((g) => g.category == category).toList();
  }

  List<MedicalGuideline> searchGuidelines(String query) {
    final lowerQuery = query.toLowerCase();
    return MedicalDatabase.guidelines.where((g) {
      return g.title.toLowerCase().contains(lowerQuery) || g.keywords.any((k) => k.contains(lowerQuery));
    }).toList();
  }

  String buildContextFromResults(List<MedicalGuideline> results) {
    if (results.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('Relevant medical guidelines:');
    for (final g in results) {
      buffer.writeln('--- ${g.title} ---');
      buffer.writeln(g.content);
    }
    return buffer.toString();
  }

  Future<String> getGuidanceForQuery(String query) async {
    final results = searchGuidelines(query);
    return buildContextFromResults(results.take(3).toList());
  }

  void dispose() { _isInitialized = false; }
}

class MedicalGuideline {
  final String id;
  final String title;
  final String content;
  final EmergencyType category;
  final List<String> keywords;

  const MedicalGuideline({required this.id, required this.title, required this.content, required this.category, required this.keywords});
}

class MedicalDatabase {
  static final List<MedicalGuideline> guidelines = [
    const MedicalGuideline(id: 'cardiac_001', title: 'Cardiac Arrest / Heart Attack', content: 'Call 911, start CPR, use AED if available', category: EmergencyType.cardiac, keywords: ['heart', 'chest pain', 'cardiac', 'cpr']),
    const MedicalGuideline(id: 'bleeding_001', title: 'Severe Bleeding', content: 'Apply direct pressure, elevate wound, call 911', category: EmergencyType.bleeding, keywords: ['bleeding', 'blood', 'cut', 'wound']),
    const MedicalGuideline(id: 'burn_001', title: 'Burns', content: 'Cool burn with water 10-20 min, cover with clean cloth', category: EmergencyType.burn, keywords: ['burn', 'fire', 'hot']),
    const MedicalGuideline(id: 'breathing_001', title: 'Choking', content: 'Call 911, perform Heimlich maneuver', category: EmergencyType.breathing, keywords: ['choke', 'breathe', 'airway', 'heimlich']),
    const MedicalGuideline(id: 'fracture_001', title: 'Fractures', content: 'Keep still, immobilize, call 911 for severe', category: EmergencyType.fracture, keywords: ['broken', 'fracture', 'bone']),
    const MedicalGuideline(id: 'poisoning_001', title: 'Poisoning', content: 'Call Poison Control 1-800-222-1222, do not induce vomiting', category: EmergencyType.poisoning, keywords: ['poison', 'swallowed', 'toxic']),
    const MedicalGuideline(id: 'seizure_001', title: 'Seizures', content: 'Keep calm, time seizure, place on side, do not put anything in mouth', category: EmergencyType.seizure, keywords: ['seizure', 'convulsion', 'epilepsy']),
    const MedicalGuideline(id: 'allergic_001', title: 'Severe Allergic Reaction', content: 'Call 911, use epinephrine if available', category: EmergencyType.allergic, keywords: ['allergic', 'swelling', 'bee sting']),
    const MedicalGuideline(id: 'diabetic_001', title: 'Diabetic Emergency', content: 'If conscious give sugar, if unconscious call 911', category: EmergencyType.diabetic, keywords: ['diabetes', 'blood sugar', 'insulin']),
    const MedicalGuideline(id: 'heat_001', title: 'Heat Emergency', content: 'Move to cool area, apply cool water, call 911 for heat stroke', category: EmergencyType.heatCold, keywords: ['heat', 'hot', 'hypothermia']),
  ];
}
