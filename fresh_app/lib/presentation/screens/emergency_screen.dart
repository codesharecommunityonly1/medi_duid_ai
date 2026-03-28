import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/animations.dart';
import '../../services/medical_diagnosis_service.dart';
import '../bloc/emergency/emergency_bloc.dart';
import '../bloc/emergency/emergency_event.dart';
import '../bloc/emergency/emergency_state.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    context.read<EmergencyBloc>().add(LoadEmergencyContactsEvent());
  }
  
  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmergencyBloc, EmergencyState>(
      listener: (context, state) {
        if (state.status == EmergencyStatus.sosTriggered && state.sosCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency alert sent!'), backgroundColor: AppColors.success));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFDC2626),
          appBar: AppBar(
            backgroundColor: Colors.transparent, 
            elevation: 0, 
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ), 
              onPressed: () => Navigator.of(context).pop()
            ), 
            title: const Text(AppStrings.emergencyTitle, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AnimatedBuilder(animation: _pulseController, builder: (context, child) {
                    return Container(
                      width: 140 + (_pulseController.value * 15), 
                      height: 140 + (_pulseController.value * 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15 - _pulseController.value * 0.05), 
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 100, 
                          height: 100, 
                          decoration: const BoxDecoration(
                            color: Colors.white, 
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                          ), 
                          child: const Icon(Icons.emergency, size: 48, color: Color(0xFFDC2626))
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🚨 RISK LEVEL: HIGH',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16), 
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15), 
                      borderRadius: BorderRadius.circular(16),
                    ), 
                    child: const Text(
                      AppStrings.emergencyInstructions, 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildImmediateSteps(context),
                  const SizedBox(height: 24),
                  _buildButton(
                    context, 
                    icon: Icons.phone, 
                    label: AppStrings.emergencyCallAmbulance, 
                    sublabel: 'Call 911 / 112', 
                    onTap: () => context.read<EmergencyBloc>().add(CallEmergencyEvent(number: '911'))
                  ),
                  const SizedBox(height: 14),
                  _buildButton(
                    context, 
                    icon: Icons.message, 
                    label: AppStrings.emergencySendSMS, 
                    sublabel: 'Send location to contacts', 
                    onTap: () => _showContactsSheet(context)
                  ),
                  const SizedBox(height: 14),
                  _buildButton(
                    context, 
                    icon: Icons.local_hospital, 
                    label: 'Nearby Hospital', 
                    sublabel: 'Find nearest hospital', 
                    onTap: () {},
                    small: true,
                  ),
                  const SizedBox(height: 24),
                  if (state.status == EmergencyStatus.sosTriggered && state.sosCompleted)
                    Container(
                      padding: const EdgeInsets.all(16), 
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.2), 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5)),
                      ), 
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 20), 
                          SizedBox(width: 8), 
                          Text('Emergency alert sent!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final quickActions = [
      {'icon': Icons.favorite, 'label': 'Heart Attack', 'color': Colors.red, 'condition': 'heart_attack'},
      {'icon': Icons.air, 'label': 'Choking', 'color': Colors.orange, 'condition': 'choking'},
      {'icon': Icons.warning, 'label': 'Stroke', 'color': Colors.purple, 'condition': 'stroke'},
      {'icon': Icons.local_fire_department, 'label': 'Burns', 'color': Colors.deepOrange, 'condition': 'burn'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Quick Emergency Actions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return AppAnimations.fadeIn(
                delayMs: index * 100,
                child: GestureDetector(
                  onTap: () => _showQuickActionDialog(context, action),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(action['icon'] as IconData, color: action['color'] as Color, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          action['label'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.touch_app, color: Colors.white54, size: 14),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showQuickActionDialog(BuildContext context, Map<String, dynamic> action) {
    final conditionId = action['condition'] as String;
    final condition = MedicalDiagnosisService.instance.getConditionById(conditionId);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (action['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            action['label'] as String,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (condition != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('⚠️ Warning', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              condition.emergencyWarning.isNotEmpty 
                                  ? condition.emergencyWarning 
                                  : 'This is a medical emergency. Call ambulance immediately!',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('🩹 First Aid Steps:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...condition.firstAid.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(entry.value, style: const TextStyle(fontSize: 15)),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.blue),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Call Emergency: 102 / 108',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.info_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('First aid information loading...', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImmediateSteps(BuildContext context) {
    final steps = [
      {'num': '1', 'text': 'Call emergency services immediately'},
      {'num': '2', 'text': 'Stay calm and do not move the person'},
      {'num': '3', 'text': 'Check breathing and provide first aid'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.format_list_numbered, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Immediate Steps',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        step['num'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step['text'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, {required IconData icon, required String label, required String sublabel, required VoidCallback onTap, bool small = false}) {
    return Material(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(16), 
      child: InkWell(
        onTap: onTap, 
        borderRadius: BorderRadius.circular(16), 
        child: Padding(
          padding: EdgeInsets.all(small ? 14 : 18), 
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(small ? 10 : 14), 
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(12),
                ), 
                child: Icon(icon, color: const Color(0xFFDC2626), size: small ? 22 : 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(label, style: TextStyle(fontSize: small ? 14 : 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(sublabel, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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

  void _showContactsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24), 
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor, 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Center(
              child: Container(
                width: 40, 
                height: 4, 
                decoration: BoxDecoration(
                  color: Colors.grey[300], 
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Send Emergency SOS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            BlocBuilder<EmergencyBloc, EmergencyState>(
              builder: (context, state) {
                if (state.contacts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16), 
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(12),
                    ), 
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFF59E0B)),
                        SizedBox(width: 12),
                        Expanded(child: Text('No emergency contacts. Add contacts in app settings.')),
                      ],
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text('Your Contacts (${state.contacts.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ...state.contacts.map((c) => ListTile(
                      contentPadding: EdgeInsets.zero, 
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1), 
                        child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ), 
                      title: Text(c.name), 
                      subtitle: Text(c.phoneNumber), 
                      trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => context.read<EmergencyBloc>().add(DeleteEmergencyContactEvent(id: c.id))),
                    )),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, 
              height: 54, 
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<EmergencyBloc>().add(TriggerEmergencySOSEvent(emergencyType: 'General Emergency'));
                  Navigator.of(context).pop();
                }, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626), 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), 
                ), 
                icon: const Icon(Icons.send), 
                label: const Text('Send SOS Alert', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}