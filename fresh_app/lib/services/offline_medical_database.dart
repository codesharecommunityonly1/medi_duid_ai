import 'dart:convert';
import 'package:flutter/services.dart';

class OfflineMedicalDatabase {
  static OfflineMedicalDatabase? _instance;
  static OfflineMedicalDatabase get instance => _instance ??= OfflineMedicalDatabase._();
  OfflineMedicalDatabase._();

  List<MedicalCondition> _conditions = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<MedicalCondition> get allConditions => _conditions;

  Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      final jsonString = await rootBundle.loadString('assets/data/medical_conditions.json');
      final jsonData = json.decode(jsonString);
      final List<dynamic> conditionsJson = jsonData['conditions'];
      
      _conditions = conditionsJson.map((c) => MedicalCondition.fromJson(c)).toList();
      _isLoaded = true;
    } catch (e) {
      _conditions = [];
      _isLoaded = true;
    }
  }

  List<MedicalCondition> searchBySymptoms(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    final queryWords = lowerQuery.split(' ').where((w) => w.length > 2).toList();
    
    return _conditions.where((condition) {
      final nameMatch = condition.name.toLowerCase().contains(lowerQuery);
      final symptomMatch = condition.symptoms.any((s) => s.toLowerCase().contains(lowerQuery));
      final categoryMatch = condition.category.toLowerCase().contains(lowerQuery);
      final keywordMatch = queryWords.any((word) => 
        condition.symptoms.any((s) => s.toLowerCase().contains(word)) ||
        condition.name.toLowerCase().contains(word) ||
        condition.possibleConditions.any((p) => p.toLowerCase().contains(word))
      );
      
      return nameMatch || symptomMatch || categoryMatch || keywordMatch;
    }).toList()
      ..sort((a, b) {
        final aExact = a.name.toLowerCase().contains(lowerQuery) ? 0 : 1;
        final bExact = b.name.toLowerCase().contains(lowerQuery) ? 0 : 1;
        return aExact.compareTo(bExact);
      });
  }

  List<MedicalCondition> searchByName(String name) {
    final lowerName = name.toLowerCase();
    return _conditions.where((c) => c.name.toLowerCase().contains(lowerName)).toList();
  }

  List<MedicalCondition> getByCategory(String category) {
    return _conditions.where((c) => c.category == category).toList();
  }

  List<MedicalCondition> getBySeverity(String severity) {
    return _conditions.where((c) => c.severity == severity).toList();
  }

  List<MedicalCondition> getEmergencyConditions() {
    return _conditions.where((c) => c.severity == 'critical' || c.severity == 'severe').toList();
  }

  List<String> get categories {
    return _conditions.map((c) => c.category).toSet().toList()..sort();
  }

  MedicalCondition? getById(String id) {
    try {
      return _conditions.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  String buildGuidanceResponse(MedicalCondition condition, String userQuery) {
    final buffer = StringBuffer();
    
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('🏥 MEDIGUIDE AI - OFFLINE MODE');
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('📋 CONDITION: ${condition.name}');
    buffer.writeln('⚠️ SEVERITY: ${_getSeverityEmoji(condition.severity)} ${condition.severity.toUpperCase()}');
    buffer.writeln('📂 CATEGORY: ${condition.category}');
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('🔍 POSSIBLE CONDITIONS:');
    buffer.writeln('═══════════════════════════════════════════════════════');
    for (final condition_ in condition.possibleConditions) {
      buffer.writeln('  • $condition_');
    }
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('🩺 FIRST AID STEPS:');
    buffer.writeln('═══════════════════════════════════════════════════════');
    for (int i = 0; i < condition.firstAid.length; i++) {
      buffer.writeln('  ${i + 1}. ${condition.firstAid[i]}');
    }
    buffer.writeln();
    
    if (condition.organicRemedies.isNotEmpty) {
      buffer.writeln('═══════════════════════════════════════════════════════');
      buffer.writeln('🌿 ORGANIC/NATURAL REMEDIES:');
      buffer.writeln('═══════════════════════════════════════════════════════');
      for (final remedy in condition.organicRemedies) {
        buffer.writeln('  • $remedy');
      }
      buffer.writeln();
    }
    
    if (condition.medications.isNotEmpty) {
      buffer.writeln('═══════════════════════════════════════════════════════');
      buffer.writeln('💊 MEDICATIONS (Consult doctor first):');
      buffer.writeln('═══════════════════════════════════════════════════════');
      for (final med in condition.medications) {
        buffer.writeln('  • $med');
      }
      buffer.writeln();
    }
    
    if (condition.emergencyWarning.isNotEmpty) {
      buffer.writeln('═══════════════════════════════════════════════════════');
      buffer.writeln('🚨 ${condition.emergencyWarning}');
      buffer.writeln('═══════════════════════════════════════════════════════');
      buffer.writeln();
    }
    
    if (condition.whenToSeekDoctor.isNotEmpty) {
      buffer.writeln('═══════════════════════════════════════════════════════');
      buffer.writeln('🏥 WHEN TO SEE A DOCTOR:');
      buffer.writeln('═══════════════════════════════════════════════════════');
      buffer.writeln('  ${condition.whenToSeekDoctor}');
      buffer.writeln();
    }
    
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('📱 This guidance is from local medical database.');
    buffer.writeln('   Consult healthcare professionals for proper diagnosis.');
    buffer.writeln('═══════════════════════════════════════════════════════');
    
    return buffer.toString();
  }

  String _getSeverityEmoji(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return '🔴';
      case 'severe':
        return '🟠';
      case 'moderate':
        return '🟡';
      case 'mild':
        return '🟢';
      default:
        return '⚪';
    }
  }
}

class MedicalCondition {
  final String id;
  final String name;
  final String category;
  final String severity;
  final List<String> symptoms;
  final List<String> possibleConditions;
  final List<String> firstAid;
  final List<String> organicRemedies;
  final List<String> medications;
  final String emergencyWarning;
  final String whenToSeekDoctor;

  MedicalCondition({
    required this.id,
    required this.name,
    required this.category,
    required this.severity,
    required this.symptoms,
    required this.possibleConditions,
    required this.firstAid,
    required this.organicRemedies,
    required this.medications,
    required this.emergencyWarning,
    required this.whenToSeekDoctor,
  });

  factory MedicalCondition.fromJson(Map<String, dynamic> json) {
    return MedicalCondition(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'mild',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      possibleConditions: List<String>.from(json['possibleConditions'] ?? []),
      firstAid: List<String>.from(json['firstAid'] ?? []),
      organicRemedies: List<String>.from(json['organicRemedies'] ?? []),
      medications: List<String>.from(json['medications'] ?? []),
      emergencyWarning: json['emergencyWarning']?.toString() ?? '',
      whenToSeekDoctor: json['whenToSeekDoctor']?.toString() ?? '',
    );
  }
}
