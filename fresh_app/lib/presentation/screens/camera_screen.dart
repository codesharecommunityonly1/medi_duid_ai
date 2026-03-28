import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../../core/constants/app_strings.dart';
import '../bloc/medical/medical_bloc.dart';
import '../bloc/medical/medical_event.dart';
import '../bloc/medical/medical_state.dart';
import 'results_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  String? _capturedImagePath;

  @override
  void initState() { super.initState(); _initializeCamera(); }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _cameraController = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {}
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final image = await _cameraController!.takePicture();
      setState(() => _capturedImagePath = image.path);
    } catch (e) {}
  }

  void _analyzeImage() {
    if (_capturedImagePath == null) return;
    context.read<MedicalBloc>().add(ProcessInjuryEvent(imagePath: _capturedImagePath!));
  }

  @override
  void dispose() { _cameraController?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MedicalBloc, MedicalState>(
      listener: (context, state) {
        if (state.status == MedicalStatus.success && state.currentSymptom != null) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ResultsScreen(symptom: state.currentSymptom!)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.cameraTitle)),
          body: SafeArea(child: state.status == MedicalStatus.processing ? _buildAnalyzing() : _capturedImagePath != null ? _buildPreview() : _buildCamera()),
        );
      },
    );
  }

  Widget _buildCamera() {
    return Column(children: [
      Expanded(child: Container(margin: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: _isInitialized && _cameraController != null ? CameraPreview(_cameraController!) : const Center(child: CircularProgressIndicator(color: Colors.white))))),
      Container(
        padding: const EdgeInsets.all(20), 
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16), 
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), 
              child: const Row(children: [Icon(Icons.info_outline, color: AppColors.primary), SizedBox(width: 12), Expanded(child: Text('Position the wound or injury in the frame for analysis'))]),
            ),
            const SizedBox(height: 20), 
            GestureDetector(
              onTap: _isInitialized ? _captureImage : null, 
              child: Container(width: 80, height: 80, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 36)),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildPreview() {
    return Column(children: [
      Expanded(child: Container(margin: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.grey[300]), child: const Center(child: Icon(Icons.image, size: 64, color: Colors.grey)))),
      Padding(padding: const EdgeInsets.all(20), child: Row(children: [Expanded(child: OutlinedButton(onPressed: () => setState(() => _capturedImagePath = null), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Retake'))), const SizedBox(width: 16), Expanded(child: ElevatedButton(onPressed: _analyzeImage, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Analyze')))])),
    ]);
  }

  Widget _buildAnalyzing() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 120, height: 120, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.analytics, size: 60, color: AppColors.primary)), const SizedBox(height: 24), Text(AppStrings.cameraAnalyzing, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 16), const CircularProgressIndicator()]));
  }
}
