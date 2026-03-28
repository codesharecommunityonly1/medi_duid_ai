import 'package:equatable/equatable.dart';
import '../../../domain/entities/medical_entities.dart';

enum MedicalStatus { initial, loading, loadingModel, ready, processing, success, error, listening, speaking }

class MedicalState extends Equatable {
  final MedicalStatus status;
  final String? errorMessage;
  final SymptomEntity? currentSymptom;
  final InjuryAnalysis? currentInjury;
  final bool isModelLoaded;
  final double modelLoadProgress;
  final String? recognizedText;
  final bool isSpeaking;

  const MedicalState({
    this.status = MedicalStatus.initial,
    this.errorMessage,
    this.currentSymptom,
    this.currentInjury,
    this.isModelLoaded = false,
    this.modelLoadProgress = 0.0,
    this.recognizedText,
    this.isSpeaking = false,
  });

  MedicalState copyWith({MedicalStatus? status, String? errorMessage, SymptomEntity? currentSymptom, InjuryAnalysis? currentInjury, bool? isModelLoaded, double? modelLoadProgress, String? recognizedText, bool? isSpeaking}) {
    return MedicalState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      currentSymptom: currentSymptom ?? this.currentSymptom,
      currentInjury: currentInjury ?? this.currentInjury,
      isModelLoaded: isModelLoaded ?? this.isModelLoaded,
      modelLoadProgress: modelLoadProgress ?? this.modelLoadProgress,
      recognizedText: recognizedText ?? this.recognizedText,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, currentSymptom, currentInjury, isModelLoaded, modelLoadProgress, recognizedText, isSpeaking];
}
