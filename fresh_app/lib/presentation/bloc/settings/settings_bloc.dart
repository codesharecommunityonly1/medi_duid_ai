import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/local/database_helper.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<ToggleDarkModeEvent>(_onToggleDarkMode);
    on<ToggleVoiceOutputEvent>(_onToggleVoiceOutput);
    on<ChangeLanguageEvent>(_onChangeLanguage);
  }

  Future<void> _onLoadSettings(LoadSettingsEvent event, Emitter<SettingsState> emit) async {
    try {
      final darkMode = await DatabaseHelper.getSetting('dark_mode');
      final voiceOutput = await DatabaseHelper.getSetting('voice_output');
      final language = await DatabaseHelper.getSetting('language');
      emit(state.copyWith(
        isDarkMode: darkMode == 'true',
        isVoiceOutputEnabled: voiceOutput != 'false',
        languageCode: language ?? 'en',
        isLoaded: true,
      ));
    } catch (_) {
      emit(state.copyWith(isLoaded: true));
    }
  }

  Future<void> _onToggleDarkMode(ToggleDarkModeEvent event, Emitter<SettingsState> emit) async {
    final newValue = !state.isDarkMode;
    await DatabaseHelper.saveSetting('dark_mode', newValue.toString());
    emit(state.copyWith(isDarkMode: newValue));
  }

  Future<void> _onToggleVoiceOutput(ToggleVoiceOutputEvent event, Emitter<SettingsState> emit) async {
    final newValue = !state.isVoiceOutputEnabled;
    await DatabaseHelper.saveSetting('voice_output', newValue.toString());
    emit(state.copyWith(isVoiceOutputEnabled: newValue));
  }

  Future<void> _onChangeLanguage(ChangeLanguageEvent event, Emitter<SettingsState> emit) async {
    await DatabaseHelper.saveSetting('language', event.languageCode);
    emit(state.copyWith(languageCode: event.languageCode));
  }
}
