import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/animations.dart';
import '../../services/medical_diagnosis_service.dart';
import '../bloc/medical/medical_bloc.dart';
import '../bloc/medical/medical_state.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/settings/settings_state.dart';
import 'input_screen.dart';
import 'emergency_screen.dart';
import 'camera_screen.dart';
import 'settings_screen.dart';
import 'accident_tab.dart';
import 'symptom_selector_screen.dart';
import 'condition_detail_screen.dart';
import 'rural_emergency_screen.dart';
import 'ai_dashboard_screen.dart';
import 'rural_impact_screen.dart';
import 'health_history_screen.dart';
import 'neural_llm_brain_screen.dart';
import 'ai_integration_hub.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _MainContent(),
    const AccidentTab(),
    const EmergencyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          indicatorColor: AppColors.primary.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 22),
              selectedIcon: Icon(Icons.home, size: 22, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.warning_amber_outlined, size: 22),
              selectedIcon: Icon(Icons.warning_amber, size: 22, color: AppColors.primary),
              label: 'Accident',
            ),
            NavigationDestination(
              icon: Icon(Icons.emergency_outlined, size: 22),
              selectedIcon: Icon(Icons.emergency, size: 22, color: AppColors.emergency),
              label: 'SOS',
            ),
          ],
        ),
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.medical_services, color: AppColors.primary, size: 26),
                                ),
                                const SizedBox(width: 12),
                                Text(AppStrings.appName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(AppStrings.appTagline, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _showLanguageDialog(context),
                              icon: const Icon(Icons.language, size: 22),
                              tooltip: 'Language',
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                                icon: const Icon(Icons.settings_outlined, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildUrgentHelpBanner(context),
                    const SizedBox(height: 16),
                    _buildOfflineStatus(context),
                    const SizedBox(height: 24),
                    
                    // Smart Diagnosis Button - Big Feature
                    _buildSmartDiagnosisCard(context),
                    
                    const SizedBox(height: 20),
                    Text("Quick Actions", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ActionCard(
                    icon: Icons.mic, 
                    title: AppStrings.homeVoiceButton, 
                    subtitle: 'Describe your symptoms', 
                    color: AppColors.primary, 
                    iconBg: AppColors.primary.withOpacity(0.1),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InputScreen(isVoiceInput: true))),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.edit_note, 
                    title: AppStrings.homeManualButton, 
                    subtitle: 'Type your symptoms', 
                    color: AppColors.secondary, 
                    iconBg: AppColors.secondary.withOpacity(0.1),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InputScreen(isVoiceInput: false))),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.camera_alt, 
                    title: AppStrings.homeCameraButton, 
                    subtitle: 'Analyze injuries', 
                    color: Colors.orange, 
                    iconBg: Colors.orange.withOpacity(0.1),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CameraScreen())),
                  ),
                  const SizedBox(height: 12),
                  
                  // Rural Emergency AI Button
                  _ActionCard(
                    icon: Icons.health_and_safety, 
                    title: AppStrings.ruralEmergency, 
                    subtitle: 'AI Diagnosis (RL Learning)', 
                    color: Colors.green, 
                    iconBg: Colors.green.withOpacity(0.1),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RuralEmergencyScreen())),
                  ),
                  const SizedBox(height: 12),
                  
                  // AI Dashboard Button
                  _ActionCard(
                    icon: Icons.analytics, 
                    title: AppStrings.aiDashboard, 
                    subtitle: 'View AI Brain Stats', 
                    color: Colors.purple, 
                    iconBg: Colors.purple.withOpacity(0.1),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AIDashboardScreen())),
                  ),
                  const SizedBox(height: 12),
                  
                  // Rural Impact Mode
                  _ActionCard(
                    icon: Icons.location_off, 
                    title: 'Rural Impact Mode', 
                    subtitle: 'No doctor nearby? AI decides', 
                    color: Colors.green.shade700, 
                    iconBg: Colors.green.shade100,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RuralImpactScreen())),
                  ),
                  const SizedBox(height: 12),
                   
                  // Health History
                  _ActionCard(
                    icon: Icons.history, 
                    title: 'Health History', 
                    subtitle: 'Your diagnosis records & patterns', 
                    color: Colors.blue.shade700, 
                    iconBg: Colors.blue.shade100,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthHistoryScreen())),
                  ),
                  const SizedBox(height: 12),
                   
                  // Neural LLM Brain
                  _ActionCard(
                    icon: Icons.psychology, 
                    title: 'AI Assistant', 
                    subtitle: 'Chat with intelligent AI', 
                    color: Colors.deepPurple, 
                    iconBg: Colors.deepPurple.withOpacity(0.1),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NeuralLLMBrainScreen())),
                  ),
                  const SizedBox(height: 12),
                   
                  // AI Integration Hub
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple.shade700, Colors.indigo.shade700],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AIIntegrationHub())),
                      icon: const Icon(Icons.hub, color: Colors.white),
                      label: const Text(
                        'AI Integration Hub',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                   
                   // Favorites Section
                  _buildFavoritesSection(context),
                  
                  const SizedBox(height: 20),
                  
                  // Emergency SOS Button
                  _buildEmergencyButton(context),
                  
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.08), Colors.green.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wifi_off, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📴 Offline Mode', 
                  style: TextStyle(
                    fontWeight: FontWeight.w600, 
                    color: Colors.green[700],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Works without internet • ${MedicalDiagnosisService.instance.conditions.length}+ conditions', 
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 12),
                SizedBox(width: 4),
                Text('Ready', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentHelpBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EmergencyScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade600, Colors.red.shade400],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.emergency, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '🚨 URGENT HELP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartDiagnosisCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SymptomSelectorScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🧠 Smart Diagnosis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select symptoms • Get AI-powered diagnosis with confidence %',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesSection(BuildContext context) {
    final favorites = MedicalDiagnosisService.instance.getFavorites();
    
    if (favorites.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('⭐ Favorites', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length > 5 ? 5 : favorites.length,
            itemBuilder: (context, index) {
              final condition = favorites[index];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ConditionDetailScreen(condition: condition)),
                ),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(height: 8),
                      Text(
                        condition.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EmergencyScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade600, Colors.red.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emergency, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚨 Emergency SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quick access to critical conditions & emergency services',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              onTap: () {
                MedicalDiagnosisService.instance.setLanguage('en');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language changed to English')),
                );
              },
            ),
            ListTile(
              leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
              title: const Text('हिंदी (Hindi)'),
              onTap: () {
                MedicalDiagnosisService.instance.setLanguage('hi');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('भाषा हिंदी में बदल दी गई')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconBg;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
