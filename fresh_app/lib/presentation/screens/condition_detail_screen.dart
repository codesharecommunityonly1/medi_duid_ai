import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../services/medical_diagnosis_service.dart';

class ConditionDetailScreen extends StatelessWidget {
  final MedicalCondition condition;

  const ConditionDetailScreen({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    final severityColor = {
      'critical': Colors.red,
      'severe': Colors.orange,
      'moderate': Colors.amber,
      'mild': Colors.green,
    }[condition.severity] ?? Colors.grey;

    final service = MedicalDiagnosisService.instance;
    final response = service.buildGuidanceResponse(condition);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: severityColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                condition.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      severityColor,
                      severityColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(condition.category),
                    size: 60,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  condition.isFavorite ? Icons.star : Icons.star_border,
                  color: condition.isFavorite ? Colors.amber : Colors.white,
                ),
                onPressed: () async {
                  await service.toggleFavorite(condition.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          condition.isFavorite
                              ? 'Removed from favorites'
                              : 'Added to favorites ⭐',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCards(context, severityColor),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    '🩺 Symptoms',
                    Icons.medical_services,
                    Colors.blue,
                    condition.symptoms.map((s) => '• $s').join('\n'),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    '🚑 First Aid Steps',
                    Icons.healing,
                    Colors.green,
                    condition.firstAid.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n'),
                  ),
                  if (condition.organicRemedies.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '🌿 Natural Remedies',
                      Icons.eco,
                      Colors.green.shade700,
                      condition.organicRemedies.map((o) => '• $o').join('\n'),
                    ),
                  ],
                  if (condition.medications.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '💊 Medications',
                      Icons.medication,
                      Colors.purple,
                      condition.medications.map((m) => '• $m').join('\n'),
                    ),
                  ],
                  if (condition.emergencyWarning.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildEmergencyCard(context, condition.emergencyWarning),
                  ],
                  if (condition.whenToSeekDoctor.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '🏥 When to See Doctor',
                      Icons.local_hospital,
                      Colors.red.shade400,
                      condition.whenToSeekDoctor,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildFullGuidanceCard(context, response),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context, Color severityColor) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            context,
            'Severity',
            condition.severity.toUpperCase(),
            severityColor,
            Icons.warning_amber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoCard(
            context,
            'Category',
            condition.category,
            AppColors.primary,
            Icons.category,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, Color color, String content) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context, String warning) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emergency, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '⚠️ EMERGENCY WARNING',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              warning,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullGuidanceCard(BuildContext context, String guidance) {
    return Card(
      color: AppColors.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '📋 Full Guidance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              guidance,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'emergency':
        return Icons.emergency;
      case 'respiratory':
        return Icons.air;
      case 'digestive':
        return Icons.restaurant;
      case 'pain':
        return Icons.healing;
      case 'skin':
        return Icons.face;
      case 'neurological':
        return Icons.psychology;
      case 'heart & blood':
        return Icons.favorite;
      case 'mental health':
        return Icons.mood;
      case 'allergies':
        return Icons.warning_amber;
      case 'eye & ear':
        return Icons.visibility;
      case 'injuries':
        return Icons.local_hospital;
      case 'chronic conditions':
        return Icons.medical_services;
      default:
        return Icons.medical_services;
    }
  }
}
