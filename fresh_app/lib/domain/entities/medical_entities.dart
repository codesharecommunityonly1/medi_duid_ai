import 'package:equatable/equatable.dart';

enum SymptomSeverity { mild, moderate, severe, critical }
enum EmergencyType { cardiac, breathing, bleeding, burn, fracture, poisoning, allergic, seizure, diabetic, heatCold, other }

class SymptomEntity extends Equatable {
  final String id;
  final String description;
  final EmergencyType? type;
  final SymptomSeverity severity;
  final List<String> symptoms;
  final String firstAidGuidance;
  final List<String> warnings;
  final List<String> nextSteps;
  final DateTime timestamp;
  final bool isVoiceInput;
  final String? imagePath;

  const SymptomEntity({
    required this.id, required this.description, this.type, required this.severity,
    required this.symptoms, required this.firstAidGuidance, required this.warnings,
    required this.nextSteps, required this.timestamp, required this.isVoiceInput, this.imagePath,
  });

  @override
  List<Object?> get props => [id, description, type, severity, symptoms, firstAidGuidance, warnings, nextSteps, timestamp, isVoiceInput, imagePath];
}

class EmergencyContact extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final bool isPrimary;
  const EmergencyContact({required this.id, required this.name, required this.phoneNumber, this.isPrimary = false});
  @override
  List<Object?> get props => [id, name, phoneNumber, isPrimary];
}

class InjuryAnalysis extends Equatable {
  final String imagePath;
  final String description;
  final SymptomSeverity severity;
  final List<String> findings;
  final String recommendation;
  final DateTime timestamp;

  const InjuryAnalysis({
    required this.imagePath,
    required this.description,
    required this.severity,
    required this.findings,
    required this.recommendation,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [imagePath, description, severity, findings, recommendation, timestamp];
}
