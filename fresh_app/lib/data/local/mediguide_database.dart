import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MediGuideDatabase {
  static MediGuideDatabase? _instance;
  static MediGuideDatabase get instance => _instance ??= MediGuideDatabase._();
  MediGuideDatabase._();

  Database? _database;
  static const String _dbName = 'mediguide_conditions.db';
  static const String _firstLaunchKey = 'db_initialized';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conditions (
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
        organicRemediesHi TEXT DEFAULT '',
        medications TEXT DEFAULT '',
        medicationsHi TEXT DEFAULT '',
        emergencyWarning TEXT DEFAULT '',
        emergencyWarningHi TEXT DEFAULT '',
        whenToSeekDoctor TEXT DEFAULT '',
        whenToSeekDoctorHi TEXT DEFAULT '',
        isFavorite INTEGER DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_conditions_name ON conditions(name)');
    await db.execute('CREATE INDEX idx_conditions_category ON conditions(category)');
    await db.execute('CREATE INDEX idx_conditions_severity ON conditions(severity)');
    await db.execute('CREATE INDEX idx_conditions_favorite ON conditions(isFavorite)');
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> setInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, true);
  }

  Future<void> initializeFromJson() async {
    final isFirst = await isFirstLaunch();
    if (!isFirst) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/medical_500.json');
      final jsonData = json.decode(jsonString);
      final List<dynamic> conditionsJson = jsonData['conditions'];

      final db = await database;
      final batch = db.batch();

      for (final c in conditionsJson) {
        batch.insert('conditions', {
          'id': c['id']?.toString() ?? '',
          'name': c['name']?.toString() ?? '',
          'nameHi': c['nameHi']?.toString() ?? '',
          'category': c['category']?.toString() ?? '',
          'severity': c['severity']?.toString() ?? 'mild',
          'symptoms': (c['symptoms'] as List<dynamic>?)?.join('|') ?? '',
          'symptomsHi': (c['symptomsHi'] as List<dynamic>?)?.join('|') ?? '',
          'firstAid': (c['firstAid'] as List<dynamic>?)?.join('|') ?? '',
          'firstAidHi': (c['firstAidHi'] as List<dynamic>?)?.join('|') ?? '',
          'possibleConditions': (c['possibleConditions'] as List<dynamic>?)?.join('|') ?? '',
          'possibleConditionsHi': (c['possibleConditionsHi'] as List<dynamic>?)?.join('|') ?? '',
          'organicRemedies': (c['organicRemedies'] as List<dynamic>?)?.join('|') ?? '',
          'organicRemediesHi': (c['organicRemediesHi'] as List<dynamic>?)?.join('|') ?? '',
          'medications': (c['medications'] as List<dynamic>?)?.join('|') ?? '',
          'medicationsHi': (c['medicationsHi'] as List<dynamic>?)?.join('|') ?? '',
          'emergencyWarning': c['emergencyWarning']?.toString() ?? '',
          'emergencyWarningHi': c['emergencyWarningHi']?.toString() ?? '',
          'whenToSeekDoctor': c['whenToSeekDoctor']?.toString() ?? '',
          'whenToSeekDoctorHi': c['whenToSeekDoctorHi']?.toString() ?? '',
          'isFavorite': 0,
        });
      }

      await batch.commit(noResult: true);
      await setInitialized();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> searchConditions(String query, {int limit = 20}) async {
    final db = await database;
    final searchQuery = '%$query%';
    return await db.query(
      'conditions',
      where: 'name LIKE ? OR symptoms LIKE ? OR category LIKE ? OR possibleConditions LIKE ?',
      whereArgs: [searchQuery, searchQuery, searchQuery, searchQuery],
      limit: limit,
      orderBy: 'severity ASC, name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getConditionsByCategory(String category) async {
    final db = await database;
    return await db.query(
      'conditions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getEmergencyConditions() async {
    final db = await database;
    return await db.query(
      'conditions',
      where: 'severity = ? OR severity = ?',
      whereArgs: ['critical', 'severe'],
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getFavoriteConditions() async {
    final db = await database;
    return await db.query(
      'conditions',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'conditions',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getConditionById(String id) async {
    final db = await database;
    final results = await db.query(
      'conditions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<String>> getAllCategories() async {
    final db = await database;
    final results = await db.rawQuery('SELECT DISTINCT category FROM conditions ORDER BY category');
    return results.map((r) => r['category'] as String).toList();
  }

  Future<int> getConditionCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM conditions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getConditionsBySymptomScore(List<String> selectedSymptoms) async {
    if (selectedSymptoms.isEmpty) return [];

    final db = await database;
    final allConditions = await db.query('conditions');

    final scoredConditions = <Map<String, dynamic>>[];
    for (final condition in allConditions) {
      final symptoms = (condition['symptoms'] as String).toLowerCase().split('|');
      int matchCount = 0;
      for (final symptom in selectedSymptoms) {
        if (symptoms.any((s) => s.contains(symptom.toLowerCase()))) {
          matchCount++;
        }
      }
      if (matchCount > 0) {
        final confidence = (matchCount / selectedSymptoms.length * 100).round();
        scoredConditions.add({...condition, 'confidence': confidence, 'matchCount': matchCount});
      }
    }

    scoredConditions.sort((a, b) {
      final confidenceA = a['confidence'] as int;
      final confidenceB = b['confidence'] as int;
      return confidenceB.compareTo(confidenceA);
    });

    return scoredConditions.take(10).toList();
  }
}
