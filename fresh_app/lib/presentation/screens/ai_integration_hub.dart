import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/medical_diagnosis_service.dart';
import '../../services/ai_engine.dart';
import '../../services/offline_llm_brain.dart';
import '../bloc/medical/medical_bloc.dart';
import '../bloc/medical/medical_state.dart';

class AIIntegrationHub extends StatefulWidget {
  const AIIntegrationHub({super.key});

  @override
  State<AIIntegrationHub> createState() => _AIIntegrationHubState();
}

class _AIIntegrationHubState extends State<AIIntegrationHub> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _aiStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAIStats();
  }

  Future<void> _loadAIStats() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final brainStats = AIBrain.instance.getStats();
    final neuralStats = ConversationalAI.instance.getStats();
    final medicalConditions = MedicalDiagnosisService.instance.conditions.length;
    
    setState(() {
      _aiStats = {
        'totalDiagnoses': brainStats['totalDiagnoses'] ?? 0,
        'correctDiagnoses': brainStats['correctDiagnoses'] ?? 0,
        'accuracy': brainStats['accuracy'] ?? 0.0,
        'healthHistoryCount': brainStats['healthHistoryCount'] ?? 0,
        'neuralTotal': neuralStats['totalDiagnoses'] ?? 0,
        'neuralCorrect': neuralStats['correctPredictions'] ?? 0,
        'neuralAccuracy': neuralStats['accuracy'] ?? 0.0,
        'medicalConditions': medicalConditions,
        'rlStats': brainStats['rlStats'] ?? {},
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 AI Integration Hub'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.psychology), text: 'Brain'),
            Tab(icon: Icon(Icons.science), text: 'ML'),
            Tab(icon: Icon(Icons.history), text: 'Learn'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrainTab(),
          _buildMLTab(),
          _buildLearningTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildBrainTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIEngineCard(
            '🤖 AIBrain (RL Engine)',
            'Reinforcement Learning with State-Action-Reward',
            [
              {'icon': Icons.layers, 'label': 'State', 'value': 'Symptoms'},
              {'icon': Icons.touch_app, 'label': 'Action', 'value': 'Diagnosis'},
              {'icon': Icons.star, 'label': 'Reward', 'value': '+1/-0.5'},
            ],
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildAIEngineCard(
            '🧠 Neural LLM Brain',
            '3-Layer Neural Network (Input → Hidden → Output)',
            [
              {'icon': Icons.input, 'label': 'Input', 'value': 'Symptom Features'},
              {'icon': Icons.hub, 'label': 'Hidden', 'value': '10 Neurons'},
              {'icon': Icons.output, 'label': 'Output', 'value': 'Probability'},
            ],
            Colors.deepPurple,
          ),
          const SizedBox(height: 16),
          _buildAIEngineCard(
            '⚡ SymptomModel',
            'Weighted Feature Matching with Bayesian Inference',
            [
              {'icon': Icons.line_weight, 'label': 'Weights', 'value': 'Severity-based'},
              {'icon': Icons.balance, 'label': 'Bias', 'value': 'Disease-specific'},
              {'icon': Icons.speed, 'label': 'Activation', 'value': 'ReLU + Sigmoid'},
            ],
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildAIEngineCard(
            '📊 ConfidenceSystem',
            'Multi-result probability with severity bonus',
            [
              {'icon': Icons.percent, 'label': 'Format', 'value': '72%, 18%, 10%'},
              {'icon': Icons.trending_up, 'label': 'Bonus', 'value': 'Critical +20%'},
              {'icon': Icons.sort, 'label': 'Sort', 'value': 'Confidence'},
            ],
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildMLTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMLFeatureCard(
            '🔍 Smart Diagnosis',
            'Multi-result with confidence percentages',
            'Symptom → Condition → Confidence %',
            Icons.search,
          ),
          _buildMLFeatureCard(
            '🎯 Pattern Matching',
            'Fuzzy string matching algorithm',
            'User symptom ↔ Database symptoms',
            Icons.pattern,
          ),
          _buildMLFeatureCard(
            '📈 Severity Weighting',
            'Critical: 1.5x, Severe: 1.3x, Moderate: 1.1x',
            'Base weight multiplied by severity',
            Icons.vertical_align_top,
          ),
          _buildMLFeatureCard(
            '🏥 Medical Conditions',
            'Offline SQLite database',
            '${_aiStats['medicalConditions'] ?? 0} conditions loaded',
            Icons.local_hospital,
          ),
          _buildMLFeatureCard(
            '🔄 Real-time Inference',
            'Instant diagnosis without network',
            'All processing on-device',
            Icons.speed,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningTab() {
    return BlocBuilder<MedicalBloc, MedicalState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLearningCard(
                '🔄 User Feedback Loop',
                'After each diagnosis, ask: "Was this correct?"',
                'Yes → +0.1 weight | No → -0.1 weight',
                Colors.green,
              ),
              _buildLearningCard(
                '📊 Chronic Pattern Detection',
                'Track frequently reported symptoms',
                '3+ occurrences → Alert user',
                Colors.orange,
              ),
              _buildLearningCard(
                '🧬 Weight Adaptation',
                'Adjust weights based on feedback',
                'Persistent storage in SharedPreferences',
                Colors.blue,
              ),
              _buildLearningCard(
                '📈 Accuracy Tracking',
                'Monitor prediction accuracy',
                'Correct / Total = Accuracy %',
                Colors.purple,
              ),
              _buildLearningCard(
                '💾 Offline Learning',
                'All learning happens on-device',
                'No internet required ever',
                Colors.teal,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCard(
            '📊 AIBrain Statistics',
            [
              {'label': 'Total Diagnoses', 'value': '${_aiStats['totalDiagnoses']}'},
              {'label': 'Correct Predictions', 'value': '${_aiStats['correctDiagnoses']}'},
              {'label': 'Accuracy', 'value': '${((_aiStats['accuracy'] as double? ?? 0) * 100).toStringAsFixed(1)}%'},
              {'label': 'Health Records', 'value': '${_aiStats['healthHistoryCount']}'},
            ],
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildStatsCard(
            '🧠 Neural LLM Statistics',
            [
              {'label': 'Total Conversations', 'value': '${_aiStats['neuralTotal']}'},
              {'label': 'Correct Assessments', 'value': '${_aiStats['neuralCorrect']}'},
              {'label': 'Neural Accuracy', 'value': '${((_aiStats['neuralAccuracy'] as double? ?? 0) * 100).toStringAsFixed(1)}%'},
            ],
            Colors.deepPurple,
          ),
          const SizedBox(height: 16),
          _buildStatsCard(
            '🏥 Medical Database',
            [
              {'label': 'Conditions', 'value': '${_aiStats['medicalConditions']}'},
              {'label': 'Offline Mode', 'value': '✅ Yes'},
              {'label': 'RL Environment', 'value': '✅ Active'},
              {'label': 'Learning', 'value': '✅ Enabled'},
            ],
            Colors.green,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 48),
                const SizedBox(height: 12),
                const Text(
                  '🎉 AI is Learning!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Every feedback makes the AI smarter',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIEngineCard(String title, String subtitle, List<Map<String, dynamic>> features, Color color) {
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
                  child: Icon(Icons.circle, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(f['icon'] as IconData, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text('${f['label']}: ', style: const TextStyle(fontSize: 12)),
                  Text(f['value'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMLFeatureCard(String title, String subtitle, String detail, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(fontSize: 12)),
            Text(detail, style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningCard(String title, String subtitle, String detail, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(detail, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, List<Map<String, dynamic>> stats, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, color: color, size: 24),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            ...stats.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s['label'] as String),
                  Text(s['value'] as String, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
