import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/form.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  static Database? _database;

  DatabaseService._();

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
      version: 2, // Increment version for new tables
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Clients table
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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

    // Forms table
    await db.execute('''
      CREATE TABLE forms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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

    // Form data table
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

    // Sync queue table (NEW)
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
    if (oldVersion < 2) {
      // Add firestore_id columns
      await db.execute('ALTER TABLE clients ADD COLUMN firestore_id TEXT UNIQUE');
      await db.execute('ALTER TABLE forms ADD COLUMN firestore_id TEXT UNIQUE');
      await db.execute('ALTER TABLE forms ADD COLUMN client_firestore_id TEXT');

      // Create sync queue table
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
  }

  // CLIENT OPERATIONS

  Future<int> createClient(Client client, {String? firestoreId}) async {
    final db = await database;
    final map = client.toMap();
    map['firestore_id'] = firestoreId;
    return await db.insert('clients', map);
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final result = await db.query('clients', orderBy: 'first_name ASC, last_name ASC');
    return result.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getClient(int id) async {
    final db = await database;
    final result = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Client.fromMap(result.first);
  }

  Future<Client?> getClientByFirestoreId(String firestoreId) async {
    final db = await database;
    final result = await db.query('clients', where: 'firestore_id = ?', whereArgs: [firestoreId]);
    if (result.isEmpty) return null;
    return Client.fromMap(result.first);
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return await db.update('clients', client.toMap(), where: 'id = ?', whereArgs: [client.id]);
  }

  Future<void> updateClientFirestoreId(int localId, String firestoreId) async {
    final db = await database;
    await db.update('clients', {'firestore_id': firestoreId}, where: 'id = ?', whereArgs: [localId]);
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // FORM OPERATIONS

  Future<int> createForm(ISCIRForm form, {String? firestoreId}) async {
    final db = await database;
    final map = form.toMap();
    map['firestore_id'] = firestoreId;
    return await db.insert('forms', map);
  }

  Future<List<ISCIRForm>> getFormsByClientId(int clientId) async {
    final db = await database;
    final formMaps = await db.query(
      'forms',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at DESC',
    );

    List<ISCIRForm> forms = [];
    for (var map in formMaps) {
      // The database returns id as an integer, need to add it to the map
      final formMap = Map<String, dynamic>.from(map);

      // Create basic form from map (id will be converted to String in fromMap)
      final basicForm = ISCIRForm.fromMap(formMap);

      // Parse the form ID to get form data
      // Since basicForm.id is now a String, we need to parse it back to int
      final formId = int.tryParse(basicForm.id ?? '');

      if (formId != null) {
        final formData = await getFormData(formId);
        forms.add(basicForm.copyWith(formData: formData));
      } else {
        // If we can't parse the ID, add the form without data
        print('WARNING: Could not parse form ID: ${basicForm.id}');
        forms.add(basicForm);
      }
    }
    return forms;
  }

  Future<ISCIRForm?> getForm(int id) async {
    final db = await database;
    final result = await db.query('forms', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;

    final formMap = Map<String, dynamic>.from(result.first);
    final form = ISCIRForm.fromMap(formMap);

    // Get form data using the integer id directly
    final formData = await getFormData(id);
    return form.copyWith(formData: formData);
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

  // Get total forms count (for report numbering)
  Future<int> getTotalFormsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM forms');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Update a form
  Future<int> updateForm(ISCIRForm form) async {
    final db = await database;
    final localId = int.tryParse(form.id!);
    if (localId == null) return 0;

    return await db.update(
      'forms',
      form.toMap(),
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // Update form's Firestore ID
  Future<void> updateFormFirestoreId(int localId, String firestoreId) async {
    final db = await database;
    await db.update(
      'forms',
      {'firestore_id': firestoreId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // Delete a form
  Future<int> deleteForm(int id) async {
    final db = await database;

    // Delete form data first (foreign key relationship)
    await db.delete('form_data', where: 'form_id = ?', whereArgs: [id]);

    // Then delete the form itself
    return await db.delete('forms', where: 'id = ?', whereArgs: [id]);
  }

  // Save a single form field
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

  // Get form by Firestore ID
  Future<ISCIRForm?> getFormByFirestoreId(String firestoreId) async {
    final db = await database;
    final result = await db.query(
      'forms',
      where: 'firestore_id = ?',
      whereArgs: [firestoreId],
    );

    if (result.isEmpty) return null;

    final form = ISCIRForm.fromMap(result.first);
    final formData = await getFormData(int.parse(form.id!));
    return form.copyWith(formData: formData);
  }

  Future<void> saveFormData(int formId, Map<String, dynamic> formData) async {
    final db = await database;

    // Use UPSERT (insert or replace) instead of delete-then-insert
    // This MERGES new data with existing data instead of replacing everything
    await db.transaction((txn) async {
      for (final entry in formData.entries) {
        String? valueStr;
        try {
          valueStr = json.encode(entry.value);
        } catch (e) {
          valueStr = entry.value.toString();
        }

        // Insert or replace individual fields
        // This preserves data from other pages!
        await txn.insert(
          'form_data',
          {
            'form_id': formId,
            'field_name': entry.key,
            'field_value': valueStr,
          },
          conflictAlgorithm: ConflictAlgorithm.replace, // ← Replace only this field, not all!
        );
      }
    });
  }

  // SYNC QUEUE OPERATIONS

  Future<void> addToSyncQueue({
    required String entityType,
    required int entityId,
    String? firestoreId,
    required String operation,
    required Map<String, dynamic> data,
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
    return await db.query('sync_queue', where: 'synced = 0', orderBy: 'created_at ASC');
  }

  Future<void> markAsSynced(int queueId, String? firestoreId) async {
    final db = await database;
    await db.update('sync_queue', {
      'synced': 1,
      'firestore_id': firestoreId,
    }, where: 'id = ?', whereArgs: [queueId]);
  }

  Future<void> clearSyncedItems() async {
    final db = await database;
    await db.delete('sync_queue', where: 'synced = 1');
  }
}