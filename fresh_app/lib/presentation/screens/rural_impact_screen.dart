import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../services/medical_diagnosis_service.dart';

class RuralImpactScreen extends StatefulWidget {
  const RuralImpactScreen({super.key});

  @override
  State<RuralImpactScreen> createState() => _RuralImpactScreenState();
}

class _RuralImpactScreenState extends State<RuralImpactScreen> {
  String? _selectedCondition;
  bool _hasDoctor = true;
  double _distanceToDoctor = 50.0;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _impactAnalysis;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏥 Rural Impact Mode'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDoctorAvailability(),
            const SizedBox(height: 24),
            _buildConditionSelector(),
            if (_selectedCondition != null) ...[
              const SizedBox(height: 24),
              _buildAnalyzeButton(),
            ],
            if (_isAnalyzing) ...[
              const SizedBox(height: 24),
              _buildAnalyzingState(),
            ],
            if (_impactAnalysis != null && !_isAnalyzing) ...[
              const SizedBox(height: 24),
              _buildImpactResults(),
            ],
            const SizedBox(height: 24),
            _buildRuralTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.health_and_safety, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            '🏥 Rural Impact Mode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI-powered decision making for areas with limited medical access',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureChip(Icons.location_off, 'Offline'),
              const SizedBox(width: 8),
              _buildFeatureChip(Icons.people, 'Rural Focus'),
              const SizedBox(width: 8),
              _buildFeatureChip(Icons.shield, 'Safe'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDoctorAvailability() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_hospital, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Doctor Availability',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is there a doctor nearby?'),
              subtitle: Text(_hasDoctor ? 'Doctor available within area' : 'No doctor in immediate vicinity'),
              value: _hasDoctor,
              onChanged: (value) => setState(() => _hasDoctor = value),
              activeColor: Colors.green,
            ),
            if (!_hasDoctor) ...[
              const SizedBox(height: 8),
              Text(
                'Distance to nearest doctor: ${_distanceToDoctor.toStringAsFixed(0)} km',
                style: const TextStyle(fontSize: 14),
              ),
              Slider(
                value: _distanceToDoctor,
                min: 5,
                max: 100,
                divisions: 19,
                label: '${_distanceToDoctor.toStringAsFixed(0)} km',
                onChanged: (value) => setState(() => _distanceToDoctor = value),
                activeColor: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConditionSelector() {
    final conditions = MedicalDiagnosisService.instance.conditions;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Select Emergency Condition',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: conditions.map((c) {
                final isSelected = _selectedCondition == c.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCondition = c.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.red : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Colors.red, size: 16),
                        if (isSelected) const SizedBox(width: 4),
                        Text(
                          c.name,
                          style: TextStyle(
                            color: isSelected ? Colors.red : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _analyzeImpact,
        icon: const Icon(Icons.analytics),
        label: const Text(
          '🔍 Analyze Rural Impact',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Future<void> _analyzeImpact() async {
    setState(() {
      _isAnalyzing = true;
      _impactAnalysis = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    final condition = MedicalDiagnosisService.instance.getConditionById(_selectedCondition ?? '');
    final isCritical = condition?.severity == 'critical' || condition?.severity == 'severe';
    
    setState(() {
      _isAnalyzing = false;
      _impactAnalysis = {
        'condition': condition?.name ?? 'Unknown',
        'severity': condition?.severity ?? 'unknown',
        'shouldTravel': !_hasDoctor && isCritical,
        'safeToWait': _hasDoctor || !isCritical,
        'travelTime': _distanceToDoctor * 2,
        'homeCareSteps': condition?.firstAid.take(5).toList() ?? [],
        'riskLevel': _calculateRiskLevel(condition?.severity ?? 'mild'),
        'recommendation': _getRecommendation(condition?.severity ?? 'mild'),
      };
    });
  }

  String _calculateRiskLevel(String severity) {
    if (severity == 'critical') return 'HIGH';
    if (severity == 'severe') return 'MEDIUM-HIGH';
    if (severity == 'moderate') return 'MEDIUM';
    return 'LOW';
  }

  String _getRecommendation(String severity) {
    if (severity == 'critical') {
      return 'URGENT: Seek immediate medical attention. Call emergency services (102/108). Do not wait.';
    }
    if (severity == 'severe') {
      if (_hasDoctor) {
        return 'Visit doctor within 24 hours. Start first aid now.';
      } else {
        return 'Plan to travel to doctor. Start first aid and monitor closely. If worsens, call emergency.';
      }
    }
    return 'First aid at home recommended. Monitor symptoms. Consult doctor if no improvement in 48 hours.';
  }

  Widget _buildAnalyzingState() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Analyzing Rural Impact...',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Calculating best course of action',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactResults() {
    final analysis = _impactAnalysis!;
    final riskColor = analysis['riskLevel'] == 'HIGH' ? Colors.red : 
                      analysis['riskLevel'] == 'MEDIUM-HIGH' ? Colors.orange : Colors.amber;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  '📊 Impact Analysis Results',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: riskColor),
              ),
              child: Row(
                children: [
                  Icon(
                    analysis['riskLevel'] == 'HIGH' ? Icons.warning : Icons.info_outline,
                    color: riskColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Risk Level: ${analysis['riskLevel']}',
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          analysis['recommendation'],
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            if (!_hasDoctor) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Travel Recommendation',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            analysis['shouldTravel'] 
                                ? '⚠️ URGENT travel needed - ${(analysis['travelTime'] as double).toStringAsFixed(0)} min to nearest facility'
                                : '✓ Can safely wait or travel normally',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            const Text(
              '🩹 Safe Home Care Steps:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...((analysis['homeCareSteps'] as List).asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.value)),
                ],
              ),
            ))),
          ],
        ),
      ),
    );
  }

  Widget _buildRuralTips() {
    final tips = [
      '🚑 Keep emergency numbers saved: 102, 108, 112',
      '💊 First aid kit essential in rural areas',
      '🏥 PHC (Primary Health Centre) available in most villages',
      '📱 App works offline - no internet needed',
      '🩸 Blood donation camps - check local schedule',
      '👨‍⚕️ ASHA worker can help with basic healthcare',
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                const Text(
                  '💡 Rural Healthcare Tips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(tip, style: const TextStyle(fontSize: 13)),
            )),
          ],
        ),
      ),
    );
  }
}
