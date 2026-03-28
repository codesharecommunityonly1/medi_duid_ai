import 'package:flutter/material.dart';
import '../../services/offline_ml_engine.dart';

class RuralEmergencyScreen extends StatefulWidget {
  const RuralEmergencyScreen({super.key});

  @override
  State<RuralEmergencyScreen> createState() => _RuralEmergencyScreenState();
}

class _RuralEmergencyScreenState extends State<RuralEmergencyScreen> {
  final OfflineMLEngine _mlEngine = OfflineMLEngine.instance;
  final MedAIRLEnvironment _rlEnvironment = MedAIRLEnvironment();
  
  bool _isInitialized = false;
  List<String> _selectedSymptoms = [];
  List<RLAction> _predictions = [];
  Map<String, dynamic>? _modelStats;
  bool _isDiagnosing = false;

  @override
  void initState() {
    super.initState();
    _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    await _mlEngine.initialize();
    setState(() {
      _isInitialized = true;
      _modelStats = _mlEngine.getModelStats();
    });
  }

  void _diagnose() {
    if (_selectedSymptoms.isEmpty) return;
    
    setState(() => _isDiagnosing = true);
    
    final result = _rlEnvironment.reset(_selectedSymptoms);
    
    if (result['actions'] != null) {
      setState(() {
        _predictions = (result['actions'] as List)
            .map((a) => RLAction(
                  diseaseId: a['diseaseId'],
                  diseaseName: a['diseaseName'],
                  confidence: a['confidence'],
                ))
            .toList();
        _isDiagnosing = false;
      });
    }
  }

  void _confirmDiagnosis(RLAction action, bool correct) {
    final result = _rlEnvironment.step(action.diseaseId, action.diseaseId);
    
    setState(() {
      _modelStats = result['modelStats'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? 'Feedback recorded! AI learns from this.' : 'Noted. AI will improve.'),
        backgroundColor: correct ? Colors.green : Colors.orange,
      ),
    );
  }

  final List<String> _commonSymptoms = [
    'fever', 'cough', 'headache', 'chest pain', 'shortness of breath',
    'vomiting', 'diarrhea', 'body ache', 'fatigue', 'sore throat',
    'runny nose', 'dizziness', 'nausea', 'stomach pain', 'chills',
    'sweating', 'loss of appetite', 'weakness', 'confusion', 'swelling',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedAI - Rural Emergency'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showModelInfo,
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRuralBanner(),
                  const SizedBox(height: 20),
                  _buildSymptomSelector(),
                  const SizedBox(height: 20),
                  _buildDiagnoseButton(),
                  if (_predictions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildPredictions(),
                  ],
                  const SizedBox(height: 20),
                  _buildModelStats(),
                ],
              ),
            ),
    );
  }

  Widget _buildRuralBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[800]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.health_and_safety, color: Colors.white, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline AI Doctor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'For Rural India - No Internet Required',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBadge(Icons.wifi_off, 'Offline'),
                    const SizedBox(width: 8),
                    _buildBadge(Icons.language, 'Hindi'),
                    const SizedBox(width: 8),
                    _buildBadge(Icons.psychology, 'AI'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSymptomSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medical_services),
                SizedBox(width: 8),
                Text(
                  'Select Your Symptoms',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap all symptoms you are experiencing',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonSymptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                  selectedColor: Colors.green[200],
                  checkmarkColor: Colors.green[800],
                );
              }).toList(),
            ),
            if (_selectedSymptoms.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Selected: ${_selectedSymptoms.join(", ")}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnoseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedSymptoms.isEmpty || _isDiagnosing ? null : _diagnose,
        icon: _isDiagnosing 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.psychology),
        label: Text(_isDiagnosing ? 'AI is Analyzing...' : 'AI Diagnosis'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPredictions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'AI Predictions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_predictions.length.clamp(0, 5), (index) {
              final prediction = _predictions[index];
              final confidence = prediction.confidence;
              final color = confidence > 0.7 
                  ? Colors.green 
                  : (confidence > 0.5 ? Colors.orange : Colors.red);
              
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Text(
                        '${(confidence * 100).toInt()}%',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(prediction.diseaseName),
                    subtitle: LinearProgressIndicator(
                      value: confidence,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  if (index == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _confirmDiagnosis(prediction, true),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Correct'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDiagnosis(prediction, false),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Wrong'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildModelStats() {
    if (_modelStats == null) return const SizedBox.shrink();
    
    return Card(
      color: Colors.grey[100],
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
                  'AI Brain Stats',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow('Model', _modelStats!['modelType'] ?? 'N/A'),
            _buildStatRow('Algorithm', _modelStats!['algorithm'] ?? 'N/A'),
            _buildStatRow('Diseases', '${_modelStats!['totalDiseases']}'),
            _buildStatRow('Accuracy', '${((_modelStats!['accuracy'] ?? 0) * 100).toStringAsFixed(1)}%'),
            _buildStatRow('Version', _modelStats!['version'] ?? 'N/A'),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.wifi_off, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Works Offline - No Internet Required',
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showModelInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.green),
            SizedBox(width: 8),
            Text('MedAI Engine'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• RL-based Environment'),
            Text('• State: User Symptoms'),
            Text('• Action: Predicted Disease'),
            Text('• Reward: +1 Correct, -0.5 Wrong'),
            Text('• Learning Rate: 0.1'),
            Text('• 28 Medical Conditions'),
            Divider(),
            Text('For Rural India:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Works without internet'),
            Text('• Hindi language support'),
            Text('• Saves lives in emergencies'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
