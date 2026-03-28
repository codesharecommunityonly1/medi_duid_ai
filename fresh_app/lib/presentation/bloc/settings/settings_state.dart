import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final bool isVoiceOutputEnabled;
  final String languageCode;
  final double speechRate;
  final bool isLoaded;

  const SettingsState({
    this.isDarkMode = false,
    this.isVoiceOutputEnabled = true,
    this.languageCode = 'en',
    this.speechRate = 0.5,
    this.isLoaded = false,
  });

  SettingsState copyWith({
    bool? isDarkMode, 
    bool? isVoiceOutputEnabled, 
    String? languageCode, 
    double? speechRate, 
    bool? isLoaded,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isVoiceOutputEnabled: isVoiceOutputEnabled ?? this.isVoiceOutputEnabled,
      languageCode: languageCode ?? this.languageCode,
      speechRate: speechRate ?? this.speechRate,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [isDarkMode, isVoiceOutputEnabled, languageCode, speechRate, isLoaded];
}
