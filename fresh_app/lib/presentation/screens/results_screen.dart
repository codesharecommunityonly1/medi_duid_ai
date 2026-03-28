import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/medical_entities.dart';
import '../bloc/medical/medical_bloc.dart';
import '../bloc/medical/medical_event.dart';
import '../bloc/medical/medical_state.dart';
import 'emergency_screen.dart';
import 'home_screen.dart';

class ResultsScreen extends StatelessWidget {
  final SymptomEntity symptom;
  const ResultsScreen({super.key, required this.symptom});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicalBloc, MedicalState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.resultsTitle),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                context.read<MedicalBloc>().add(ClearMedicalStateEvent());
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(state.isSpeaking ? Icons.stop : Icons.volume_up),
                onPressed: () {
                  if (state.isSpeaking) {
                    context.read<MedicalBloc>().add(StopSpeakingEvent());
                  } else {
                    context.read<MedicalBloc>().add(SpeakResultEvent(text: symptom.firstAidGuidance));
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: symptom.severity == SymptomSeverity.severe 
                        ? AppColors.emergency.withOpacity(0.1) 
                        : AppColors.success.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        symptom.severity == SymptomSeverity.severe ? Icons.warning_amber : Icons.check_circle, 
                        color: symptom.severity == SymptomSeverity.severe ? AppColors.emergency : AppColors.success, 
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          symptom.severity == SymptomSeverity.severe 
                              ? 'SEVERE - Seek Immediate Help' 
                              : symptom.severity == SymptomSeverity.moderate 
                                  ? 'MODERATE - Seek Medical Attention' 
                                  : 'Minor - First Aid Guidance', 
                          style: TextStyle(
                            color: symptom.severity == SymptomSeverity.severe ? AppColors.emergency : AppColors.success, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface, 
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.medical_services, color: AppColors.primary), 
                          SizedBox(width: 12), 
                          Text('First Aid Guidance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(symptom.firstAidGuidance, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
                    ],
                  ),
                ),
                if (symptom.warnings.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.emergencyLight, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber, color: AppColors.emergency), 
                            SizedBox(width: 8), 
                            Text(AppStrings.resultsWarning, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.emergency)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...symptom.warnings.map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 8), 
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children: [
                              const Icon(Icons.circle, size: 8, color: AppColors.emergency), 
                              const SizedBox(width: 12), 
                              Expanded(child: Text(w)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.grey), 
                      SizedBox(width: 12), 
                      Expanded(child: Text(AppStrings.resultsDisclaimer, style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, 
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencyScreen())), 
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergency, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), 
                    icon: const Icon(Icons.emergency), 
                    label: const Text('Emergency SOS'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, 
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<MedicalBloc>().add(ClearMedicalStateEvent());
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()), 
                        (route) => false,
                      );
                    }, 
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), 
                    icon: const Icon(Icons.home), 
                    label: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
