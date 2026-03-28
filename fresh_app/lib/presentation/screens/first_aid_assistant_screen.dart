import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FirstAidStep {
  final String stepNumber;
  final String instruction;
  final String instructionHi;
  final int durationSeconds;
  final bool isCritical;

  FirstAidStep({
    required this.stepNumber,
    required this.instruction,
    required this.instructionHi,
    required this.durationSeconds,
    this.isCritical = false,
  });
}

class FirstAidAssistantScreen extends StatefulWidget {
  final String conditionName;
  final List<String> firstAidSteps;
  final List<String> firstAidStepsHi;
  final bool isHindi;
  final bool isEmergency;

  const FirstAidAssistantScreen({
    super.key,
    required this.conditionName,
    required this.firstAidSteps,
    this.firstAidStepsHi = const [],
    this.isHindi = false,
    this.isEmergency = false,
  });

  @override
  State<FirstAidAssistantScreen> createState() => _FirstAidAssistantScreenState();
}

class _FirstAidAssistantScreenState extends State<FirstAidAssistantScreen> {
  final FlutterTts _tts = FlutterTts();
  int _currentStep = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isPaused = false;
  bool _isSpeaking = false;
  bool _completedAll = false;

  List<FirstAidStep> get _steps {
    final steps = widget.isHindi && widget.firstAidStepsHi.isNotEmpty
        ? widget.firstAidStepsHi
        : widget.firstAidSteps;
    
    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      int duration = 30;
      
      if (step.toLowerCase().contains('seconds') || step.toLowerCase().contains('minute')) {
        final match = RegExp(r'(\d+)').firstMatch(step);
        if (match != null) {
          duration = int.parse(match.group(1)!) * (step.toLowerCase().contains('minute') ? 60 : 1);
        }
      }
      
      return FirstAidStep(
        stepNumber: '${index + 1}',
        instruction: step,
        instructionHi: widget.firstAidStepsHi.length > index ? widget.firstAidStepsHi[index] : step,
        durationSeconds: duration.clamp(15, 300),
        isCritical: widget.isEmergency && index < 2,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _initTts();
    _startStepTimer();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage(widget.isHindi ? 'hi-IN' : 'en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  void _startStepTimer() {
    if (_steps.isEmpty) return;
    _remainingSeconds = _steps[_currentStep].durationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _nextStep();
          }
        });
      }
    });
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
        _remainingSeconds = _steps[_currentStep].durationSeconds;
      });
      _speakCurrentStep();
    } else {
      setState(() => _completedAll = true);
      _stopTimer();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _remainingSeconds = _steps[_currentStep].durationSeconds;
      });
      _speakCurrentStep();
    }
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _speakCurrentStep() async {
    if (_steps.isEmpty) return;
    setState(() => _isSpeaking = true);
    final step = _steps[_currentStep];
    final text = widget.isHindi ? step.instructionHi : step.instruction;
    await _tts.speak(text);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    _tts.stop();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('First Aid Assistant')),
        body: const Center(child: Text('No first aid steps available')),
      );
    }

    if (_completedAll) {
      return _buildCompletionScreen();
    }

    final currentStep = _steps[_currentStep];
    final progress = (_currentStep + 1) / _steps.length;

    return Scaffold(
      backgroundColor: widget.isEmergency ? Colors.red[50] : null,
      appBar: AppBar(
        title: Text(widget.conditionName),
        backgroundColor: widget.isEmergency ? Colors.red : null,
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_off),
            onPressed: _speakCurrentStep,
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isEmergency ? Colors.red : Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Step ${currentStep.stepNumber} of ${_steps.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (currentStep.isCritical)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'CRITICAL STEP',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isHindi ? currentStep.instructionHi : currentStep.instruction,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _buildTimerWidget(),
                  const SizedBox(height: 40),
                  _buildControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget() {
    final isLowTime = _remainingSeconds <= 10;
    
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isEmergency 
            ? (isLowTime ? Colors.red : Colors.red[100])
            : (isLowTime ? Colors.orange : Theme.of(context).colorScheme.primaryContainer),
        boxShadow: [
          BoxShadow(
            color: (widget.isEmergency ? Colors.red : Theme.of(context).colorScheme.primary).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isPaused ? Icons.pause : Icons.timer,
            size: 32,
            color: widget.isEmergency ? Colors.white : Colors.black87,
          ),
          const SizedBox(height: 8),
          Text(
            _formattedTime,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: widget.isEmergency ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _currentStep > 0 ? _previousStep : null,
          icon: const Icon(Icons.skip_previous),
          label: const Text('Previous'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _togglePause,
          icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
          label: Text(_isPaused ? 'Resume' : 'Pause'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isEmergency ? Colors.red : null,
            foregroundColor: widget.isEmergency ? Colors.white : null,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _nextStep,
          icon: const Icon(Icons.skip_next),
          label: const Text('Next'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 120,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'First Aid Complete!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You\'ve completed all steps',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                if (widget.isEmergency)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Call emergency
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Emergency Services'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
