import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../services/voice/stt_service.dart';
import '../../../services/voice/tts_service.dart';
import '../../../services/vision/injury_analysis_service.dart';
import '../../../services/offline_medical_database.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/medical_library.dart';
import '../../../domain/entities/medical_entities.dart';
import 'medical_event.dart';
import 'medical_state.dart';

class MedicalBloc extends Bloc<MedicalEvent, MedicalState> {
  final SttService sttService = SttService();
  final TtsService ttsService = TtsService();
  final InjuryAnalysisService injuryAnalysisService = InjuryAnalysisService();

  MedicalBloc() : super(const MedicalState()) {
    on<InitializeDatabaseEvent>(_onInitializeDatabase);
    on<ProcessSymptomsEvent>(_onProcessSymptoms);
    on<ProcessInjuryEvent>(_onProcessInjury);
    on<StartVoiceInputEvent>(_onStartVoiceInput);
    on<StopVoiceInputEvent>(_onStopVoiceInput);
    on<ClearMedicalStateEvent>(_onClearState);
    on<SpeakResultEvent>(_onSpeakResult);
    on<StopSpeakingEvent>(_onStopSpeaking);
  }

  Future<void> _onInitializeDatabase(InitializeDatabaseEvent event, Emitter<MedicalState> emit) async {
    emit(state.copyWith(status: MedicalStatus.loadingModel, modelLoadProgress: 0.0));
    await MedicalProblemLibrary.initialize();
    emit(state.copyWith(status: MedicalStatus.ready, isModelLoaded: true, modelLoadProgress: 1.0));
  }

  Future<void> _onProcessSymptoms(ProcessSymptomsEvent event, Emitter<MedicalState> emit) async {
    emit(state.copyWith(status: MedicalStatus.processing, recognizedText: event.description));
    try {
      final libraryResults = MedicalProblemLibrary.searchBySymptoms(event.description);
      
      String response;
      SymptomSeverity severity;
      List<String> warnings;
      List<String> nextSteps;
      List<String> symptoms;

      if (libraryResults.isNotEmpty) {
        final condition = OfflineMedicalDatabase.instance.searchBySymptoms(event.description).first;
        response = MedicalProblemLibrary.getGuidanceForCondition(condition, event.description);
        symptoms = condition.symptoms;
        severity = _mapSeverity(condition.severity);
        warnings = condition.emergencyWarning.isNotEmpty 
          ? [condition.emergencyWarning] 
          : ['Consult doctor if symptoms worsen'];
        nextSteps = condition.firstAid.take(5).toList();
      } else {
        response = _buildNoMatchResponse(event.description);
        symptoms = event.description.split(' ');
        severity = SymptomSeverity.mild;
        warnings = ['Consult healthcare professional for proper diagnosis'];
        nextSteps = ['Rest and monitor symptoms', 'Seek medical help if worsen'];
      }

      final symptom = SymptomEntity(
        id: const Uuid().v4(), 
        description: event.description, 
        severity: severity, 
        symptoms: symptoms, 
        firstAidGuidance: response, 
        warnings: warnings, 
        nextSteps: nextSteps, 
        timestamp: DateTime.now(), 
        isVoiceInput: event.isVoiceInput,
      );
      await DatabaseHelper.saveSymptom(symptom);
      emit(state.copyWith(status: MedicalStatus.success, currentSymptom: symptom));
    } catch (e) {
      emit(state.copyWith(status: MedicalStatus.error, errorMessage: 'Error: $e'));
    }
  }

  String _buildNoMatchResponse(String description) {
    return '''
═══════════════════════════════════════════════════════
🏥 MEDIGUIDE AI - OFFLINE MODE
═══════════════════════════════════════════════════════

Based on your input: "$description"

We couldn't find an exact match in our database.

📋 GENERAL FIRST AID GUIDANCE:

1. Rest and monitor your symptoms
2. Stay hydrated
3. Take appropriate pain relievers if needed
4. Apply cold/heat as needed
5. Seek medical attention if symptoms worsen

⚠️ IMPORTANT:
- Consult healthcare professionals for proper diagnosis
- Seek immediate care for serious symptoms
- For emergencies, call your local emergency number

📱 This guidance is from our local medical database.
   Stay healthy! 
═══════════════════════════════════════════════════════
''';
  }

