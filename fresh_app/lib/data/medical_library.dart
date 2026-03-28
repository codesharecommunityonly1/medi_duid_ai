import '../services/offline_medical_database.dart';

class MedicalProblemLibrary {
  static final OfflineMedicalDatabase _database = OfflineMedicalDatabase.instance;
  
  static bool get isLoaded => _database.isLoaded;
  
  static Future<void> initialize() async {
    await _database.initialize();
  }

  static List<MedicalProblem> searchBySymptoms(String query) {
    final results = _database.searchBySymptoms(query);
    return results.map((c) => MedicalProblem(
      id: c.id,
      name: c.name,
      category: c.category,
      symptoms: c.symptoms,
      organicSolution: c.organicRemedies.isNotEmpty 
        ? c.organicRemedies.join(', ')
        : 'Rest and consult doctor',
      chemicalSolution: c.medications.isNotEmpty 
        ? c.medications.join(', ')
        : 'Consult doctor for medications',
    )).toList();
  }

  static List<MedicalProblem> searchByName(String name) {
    final results = _database.searchByName(name);
    return results.map((c) => MedicalProblem(
      id: c.id,
      name: c.name,
      category: c.category,
      symptoms: c.symptoms,
      organicSolution: c.organicRemedies.isNotEmpty 
        ? c.organicRemedies.join(', ')
        : 'Rest and consult doctor',
      chemicalSolution: c.medications.isNotEmpty 
        ? c.medications.join(', ')
        : 'Consult doctor for medications',
    )).toList();
  }

  static List<MedicalProblem> getByCategory(String category) {
    final results = _database.getByCategory(category);
    return results.map((c) => MedicalProblem(
      id: c.id,
      name: c.name,
      category: c.category,
      symptoms: c.symptoms,
      organicSolution: c.organicRemedies.isNotEmpty 
        ? c.organicRemedies.join(', ')
        : 'Rest and consult doctor',
      chemicalSolution: c.medications.isNotEmpty 
        ? c.medications.join(', ')
        : 'Consult doctor for medications',
    )).toList();
  }

  static List<String> get categories => _database.categories;

  static String getGuidanceForCondition(MedicalCondition condition, String userQuery) {
    return _database.buildGuidanceResponse(condition, userQuery);
  }

  static List<MedicalCondition> get allConditions => _database.allConditions;

  static MedicalCondition? getConditionById(String id) => _database.getById(id);
}

class MedicalProblem {
  final String id;
  final String name;
  final String category;
  final List<String> symptoms;
  final String organicSolution;
  final String chemicalSolution;

  const MedicalProblem({
    required this.id,
    required this.name,
    required this.category,
    required this.symptoms,
    required this.organicSolution,
    required this.chemicalSolution,
  });
}
