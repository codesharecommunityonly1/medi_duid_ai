import 'dart:convert';
import 'package:http/http.dart' as http;

class OnlineAIService {
  String openAiKey;
  String geminiKey;
  bool isInitialized = false;

  OnlineAIService({required this.openAiKey, required this.geminiKey});

  Future<void> initialize() async {
    isInitialized = true;
  }

  Future<String> getOpenAIResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiKey',
        },
        body: jsonEncode({
          'model': 'openai/gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are a medical assistant providing first-aid guidance. Provide detailed, accurate medical information. Always recommend seeking professional help for serious conditions.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '';
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'OpenAI Error: $e';
    }
  }

  Future<String> getGeminiResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$geminiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': 'You are a medical assistant. Provide first-aid guidance. Prompt: $prompt'}]}],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1000},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ?? '';
      } else {
        return 'Gemini Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Gemini Error: $e';
    }
  }

  Future<String> getDetailedDiagnosis(String symptoms, String mode) async {
    if (!isInitialized) await initialize();

    if (mode == 'offline') {
      return 'Offline mode - Using local database';
    }

    final prompt = '''
User symptoms: $symptoms

As a medical AI assistant, provide:
1. Possible conditions
2. Immediate first aid steps
3. When to seek emergency care
4. Organic/natural remedies (if applicable)
5. Conventional medicine options (if applicable)
6. Warnings and precautions

Be detailed and accurate. Always recommend professional medical help.
''';

    final openAIResult = await getOpenAIResponse(prompt);
    final geminiResult = await getGeminiResponse(prompt);

    return '''
═══════════════════════════════════════════
🔬 DETAILED DIAGNOSIS (Online Mode)
═══════════════════════════════════════════

📋 OPENAI ANALYSIS:
$openAIResult

═══════════════════════════════════════════

🔍 GEMINI ANALYSIS:  
$geminiResult

═══════════════════════════════════════════

⚠️ IMPORTANT: This is AI-generated guidance only. 
Please consult healthcare professionals for proper diagnosis.
''';
  }

  void dispose() {
    isInitialized = false;
  }
}
