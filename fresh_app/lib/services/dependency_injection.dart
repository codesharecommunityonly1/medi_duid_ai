import 'package:get_it/get_it.dart';
import 'ai/llama_service.dart';
import 'ai/llama_offline_service.dart';
import 'ai/rag_service.dart';
import 'ai/llama_api_service.dart';
import 'ai/ai_simulation_service.dart';
import 'voice/stt_service.dart';
import 'voice/tts_service.dart';
import 'vision/injury_analysis_service.dart';
import 'emergency/emergency_service.dart';
import 'security/safety_filter_service.dart';

class DependencyInjection {
  static final GetIt _getIt = GetIt.instance;
  static late LlamaService llamaService;
  static late LlamaOfflineService llamaOfflineService;
  static late RagService ragService;
  static late LlamaAPIService llamaAPIService;
  static late AISimulationService aiSimulationService;
  static late SafetyFilterService safetyFilterService;
  static late SttService sttService;
  static late TtsService ttsService;
  static late InjuryAnalysisService injuryAnalysisService;
  static late LocationService locationService;
  static late EmergencyService emergencyService;

  static Future<void> setup() async {
    llamaService = LlamaService();
    llamaOfflineService = LlamaOfflineService();
    ragService = RagService();
    llamaAPIService = LlamaAPIService(llamaApiKey: '');
    aiSimulationService = AISimulationService();
    safetyFilterService = SafetyFilterService();
    sttService = SttService();
    ttsService = TtsService();
    injuryAnalysisService = InjuryAnalysisService();
    locationService = LocationService();
    emergencyService = EmergencyService(locationService: locationService);

    _getIt.registerSingleton<LlamaService>(llamaService);
    _getIt.registerSingleton<LlamaOfflineService>(llamaOfflineService);
    _getIt.registerSingleton<RagService>(ragService);
    _getIt.registerSingleton<LlamaAPIService>(llamaAPIService);
    _getIt.registerSingleton<AISimulationService>(aiSimulationService);
    _getIt.registerSingleton<SafetyFilterService>(safetyFilterService);
    _getIt.registerSingleton<SttService>(sttService);
    _getIt.registerSingleton<TtsService>(ttsService);
    _getIt.registerSingleton<InjuryAnalysisService>(injuryAnalysisService);
    _getIt.registerSingleton<LocationService>(locationService);
    _getIt.registerSingleton<EmergencyService>(emergencyService);

    await llamaService.initialize();
    await llamaOfflineService.initialize();
    await ragService.initialize();
    await llamaAPIService.initialize();
    await sttService.initialize();
    await ttsService.initialize();
    await injuryAnalysisService.initialize();
    await locationService.initialize();
  }

  static void dispose() {
    llamaService.dispose();
    llamaOfflineService.dispose();
    ragService.dispose();
    llamaAPIService.dispose();
    sttService.dispose();
    ttsService.dispose();
    injuryAnalysisService.dispose();
    locationService.dispose();
  }
}