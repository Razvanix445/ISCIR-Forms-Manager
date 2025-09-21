import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/form.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('iscir_forms.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    print('Creating database tables...');

    // Clients table - FIXED schema
    await db.execute('''
    CREATE TABLE clients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      email TEXT NOT NULL,
      address TEXT NOT NULL,
      street TEXT NOT NULL,
      phone TEXT NOT NULL,
      installation_location TEXT NOT NULL,
      holder TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

    // Forms table
    await db.execute('''
    CREATE TABLE forms (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      client_id INTEGER NOT NULL,
      form_type TEXT NOT NULL,
      report_number TEXT NOT NULL,
      report_date TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (client_id) REFERENCES clients (id)
    )
  ''');

    // Form data table
    await db.execute('''
    CREATE TABLE form_data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      form_id INTEGER NOT NULL,
      field_name TEXT NOT NULL,
      field_value TEXT,
      FOREIGN KEY (form_id) REFERENCES forms (id),
      UNIQUE(form_id, field_name)
    )
  ''');

    // Generated PDFs table
    await db.execute('''
    CREATE TABLE generated_pdfs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      form_id INTEGER NOT NULL,
      pdf_path TEXT NOT NULL,
      pdf_type TEXT NOT NULL,
      generated_at TEXT NOT NULL,
      FOREIGN KEY (form_id) REFERENCES forms (id)
    )
  ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      await db.execute('ALTER TABLE forms ADD COLUMN report_number TEXT DEFAULT ""');
      await db.execute('ALTER TABLE forms ADD COLUMN report_date TEXT DEFAULT ""');
    }

    if (oldVersion < 3) {
      // Check if we need to migrate from old 'name' column to new structure
      try {
        // Check if old 'name' column exists
        final tableInfo = await db.rawQuery('PRAGMA table_info(clients)');
        final columnNames = tableInfo.map((row) => row['name']).toList();

        if (columnNames.contains('name') && !columnNames.contains('first_name')) {
          print('Migrating from old client schema...');

          // Add new columns
          await db.execute('ALTER TABLE clients ADD COLUMN first_name TEXT DEFAULT ""');
          await db.execute('ALTER TABLE clients ADD COLUMN last_name TEXT DEFAULT ""');
          await db.execute('ALTER TABLE clients ADD COLUMN email TEXT DEFAULT ""');

          // Migrate data from 'name' to 'first_name'
          await db.execute('''
          UPDATE clients 
          SET first_name = name, last_name = '', email = ''
          WHERE name IS NOT NULL AND name != ''
        ''');

          print('Migration completed successfully');
        } else if (!columnNames.contains('first_name')) {
          // Fresh install, add the columns
          await db.execute('ALTER TABLE clients ADD COLUMN first_name TEXT DEFAULT ""');
          await db.execute('ALTER TABLE clients ADD COLUMN last_name TEXT DEFAULT ""');
          await db.execute('ALTER TABLE clients ADD COLUMN email TEXT DEFAULT ""');
        }
      } catch (e) {
        print('Error during migration: $e');
        // If migration fails, you might need to recreate the table
        rethrow;
      }
    }
  }

  // Client operations
  Future<int> createClient(Client client) async {
    final db = await instance.database;
    return await db.insert('clients', client.toMap());
  }

  Future<List<Client>> getAllClients() async {
    try {
      final db = await instance.database;

      // Use CORRECT column names (first_name, last_name, not 'name')
      final result = await db.query(
          'clients',
          orderBy: 'first_name ASC, last_name ASC'  // FIXED: Use correct columns
      );

      print('Found ${result.length} clients');
      return result.map((map) => Client.fromMap(map)).toList();

    } catch (e) {
      print('Error getting clients: $e');
      return [];
    }
  }

  Future<Client?> getClient(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Client.fromMap(result.first);
    }
    return null;
  }

  Future<int> getTotalFormsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM forms');

    if (result.isNotEmpty) {
      return result.first['count'] as int;
    }

    return 0;
  }

  Future<List<ISCIRForm>> getAllFormsOrderedByCreation() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'forms',
      orderBy: 'created_at ASC', // Oldest first for sequential numbering
    );

    List<ISCIRForm> forms = [];
    for (var map in maps) {
      final basicForm = ISCIRForm.fromMap(map);
      final formData = await getFormData(basicForm.id!);
      final completeForm = basicForm.copyWith(formData: formData);
      forms.add(completeForm);
    }

    return forms;
  }

  Future<void> updateFormReportNumber(int formId, String reportNumber) async {
    final db = await database;
    await db.update(
      'forms',
      {'report_number': reportNumber},
      where: 'id = ?',
      whereArgs: [formId],
    );
  }

  Future<List<ISCIRForm>> getFormsByClient(int clientId) async {
    final db = await database;

    final List<Map<String, dynamic>> formMaps = await db.query(
      'forms',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at DESC',
    );

    if (formMaps.isEmpty) {
      return [];
    }

    final formIds = formMaps.map((map) => map['id'] as int).toList();

    final List<Map<String, dynamic>> dataRows = await db.query(
      'form_data',
      where: 'form_id IN (${formIds.map((_) => '?').join(',')})',
      whereArgs: formIds,
    );

    Map<int, Map<String, dynamic>> formDataByFormId = {};

    for (var row in dataRows) {
      final formId = row['form_id'] as int;
      final fieldName = row['field_name'] as String;
      final fieldValue = row['field_value'] as String?;

      if (!formDataByFormId.containsKey(formId)) {
        formDataByFormId[formId] = {};
      }

      if (fieldValue != null) {
        try {
          formDataByFormId[formId]![fieldName] = json.decode(fieldValue);
        } catch (e) {
          formDataByFormId[formId]![fieldName] = fieldValue;
        }
      }
    }

    return formMaps.map((map) {
      final form = ISCIRForm.fromMap(map);
      final formData = formDataByFormId[form.id] ?? {};
      return form.copyWith(formData: formData);
    }).toList();
  }

  Future<int> updateClient(Client client) async {
    final db = await instance.database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await instance.database;
    return await db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Form operations
  Future<int> createForm(ISCIRForm form) async {
    final db = await instance.database;
    return await db.insert('forms', form.toMap());
  }

  Future<ISCIRForm?> getForm(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'forms',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      final form = ISCIRForm.fromMap(result.first);
      final formData = await getFormData(id);
      return form.copyWith(formData: formData);
    }
    return null;
  }

  Future<int> updateForm(ISCIRForm form) async {
    final db = await instance.database;
    return await db.update(
      'forms',
      form.toMap(),
      where: 'id = ?',
      whereArgs: [form.id],
    );
  }

  Future<int> deleteForm(int id) async {
    final db = await instance.database;
    // Delete form data first
    await db.delete('form_data', where: 'form_id = ?', whereArgs: [id]);
    // Delete the form
    return await db.delete('forms', where: 'id = ?', whereArgs: [id]);
  }

  // Form data operations
  Future<Map<String, dynamic>> getFormData(int formId) async {
    final db = await instance.database;
    final result = await db.query(
      'form_data',
      where: 'form_id = ?',
      whereArgs: [formId],
    );

    Map<String, dynamic> formData = {};
    for (var row in result) {
      final fieldName = row['field_name'] as String;
      final fieldValue = row['field_value'] as String?;

      if (fieldValue != null) {
        // Try to decode as JSON first (for complex objects like signatures)
        try {
          formData[fieldName] = json.decode(fieldValue);
        } catch (e) {
          // If JSON decode fails, store as string
          formData[fieldName] = fieldValue;
        }
      }
    }
    return formData;
  }

  Future<void> saveFormField(int formId, String fieldName, String? fieldValue) async {
    final db = await instance.database;
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

  Future<void> saveFormData(int formId, Map<String, dynamic> formData) async {
    final db = await database;

    // Use transaction to ensure all data is saved consistently
    await db.transaction((txn) async {
      // First, delete all existing form data for this form
      await txn.delete('form_data', where: 'form_id = ?', whereArgs: [formId]);

      // Then insert all new form data
      for (final entry in formData.entries) {
        String? valueToStore;

        // Handle different data types appropriately
        if (entry.value != null) {
          if (entry.value is Map || entry.value is List) {
            // For complex objects like signatures map, encode as JSON
            valueToStore = json.encode(entry.value);
          } else {
            // For simple values, convert to string
            valueToStore = entry.value.toString();
          }
        }

        await txn.insert(
          'form_data',
          {
            'form_id': formId,
            'field_name': entry.key,
            'field_value': valueToStore,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Update the form's updated_at timestamp
      await txn.update(
        'forms',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [formId],
      );
    });
  }

  Future<void> resetDatabase() async {
    try {
      // Close current database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Delete the database file completely
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'iscir_forms.db');
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
        print('✅ Database file deleted');
      }

      // Recreate database with fresh schema
      _database = await _initDB('iscir_forms.db');
      print('✅ Database recreated from scratch');

    } catch (e) {
      print('❌ Error resetting database: $e');
      rethrow;
    }
  }

  Future<void> fixClientSchema() async {
    try {
      final db = await database;

      final tableInfo = await db.rawQuery('PRAGMA table_info(clients)');
      final columnNames = tableInfo.map((row) => row['name']).toList();

      if (!columnNames.contains('first_name')) {
        await db.execute('ALTER TABLE clients ADD COLUMN first_name TEXT DEFAULT ""');
      }

      if (!columnNames.contains('last_name')) {
        await db.execute('ALTER TABLE clients ADD COLUMN last_name TEXT DEFAULT ""');
      }

      if (!columnNames.contains('email')) {
        await db.execute('ALTER TABLE clients ADD COLUMN email TEXT DEFAULT ""');
      }

      print('Database schema fixed');
    } catch (e) {
      print('Error fixing schema: $e');
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}