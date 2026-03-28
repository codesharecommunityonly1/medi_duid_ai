import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable { 
  @override 
  List<Object?> get props => []; 
}

class LoadSettingsEvent extends SettingsEvent {}
class ToggleDarkModeEvent extends SettingsEvent {}
class ToggleVoiceOutputEvent extends SettingsEvent {}
class ChangeLanguageEvent extends SettingsEvent { 
  final String languageCode; 
  ChangeLanguageEvent({required this.languageCode}); 
  @override 
  List<Object?> get props => [languageCode]; 
}
