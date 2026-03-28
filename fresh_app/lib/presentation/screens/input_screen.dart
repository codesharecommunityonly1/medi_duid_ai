import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../services/medical_diagnosis_service.dart';
import '../../services/offline_llm_brain.dart';
import '../bloc/medical/medical_bloc.dart';
import '../bloc/medical/medical_state.dart';
import 'condition_detail_screen.dart';

class InputScreen extends StatefulWidget {
  final bool isVoiceInput;
  const InputScreen({super.key, required this.isVoiceInput});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _textController = TextEditingController();
  bool _isProcessing = false;
  bool _isListening = false;
  String _statusMessage = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _processInput() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your symptoms')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Analyzing symptoms...';
    });

    try {
      final symptoms = _parseSymptoms(text);
      
      if (symptoms.isEmpty) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not identify symptoms. Please describe more clearly.')),
        );
        return;
      }

      final results = MedicalDiagnosisService.instance.diagnoseBySymptoms(symptoms);

      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });

      if (results.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DiagnosisResultsScreen(
              selectedSymptoms: symptoms,
              results: results,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching conditions found. Please try different symptoms.')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  List<String> _parseSymptoms(String input) {
    final symptoms = <String>[];
    final inputLower = input.toLowerCase();
    
    final symptomKeywords = [
      'fever', 'headache', 'cough', 'pain', 'nausea', 'vomiting', 'diarrhea',
      'fatigue', 'dizziness', 'chest', 'breathing', 'breath', 'rash', 'swelling',
      'bleeding', 'fracture', 'burn', 'choking', 'seizure', 'unconscious',
      'sweating', 'chills', 'body ache', 'joint pain', 'stomach pain', 'abdominal pain',
      'chest pain', 'shortness of breath', 'wheezing', 'sore throat',
      'runny nose', 'congestion', 'loss of appetite', 'weight loss',
      'vomit', 'nausea', 'headache', 'back pain', 'leg pain', 'arm pain',
      'skin rash', 'itching', 'dry skin', 'blister', 'sore', 'wound',
      'cold', 'flu', 'malaria', 'dengue', 'typhoid', 'asthma', 'diabetes',
      'heart', 'blood pressure', 'hypertension', 'anxiety', 'depression',
    ];

    for (final keyword in symptomKeywords) {
      if (inputLower.contains(keyword)) {
        symptoms.add(keyword);
      }
    }

    return symptoms.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isVoiceInput ? '🎤 Voice Input' : '📝 Describe Symptoms'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Describe your symptoms in detail. The AI will analyze and provide diagnosis with first-aid guidance.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: widget.isVoiceInput 
                  ? _buildVoiceInputArea()
                  : TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Example: I have fever, headache, and body pain since yesterday...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processInput,
                  icon: const Icon(Icons.psychology),
                  label: const Text(
                    '🔍 Get First Aid Guidance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceInputArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            size: 80,
            color: _isListening ? Colors.red : AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text(
            _isListening ? 'Listening...' : 'Tap to speak',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Describe your symptoms clearly',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          if (!_isListening)
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isListening = true);
                _startListening();
              },
              icon: const Icon(Icons.mic),
              label: const Text('Start Speaking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          if (_isListening)
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isListening = false);
              },
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _startListening() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _isListening = false;
        _textController.text = 'I have fever and headache';
      });
    }
  }
}

class DiagnosisResultsScreen extends StatelessWidget {
  final List<String> selectedSymptoms;
  final List<MedicalCondition> results;

  const DiagnosisResultsScreen({
    super.key,
    required this.selectedSymptoms,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🩺 Diagnosis Results'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'AI Diagnosis Complete',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Your symptoms: ${selectedSymptoms.join(", ")}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final condition = results[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ConditionDetailScreen(condition: condition),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(condition.severity).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  condition.severity.toUpperCase(),
                                  style: TextStyle(
                                    color: _getSeverityColor(condition.severity),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${condition.confidenceScore}%',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _getConfidenceColor(condition.confidenceScore / 100),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(condition.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(condition.category, style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: condition.confidenceScore / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(_getConfidenceColor(condition.confidenceScore / 100)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical': return Colors.red;
      case 'severe': return Colors.orange;
      case 'moderate': return Colors.amber;
      default: return Colors.green;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
