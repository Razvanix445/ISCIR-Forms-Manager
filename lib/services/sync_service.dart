import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import '../models/client.dart';
import '../models/form.dart';

class SyncService {
  static final SyncService instance = SyncService._();

  SyncService._();

  final Connectivity _connectivity = Connectivity();

  /// Check if device is online
  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);
  }

  /// ============================================
  /// CLIENT OPERATIONS (LOCAL ONLY)
  /// ============================================

  /// Create client locally (no cloud upload)
  Future<String> createClient(Client client) async {
    final localId = await DatabaseService.instance.createClient(client);
    return localId.toString();
  }

  /// Update client locally (no cloud upload)
  Future<bool> updateClient(Client client) async {
    final localId = int.tryParse(client.id!);
    if (localId == null) return false;

    await DatabaseService.instance.updateClient(client);
    return true;
  }

  /// Delete client locally (no cloud delete)
  Future<bool> deleteClient(String clientId) async {
    final localId = int.tryParse(clientId);
    if (localId == null) return false;

    await DatabaseService.instance.deleteClient(localId);
    return true;
  }

  /// Load clients from local database
  Future<List<Client>> loadClients() async {
    return await DatabaseService.instance.getAllClients();
  }

  /// Get recent clients from local database
  Future<List<Client>> getRecentClients({int limit = 15}) async {
    return await DatabaseService.instance.getRecentClients(limit: limit);
  }

  /// Search clients in local database only
  Future<List<Client>> searchClients(String query) async {
    return await DatabaseService.instance.searchClients(query);
  }

  /// ============================================
  /// FORM OPERATIONS (LOCAL ONLY)
  /// ============================================

  /// Create form locally (no cloud upload)
  Future<String> createForm(ISCIRForm form, int localClientId) async {
    final formForLocal = form.copyWith(clientId: localClientId.toString());
    final localFormId = await DatabaseService.instance.createForm(formForLocal);
    return localFormId.toString();
  }

  /// Update form locally (no cloud upload)
  Future<bool> updateForm(ISCIRForm form) async {
    final localId = int.tryParse(form.id!);
    if (localId == null) return false;

    await DatabaseService.instance.updateForm(form);
    return true;
  }

  /// Delete form locally (no cloud delete)
  Future<bool> deleteForm(int formId) async {
    await DatabaseService.instance.deleteForm(formId);
    return true;
  }

  /// Load forms for a specific client
  Future<List<ISCIRForm>> loadFormsByClient(int clientId) async {
    return await DatabaseService.instance.getFormsByClientId(clientId);
  }

  /// Save form data locally (no cloud upload)
  Future<bool> saveFormData(int formId, Map<String, dynamic> formData) async {
    await DatabaseService.instance.saveFormData(formId, formData);
    return true;
  }

  /// ============================================
  /// MANUAL SYNC OPERATIONS
  /// ============================================

  /// Get summary of unsynced data (clients and their forms)
  Future<Map<String, dynamic>> getUnsyncedSummary() async {
    final db = await DatabaseService.instance.database;

    // Get all clients that need syncing (needs_sync = 1)
    final unsyncedClientRows = await db.query(
      'clients',
      where: 'needs_sync = ?',
      whereArgs: [1],
    );

    List<Map<String, dynamic>> unsyncedClientsWithForms = [];
    int totalForms = 0;

    for (var clientRow in unsyncedClientRows) {
      final clientId = clientRow['id'] as int;
      final clientName = '${clientRow['first_name']} ${clientRow['last_name']}';

      // Count forms that need syncing for this client
      final formsCount = await db.query(
        'forms',
        columns: ['COUNT(*) as count'],
        where: 'client_id = ? AND needs_sync = ?',
        whereArgs: [clientId, 1],
      );

      final formCount = formsCount.first['count'] as int;
      totalForms += formCount;

      unsyncedClientsWithForms.add({
        'id': clientId,
        'name': clientName,
        'formCount': formCount,
      });
    }

    // ALSO check for synced clients with unsynced forms
    final syncedClientsWithUnsyncedForms = await db.rawQuery('''
      SELECT DISTINCT c.id, c.first_name, c.last_name, COUNT(f.id) as form_count
      FROM clients c
      INNER JOIN forms f ON c.id = f.client_id
      WHERE c.needs_sync = 0
        AND f.needs_sync = 1
      GROUP BY c.id, c.first_name, c.last_name
    ''');

    // Add these to the summary
    for (var row in syncedClientsWithUnsyncedForms) {
      final clientId = row['id'] as int;
      final clientName = '${row['first_name']} ${row['last_name']}';
      final formCount = row['form_count'] as int;

      totalForms += formCount;

      unsyncedClientsWithForms.add({
        'id': clientId,
        'name': clientName,
        'formCount': formCount,
        'clientAlreadySynced': true,
      });
    }

    return {
      'clients': unsyncedClientsWithForms,
      'totalClients': unsyncedClientsWithForms.length,
      'totalForms': totalForms,
    };
  }

  /// Manually upload all unsynced data to cloud
  Future<Map<String, int>> manualUploadToCloud() async {
    if (!await isOnline()) {
      throw Exception('No internet connection');
    }

    int successClients = 0;
    int failClients = 0;
    int successForms = 0;
    int failForms = 0;

    final db = await DatabaseService.instance.database;

    print('📤 Starting manual upload...');

    // ============================================
    // STEP 1: Upload clients that need syncing (needs_sync = 1)
    // ============================================
    final unsyncedClientRows = await db.query(
      'clients',
      where: 'needs_sync = ?',
      whereArgs: [1],
    );

    print('📤 Found ${unsyncedClientRows.length} clients that need syncing');

    for (var clientRow in unsyncedClientRows) {
      final localClientId = clientRow['id'] as int;
      final client = Client.fromMap(Map<String, dynamic>.from(clientRow));
      final hasFirestoreId = clientRow['firestore_id'] as String?;

      try {
        String clientFirestoreId;

        if (hasFirestoreId != null && hasFirestoreId.isNotEmpty) {
          // ========================================
          // UPDATE existing client in Firebase
          // ========================================
          print('📤 Updating existing client: ${client.name}');

          final clientForFirebase = client.copyWith(id: hasFirestoreId);
          await FirestoreService.instance.updateClient(clientForFirebase);

          clientFirestoreId = hasFirestoreId;

          // Mark as synced
          await db.update(
            'clients',
            {'needs_sync': 0},
            where: 'id = ?',
            whereArgs: [localClientId],
          );

          print('✅ Client updated in Firebase');
        } else {
          // ========================================
          // CREATE new client in Firebase
          // ========================================
          print('📤 Creating new client: ${client.name}');

          clientFirestoreId = await FirestoreService.instance.createClient(client);

          // Update local record with firestore_id and mark as synced
          await DatabaseService.instance.updateClientFirestoreId(localClientId, clientFirestoreId);

          print('✅ Client created with Firestore ID: $clientFirestoreId');
        }

        successClients++;

        // Now upload all forms for this client that need syncing
        final clientForms = await db.query(
          'forms',
          where: 'client_id = ? AND needs_sync = ?',
          whereArgs: [localClientId, 1],
        );

        print('📤 Uploading ${clientForms.length} forms for client...');

        for (var formRow in clientForms) {
          final localFormId = formRow['id'] as int;

          try {
            // Load complete form with data
            final form = await DatabaseService.instance.getForm(localFormId);
            if (form == null) {
              print('⚠️ Form $localFormId not found');
              failForms++;
              continue;
            }

            // Upload form with the client's firestore_id
            final formForFirebase = form.copyWith(clientId: clientFirestoreId);
            final formFirestoreId = await FirestoreService.instance.createForm(formForFirebase);

            // Update local form with firestore_id and mark as synced
            await DatabaseService.instance.updateFormFirestoreId(localFormId, formFirestoreId);

            print('✅ Form uploaded with Firestore ID: $formFirestoreId');
            successForms++;

          } catch (e) {
            print('❌ Failed to upload form $localFormId: $e');
            failForms++;
          }
        }

      } catch (e) {
        print('❌ Failed to upload client $localClientId: $e');
        failClients++;
      }
    }

    // ============================================
    // STEP 2: Upload unsynced forms for synced clients
    // ============================================
    print('📤 Checking for unsynced forms on synced clients...');

    final syncedClientsWithUnsyncedForms = await db.rawQuery('''
    SELECT DISTINCT c.id, c.firestore_id
    FROM clients c
    INNER JOIN forms f ON c.id = f.client_id
    WHERE c.needs_sync = 0
      AND c.firestore_id IS NOT NULL AND c.firestore_id != ''
      AND f.needs_sync = 1
  ''');

    print('📤 Found ${syncedClientsWithUnsyncedForms.length} synced clients with unsynced forms');

    for (var row in syncedClientsWithUnsyncedForms) {
      final localClientId = row['id'] as int;
      final clientFirestoreId = row['firestore_id'] as String;

      // Get all unsynced forms for this client
      final unsyncedForms = await db.query(
        'forms',
        where: 'client_id = ? AND needs_sync = ?',
        whereArgs: [localClientId, 1],
      );

      print('📤 Uploading ${unsyncedForms.length} unsynced forms for client (firestore_id: $clientFirestoreId)...');

      for (var formRow in unsyncedForms) {
        final localFormId = formRow['id'] as int;

        try {
          // Load complete form with data
          final form = await DatabaseService.instance.getForm(localFormId);
          if (form == null) {
            print('⚠️ Form $localFormId not found');
            failForms++;
            continue;
          }

          // Upload form with the client's firestore_id
          final formForFirebase = form.copyWith(clientId: clientFirestoreId);
          final formFirestoreId = await FirestoreService.instance.createForm(formForFirebase);

          // Update local form with firestore_id and mark as synced
          await DatabaseService.instance.updateFormFirestoreId(localFormId, formFirestoreId);

          print('✅ Form uploaded with Firestore ID: $formFirestoreId');
          successForms++;

        } catch (e) {
          print('❌ Failed to upload form $localFormId: $e');
          failForms++;
        }
      }
    }

    print('📊 Upload complete: $successClients clients, $successForms forms uploaded');

    return {
      'successClients': successClients,
      'failClients': failClients,
      'successForms': successForms,
      'failForms': failForms,
    };
  }

  /// Manually download all data from cloud (additive only - never deletes local data)
  Future<Map<String, int>> manualDownloadFromCloud() async {
    if (!await isOnline()) {
      throw Exception('No internet connection');
    }

    int newClients = 0;
    int newForms = 0;

    print('📥 Starting manual download from cloud...');

    try {
      // Download all clients from Firestore
      final cloudClients = await FirestoreService.instance.getAllClients();
      print('📥 Found ${cloudClients.length} clients in cloud');

      final db = await DatabaseService.instance.database;

      // Get existing firestore_ids from local database
      final existingFirestoreIds = await db.query(
        'clients',
        columns: ['firestore_id'],
        where: 'firestore_id IS NOT NULL AND firestore_id != ?',
        whereArgs: [''],
      );

      final localFirestoreIdSet = existingFirestoreIds
          .map((row) => row['firestore_id'] as String)
          .toSet();

      // Add clients that don't exist locally
      for (var cloudClient in cloudClients) {
        if (!localFirestoreIdSet.contains(cloudClient.id)) {
          await DatabaseService.instance.createClient(
            cloudClient,
            firestoreId: cloudClient.id,
          );
          newClients++;
          print('✅ Downloaded client: ${cloudClient.name}');
        }
      }

      // Download all forms from Firestore
      final cloudForms = await FirestoreService.instance.getAllForms();
      print('📥 Found ${cloudForms.length} forms in cloud');

      // Get existing form firestore_ids from local database
      final existingFormIds = await db.query(
        'forms',
        columns: ['firestore_id'],
        where: 'firestore_id IS NOT NULL AND firestore_id != ?',
        whereArgs: [''],
      );

      final localFormIdSet = existingFormIds
          .map((row) => row['firestore_id'] as String)
          .toSet();

      // Add forms that don't exist locally
      for (var cloudForm in cloudForms) {
        if (!localFormIdSet.contains(cloudForm.id)) {
          // Find local client by their firestore_id
          final localClientResult = await db.query(
            'clients',
            columns: ['id'],
            where: 'firestore_id = ?',
            whereArgs: [cloudForm.clientId],
          );

          if (localClientResult.isEmpty) {
            print('⚠️ Client not found for form ${cloudForm.id}');
            continue;
          }

          final localClientId = localClientResult.first['id'] as int;

          // Create form with local client_id
          final formForLocal = cloudForm.copyWith(clientId: localClientId.toString());
          final localFormId = await DatabaseService.instance.createForm(
            formForLocal,
            firestoreId: cloudForm.id,
          );

          // Save form data if exists
          if (cloudForm.formData.isNotEmpty) {
            await DatabaseService.instance.saveFormData(localFormId, cloudForm.formData);
          }

          newForms++;
          print('✅ Downloaded form: ${cloudForm.id}');
        }
      }

      print('📊 Download complete: $newClients new clients, $newForms new forms');

      return {
        'newClients': newClients,
        'newForms': newForms,
      };
    } catch (e) {
      print('❌ Download failed: $e');
      rethrow;
    }
  }
}