import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_strings.dart';
import '../../services/emergency_numbers_service.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/settings/settings_event.dart';
import '../bloc/settings/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCountry = 'India';
  CountryEmergencyNumbers? _currentEmergency;

  @override
  void initState() {
    super.initState();
    _loadCountry();
  }

  Future<void> _loadCountry() async {
    final prefs = await SharedPreferences.getInstance();
    final country = prefs.getString('selected_country') ?? 'India';
    setState(() {
      _selectedCountry = country;
      _currentEmergency = CountryEmergencyNumbers.getByCountry(country);
    });
  }

  Future<void> _saveCountry(String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_country', country);
    setState(() {
      _selectedCountry = country;
      _currentEmergency = CountryEmergencyNumbers.getByCountry(country);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(context, title: 'Mode', children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(8),
                    ), 
                    child: const Icon(Icons.wifi_off, color: Colors.green),
                  ),
                  title: const Text('Offline Mode'),
                  subtitle: const Text('Works without internet using local database'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              ]),
              _section(context, title: 'Safety Features', children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(
                      color: AppColors.emergency.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(8),
                    ), 
                    child: const Icon(Icons.health_and_safety, color: AppColors.emergency),
                  ), 
                  title: const Text('Safety Filter'), 
                  subtitle: const Text('High-risk keyword detection + Confidence Score'),
                  trailing: const Icon(Icons.check_circle, color: AppColors.success),
                ),
                const ListTile(
                  leading: Icon(Icons.warning_amber, color: Colors.orange),
                  title: Text('Confidence Threshold'),
                  subtitle: Text('80% - Below this: "Consult a doctor"'),
                ),
              ]),
              _section(context, title: 'Appearance', children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), 
                    child: const Icon(Icons.dark_mode, color: AppColors.primary),
                  ), 
                  title: const Text(AppStrings.settingsTheme), 
                  trailing: Switch(value: state.isDarkMode, onChanged: (_) => context.read<SettingsBloc>().add(ToggleDarkModeEvent())),
                ),
              ]),
              _section(context, title: 'Voice & Audio', children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), 
                    child: const Icon(Icons.record_voice_over, color: AppColors.primary),
                  ), 
                  title: const Text(AppStrings.settingsVoice), 
                  trailing: Switch(value: state.isVoiceOutputEnabled, onChanged: (_) => context.read<SettingsBloc>().add(ToggleVoiceOutputEvent())),
                ),
              ]),
              _section(context, title: 'Emergency Numbers', children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), 
                    child: const Icon(Icons.public, color: Colors.red),
                  ), 
                  title: const Text('Select Your Country'),
                  subtitle: Text(_selectedCountry),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showCountrySelector(context),
                ),
                if (_currentEmergency != null) ...[
                  _buildEmergencyNumberTile('🚔 Police', _currentEmergency!.police, Icons.local_police),
                  _buildEmergencyNumberTile('🚑 Ambulance', _currentEmergency!.ambulance, Icons.local_hospital),
                  _buildEmergencyNumberTile('🆘 General Emergency', _currentEmergency!.generalEmergency, Icons.emergency),
                ],
              ]),
              _section(context, title: 'About', children: [
                const ListTile(leading: Icon(Icons.info_outline), title: Text(AppStrings.appName), subtitle: Text('Version 4.0 - AI Edition')),
                const ListTile(
                  leading: Icon(Icons.offline_bolt), 
                  title: Text('Offline AI'),
                  subtitle: Text('Powered by Neural LLM + Medical Database'),
                ),
                const ListTile(
                  leading: Icon(Icons.psychology), 
                  title: Text('AI Features'),
                  subtitle: Text('RL Learning + Neural Network + Pattern Detection'),
                ),
              ]),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.health_and_safety, color: Colors.green, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'MediGuide AI',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Your offline medical assistant',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmergencyNumberTile(String title, String number, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.red.shade700),
      title: Text(title),
      subtitle: Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  void _showCountrySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.public, color: Colors.red),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Select Your Country',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: CountryEmergencyNumbers.countries.length,
                itemBuilder: (_, index) {
                  final country = CountryEmergencyNumbers.countries[index];
                  return ListTile(
                    leading: Text(country.countryCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                    title: Text(country.country),
                    subtitle: Text('Police: ${country.police} | Ambulance: ${country.ambulance}'),
                    trailing: _selectedCountry == country.country 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      _saveCountry(country.country);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(children: children),
        ),
      ],
    );
  }
}
