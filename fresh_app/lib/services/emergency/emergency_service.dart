import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/medical_entities.dart';

class LocationService {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Map<String, double>? _lastPosition;

  Future<void> initialize() async { _isInitialized = true; }

  Future<bool> checkPermission() async {
    return true;
  }

  Future<Map<String, double>?> getCurrentLocation() async {
    return null;
  }

  String formatLocationForSMS(Map<String, double> position) {
    final lat = position['latitude']!.toStringAsFixed(6);
    final lon = position['longitude']!.toStringAsFixed(6);
    return 'My location: https://maps.google.com/?q=$lat,$lon';
  }

  void dispose() { _isInitialized = false; }
}

class EmergencyService {
  late final LocationService locationService;
  bool _isInitialized = false;
  
  EmergencyService() : locationService = LocationService();
  
  Future<void> initialize() async {
    await locationService.initialize();
    _isInitialized = true;
  }

  Future<bool> callEmergencyNumber(String number) async {
    try {
      final uri = Uri(scheme: 'tel', path: number);
      return await canLaunchUrl(uri) && await launchUrl(uri);
    } catch (e) { return false; }
  }

  Future<bool> sendEmergencySMS({required List<EmergencyContact> contacts, required String message, Map<String, double>? location}) async {
    try {
      String fullMessage = message;
      if (location != null) fullMessage += '\n\n${locationService.formatLocationForSMS(location)}';
      fullMessage += '\n\nSent from MediGuide AI';
      for (final contact in contacts) {
        final uri = Uri(scheme: 'sms', path: contact.phoneNumber, queryParameters: {'body': fullMessage});
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
      return true;
    } catch (e) { return false; }
  }

  Future<EmergencyResult> triggerEmergencySOS({required List<EmergencyContact> contacts, required String emergencyType}) async {
    final position = await locationService.getCurrentLocation();
    final message = 'EMERGENCY ALERT from MediGuide AI\n\nType: $emergencyType\nTime: ${DateTime.now()}\n\nPlease help me or call emergency services (911).';
    final smsSent = await sendEmergencySMS(contacts: contacts, message: message, location: position);
    return EmergencyResult(locationSent: position != null, smsSent: smsSent, location: position);
  }
}

class EmergencyResult {
  final bool locationSent;
  final bool smsSent;
  final Map<String, double>? location;
  EmergencyResult({required this.locationSent, required this.smsSent, this.location});
}
