import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';

class EmergencyTimerScreen extends StatefulWidget {
  final String conditionName;
  final List<String> steps;
  
  const EmergencyTimerScreen({
    super.key,
    required this.conditionName,
    required this.steps,
  });

  @override
  State<EmergencyTimerScreen> createState() => _EmergencyTimerScreenState();
}

class _EmergencyTimerScreenState extends State<EmergencyTimerScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  int _secondsRemaining = 0;
  bool _isRunning = false;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  List<bool> _completedSteps = [];

  @override
  void initState() {
    super.initState();
    _completedSteps = List.filled(widget.steps.length, false);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer(int seconds) {
    setState(() {
      _secondsRemaining = seconds;
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _completeCurrentStep();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = 0;
    });
  }

  void _completeCurrentStep() {
    setState(() {
      if (_currentStep < _completedSteps.length) {
        _completedSteps[_currentStep] = true;
        if (_currentStep < widget.steps.length - 1) {
          _currentStep++;
        }
      }
    });
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _completedSteps[_currentStep] = true;
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAllComplete = _completedSteps.every((s) => s);

    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: Text('🚨 ${widget.conditionName}'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (!isAllComplete)
            TextButton.icon(
              onPressed: _completeCurrentStep,
              icon: const Icon(Icons.skip_next, color: Colors.white),
              label: const Text('Skip', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProgressIndicator(),
                    const SizedBox(height: 24),
                    _buildCurrentStepCard(),
                    const SizedBox(height: 24),
                    if (_isRunning) _buildTimerCard(),
                    const SizedBox(height: 24),
                    _buildTimerControls(),
                    const SizedBox(height: 24),
                    _buildStepNavigation(),
                  ],
                ),
              ),
            ),
            if (isAllComplete) _buildCompletionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${_currentStep + 1} of ${widget.steps.length}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            Text(
              '${((_completedSteps.where((s) => s).length / widget.steps.length) * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _completedSteps.where((s) => s).length / widget.steps.length,
            backgroundColor: Colors.red.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepCard() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isRunning ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: _isRunning ? Colors.red : Colors.green,
            width: 3,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _isRunning ? Icons.timer : Icons.check_circle,
              size: 48,
              color: _isRunning ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              widget.steps[_currentStep],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (_isRunning) ...[
              const SizedBox(height: 16),
              Text(
                '$_secondsRemaining',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: _secondsRemaining <= 5 ? Colors.red : Colors.red.shade700,
                ),
              ),
              const Text(
                'seconds remaining',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Text(
            _secondsRemaining > 0 
                ? 'Timer running: $_secondsRemaining sec'
                : 'Timer paused',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerControls() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildTimerButton('10s', 10),
        _buildTimerButton('30s', 30),
        _buildTimerButton('1min', 60),
        _buildTimerButton('2min', 120),
        _buildTimerButton('5min', 300),
        if (_isRunning)
          ElevatedButton.icon(
            onPressed: _stopTimer,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildTimerButton(String label, int seconds) {
    return ElevatedButton(
      onPressed: _isRunning ? null : () => _startTimer(seconds),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
      ),
      child: Text(label),
    );
  }

  Widget _buildStepNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: _currentStep > 0 ? _previousStep : null,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Previous'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.grey.shade700,
          ),
        ),
        if (_currentStep < widget.steps.length - 1)
          ElevatedButton.icon(
            onPressed: _nextStep,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildCompletionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          const Text(
            '✅ First Aid Complete!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have completed all steps for ${widget.conditionName}',
            style: TextStyle(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                    _completedSteps = List.filled(widget.steps.length, false);
                  });
                },
                icon: const Icon(Icons.replay),
                label: const Text('Restart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
