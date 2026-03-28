import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'services/medical_diagnosis_service.dart';
import 'presentation/bloc/medical/medical_bloc.dart';
import 'presentation/bloc/medical/medical_event.dart';
import 'presentation/bloc/emergency/emergency_bloc.dart';
import 'presentation/bloc/settings/settings_bloc.dart';
import 'services/emergency/emergency_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await Hive.initFlutter();
  
  await MedicalDiagnosisService.instance.initialize();
  
  final emergencyService = EmergencyService();
  await emergencyService.initialize();
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<MedicalBloc>(
          create: (_) => MedicalBloc()..add(InitializeDatabaseEvent()),
        ),
        BlocProvider<EmergencyBloc>(
          create: (_) => EmergencyBloc(
            emergencyService: emergencyService,
          ),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(),
        ),
      ],
      child: const MediGuideApp(),
    ),
  );
}
