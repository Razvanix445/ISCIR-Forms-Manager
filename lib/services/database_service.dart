import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/client.dart';
import '../models/form.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  static Database? _database;

  DatabaseService._();

  /// Get current user ID from Firebase Auth
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'iscir_forms.db');

    return await openDatabase(
      path,
      version: 6,  // Version 6 - added needs_sync column
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    /// Clients table
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        firestore_id TEXT UNIQUE,
        first_name TEXT,
        last_name TEXT,
        email TEXT,
        address TEXT,
        street TEXT,
        phone TEXT,
        installation_location TEXT,
        holder TEXT,
        created_at TEXT,
        updated_at TEXT,
        needs_sync INTEGER DEFAULT 1
      )
    ''');

    /// Forms table
    await db.execute('''
      CREATE TABLE forms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        firestore_id TEXT UNIQUE,
        client_id INTEGER,
        client_firestore_id TEXT,
        form_type TEXT,
        report_number TEXT,
        report_date TEXT,
        created_at TEXT,
        updated_at TEXT,
        needs_sync INTEGER DEFAULT 1,
        FOREIGN KEY (client_id) REFERENCES clients (id)
      )
    ''');

    /// Form data table
    await db.execute('''
      CREATE TABLE form_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        form_id INTEGER,
        field_name TEXT,
        field_value TEXT,
        FOREIGN KEY (form_id) REFERENCES forms (id),
        UNIQUE(form_id, field_name)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add user_id columns for multi-tenancy
      await db.execute('ALTER TABLE clients ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE forms ADD COLUMN user_id TEXT');

      // Set default user_id for existing records
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await db.update('clients', {'user_id': currentUser.uid});
        await db.update('forms', {'user_id': currentUser.uid});
      }
    }

    if (oldVersion < 3) {
      // Add firestore_id columns for cloud sync
      await db.execute('ALTER TABLE clients ADD COLUMN firestore_id TEXT UNIQUE');
      await db.execute('ALTER TABLE forms ADD COLUMN firestore_id TEXT UNIQUE');
    }

    if (oldVersion < 4) {
      // Add client_firestore_id to forms for easier lookups
      await db.execute('ALTER TABLE forms ADD COLUMN client_firestore_id TEXT');
    }

    if (oldVersion < 5) {
      // Remove sync_queue table if it exists
      await db.execute('DROP TABLE IF EXISTS sync_queue');
    }

    if (oldVersion < 6) {
      // Add needs_sync column for tracking modified clients
      await db.execute('ALTER TABLE clients ADD COLUMN needs_sync INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE forms ADD COLUMN needs_sync INTEGER DEFAULT 1');

      // Mark existing clients without firestore_id as needing sync
      await db.execute('UPDATE clients SET needs_sync = 1 WHERE firestore_id IS NULL OR firestore_id = ""');
      await db.execute('UPDATE forms SET needs_sync = 1 WHERE firestore_id IS NULL OR firestore_id = ""');

      // Mark existing clients WITH firestore_id as synced
      await db.execute('UPDATE clients SET needs_sync = 0 WHERE firestore_id IS NOT NULL AND firestore_id != ""');
      await db.execute('UPDATE forms SET needs_sync = 0 WHERE firestore_id IS NOT NULL AND firestore_id != ""');
    }
  }

  /// ============================================
  /// CLIENT OPERATIONS
  /// ============================================

  Future<int> createClient(Client client, {String? firestoreId}) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }

    final db = await database;
    final clientMap = client.toMap();
    clientMap['user_id'] = _currentUserId;

    if (firestoreId != null) {
      clientMap['firestore_id'] = firestoreId;
      clientMap['needs_sync'] = 0;  // Already synced from cloud
    } else {
      clientMap['needs_sync'] = 1;  // Needs upload
    }

    return await db.insert('clients', clientMap);
  }

  Future<void> updateClient(Client client) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }

    final db = await database;
    final localId = int.tryParse(client.id!);

    if (localId == null) {
      throw Exception('Invalid client ID');
    }

    final clientMap = client.toMap();
    clientMap['needs_sync'] = 1;  // Mark as needing sync

    await db.update(
      'clients',
      clientMap,
      where: 'id = ? AND user_id = ?',
      whereArgs: [localId, _currentUserId],
    );
  }

  Future<void> deleteClient(int localId) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }

    final db = await database;

    // Delete all forms for this client first
    await db.delete(
      'forms',
      where: 'client_id = ? AND user_id = ?',
      whereArgs: [localId, _currentUserId],
    );

    // Delete the client
    await db.delete(
      'clients',
      where: 'id = ? AND user_id = ?',
      whereArgs: [localId, _currentUserId],
    );
  }

  Future<Client?> getClient(int localId) async {
    if (_currentUserId == null) return null;

    final db = await database;
    final results = await db.query(
      'clients',
      where: 'id = ? AND user_id = ?',
      whereArgs: [localId, _currentUserId],
    );

    if (results.isEmpty) return null;
    return Client.fromMap(results.first);
  }

  Future<List<Client>> getAllClients() async {
    if (_currentUserId == null) return [];

    final db = await database;
    final results = await db.query(
      'clients',
      where: 'user_id = ?',
      whereArgs: [_currentUserId],
      orderBy: 'first_name ASC, last_name ASC',
    );

    return results.map((map) => Client.fromMap(map)).toList();
  }

  Future<List<Client>> getRecentClients({int limit = 15}) async {
    if (_currentUserId == null) return [];

    final db = await database;
    final results = await db.query(
      'clients',
      where: 'user_id = ?',
      whereArgs: [_currentUserId],
      orderBy: 'updated_at DESC',
      limit: limit,
    );

    return results.map((map) => Client.fromMap(map)).toList();
  }

  Future<List<Client>> searchClients(String query) async {
    if (_currentUserId == null) return [];

    final db = await database;
    final searchTerm = '%$query%';

    final results = await db.query(
      'clients',
      where: '''
        user_id = ? AND (
          first_name LIKE ? OR 
          last_name LIKE ? OR 
          email LIKE ? OR 
          phone LIKE ? OR 
          address LIKE ? OR
          holder LIKE ?
        )
      ''',
      whereArgs: [
        _currentUserId,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
      ],
      orderBy: 'first_name ASC, last_name ASC',
    );

    return results.map((map) => Client.fromMap(map)).toList();
  }

  Future<void> updateClientFirestoreId(int localId, String firestoreId) async {
    if (_currentUserId == null) return;

    final db = await database;
    await db.update(
      'clients',
      {
        'firestore_id': firestoreId,
        'needs_sync': 0,  // Mark as synced
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [localId, _currentUserId],
    );
  }

  /// ============================================
  /// FORM OPERATIONS
  /// ============================================

  Future<int> createForm(ISCIRForm form, {String? firestoreId}) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }

    final db = await database;
    final formMap = form.toMap();
    formMap['user_id'] = _currentUserId;

    if (firestoreId != null) {
      formMap['firestore_id'] = firestoreId;
      formMap['needs_sync'] = 0;  // Already synced from cloud
    } else {
      formMap['needs_sync'] = 1;  // Needs upload
    }

    return await db.insert('forms', formMap);
  }

  Future<void> updateForm(ISCIRForm form) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }

    final db = await database;
    final localId = int.tryParse(form.id!);

    if (localId == null) {
      throw Exception('Invalid form ID');
    }

    final formMap = form.toMap();
    formMap['needs_sync'] = 1;  // Mark as needing sync

    await db.update(
      'forms',
      formMap,
      where: 'id = ? AND user_id = ?',
      whereArgs: [localId, _currentUserId],
    );
  }

  Future<void> deleteForm(int formId) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }

    final db = await database;

    // Delete form data first
    await db.delete(
      'form_data',
      where: 'form_id = ?',
      whereArgs: [formId],
    );

    // Delete the form
    await db.delete(
      'forms',
      where: 'id = ? AND user_id = ?',
      whereArgs: [formId, _currentUserId],
    );
  }

  Future<ISCIRForm?> getForm(int formId) async {
    if (_currentUserId == null) return null;

    final db = await database;
    final results = await db.query(
      'forms',
      where: 'id = ? AND user_id = ?',
      whereArgs: [formId, _currentUserId],
    );

    if (results.isEmpty) return null;

    final formMap = Map<String, dynamic>.from(results.first);

    // Load form data
    final formDataResults = await db.query(
      'form_data',
      where: 'form_id = ?',
      whereArgs: [formId],
    );

    final formData = <String, dynamic>{};
    for (var row in formDataResults) {
      final fieldName = row['field_name'] as String;
      final fieldValue = row['field_value'] as String;
      formData[fieldName] = fieldValue;
    }

    // Set formData as a Map, NOT as a JSON string
    formMap['formData'] = formData;

    return ISCIRForm.fromMap(formMap);
  }

  Future<List<ISCIRForm>> getFormsByClientId(int clientId) async {
    if (_currentUserId == null) return [];

    final db = await database;
    final results = await db.query(
      'forms',
      where: 'client_id = ? AND user_id = ?',
      whereArgs: [clientId, _currentUserId],
      orderBy: 'created_at DESC',
    );

    List<ISCIRForm> forms = [];

    for (var formMap in results) {
      final formId = formMap['id'] as int;

      // Load form data
      final formDataResults = await db.query(
        'form_data',
        where: 'form_id = ?',
        whereArgs: [formId],
      );

      final formData = <String, dynamic>{};
      for (var row in formDataResults) {
        final fieldName = row['field_name'] as String;
        final fieldValue = row['field_value'] as String;
        formData[fieldName] = fieldValue;
      }

      final completeFormMap = Map<String, dynamic>.from(formMap);
      // Set formData as a Map, NOT as a JSON string
      completeFormMap['formData'] = formData;

      forms.add(ISCIRForm.fromMap(completeFormMap));
    }

    return forms;
  }

  Future<void> updateFormFirestoreId(int localFormId, String firestoreId) async {
    if (_currentUserId == null) return;

    final db = await database;
    await db.update(
      'forms',
      {
        'firestore_id': firestoreId,
        'needs_sync': 0,  // Mark as synced
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [localFormId, _currentUserId],
    );
  }

  /// ============================================
  /// FORM DATA OPERATIONS
  /// ============================================

  Future<void> saveFormData(int formId, Map<String, dynamic> formData) async {
    final db = await database;

    for (var entry in formData.entries) {
      await db.insert(
        'form_data',
        {
          'form_id': formId,
          'field_name': entry.key,
          'field_value': entry.value.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<Map<String, dynamic>> getFormData(int formId) async {
    final db = await database;
    final results = await db.query(
      'form_data',
      where: 'form_id = ?',
      whereArgs: [formId],
    );

    final formData = <String, dynamic>{};
    for (var row in results) {
      final fieldName = row['field_name'] as String;
      final fieldValue = row['field_value'] as String;
      formData[fieldName] = fieldValue;
    }

    return formData;
  }

  /// ============================================
  /// REPORT NUMBER OPERATIONS
  /// ============================================

  Future<int> getLastReportNumber() async {
    if (_currentUserId == null) return 0;

    final db = await database;
    final result = await db.rawQuery('''
      SELECT report_number 
      FROM forms 
      WHERE user_id = ? AND report_number IS NOT NULL AND report_number != ''
      ORDER BY CAST(report_number AS INTEGER) DESC 
      LIMIT 1
    ''', [_currentUserId]);

    if (result.isEmpty) return 0;

    final reportNumber = result.first['report_number'] as String?;
    if (reportNumber == null || reportNumber.isEmpty) return 0;

    return int.tryParse(reportNumber) ?? 0;
  }

  /// Get highest report number for generating new report numbers
  Future<int> getHighestReportNumber() async {
    return await getLastReportNumber();
  }

  /// Save a single form field (used during form editing)
  Future<void> saveFormField(int formId, String fieldName, String fieldValue) async {
    final db = await database;
    await db.insert(
      'form_data',
      {
        'form_id': formId,
        'field_name': fieldName,
        'field_value': fieldValue,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}