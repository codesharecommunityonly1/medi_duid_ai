import 'package:flutter/material.dart';
import '../../services/ai_brain_service.dart';
import '../../services/medical_diagnosis_service.dart';

class AIDashboardScreen extends StatefulWidget {
  const AIDashboardScreen({super.key});

  @override
  State<AIDashboardScreen> createState() => _AIDashboardScreenState();
}

class _AIDashboardScreenState extends State<AIDashboardScreen> {
  final AIBrainService _aiBrain = AIBrainService.instance;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await _aiBrain.initialize();
    setState(() {
      _stats = _aiBrain.getAIStats();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Brain Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 20),
                  _buildConfidenceChart(),
                  const SizedBox(height: 20),
                  _buildTopPredictions(),
                  const SizedBox(height: 20),
                  _buildLearningStats(),
                  const SizedBox(height: 20),
                  _buildRecentFeedback(),
                  const SizedBox(height: 20),
                  _buildResetButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    final totalDiagnoses = _stats?['totalDiagnoses'] ?? 0;
    final accuracy = _stats?['accuracy'] ?? 0.0;

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.psychology, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            const Text(
              'MedAI Brain',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI-Powered Diagnosis Engine',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Total Diagnoses', totalDiagnoses.toString(), Icons.assessment),
                _buildStatItem('Accuracy', '${accuracy.toStringAsFixed(1)}%', Icons.trending_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceChart() {
    final weights = _stats?['conditionWeights'] as Map<String, dynamic>? ?? {};
    if (weights.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.insights, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              const Text('No learning data yet'),
              const SizedBox(height: 8),
              Text(
                'Start diagnosing conditions to train the AI',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final sortedWeights = weights.entries.toList()
      ..sort((a, b) => (b.value['weight'] as double).compareTo(a.value['weight'] as double));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights),
                SizedBox(width: 8),
                Text(
                  'AI Confidence Weights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedWeights.take(5).map((entry) {
              final weight = entry.value['weight'] as double;
              final normalizedWeight = ((weight - 0.5) / 1.5).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('${(weight * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: normalizedWeight,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        weight > 1.2 ? Colors.green : (weight < 0.8 ? Colors.orange : Colors.blue),
                      ),
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

  Widget _buildTopPredictions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome),
                SizedBox(width: 8),
                Text(
                  'Top Conditions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPredictionRow('Flu', 0.85, Colors.blue),
            _buildPredictionRow('Cold', 0.72, Colors.green),
            _buildPredictionRow('Headache', 0.68, Colors.orange),
            _buildPredictionRow('Fever', 0.65, Colors.red),
            _buildPredictionRow('Allergy', 0.55, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionRow(String name, double confidence, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(confidence * 100).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _buildLearningStats() {
    final total = _stats?['totalDiagnoses'] ?? 0;
    final correct = _stats?['correctPredictions'] ?? 0;
    final incorrect = total - correct;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school),
                SizedBox(width: 8),
                Text(
                  'Learning Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressCard('Correct', correct, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProgressCard('Incorrect', incorrect, Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              total == 0 
                  ? 'No feedback data yet. Your diagnoses will help the AI learn!'
                  : 'The AI learns from your feedback to improve accuracy.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildRecentFeedback() {
    final feedback = _stats?['recentFeedback'] as List? ?? [];
    if (feedback.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history),
                SizedBox(width: 8),
                Text(
                  'Recent Feedback',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...feedback.take(5).map((f) => ListTile(
              leading: Icon(
                f['wasCorrect'] ? Icons.check_circle : Icons.cancel,
                color: f['wasCorrect'] ? Colors.green : Colors.red,
              ),
              title: Text(f['conditionId']),
              subtitle: Text(f['symptoms'].toString().split('|').take(2).join(', ')),
              dense: true,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reset Learning?'),
              content: const Text('This will clear all learned data and start fresh.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Reset', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await _aiBrain.resetLearning();
            await _loadStats();
          }
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Reset Learning'),
      ),
    );
  }
}
