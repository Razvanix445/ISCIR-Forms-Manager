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
      version: 4,  // Version 4 for multi-tenancy (user_id columns)
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
        updated_at TEXT
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

    /// Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT,
        entity_id INTEGER,
        firestore_id TEXT,
        operation TEXT,
        data TEXT,
        created_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Upgrade from version 1 to 2
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE clients ADD COLUMN firestore_id TEXT UNIQUE');
      await db.execute('ALTER TABLE forms ADD COLUMN firestore_id TEXT UNIQUE');
      await db.execute('ALTER TABLE forms ADD COLUMN client_firestore_id TEXT');

      await db.execute('''
        CREATE TABLE sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entity_type TEXT,
          entity_id INTEGER,
          firestore_id TEXT,
          operation TEXT,
          data TEXT,
          created_at TEXT,
          synced INTEGER DEFAULT 0
        )
      ''');
    }

    // Upgrade from version 2 to 3 - Add first_name/last_name columns
    if (oldVersion < 3) {
      print('🔄 Upgrading database from version $oldVersion to 3');

      final columns = await db.rawQuery('PRAGMA table_info(clients)');
      final columnNames = columns.map((col) => col['name'] as String).toList();

      if (!columnNames.contains('first_name')) {
        print('📝 Adding first_name column...');
        await db.execute('ALTER TABLE clients ADD COLUMN first_name TEXT');
      }

      if (!columnNames.contains('last_name')) {
        print('📝 Adding last_name column...');
        await db.execute('ALTER TABLE clients ADD COLUMN last_name TEXT');
      }

      // Migrate existing data from 'name' field if it exists
      if (columnNames.contains('name')) {
        print('🔄 Migrating name data to first_name/last_name...');
        final clients = await db.query('clients');
        for (var client in clients) {
          final name = client['name'] as String?;
          if (name != null && name.isNotEmpty) {
            final parts = name.split(' ');
            final firstName = parts.isNotEmpty ? parts.first : '';
            final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';

            await db.update(
              'clients',
              {
                'first_name': firstName,
                'last_name': lastName,
              },
              where: 'id = ?',
              whereArgs: [client['id']],
            );
          }
        }
      }

      print('✅ Database upgrade to version 3 completed!');
    }

    // Upgrade from version 3 to 4 - Add user_id for multi-tenancy
    if (oldVersion < 4) {
      print('🔄 Upgrading database to version 4 for multi-tenancy...');
      print('⚠️  CRITICAL: Adding user_id columns to isolate user data');

      final columns = await db.rawQuery('PRAGMA table_info(clients)');
      final columnNames = columns.map((col) => col['name'] as String).toList();

      // Add user_id to clients table
      if (!columnNames.contains('user_id')) {
        print('📝 Adding user_id column to clients table...');
        await db.execute('ALTER TABLE clients ADD COLUMN user_id TEXT');
      }

      // Add user_id to forms table
      final formColumns = await db.rawQuery('PRAGMA table_info(forms)');
      final formColumnNames = formColumns.map((col) => col['name'] as String).toList();

      if (!formColumnNames.contains('user_id')) {
        print('📝 Adding user_id column to forms table...');
        await db.execute('ALTER TABLE forms ADD COLUMN user_id TEXT');
      }

      print('⚠️  WARNING: Existing data has no user_id.');
      print('   Recommendation: Clear app data or uninstall/reinstall for clean state');
      print('✅ Database upgrade to version 4 completed!');
    }
  }

  /// CLIENT OPERATIONS

  Future<int> createClient(Client client, {String? firestoreId}) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    final map = client.toMap();
    map['user_id'] = _currentUserId;
    map['firestore_id'] = firestoreId;
    return await db.insert('clients', map);
  }

  Future<List<Client>> getAllClients() async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    final result = await db.query(
      'clients',
      where: 'user_id = ?',
      whereArgs: [_currentUserId],
      orderBy: 'first_name ASC, last_name ASC',
    );
    return result.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getClient(int id) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    final result = await db.query(
      'clients',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _currentUserId],
    );
    if (result.isEmpty) return null;
    return Client.fromMap(result.first);
  }

  Future<Client?> getClientByFirestoreId(String firestoreId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    final result = await db.query(
      'clients',
      where: 'firestore_id = ? AND user_id = ?',
      whereArgs: [firestoreId, _currentUserId],
    );
    if (result.isEmpty) return null;
    return Client.fromMap(result.first);
  }

  /// Get recently created or updated clients
  Future<List<Client>> getRecentClients({int limit = 10}) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    final result = await db.rawQuery('''
    SELECT * FROM clients 
    WHERE user_id = ? 
    ORDER BY updated_at DESC, created_at DESC
    LIMIT ?
  ''', [_currentUserId, limit]);

    return result.map((map) => Client.fromMap(map)).toList();
  }

  Future<List<Client>> searchClients(String query) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    if (query.isEmpty) return [];

    final db = await database;
    final lowerQuery = '%${query.toLowerCase()}%';

    final result = await db.rawQuery('''
    SELECT * FROM clients 
    WHERE user_id = ? 
    AND (
      LOWER(first_name) LIKE ? OR 
      LOWER(last_name) LIKE ? OR 
      LOWER(email) LIKE ? OR 
      LOWER(phone) LIKE ?
    )
    ORDER BY first_name ASC, last_name ASC
  ''', [_currentUserId, lowerQuery, lowerQuery, lowerQuery, lowerQuery]);

    return result.map((map) => Client.fromMap(map)).toList();
  }

  Future<int> updateClient(Client client) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [client.id, _currentUserId],
    );
  }

  Future<void> updateClientFirestoreId(int localId, String firestoreId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    await db.update(
      'clients',
      {'firestore_id': firestoreId},
      where: 'id = ? AND user_id = ?',
      whereArgs: [localId, _currentUserId],
    );
  }

  Future<int> deleteClient(int id) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    return await db.delete(
      'clients',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _currentUserId],
    );
  }

  /// Clear all local data (useful when switching users)
  Future<void> clearAllData() async {
    final db = await database;
    print('🗑️  Clearing all local data...');
    await db.delete('clients');
    await db.delete('forms');
    await db.delete('form_data');
    await db.delete('sync_queue');
    print('✅ All local data cleared');
  }

  /// FORM OPERATIONS

  Future<int> createForm(ISCIRForm form, {String? firestoreId}) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    final map = form.toMap();
    map['user_id'] = _currentUserId;
    map['firestore_id'] = firestoreId;
    return await db.insert('forms', map);
  }

  Future<List<ISCIRForm>> getFormsByClientId(int clientId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    final formMaps = await db.query(
      'forms',
      where: 'client_id = ? AND user_id = ?',
      whereArgs: [clientId, _currentUserId],
      orderBy: 'created_at DESC',
    );

    List<ISCIRForm> forms = [];
    for (var map in formMaps) {
      final formMap = Map<String, dynamic>.from(map);

      final basicForm = ISCIRForm.fromMap(formMap);

      final formId = int.tryParse(basicForm.id ?? '');

      if (formId != null) {
        final formData = await getFormData(formId);
        forms.add(basicForm.copyWith(formData: formData));
      } else {
        print('WARNING: Could not parse form ID: ${basicForm.id}');
        forms.add(basicForm);
      }
    }
    return forms;
  }

  Future<ISCIRForm?> getForm(int id) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    final result = await db.query(
      'forms',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _currentUserId],
    );
    if (result.isEmpty) return null;

    final formMap = Map<String, dynamic>.from(result.first);
    final form = ISCIRForm.fromMap(formMap);

    final formData = await getFormData(id);
    return form.copyWith(formData: formData);
  }

  /// Get ALL forms from the local database (for Excel export)
  Future<List<ISCIRForm>> getAllForms() async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    final formMaps = await db.query(
      'forms',
      where: 'user_id = ?',
      whereArgs: [_currentUserId],
      orderBy: 'created_at DESC',
    );

    List<ISCIRForm> forms = [];
    for (var map in formMaps) {
      final formMap = Map<String, dynamic>.from(map);
      final basicForm = ISCIRForm.fromMap(formMap);

      final formId = int.tryParse(basicForm.id ?? '');
      if (formId != null) {
        final formData = await getFormData(formId);
        forms.add(basicForm.copyWith(formData: formData));
      } else {
        print('WARNING: Could not parse form ID: ${basicForm.id}');
        forms.add(basicForm);
      }
    }
    return forms;
  }

  Future<Map<String, dynamic>> getFormData(int formId) async {
    final db = await database;
    final result = await db.query('form_data', where: 'form_id = ?', whereArgs: [formId]);

    Map<String, dynamic> formData = {};
    for (var row in result) {
      final fieldName = row['field_name'] as String;
      final fieldValue = row['field_value'] as String?;
      if (fieldValue != null) {
        try {
          formData[fieldName] = json.decode(fieldValue);
        } catch (e) {
          formData[fieldName] = fieldValue;
        }
      }
    }
    return formData;
  }

  Future<int> getTotalFormsCount() async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM forms WHERE user_id = ?',
      [_currentUserId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> updateForm(ISCIRForm form) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    final localId = int.tryParse(form.id!);
    if (localId == null) return 0;

    return await db.update(
      'forms',
      form.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [localId, _currentUserId],
    );
  }

  Future<void> updateFormFirestoreId(int localId, String firestoreId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    await db.update(
      'forms',
      {'firestore_id': firestoreId},
      where: 'id = ? AND user_id = ?',
      whereArgs: [localId, _currentUserId],
    );
  }

  Future<int> deleteForm(int id) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;

    await db.delete('form_data', where: 'form_id = ?', whereArgs: [id]);

    return await db.delete(
      'forms',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _currentUserId],
    );
  }

  Future<void> saveFormField(int formId, String fieldName, dynamic fieldValue) async {
    final db = await database;

    await db.insert(
      'form_data',
      {
        'form_id': formId,
        'field_name': fieldName,
        'field_value': fieldValue?.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save multiple form fields at once
  Future<void> saveFormData(int formId, Map<String, dynamic> formData) async {
    final db = await database;

    // Save each field in the formData map
    for (var entry in formData.entries) {
      await db.insert(
        'form_data',
        {
          'form_id': formId,
          'field_name': entry.key,
          'field_value': json.encode(entry.value),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<ISCIRForm?> getFormByFirestoreId(String firestoreId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;
    final result = await db.query(
      'forms',
      where: 'firestore_id = ? AND user_id = ?',
      whereArgs: [firestoreId, _currentUserId],
    );

    if (result.isEmpty) return null;

    final form = ISCIRForm.fromMap(result.first);
    final formData = await getFormData(int.parse(form.id!));
    return form.copyWith(formData: formData);
  }

  Future<int> getHighestReportNumber() async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final db = await database;

    final result = await db.rawQuery('''
      SELECT report_number FROM forms 
      WHERE user_id = ?
      ORDER BY CAST(report_number AS INTEGER) DESC 
      LIMIT 1
    ''', [_currentUserId]);

    if (result.isEmpty) return 0;

    final reportNumber = result.first['report_number'] as String?;
    if (reportNumber == null || reportNumber.isEmpty) return 0;

    return int.tryParse(reportNumber) ?? 0;
  }

  /// SYNC QUEUE OPERATIONS

  Future<void> addToSyncQueue({
    required String entityType,
    required int entityId,
    required String operation,
    required Map<String, dynamic> data,
    String? firestoreId,
  }) async {
    final db = await database;

    await db.insert('sync_queue', {
      'entity_type': entityType,
      'entity_id': entityId,
      'firestore_id': firestoreId,
      'operation': operation,
      'data': json.encode(data),
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedItems() async {
    final db = await database;
    return await db.query('sync_queue', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markAsSynced(int id, String? firestoreId) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {
        'synced': 1,
        'firestore_id': firestoreId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearSyncedItems() async {
    final db = await database;
    await db.delete('sync_queue', where: 'synced = ?', whereArgs: [1]);
  }
}