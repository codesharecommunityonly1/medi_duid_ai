import 'package:equatable/equatable.dart';
import '../../../domain/entities/medical_entities.dart';

abstract class EmergencyEvent extends Equatable { @override List<Object?> get props => []; }

class LoadEmergencyContactsEvent extends EmergencyEvent {}
class AddEmergencyContactEvent extends EmergencyEvent {
  final EmergencyContact contact;
  AddEmergencyContactEvent({required this.contact});
  @override List<Object?> get props => [contact];
}
class DeleteEmergencyContactEvent extends EmergencyEvent {
  final String id;
  DeleteEmergencyContactEvent({required this.id});
  @override List<Object?> get props => [id];
}
class TriggerEmergencySOSEvent extends EmergencyEvent {
  final String emergencyType;
  TriggerEmergencySOSEvent({required this.emergencyType});
  @override List<Object?> get props => [emergencyType];
}
class CallEmergencyEvent extends EmergencyEvent {
  final String number;
  CallEmergencyEvent({required this.number});
  @override List<Object?> get props => [number];
}
