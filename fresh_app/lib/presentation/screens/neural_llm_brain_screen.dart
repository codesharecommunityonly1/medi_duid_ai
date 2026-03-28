import 'package:flutter/material.dart';
import '../../services/offline_llm_brain.dart';
import '../../services/medical_diagnosis_service.dart';

class NeuralLLMBrainScreen extends StatefulWidget {
  const NeuralLLMBrainScreen({super.key});

  @override
  State<NeuralLLMBrainScreen> createState() => _NeuralLLMBrainScreenState();
}

class _NeuralLLMBrainScreenState extends State<NeuralLLMBrainScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;
  String _currentDiagnosis = '';
  bool? _feedbackGiven;
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    final conditions = MedicalDiagnosisService.instance.conditions
        .map((c) => {'id': c.id, 'name': c.name, 'symptoms': c.symptoms, 'severity': c.severity})
        .toList();
    await ConversationalAI.instance.initialize(conditions);
  }

  Future<void> _processInput() async {
    if (_inputController.text.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _feedbackGiven = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final result = await ConversationalAI.instance.processInput(_inputController.text);
    final stats = ConversationalAI.instance.getStats();

    setState(() {
      _currentDiagnosis = result;
      _isProcessing = false;
      if (stats['predictions'] != null && (stats['predictions'] as Map).isNotEmpty) {
        _lastResult = (stats['predictions'] as Map).values.first as Map<String, dynamic>;
        _currentDiagnosis = _lastResult?['probability'] != null 
            ? '${_lastResult!['probability']}'
            : '';
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitFeedback(bool wasCorrect) {
    if (_lastResult == null) return;
    
    ConversationalAI.instance.submitFeedback(
      _lastResult!['diseaseId'] ?? 'unknown',
      wasCorrect,
    );
    
    setState(() {
      _feedbackGiven = wasCorrect;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasCorrect 
            ? '✅ Thanks! Neural network is learning!' 
            : '📊 Feedback recorded. Improving accuracy...'),
        backgroundColor: wasCorrect ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 TensorFlow Lite AI'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStats,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildChatArea()),
          if (_lastResult != null && _feedbackGiven == null) _buildFeedbackSection(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TensorFlow Lite AI Brain',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('Offline', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '🧠 Neural Network',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeMessage(),
            if (_isProcessing) _buildTypingIndicator(),
            if (_currentDiagnosis.isNotEmpty && !_isProcessing)
              _buildDiagnosisResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.deepPurple.shade700),
              const SizedBox(width: 8),
              const Text(
                'MedAI Assistant',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
                const Text(
                "Hello! I'm your TensorFlow Lite Medical AI Assistant. 🧠\n\nI use a deep neural network to analyze your symptoms and provide intelligent diagnoses.\n\nTry describing your symptoms like:\n• 'I have fever and headache'\n• 'Chest pain and difficulty breathing'\n• 'Vomiting and diarrhea'",
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This AI learns from your feedback!',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '🧠 Neural network is processing...',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisResult() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text(
                'Neural Network Analysis',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNeuralLayer('Input Layer', 'Symptom features: ${_lastResult?['matchedSymptoms']?.length ?? 0} features'),
          _buildNeuralLayer('Hidden Layer', '10 neurons activated'),
          _buildNeuralLayer('Output Layer', 'Disease probability calculated'),
          const SizedBox(height: 16),
          if (_lastResult != null) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '🧠 Reasoning:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700),
            ),
            const SizedBox(height: 8),
            ...(_lastResult!['reasoning'] as List<String>? ?? []).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(r, style: const TextStyle(fontSize: 12)),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildNeuralLayer(String name, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('$name: ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          const Text(
            '❓ Was this diagnosis correct?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _submitFeedback(true),
                icon: const Icon(Icons.thumb_up),
                label: const Text('Yes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _submitFeedback(false),
                icon: const Icon(Icons.thumb_down),
                label: const Text('No'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_feedbackGiven != null) ...[
            const SizedBox(height: 8),
            Text(
              _feedbackGiven! 
                  ? '✅ Neural network is learning from this!' 
                  : '📊 Adjusting weights for better accuracy...',
              style: TextStyle(
                color: _feedbackGiven! ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: 'Describe your symptoms...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _processInput(),
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton(
              onPressed: _isProcessing ? null : _processInput,
              backgroundColor: Colors.deepPurple,
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showStats() {
    final stats = ConversationalAI.instance.getStats();
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  '🧠 Neural Network Stats',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildStatRow('🤖 Framework', stats['framework'] ?? 'TensorFlow Lite'),
            _buildStatRow('Total Diagnoses', '${stats['totalDiagnoses']}'),
            _buildStatRow('Correct Predictions', '${stats['correctPredictions']}'),
            _buildStatRow('Accuracy', '${((stats['accuracy'] as double) * 100).toStringAsFixed(1)}%'),
            _buildStatRow('Learned Weights', '${stats['learnedWeights']}'),
            _buildStatRow('Offline Mode', '${stats['offline']}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This neural network learns from every feedback you provide!',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
