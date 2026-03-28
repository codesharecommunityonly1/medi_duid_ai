import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/medical_entities.dart';

class DatabaseHelper {
  static Database? _database;
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mediguide.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE symptoms (id TEXT PRIMARY KEY, description TEXT, type TEXT, severity TEXT, symptoms TEXT, firstAidGuidance TEXT, warnings TEXT, nextSteps TEXT, timestamp TEXT, isVoiceInput INTEGER, imagePath TEXT)
    ''');
    await db.execute('CREATE TABLE emergency_contacts (id TEXT PRIMARY KEY, name TEXT, phoneNumber TEXT, isPrimary INTEGER)');
    await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)');
  }

  static Future<void> saveSymptom(SymptomEntity symptom) async {
    final db = await database;
    await db.insert('symptoms', {'id': symptom.id, 'description': symptom.description, 'type': symptom.type?.name, 'severity': symptom.severity.name, 'symptoms': symptom.symptoms.join('|'), 'firstAidGuidance': symptom.firstAidGuidance, 'warnings': symptom.warnings.join('|'), 'nextSteps': symptom.nextSteps.join('|'), 'timestamp': symptom.timestamp.toIso8601String(), 'isVoiceInput': symptom.isVoiceInput ? 1 : 0, 'imagePath': symptom.imagePath}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<SymptomEntity>> getSymptoms({int limit = 50}) async {
    final db = await database;
    final results = await db.query('symptoms', orderBy: 'timestamp DESC', limit: limit);
    return results.map((row) => SymptomEntity(id: row['id'] as String, description: row['description'] as String, type: row['type'] != null ? EmergencyType.values.firstWhere((e) => e.name == row['type'], orElse: () => EmergencyType.other) : null, severity: SymptomSeverity.values.firstWhere((e) => e.name == row['severity'], orElse: () => SymptomSeverity.mild), symptoms: (row['symptoms'] as String).split('|'), firstAidGuidance: row['firstAidGuidance'] as String, warnings: (row['warnings'] as String).split('|'), nextSteps: (row['nextSteps'] as String).split('|'), timestamp: DateTime.parse(row['timestamp'] as String), isVoiceInput: (row['isVoiceInput'] as int) == 1, imagePath: row['imagePath'] as String?)).toList();
  }

  static Future<void> saveEmergencyContact(EmergencyContact contact) async {
    final db = await database;
    await db.insert('emergency_contacts', {'id': contact.id, 'name': contact.name, 'phoneNumber': contact.phoneNumber, 'isPrimary': contact.isPrimary ? 1 : 0}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    final db = await database;
    final results = await db.query('emergency_contacts', orderBy: 'isPrimary DESC');
    return results.map((row) => EmergencyContact(id: row['id'] as String, name: row['name'] as String, phoneNumber: row['phoneNumber'] as String, isPrimary: (row['isPrimary'] as int) == 1)).toList();
  }

  static Future<void> deleteEmergencyContact(String id) async {
    final db = await database;
    await db.delete('emergency_contacts', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }
}