  SymptomSeverity _mapSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'severe':
        return SymptomSeverity.severe;
      case 'moderate':
        return SymptomSeverity.moderate;
      default:
        return SymptomSeverity.mild;
    }
  }

  Future<void> _onProcessInjury(ProcessInjuryEvent event, Emitter<MedicalState> emit) async {
    emit(state.copyWith(status: MedicalStatus.processing));
    try {
      final analysis = await injuryAnalysisService.analyzeInjury(event.imagePath);
      
      final searchResults = OfflineMedicalDatabase.instance.searchBySymptoms(analysis.description);
      String response;
      
      if (searchResults.isNotEmpty) {
        final condition = searchResults.first;
        response = '''
═══════════════════════════════════════════════════════
🏥 MEDIGUIDE AI - INJURY ANALYSIS (OFFLINE)
═══════════════════════════════════════════════════════

📋 ANALYSIS: ${analysis.description}
⚠️ SEVERITY: ${analysis.severity.name.toUpperCase()}

═══════════════════════════════════════════════════════
🩺 FIRST AID RECOMMENDATIONS:
═══════════════════════════════════════════════════════
${analysis.findings.map((f) => '• $f').join('\n')}

═══════════════════════════════════════════════════════
${MedicalProblemLibrary.getGuidanceForCondition(condition, analysis.description)}
═══════════════════════════════════════════════════════
''';
      } else {
        response = '''
═══════════════════════════════════════════════════════
🏥 MEDIGUIDE AI - INJURY ANALYSIS (OFFLINE)
═══════════════════════════════════════════════════════

📋 ANALYSIS: ${analysis.description}
⚠️ SEVERITY: ${analysis.severity.name.toUpperCase()}

═══════════════════════════════════════════════════════
🩺 FIRST AID RECOMMENDATIONS:
═══════════════════════════════════════════════════════
${analysis.findings.map((f) => '• $f').join('\n')}

═══════════════════════════════════════════════════════
⚠️ RECOMMENDATIONS:
1. Clean the wound thoroughly
2. Apply antibiotic ointment
3. Cover with sterile bandage
4. Watch for signs of infection
5. Seek medical care if severe

🏥 For serious injuries, consult a healthcare professional.
═══════════════════════════════════════════════════════
''';
      }
      
      final symptom = SymptomEntity(
        id: const Uuid().v4(), 
        description: analysis.description, 
        severity: analysis.severity, 
        symptoms: analysis.findings, 
        firstAidGuidance: response, 
        warnings: injuryAnalysisService.getEmergencyWarnings(analysis.severity), 
        nextSteps: analysis.findings, 
        timestamp: DateTime.now(), 
        isVoiceInput: false, 
        imagePath: event.imagePath,
      );
      await DatabaseHelper.saveSymptom(symptom);
      emit(state.copyWith(status: MedicalStatus.success, currentSymptom: symptom, currentInjury: analysis));
    } catch (e) {
      emit(state.copyWith(status: MedicalStatus.error, errorMessage: 'Error: $e'));
    }
  }

  Future<void> _onStartVoiceInput(StartVoiceInputEvent event, Emitter<MedicalState> emit) async {
    emit(state.copyWith(status: MedicalStatus.listening));
    await sttService.initialize();
    sttService.stream.listen((text) {
      if (text.isNotEmpty) add(ProcessSymptomsEvent(description: text, isVoiceInput: true));
    });
    await sttService.startListening();
  }

  Future<void> _onStopVoiceInput(StopVoiceInputEvent event, Emitter<MedicalState> emit) async {
    await sttService.stopListening();
    emit(state.copyWith(status: MedicalStatus.ready));
  }

  Future<void> _onClearState(ClearMedicalStateEvent event, Emitter<MedicalState> emit) async {
    emit(state.copyWith(status: MedicalStatus.ready, currentSymptom: null, currentInjury: null));
  }

  Future<void> _onSpeakResult(SpeakResultEvent event, Emitter<MedicalState> emit) async {
    emit(state.copyWith(isSpeaking: true, status: MedicalStatus.speaking));
    await ttsService.speak(event.text);
    emit(state.copyWith(isSpeaking: false, status: MedicalStatus.success));
  }

  Future<void> _onStopSpeaking(StopSpeakingEvent event, Emitter<MedicalState> emit) async {
    await ttsService.stop();
    emit(state.copyWith(isSpeaking: false, status: MedicalStatus.ready));
  }

  @override
  Future<void> close() { sttService.dispose(); ttsService.dispose(); injuryAnalysisService.dispose(); return super.close(); }
}
