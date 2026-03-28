import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/emergency/emergency_service.dart';
import '../../../data/local/database_helper.dart';
import 'emergency_event.dart';
import 'emergency_state.dart';

class EmergencyBloc extends Bloc<EmergencyEvent, EmergencyState> {
  final EmergencyService emergencyService;
  EmergencyBloc({required this.emergencyService}) : super(const EmergencyState()) {
    on<LoadEmergencyContactsEvent>(_onLoadContacts);
    on<AddEmergencyContactEvent>(_onAddContact);
    on<DeleteEmergencyContactEvent>(_onDeleteContact);
    on<TriggerEmergencySOSEvent>(_onTriggerSOS);
    on<CallEmergencyEvent>(_onCallEmergency);
  }

  Future<void> _onLoadContacts(LoadEmergencyContactsEvent event, Emitter<EmergencyState> emit) async {
    emit(state.copyWith(status: EmergencyStatus.loading));
    try {
      final contacts = await DatabaseHelper.getEmergencyContacts();
      emit(state.copyWith(status: EmergencyStatus.loaded, contacts: contacts));
    } catch (e) {
      emit(state.copyWith(status: EmergencyStatus.error, errorMessage: 'Failed: $e'));
    }
  }

  Future<void> _onAddContact(AddEmergencyContactEvent event, Emitter<EmergencyState> emit) async {
    try {
      await DatabaseHelper.saveEmergencyContact(event.contact);
      final contacts = await DatabaseHelper.getEmergencyContacts();
      emit(state.copyWith(contacts: contacts));
    } catch (e) {
      emit(state.copyWith(status: EmergencyStatus.error, errorMessage: 'Failed: $e'));
    }
  }

  Future<void> _onDeleteContact(DeleteEmergencyContactEvent event, Emitter<EmergencyState> emit) async {
    try {
      await DatabaseHelper.deleteEmergencyContact(event.id);
      final contacts = await DatabaseHelper.getEmergencyContacts();
      emit(state.copyWith(contacts: contacts));
    } catch (e) {
      emit(state.copyWith(status: EmergencyStatus.error, errorMessage: 'Failed: $e'));
    }
  }

  Future<void> _onTriggerSOS(TriggerEmergencySOSEvent event, Emitter<EmergencyState> emit) async {
    emit(state.copyWith(status: EmergencyStatus.sending, sosCompleted: false));
    try {
      final result = await emergencyService.triggerEmergencySOS(contacts: state.contacts, emergencyType: event.emergencyType);
      emit(state.copyWith(status: EmergencyStatus.sosTriggered, sosCompleted: true, currentLocation: result.location));
    } catch (e) {
      emit(state.copyWith(status: EmergencyStatus.error, errorMessage: 'Failed: $e'));
    }
  }

  Future<void> _onCallEmergency(CallEmergencyEvent event, Emitter<EmergencyState> emit) async {
    emit(state.copyWith(status: EmergencyStatus.calling));
    final success = await emergencyService.callEmergencyNumber(event.number);
    emit(state.copyWith(status: success ? EmergencyStatus.loaded : EmergencyStatus.error));
  }
}
