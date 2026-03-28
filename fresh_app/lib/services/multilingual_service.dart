class MultilingualService {
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'hi', 'es'];

  static Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'MediGuide AI',
      'home_subtitle': 'Your Offline Medical Assistant',
      'voice_input': 'Voice Input',
      'manual_input': 'Manual Input',
      'camera': 'Camera Analysis',
      'emergency': 'Emergency SOS',
      'settings': 'Settings',
      'offline_mode': 'Offline Mode',
      'online_mode': 'Online Mode',
      'processing': 'Processing...',
      'get_guidance': 'Get First Aid Guidance',
      'emergency_detected': '🚨 EMERGENCY DETECTED',
      'call_911': 'Call 911 Now',
      'stay_calm': 'Stay Calm',
      'first_aid': 'First Aid',
      'organic_solution': 'Organic Solution',
      'chemical_solution': 'Medical Solution',
      'warnings': 'Warnings',
      'disclaimer': 'This is AI guidance only. Consult a doctor.',
      'try_online': 'Switch to Online Mode for detailed analysis',
      'no_match_found': 'No matching condition found',
    },
    'hi': {
      'app_name': 'मेडीगाइड AI',
      'home_subtitle': 'आपका ऑफलाइन मेडिकल असिस्टेंट',
      'voice_input': 'वॉइस इनपुट',
      'manual_input': 'मैनुअल इनपुट',
      'camera': 'कैमरा विश्लेषण',
      'emergency': 'आपातकालीन SOS',
      'settings': 'सेटिंग्स',
      'offline_mode': 'ऑफलाइन मोड',
      'online_mode': 'ऑनलाइन मोड',
      'processing': 'प्रोसेसिंग...',
      'get_guidance': 'प्राथमिक चिकित्सा मार्गदर्शन प्राप्त करें',
      'emergency_detected': '🚨 आपातकालीन स्थिति का पता चला',
      'call_911': '911 को कॉल करें',
      'stay_calm': 'शांत रहें',
      'first_aid': 'प्राथमिक चिकित्सा',
      'organic_solution': 'प्राकृतिक समाधान',
      'chemical_solution': 'चिकित्सा समाधान',
      'warnings': 'चेतावनियाँ',
      'disclaimer': 'यह केवल AI मार्गदर्शन है। डॉक्टर से परामर्श करें।',
      'try_online': 'विस्तृत विश्लेषण के लिए ऑनलाइन मोड में स्विच करें',
      'no_match_found': 'कोई मिलान स्थिति नहीं मिली',
    },
    'es': {
      'app_name': 'MediGuide AI',
      'home_subtitle': 'Tu Asistente Médico Sin Conexión',
      'voice_input': 'Entrada de Voz',
      'manual_input': 'Entrada Manual',
      'camera': 'Análisis de Cámara',
      'emergency': 'SOS de Emergencia',
      'settings': 'Configuración',
      'offline_mode': 'Modo Sin Conexión',
      'online_mode': 'Modo En Línea',
      'processing': 'Procesando...',
      'get_guidance': 'Obtener Guía de Primeros Auxilios',
      'emergency_detected': '🚨 EMERGENCIA DETECTADA',
      'call_911': 'Llamar al 911',
      'stay_calm': 'Mantén la Calma',
      'first_aid': 'Primeros Auxilios',
      'organic_solution': 'Solución Natural',
      'chemical_solution': 'Solución Médica',
      'warnings': 'Advertencias',
      'disclaimer': 'Esto es solo guía de IA. Consulta a un médico.',
      'try_online': 'Cambia al modo en línea para análisis detallado',
      'no_match_found': 'No se encontró condición coincidente',
    },
  };

  static Map<String, Map<String, String>> _medicalTerms = {
    'en': {
      'chest_pain': 'Chest Pain',
      'bleeding': 'Bleeding',
      'burn': 'Burn',
      'fracture': 'Fracture',
      'headache': 'Headache',
      'fever': 'Fever',
      'cough': 'Cough',
      'nausea': 'Nausea',
      'dizziness': 'Dizziness',
      'shortness_of_breath': 'Shortness of Breath',
    },
    'hi': {
      'chest_pain': 'छाती में दर्द',
      'bleeding': 'खून बहना',
      'burn': 'जलना',
      'fracture': 'हड्डी टूटना',
      'headache': 'सिरदर्द',
      'fever': 'बुखार',
      'cough': 'खाँसी',
      'nausea': 'मतली',
      'dizziness': 'सिर में चक्कर',
      'shortness_of_breath': 'साँस फूलना',
    },
    'es': {
      'chest_pain': 'Dolor en el Pecho',
      'bleeding': 'Sangrado',
      'burn': 'Quemadura',
      'fracture': 'Fractura',
      'headache': 'Dolor de Cabeza',
      'fever': 'Fiebre',
      'cough': 'Tos',
      'nausea': 'Náusea',
      'dizziness': 'Mareo',
      'shortness_of_breath': 'Falta de Aire',
    },
  };

  static String translate(String key, String languageCode) {
    if (languageCode == defaultLanguage) {
      return _translations[defaultLanguage]![key] ?? key;
    }
    return _translations[languageCode]?[key] ?? _translations[defaultLanguage]![key] ?? key;
  }

  static String translateMedicalTerm(String termKey, String languageCode) {
    return _medicalTerms[languageCode]?[termKey] ?? _medicalTerms['en']![termKey] ?? termKey;
  }

  static String getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'hi': return 'हिंदी (Hindi)';
      case 'es': return 'Español (Spanish)';
      default: return 'English';
    }
  }

  static String detectLanguage(String text) {
    // Simple language detection based on character ranges
    final hindiChars = text.codeUnits.where((c) => c >= 0x0900 && c <= 0x097F);
    final spanishChars = text.toLowerCase().contains(RegExp(r'[áéíóúñü]'));
    
    if (hindiChars.isNotEmpty) return 'hi';
    if (spanishChars) return 'es';
    return 'en';
  }
}
