import 'package:equatable/equatable.dart';

abstract class MedicalEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitializeDatabaseEvent extends MedicalEvent {}

class ProcessSymptomsEvent extends MedicalEvent {
  final String description;
  final bool isVoiceInput;
  ProcessSymptomsEvent({required this.description, required this.isVoiceInput});
  @override
  List<Object?> get props => [description, isVoiceInput];
}

class ProcessInjuryEvent extends MedicalEvent {
  final String imagePath;
  ProcessInjuryEvent({required this.imagePath});
  @override
  List<Object?> get props => [imagePath];
}

class StartVoiceInputEvent extends MedicalEvent {}
class StopVoiceInputEvent extends MedicalEvent {}
class ClearMedicalStateEvent extends MedicalEvent {}

class SpeakResultEvent extends MedicalEvent {
  final String text;
  SpeakResultEvent({required this.text});
  @override
  List<Object?> get props => [text];
}

class StopSpeakingEvent extends MedicalEvent {}
