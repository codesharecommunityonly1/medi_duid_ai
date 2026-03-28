import 'dart:convert';
import 'package:http/http.dart' as http;

class LlamaAPIService {
  String llamaApiKey;
  bool isInitialized = false;

  LlamaAPIService({required this.llamaApiKey});

  Future<void> initialize() async {
    isInitialized = true;
  }

  Future<LlamaResponse> getLlamaResponse(String prompt, {double temperature = 0.7, int maxTokens = 1000}) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.llama.ai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $llamaApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': '''You are MediGuide AI, a medical assistant providing first-aid guidance. 
- Provide accurate, detailed medical information
- Always prioritize safety
- Recommend seeking professional help for serious conditions
- Use markdown formatting for clarity
- Provide confidence levels for your assessments'''
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] ?? '';
        final usage = data['usage'] ?? {};
        
        return LlamaResponse(
          success: true,
          content: content,
          model: data['model'] ?? 'llama-3.1-70b-versatile',
          tokensUsed: usage['total_tokens'] ?? 0,
          confidenceScore: _calculateConfidence(content),
        );
      } else {
        return LlamaResponse(
          success: false,
          content: '',
          error: 'API Error: ${response.statusCode}',
          confidenceScore: 0.0,
        );
      }
    } catch (e) {
      return LlamaResponse(
        success: false,
        content: '',
        error: 'Connection Error: $e',
        confidenceScore: 0.0,
      );
    }
  }

  double _calculateConfidence(String content) {
    final lowerContent = content.toLowerCase();
    double confidence = 0.85;
    
    if (lowerContent.contains('uncertain') || lowerContent.contains('not sure')) {
      confidence -= 0.2;
    }
    if (lowerContent.contains('may be') || lowerContent.contains('possibly')) {
      confidence -= 0.1;
    }
    if (lowerContent.contains('definitely') || lowerContent.contains('clear')) {
      confidence += 0.1;
    }
    if (lowerContent.contains('medical professional') || lowerContent.contains('consult')) {
      confidence += 0.05;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  Future<LlamaResponse> getMedicalDiagnosis(String symptoms) async {
    if (!isInitialized) await initialize();

    final prompt = '''
User symptoms: $symptoms

As a medical AI assistant, analyze these symptoms and provide:
1. Possible conditions (list 2-4 most likely)
2. Confidence level for each condition
3. Immediate first aid steps (numbered)
4. Warning signs requiring emergency care
5. When to seek professional help
6. Organic/natural remedies if applicable
7. Conventional medicine options if applicable

Format your response clearly with headers and bullet points.
End with a confidence score out of 100%.
''';

    return await getLlamaResponse(prompt, temperature: 0.3, maxTokens: 1500);
  }

  Future<LlamaResponse> analyzeInjury(String imageDescription) async {
    if (!isInitialized) await initialize();

    final prompt = '''
Analyze this injury based on description: $imageDescription

Provide:
1. Injury type assessment
2. Severity level (minor/moderate/severe/critical)
3. Immediate first aid steps
4. Warning signs requiring emergency care
5. When to seek medical attention
6. Recommended treatments
7. Recovery time estimate

End with confidence score out of 100%.
''';

    return await getLlamaResponse(prompt, temperature: 0.2, maxTokens: 1200);
  }

  Future<String> getDetailedDiagnosis(String symptoms, String mode) async {
    final response = await getMedicalDiagnosis(symptoms);
    
    if (response.success) {
      return '''
══════════════════════════════════════════
🔬 DETAILED DIAGNOSIS (Llama API)
══════════════════════════════════════════

${response.content}

══════════════════════════════════════════

⚠️ IMPORTANT: This is AI-generated guidance only. 
Please consult healthcare professionals for proper diagnosis.

📊 Confidence Score: ${response.confidencePercentage}
${response.warningMessage}
''';
    } else {
      return 'Error: ${response.error}';
    }
  }

  void dispose() {
    isInitialized = false;
  }
}

class LlamaResponse {
  final bool success;
  final String content;
  final String? error;
  final String model;
  final int tokensUsed;
  final double confidenceScore;

  LlamaResponse({
    required this.success,
    required this.content,
    this.error,
    this.model = 'llama-3.1-70b-versatile',
    this.tokensUsed = 0,
    required this.confidenceScore,
  });

  String get confidencePercentage => '${(confidenceScore * 100).toInt()}%';
  
  bool get isConfident => confidenceScore >= 0.80;
  
  String get warningMessage {
    if (confidenceScore < 0.80) {
      return '⚠️ I am only ${confidencePercentage} confident. Please consult a human doctor for accurate diagnosis.';
    }
    return '';
  }
}