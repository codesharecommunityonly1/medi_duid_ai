import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_engine.dart';

class MedicalCondition {
  final String id;
  final String name;
  final String nameHi;
  final String category;
  final String severity;
  final List<String> symptoms;
  final List<String> symptomsHi;
  final List<String> firstAid;
  final List<String> firstAidHi;
  final List<String> possibleConditions;
  final List<String> possibleConditionsHi;
  final List<String> organicRemedies;
  final List<String> medications;
  final String emergencyWarning;
  final String emergencyWarningHi;
  final String whenToSeekDoctor;
  final String whenToSeekDoctorHi;
  bool isFavorite;
  int confidenceScore;

  MedicalCondition({
    required this.id,
    required this.name,
    this.nameHi = '',
    required this.category,
    required this.severity,
    required this.symptoms,
    this.symptomsHi = const [],
    required this.firstAid,
    this.firstAidHi = const [],
    required this.possibleConditions,
    this.possibleConditionsHi = const [],
    this.organicRemedies = const [],
    this.medications = const [],
    this.emergencyWarning = '',
    this.emergencyWarningHi = '',
    this.whenToSeekDoctor = '',
    this.whenToSeekDoctorHi = '',
    this.isFavorite = false,
    this.confidenceScore = 0,
  });

  factory MedicalCondition.fromJson(Map<String, dynamic> json) {
    return MedicalCondition(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameHi: json['nameHi']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'mild',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      symptomsHi: List<String>.from(json['symptomsHi'] ?? []),
      firstAid: List<String>.from(json['firstAid'] ?? []),
      firstAidHi: List<String>.from(json['firstAidHi'] ?? []),
      possibleConditions: List<String>.from(json['possibleConditions'] ?? []),
      possibleConditionsHi: List<String>.from(json['possibleConditionsHi'] ?? []),
      organicRemedies: List<String>.from(json['organicRemedies'] ?? []),
      medications: List<String>.from(json['medications'] ?? []),
      emergencyWarning: json['emergencyWarning']?.toString() ?? '',
      emergencyWarningHi: json['emergencyWarningHi']?.toString() ?? '',
      whenToSeekDoctor: json['whenToSeekDoctor']?.toString() ?? '',
      whenToSeekDoctorHi: json['whenToSeekDoctorHi']?.toString() ?? '',
    );
  }
}

class MedicalDiagnosisService {
  static MedicalDiagnosisService? _instance;
  static MedicalDiagnosisService get instance => _instance ??= MedicalDiagnosisService._();
  MedicalDiagnosisService._();

  Database? _database;
  List<MedicalCondition> _conditions = [];
  bool _isLoaded = false;
  String _currentLanguage = 'en';

  bool get isLoaded => _isLoaded;
  List<MedicalCondition> get conditions => _conditions;
  String get currentLanguage => _currentLanguage;
  AIBrain get aiBrain => AIBrain.instance;

  void setLanguage(String lang) {
    _currentLanguage = lang;
  }

  Future<void> initialize() async {
    if (_isLoaded) return;

    await _initDatabase();
    await _loadConditions();
    
    await AIBrain.instance.initialize(
      _conditions.map((c) => {
        'id': c.id,
        'name': c.name,
        'severity': c.severity,
        'symptoms': c.symptoms,
      }).toList(),
    );
    
    _isLoaded = true;
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mediguide_medical.db');
    _database = await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conditions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        nameHi TEXT DEFAULT '',
        category TEXT NOT NULL,
        severity TEXT NOT NULL,
        symptoms TEXT NOT NULL,
        symptomsHi TEXT DEFAULT '',
        firstAid TEXT NOT NULL,
        firstAidHi TEXT DEFAULT '',
        possibleConditions TEXT NOT NULL,
        possibleConditionsHi TEXT DEFAULT '',
        organicRemedies TEXT DEFAULT '',
        medications TEXT DEFAULT '',
        emergencyWarning TEXT DEFAULT '',
        emergencyWarningHi TEXT DEFAULT '',
        whenToSeekDoctor TEXT DEFAULT '',
        whenToSeekDoctorHi TEXT DEFAULT '',
        isFavorite INTEGER DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_conditions_name ON conditions(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_conditions_category ON conditions(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_conditions_severity ON conditions(severity)');
  }

  Future<void> _loadConditions() async {
    final isFirstLaunch = await _isFirstLaunch();

    if (isFirstLaunch) {
      await _loadFromJson();
      await _saveToDatabase();
      await _setInitialized();
    } else {
      await _loadFromDatabase();
    }

    if (_conditions.isEmpty) {
      await _loadFromJson();
      await _saveToDatabase();
    }
  }

  Future<bool> _isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('mediguide_db_initialized') ?? true;
  }

  Future<void> _setInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mediguide_db_initialized', true);
  }

