import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/animations.dart';
import '../../services/ai_engine.dart';
import '../../services/medical_diagnosis_service.dart';

class DemoModeScreen extends StatefulWidget {
  const DemoModeScreen({super.key});

  @override
  State<DemoModeScreen> createState() => _DemoModeScreenState();
}

class _DemoModeScreenState extends State<DemoModeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final DemoMode _demoMode = DemoMode();
  List<DemoScenario> _scenarios = [];
  bool _isRunning = false;
  int _currentIndex = 0;
  Map<String, double>? _results;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scenarios = _demoMode.getScenarios();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _runDemo(DemoScenario scenario) async {
    setState(() {
      _isRunning = true;
      _currentIndex = _scenarios.indexOf(scenario);
    });

    final conditions = MedicalDiagnosisService.instance.conditions;
    final diseaseSymptoms = <String, List<String>>{};
    for (final condition in conditions) {
      diseaseSymptoms[condition.id] = condition.symptoms;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _results = ConfidenceSystem.calculateConfidence(diseaseSymptoms, scenario.symptoms);
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Mode'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDemoHeader(),
              const SizedBox(height: 24),
              _buildScenariosList(),
              if (_results != null) ...[
                const SizedBox(height: 24),
                _buildResults(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.play_circle_filled, color: Colors.white, size: 64),
          const SizedBox(height: 12),
          const Text(
            'Demo Mode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pre-filled scenarios for quick testing',
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge(Icons.science, 'AI Test'),
              const SizedBox(width: 8),
              _buildBadge(Icons.speed, 'Fast'),
              const SizedBox(width: 8),
              _buildBadge(Icons.offline_bolt, 'Offline'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildScenariosList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sample Scenarios',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List.generate(_scenarios.length, (index) {
          final scenario = _scenarios[index];
          return _buildScenarioCard(scenario, index);
        }),
      ],
    );
  }

  Widget _buildScenarioCard(DemoScenario scenario, int index) {
    final isSelected = _currentIndex == index;
    final isRunningThis = _isRunning && isSelected;

    return AppAnimations.fadeIn(
      delayMs: index * 50,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSelected
              ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: _isRunning ? null : () => _runDemo(scenario),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  scenario.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              _buildSeverityBadge(scenario.severity),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scenario.description,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (isRunningThis)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: scenario.symptoms.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    String label;
    switch (severity) {
      case 'critical':
        color = Colors.red;
        label = 'CRITICAL';
        break;
      case 'severe':
        color = Colors.orange;
        label = 'SEVERE';
        break;
      case 'moderate':
        color = Colors.amber;
        label = 'MODERATE';
        break;
      default:
        color = Colors.green;
        label = 'MILD';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_results == null) return const SizedBox.shrink();

    final sortedResults = _results!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'AI Predictions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedResults.take(5).map((entry) {
              final confidence = entry.value;
              final color = confidence > 0.7
                  ? Colors.green
                  : (confidence > 0.4 ? Colors.orange : Colors.red);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ConfidenceSystem.formatConfidence(confidence),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: confidence,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
