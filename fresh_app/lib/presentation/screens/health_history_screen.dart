import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../services/ai_engine.dart';
import '../../services/medical_diagnosis_service.dart';

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  List<Map<String, dynamic>> _chronicPatterns = [];
  int _totalDiagnoses = 0;
  int _correctDiagnoses = 0;
  double _accuracy = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final brain = AIBrain.instance;
    _chronicPatterns = brain.getChronicPatterns();
    final stats = brain.getStats();
    _totalDiagnoses = stats['totalDiagnoses'];
    _correctDiagnoses = stats['correctDiagnoses'];
    _accuracy = stats['accuracy'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Health History'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadData();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAIStatsCard(),
              const SizedBox(height: 24),
              _buildChronicPatternsCard(),
              const SizedBox(height: 24),
              _buildRecentHistoryCard(),
              const SizedBox(height: 24),
              _buildInsightsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology, color: Colors.white, size: 32),
              const SizedBox(width: 8),
              const Text(
                '🧠 AI Learning Stats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', '$_totalDiagnoses', Icons.analytics),
              _buildStatItem('Correct', '$_correctDiagnoses', Icons.check_circle),
              _buildStatItem('Accuracy', '${(_accuracy * 100).toStringAsFixed(0)}%', Icons.trending_up),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  _accuracy >= 0.7 
                      ? '🎉 AI is learning well from your feedback!'
                      : '📈 Keep providing feedback to improve AI',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildChronicPatternsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  '⚠️ Chronic Patterns Detected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Frequently reported symptoms that may need attention',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            if (_chronicPatterns.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No chronic patterns detected yet. Keep using the app to track your health.',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._chronicPatterns.map((pattern) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${pattern['count']}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pattern['symptom'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pattern['possibleCause'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHistoryCard() {
    final history = AIBrain.instance.healthHistory.reversed.take(10).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  '📋 Recent Diagnoses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No diagnosis history yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...history.map((record) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  record.wasCorrect ? Icons.check_circle : Icons.cancel,
                  color: record.wasCorrect ? Colors.green : Colors.red,
                ),
                title: Text(record.diagnosis ?? 'Unknown'),
                subtitle: Text(
                  '${record.symptoms.take(3).join(", ")} • ${record.timestamp.day}/${record.timestamp.month}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  '${(record.confidence ?? 0 * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: (record.confidence ?? 0) > 0.7 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    final insights = <String>[];
    
    if (_accuracy > 0.7) {
      insights.add('✅ Your feedback is helping AI improve!');
    }
    if (_chronicPatterns.isNotEmpty) {
      insights.add('⚠️ Consider consulting a doctor for frequent symptoms');
    }
    if (_totalDiagnoses > 20) {
      insights.add('📊 Good progress! Keep tracking your health');
    }
    insights.add('💡 Tip: Answer "Was this correct?" after each diagnosis to help AI learn');

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
                  '💡 Health Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 14)),
                  Expanded(child: Text(insight, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
