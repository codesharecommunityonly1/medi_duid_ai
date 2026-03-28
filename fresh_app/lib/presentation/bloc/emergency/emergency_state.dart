import 'package:equatable/equatable.dart';
import '../../../domain/entities/medical_entities.dart';

enum EmergencyStatus { initial, loading, loaded, calling, sending, sosTriggered, error }

class EmergencyState extends Equatable {
  final EmergencyStatus status;
  final List<EmergencyContact> contacts;
  final Map<String, double>? currentLocation;
  final String? errorMessage;
  final bool sosCompleted;

  const EmergencyState({
    this.status = EmergencyStatus.initial,
    this.contacts = const [],
    this.currentLocation,
    this.errorMessage,
    this.sosCompleted = false,
  });

  EmergencyState copyWith({EmergencyStatus? status, List<EmergencyContact>? contacts, Map<String, double>? currentLocation, String? errorMessage, bool? sosCompleted}) {
    return EmergencyState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      currentLocation: currentLocation ?? this.currentLocation,
      errorMessage: errorMessage,
      sosCompleted: sosCompleted ?? this.sosCompleted,
    );
  }

  @override
  List<Object?> get props => [status, contacts, currentLocation, errorMessage, sosCompleted];
}