  Future<void> _loadFromJson() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/medical_conditions.json');
      final jsonData = json.decode(jsonString);
      final List<dynamic> conditionsJson = jsonData['conditions'];
      _conditions = conditionsJson.map((c) => MedicalCondition.fromJson(c)).toList();
    } catch (e) {
      _conditions = [];
    }
  }

  Future<void> _loadFromDatabase() async {
    if (_database == null) return;

    final results = await _database!.query('conditions');
    _conditions = results.map((row) {
      return MedicalCondition(
        id: row['id'] as String,
        name: row['name'] as String,
        nameHi: row['nameHi'] as String? ?? '',
        category: row['category'] as String,
        severity: row['severity'] as String,
        symptoms: (row['symptoms'] as String).split('|'),
        symptomsHi: (row['symptomsHi'] as String?)?.split('|') ?? [],
        firstAid: (row['firstAid'] as String).split('|'),
        firstAidHi: (row['firstAidHi'] as String?)?.split('|') ?? [],
        possibleConditions: (row['possibleConditions'] as String).split('|'),
        possibleConditionsHi: (row['possibleConditionsHi'] as String?)?.split('|') ?? [],
        organicRemedies: (row['organicRemedies'] as String?)?.split('|') ?? [],
        medications: (row['medications'] as String?)?.split('|') ?? [],
        emergencyWarning: row['emergencyWarning'] as String? ?? '',
        emergencyWarningHi: row['emergencyWarningHi'] as String? ?? '',
        whenToSeekDoctor: row['whenToSeekDoctor'] as String? ?? '',
        whenToSeekDoctorHi: row['whenToSeekDoctorHi'] as String? ?? '',
        isFavorite: (row['isFavorite'] as int?) == 1,
      );
    }).toList();
  }

  Future<void> _saveToDatabase() async {
    if (_database == null || _conditions.isEmpty) return;

    final batch = _database!.batch();
    for (final condition in _conditions) {
      batch.insert('conditions', {
        'id': condition.id,
        'name': condition.name,
        'nameHi': condition.nameHi,
        'category': condition.category,
        'severity': condition.severity,
        'symptoms': condition.symptoms.join('|'),
        'symptomsHi': condition.symptomsHi.join('|'),
        'firstAid': condition.firstAid.join('|'),
        'firstAidHi': condition.firstAidHi.join('|'),
        'possibleConditions': condition.possibleConditions.join('|'),
        'possibleConditionsHi': condition.possibleConditionsHi.join('|'),
        'organicRemedies': condition.organicRemedies.join('|'),
        'medications': condition.medications.join('|'),
        'emergencyWarning': condition.emergencyWarning,
        'emergencyWarningHi': condition.emergencyWarningHi,
        'whenToSeekDoctor': condition.whenToSeekDoctor,
        'whenToSeekDoctorHi': condition.whenToSeekDoctorHi,
        'isFavorite': condition.isFavorite ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  List<MedicalCondition> searchConditions(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final queryWords = lowerQuery.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();

    return _conditions.where((condition) {
      final nameMatch = condition.name.toLowerCase().contains(lowerQuery);
      final symptomMatch = condition.symptoms.any((s) => s.toLowerCase().contains(lowerQuery));
      final categoryMatch = condition.category.toLowerCase().contains(lowerQuery);
      final possibleMatch = condition.possibleConditions.any((p) => p.toLowerCase().contains(lowerQuery));
      final keywordMatch = queryWords.any((word) =>
        condition.symptoms.any((s) => s.toLowerCase().contains(word)) ||
        condition.name.toLowerCase().contains(word) ||
        condition.possibleConditions.any((p) => p.toLowerCase().contains(word))
      );

      return nameMatch || symptomMatch || categoryMatch || possibleMatch || keywordMatch;
    }).toList()
      ..sort((a, b) {
        final aExact = a.name.toLowerCase().contains(lowerQuery) ? 0 : 1;
        final bExact = b.name.toLowerCase().contains(lowerQuery) ? 0 : 1;
        return aExact.compareTo(bExact);
      });
  }

  List<MedicalCondition> diagnoseBySymptoms(List<String> userSymptoms) {
    if (userSymptoms.isEmpty) return [];

    final scoredConditions = <MedicalCondition>[];

    for (final condition in _conditions) {
      int matchCount = 0;
      final normalizedUserSymptoms = userSymptoms.map((s) => s.toLowerCase().trim()).where((s) => s.isNotEmpty).toList();
      final normalizedConditionSymptoms = condition.symptoms.map((s) => s.toLowerCase()).toList();

      for (final userSymptom in normalizedUserSymptoms) {
        for (final conditionSymptom in normalizedConditionSymptoms) {
          if (conditionSymptom.contains(userSymptom) || userSymptom.contains(conditionSymptom)) {
            matchCount++;
            break;
          }
        }
      }

      if (matchCount > 0) {
        final confidence = ((matchCount / normalizedUserSymptoms.length) * 100).clamp(0, 100).round();
        final newCondition = MedicalCondition(
          id: condition.id,
          name: condition.name,
          nameHi: condition.nameHi,
          category: condition.category,
          severity: condition.severity,
          symptoms: condition.symptoms,
          symptomsHi: condition.symptomsHi,
          firstAid: condition.firstAid,
          firstAidHi: condition.firstAidHi,
          possibleConditions: condition.possibleConditions,
          possibleConditionsHi: condition.possibleConditionsHi,
          organicRemedies: condition.organicRemedies,
          medications: condition.medications,
          emergencyWarning: condition.emergencyWarning,
          emergencyWarningHi: condition.emergencyWarningHi,
          whenToSeekDoctor: condition.whenToSeekDoctor,
          whenToSeekDoctorHi: condition.whenToSeekDoctorHi,
          isFavorite: condition.isFavorite,
          confidenceScore: confidence,
        );
        scoredConditions.add(newCondition);
      }
    }

    scoredConditions.sort((a, b) {
      final severityOrder = {'critical': 0, 'severe': 1, 'moderate': 2, 'mild': 3};
      final severityCompare = (severityOrder[a.severity] ?? 4).compareTo(severityOrder[b.severity] ?? 4);
      if (severityCompare != 0) return severityCompare;
      return b.confidenceScore.compareTo(a.confidenceScore);
    });

    return scoredConditions.take(10).toList();
  }

  List<MedicalCondition> getEmergencyConditions() {
    return _conditions.where((c) => c.severity == 'critical' || c.severity == 'severe').toList()
      ..sort((a, b) {
        final order = {'critical': 0, 'severe': 1};
        return (order[a.severity] ?? 2).compareTo(order[b.severity] ?? 2);
      });
  }

  List<MedicalCondition> getFavorites() {
    return _conditions.where((c) => c.isFavorite).toList();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _conditions.indexWhere((c) => c.id == id);
    if (index != -1) {
      _conditions[index].isFavorite = !_conditions[index].isFavorite;
      await _database?.update(
        'conditions',
        {'isFavorite': _conditions[index].isFavorite ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  MedicalCondition? getConditionById(String id) {
    try {
      return _conditions.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  List<String> get categories {
    return _conditions.map((c) => c.category).toSet().toList()..sort();
  }

  List<MedicalCondition> getByCategory(String category) {
    return _conditions.where((c) => c.category == category).toList();
  }

  List<MedicalCondition> getBySeverity(String severity) {
    return _conditions.where((c) => c.severity == severity).toList();
  }

  String buildGuidanceResponse(MedicalCondition condition) {
    final isHindi = _currentLanguage == 'hi';
    final name = isHindi && condition.nameHi.isNotEmpty ? condition.nameHi : condition.name;
    final symptoms = condition.symptoms;
    final firstAid = condition.firstAid;
    final organic = condition.organicRemedies;
    final medications = condition.medications;
    final emergency = isHindi ? condition.emergencyWarningHi : condition.emergencyWarning;
    final seekDoctor = isHindi ? condition.whenToSeekDoctorHi : condition.whenToSeekDoctor;

    final severityEmoji = {
      'critical': '🔴',
      'severe': '🟠',
      'moderate': '🟡',
      'mild': '🟢',
    }[condition.severity] ?? '⚪';

    return '''
═══════════════════════════════════════════════════════
🏥 MEDIGUIDE AI - ${isHindi ? 'ऑफलाइन मोड' : 'OFFLINE MODE'}
═══════════════════════════════════════════════════════

📋 ${isHindi ? 'स्थिति' : 'CONDITION'}: $name
⚠️ ${isHindi ? 'गंभीरता' : 'SEVERITY'}: $severityEmoji ${condition.severity.toUpperCase()}
📂 ${isHindi ? 'श्रेणी' : 'CATEGORY'}: ${condition.category}

═══════════════════════════════════════════════════════
🔍 ${isHindi ? 'संभावित स्थितियाँ' : 'POSSIBLE CONDITIONS'}:
═══════════════════════════════════════════════════════
${condition.possibleConditions.map((c) => '  • $c').join('\n')}

═══════════════════════════════════════════════════════
🩺 ${isHindi ? 'प्राथमिक चिकित्सा' : 'FIRST AID STEPS'}:
═══════════════════════════════════════════════════════
${firstAid.asMap().entries.map((e) => '  ${e.key + 1}. ${e.value}').join('\n')}

${organic.isNotEmpty ? '''
═══════════════════════════════════════════════════════
🌿 ${isHindi ? 'प्राकृतिक उपचार' : 'NATURAL REMEDIES'}:
═══════════════════════════════════════════════════════
${organic.map((o) => '  • $o').join('\n')}
''' : ''}

${medications.isNotEmpty ? '''
═══════════════════════════════════════════════════════
💊 ${isHindi ? 'दवाइयाँ (डॉक्टर से परामर्श करें)' : 'MEDICATIONS (Consult Doctor)'}:
═══════════════════════════════════════════════════════
${medications.map((m) => '  • $m').join('\n')}
''' : ''}

${emergency.isNotEmpty ? '''
═══════════════════════════════════════════════════════
🚨 $emergency
═══════════════════════════════════════════════════════
''' : ''}

${seekDoctor.isNotEmpty ? '''
═══════════════════════════════════════════════════════
🏥 ${isHindi ? 'डॉक्टर को कब दिखाएं' : 'WHEN TO SEE DOCTOR'}:
═══════════════════════════════════════════════════════
  $seekDoctor
''' : ''}

═══════════════════════════════════════════════════════
📱 ${isHindi ? 'यह मार्गदर्शन स्थानीय चिकित्सा डेटाबेस से है।' : 'This guidance is from local medical database.'}
   ${isHindi ? 'निदान के लिए स्वास्थ्य पेशेवरों से परामर्श करें।' : 'Consult healthcare professionals for diagnosis.'}
═══════════════════════════════════════════════════════
''';
  }

  List<String> getAllSymptoms() {
    final allSymptoms = <String>{};
    for (final condition in _conditions) {
      allSymptoms.addAll(condition.symptoms);
    }
    return allSymptoms.toList()..sort();
  }
}
