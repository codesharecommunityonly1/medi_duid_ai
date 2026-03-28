import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  final _controller = StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize();
      return _isInitialized;
    } catch (e) { return false; }
  }

  Future<void> startListening({String localeId = 'en_US'}) async {
    if (!_isInitialized) await initialize();
    if (_isListening) return;
    
    _isListening = true;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          _controller.add(result.recognizedWords);
          _isListening = false;
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: localeId,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
  }

  void dispose() {
    _controller.close();
    _isListening = false;
  }
}
