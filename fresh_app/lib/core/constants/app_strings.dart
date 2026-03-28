import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF10A37F);
  static const Color primaryDark = Color(0xFF0D8A66);
  static const Color secondary = Color(0xFF6366F1);
  
  // High contrast emergency colors (for medical apps)
  static const Color emergency = Color(0xFFDC2626);
  static const Color emergencyDark = Color(0xFFB91C1C);
  static const Color emergencyLight = Color(0xFFFEE2E2);
  
  // Status colors - high contrast
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);
  static const Color successDark = Color(0xFF16A34A);
  
  // Background - high contrast for readability
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  
  // Surface - high contrast
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);
  
  // Text - high contrast for readability under stress
  static const Color textPrimary = Color(0xFF0F172A);  // Almost black
  static const Color textSecondary = Color(0xFF475569);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  
  // Emergency specific
  static const Color emergencyBg = Color(0xFFDC2626);
  static const Color warningBg = Color(0xFFFEF3C7);
  
  // Chain of Thought visualization
  static const Color reasoningStep = Color(0xFFE0F2FE);
  static const Color reasoningStepActive = Color(0xFF0284C7);
}

class AppStrings {
  static const String appName = 'MediGuide AI';
  static const String settingsTitle = 'Settings';
  static const String homeTitle = 'MediGuide AI';
  static const String homeSubtitle = 'Your offline emergency medical assistant';
  static const String inputTitle = 'Describe Symptoms';
  static const String resultsTitle = 'First Aid Results';
  static const String resultsWarning = 'Warnings';
  static const String resultsDisclaimer = 'This is first-aid guidance only. Not a substitute for professional medical advice.';
  static const String settingsTheme = 'Dark Mode';
  static const String settingsVoice = 'Voice Output';
  static const String emergencyTitle = 'Emergency SOS';
  static const String emergencyCallNow = 'Call Emergency Services';
  static const String emergencyShareLocation = 'Share Location';
  static const String emergencyDone = 'I\'m Safe';
  static const String cameraTitle = 'Analyze Injury';
  static const String splashTitle = 'MediGuide AI';
  static const String splashLoading = 'Initializing AI...';
  static const String homeVoiceButton = 'Voice Input';
  static const String homeManualButton = 'Manual Input';
  static const String homeCameraButton = 'Camera Analysis';
  static const String homeEmergencyButton = 'Emergency SOS';
  static const String inputHint = 'Describe your symptoms...';
  static const String inputProcessing = 'Analyzing...';
  static const String inputListening = 'Listening...';
  static const String inputTapToSpeak = 'Tap to speak';
  static const String emergencyInstructions = 'Tap a button below to get help immediately';
  static const String emergencyCallAmbulance = 'Call Ambulance';
  static const String emergencySendSMS = 'Send Emergency SMS';
  static const String cameraAnalyzing = 'Analyzing injury...';
  static const String appTagline = 'Offline Emergency Medical AI';
  static const String homeTab = 'Home';
  static const String accidentTab = 'Accident';
  static const String sosTab = 'SOS';
  static const String ruralEmergency = 'Rural AI Doctor';
  static const String aiDashboard = 'AI Dashboard';
}
