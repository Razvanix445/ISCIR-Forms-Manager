import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import '../models/client.dart';
import '../models/form.dart';

class SyncService {
  static final SyncService instance = SyncService._();

  SyncService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  // Initialize connectivity listener
  void initialize() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
          if (result.contains(ConnectivityResult.mobile) ||
              result.contains(ConnectivityResult.wifi)) {
            // Back online - trigger sync
            syncToCloud();
          }
        });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // Check if device is online
  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);
  }

  // CLIENT OPERATIONS

  // Create client (works offline and online)
  Future<String> createClient(Client client) async {
    // Always save to local SQLite first (fast, works offline)
    final localId = await DatabaseService.instance.createClient(client);

    if (await isOnline()) {
      try {
        // Try to save to Firestore
        final firestoreId = await FirestoreService.instance.createClient(
            client);

        // Update local record with Firestore ID
        await DatabaseService.instance.updateClientFirestoreId(
            localId, firestoreId);

        return firestoreId;
      } catch (e) {
        print('Failed to sync client to cloud: $e');
        // Add to sync queue for later
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'client',
          entityId: localId,
          operation: 'create',
          data: client.toMap(),
        );
        return localId.toString();
      }
    } else {
      // Offline - add to sync queue
      await DatabaseService.instance.addToSyncQueue(
        entityType: 'client',
        entityId: localId,
        operation: 'create',
        data: client.toMap(),
      );
      return localId.toString();
    }
  }

  // Load clients (always from local, sync in background)
  Future<List<Client>> loadClients() async {
    // Always return local data immediately (fast)
    final localClients = await DatabaseService.instance.getAllClients();

    // Trigger background sync if online
    if (await isOnline()) {
      final hasChanges = await syncFromCloud();

      if (hasChanges) {
        return await DatabaseService.instance.getAllClients();
      }
    }

    return localClients;
  }

  // Update client
  Future<bool> updateClient(Client client) async {
    print('DEBUG: updateClient called for client ID: ${client.id}');

    // Update local first
    final localId = int.tryParse(client.id!);
    if (localId == null) {
      print('ERROR: Invalid local ID: ${client.id}');
      return false;
    }

    await DatabaseService.instance.updateClient(client);
    print('DEBUG: Updated local client with local ID: $localId');

    if (await isOnline()) {
      try {
        // Get the client's Firestore ID from the database
        final db = await DatabaseService.instance.database;
        final result = await db.query(
          'clients',
          columns: ['firestore_id'],
          where: 'id = ?',
          whereArgs: [localId],
        );

        if (result.isEmpty) {
          print('ERROR: Client not found in local database');
          return false;
        }

        final firestoreId = result.first['firestore_id'] as String?;

        if (firestoreId == null || firestoreId.isEmpty) {
          print('DEBUG: Client has no Firestore ID yet - adding to sync queue');
          // Client was created offline, add to sync queue
          await DatabaseService.instance.addToSyncQueue(
            entityType: 'client',
            entityId: localId,
            operation: 'update',
            data: client.toMap(),
          );
          return true;
        }

        print('DEBUG: Found Firestore ID: $firestoreId');

        // Create a client with the Firestore ID for Firebase update
        final clientForFirebase = client.copyWith(id: firestoreId);
        await FirestoreService.instance.updateClient(clientForFirebase);

        print('DEBUG: Successfully updated client in Firebase');
        return true;
      } catch (e) {
        print('ERROR: Failed to sync update to cloud: $e');
        // Add to sync queue
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'client',
          entityId: localId,
          operation: 'update',
          data: client.toMap(),
        );
      }
    } else {
      print('DEBUG: Offline - adding update to sync queue');
      // Offline - add to sync queue
      await DatabaseService.instance.addToSyncQueue(
        entityType: 'client',
        entityId: localId,
        operation: 'update',
        data: client.toMap(),
      );
    }

    return true;
  }

  // Delete client
  Future<bool> deleteClient(String clientId) async {
    print('DEBUG: deleteClient called for client ID: $clientId');

    final localId = int.tryParse(clientId);
    if (localId == null) {
      print('ERROR: Invalid local ID: $clientId');
      return false;
    }

    // First, get the Firestore ID BEFORE deleting locally
    String? firestoreId;
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query(
        'clients',
        columns: ['firestore_id'],
        where: 'id = ?',
        whereArgs: [localId],
      );

      if (result.isNotEmpty) {
        firestoreId = result.first['firestore_id'] as String?;
        print('DEBUG: Found Firestore ID before delete: $firestoreId');
      }
    } catch (e) {
      print('ERROR: Failed to get Firestore ID: $e');
    }

    // Delete from local database
    await DatabaseService.instance.deleteClient(localId);
    print('DEBUG: Deleted client from local database');

    if (await isOnline()) {
      try {
        // Only delete from Firestore if it has a Firestore ID
        if (firestoreId != null && firestoreId.isNotEmpty) {
          print('DEBUG: Deleting from Firestore with ID: $firestoreId');
          await FirestoreService.instance.deleteClient(firestoreId);
          print('DEBUG: Successfully deleted from Firebase');
          return true;
        } else {
          print('DEBUG: Client has no Firestore ID - was created offline and never synced');
          // Nothing to delete from Firebase
          return true;
        }
      } catch (e) {
        print('ERROR: Failed to sync delete to cloud: $e');
        // Add to sync queue only if it had a Firestore ID
        if (firestoreId != null && firestoreId.isNotEmpty) {
          await DatabaseService.instance.addToSyncQueue(
            entityType: 'client',
            entityId: localId,
            operation: 'delete',
            data: {'id': firestoreId}, // ← Use Firestore ID, not local ID!
          );
        }
      }
    } else {
      print('DEBUG: Offline - adding delete to sync queue');
      // Offline - add to sync queue
      if (firestoreId != null && firestoreId.isNotEmpty) {
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'client',
          entityId: localId,
          operation: 'delete',
          data: {'id': firestoreId}, // ← Use Firestore ID, not local ID!
        );
      }
    }

    return true;
  }

  // FORM OPERATIONS

  // Create form
  Future<String> createForm(ISCIRForm form, int localClientId) async {
    print('DEBUG: createForm in SyncService - LOCAL client ID: $localClientId');

    // IMPORTANT: Create form with LOCAL client ID (as string)
    // This ensures offline forms have the correct reference
    final formForLocal = form.copyWith(clientId: localClientId.toString());

    // Save to local database first
    final localFormId = await DatabaseService.instance.createForm(formForLocal);
    print('DEBUG: Created form in local DB with ID: $localFormId');

    if (await isOnline()) {
      try {
        // Get client's Firestore ID
        final db = await DatabaseService.instance.database;
        final result = await db.query(
          'clients',
          columns: ['firestore_id'],
          where: 'id = ?',
          whereArgs: [localClientId],
        );

        String? clientFirestoreId;
        if (result.isNotEmpty) {
          clientFirestoreId = result.first['firestore_id'] as String?;
        }

        if (clientFirestoreId != null && clientFirestoreId.isNotEmpty) {
          print('DEBUG: Client has Firestore ID: $clientFirestoreId');

          // Create form in Firestore with CLIENT'S Firestore ID
          final formForFirebase = formForLocal.copyWith(clientId: clientFirestoreId);
          final firestoreFormId = await FirestoreService.instance.createForm(formForFirebase);

          print('DEBUG: Created form in Firebase with ID: $firestoreFormId');

          // Update local record with Firestore ID
          await DatabaseService.instance.updateFormFirestoreId(localFormId, firestoreFormId);
          print('DEBUG: Linked local form $localFormId to Firestore ID $firestoreFormId');
        } else {
          print('DEBUG: Client has no Firestore ID yet - client was created offline');
          // Client doesn't have Firestore ID yet, add to sync queue
          await DatabaseService.instance.addToSyncQueue(
            entityType: 'form',
            entityId: localFormId,
            operation: 'create',
            data: formForLocal.toMap(),
          );
        }
      } catch (e) {
        print('ERROR: Failed to sync form to cloud: $e');
        // Add to sync queue
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'form',
          entityId: localFormId,
          operation: 'create',
          data: formForLocal.toMap(),
        );
      }
    } else {
      print('DEBUG: Offline - adding form to sync queue');
      // Offline - add to sync queue
      await DatabaseService.instance.addToSyncQueue(
        entityType: 'form',
        entityId: localFormId,
        operation: 'create',
        data: formForLocal.toMap(),
      );
    }

    // ALWAYS return local ID (integer as string)
    return localFormId.toString();
  }

  // Update form
  Future<bool> updateForm(ISCIRForm form) async {
    print('DEBUG: updateForm called for form ID: ${form.id}');

    final localId = int.tryParse(form.id!);
    if (localId == null) {
      print('ERROR: Invalid local ID: ${form.id}');
      return false;
    }

    // Update local first
    await DatabaseService.instance.updateForm(form);
    print('DEBUG: Updated local form with local ID: $localId');

    if (await isOnline()) {
      try {
        // Get the form's Firestore ID
        final db = await DatabaseService.instance.database;
        final result = await db.query(
          'forms',
          columns: ['firestore_id'],
          where: 'id = ?',
          whereArgs: [localId],
        );

        if (result.isEmpty) {
          print('ERROR: Form not found in local database');
          return false;
        }

        final firestoreId = result.first['firestore_id'] as String?;

        if (firestoreId == null || firestoreId.isEmpty) {
          print('DEBUG: Form has no Firestore ID yet - adding to sync queue');
          await DatabaseService.instance.addToSyncQueue(
            entityType: 'form',
            entityId: localId,
            operation: 'update',
            data: form.toMap(),
          );
          return true;
        }

        print('DEBUG: Found Firestore ID: $firestoreId');

        // Update in Firestore
        final formForFirebase = form.copyWith(id: firestoreId);
        await FirestoreService.instance.updateForm(formForFirebase);

        print('DEBUG: Successfully updated form in Firebase');
        return true;
      } catch (e) {
        print('ERROR: Failed to sync form update to cloud: $e');
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'form',
          entityId: localId,
          operation: 'update',
          data: form.toMap(),
        );
      }
    }

    return true;
  }

  // Delete form
  Future<bool> deleteForm(int formId) async {
    print('DEBUG: deleteForm called for form ID: $formId');

    // Get Firestore ID before deleting
    String? firestoreId;
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query(
        'forms',
        columns: ['firestore_id'],
        where: 'id = ?',
        whereArgs: [formId],
      );

      if (result.isNotEmpty) {
        firestoreId = result.first['firestore_id'] as String?;
        print('DEBUG: Found Firestore ID before delete: $firestoreId');
      }
    } catch (e) {
      print('ERROR: Failed to get Firestore ID: $e');
    }

    // Delete from local database
    await DatabaseService.instance.deleteForm(formId);
    print('DEBUG: Deleted form from local database');

    if (await isOnline() && firestoreId != null && firestoreId.isNotEmpty) {
      try {
        print('DEBUG: Deleting from Firestore with ID: $firestoreId');
        await FirestoreService.instance.deleteForm(firestoreId);
        print('DEBUG: Successfully deleted from Firebase');
        return true;
      } catch (e) {
        print('ERROR: Failed to sync delete to cloud: $e');
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'form',
          entityId: formId,
          operation: 'delete',
          data: {'id': firestoreId},
        );
      }
    } else if (firestoreId != null && firestoreId.isNotEmpty) {
      print('DEBUG: Offline - adding form delete to sync queue');
      await DatabaseService.instance.addToSyncQueue(
        entityType: 'form',
        entityId: formId,
        operation: 'delete',
        data: {'id': firestoreId},
      );
    } else {
      print('DEBUG: Form has no Firestore ID - was never synced to cloud');
    }

    return true;
  }

  // Load forms for a client
  Future<List<ISCIRForm>> loadFormsByClient(int clientId) async {
    // Return local data
    return await DatabaseService.instance.getFormsByClientId(clientId);
  }

  // Save form data
  Future<bool> saveFormData(int formId, Map<String, dynamic> formData) async {
    print('DEBUG: saveFormData called for local form ID: $formId');

    // Save to local database first
    await DatabaseService.instance.saveFormData(formId, formData);
    print('DEBUG: Saved form data to local database');

    if (await isOnline()) {
      try {
        // Get the form's Firestore ID from the database
        final db = await DatabaseService.instance.database;
        final result = await db.query(
          'forms',
          columns: ['firestore_id'],
          where: 'id = ?',
          whereArgs: [formId],
        );

        if (result.isEmpty) {
          print('ERROR: Form not found in local database');
          return false;
        }

        final firestoreId = result.first['firestore_id'] as String?;

        if (firestoreId == null || firestoreId.isEmpty) {
          print('DEBUG: Form has no Firestore ID yet - adding to sync queue');
          // Form was created offline, add to sync queue
          await DatabaseService.instance.addToSyncQueue(
            entityType: 'form_data',
            entityId: formId,
            operation: 'update',
            data: formData,
          );
          return true;
        }

        print('DEBUG: Found Firestore ID: $firestoreId, syncing data to Firebase');

        // Save to Firestore using the Firestore ID
        await FirestoreService.instance.saveFormData(firestoreId, formData);
        print('DEBUG: Successfully saved form data to Firebase');

        return true;
      } catch (e) {
        print('ERROR: Failed to sync form data to cloud: $e');
        // Add to sync queue
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'form_data',
          entityId: formId,
          operation: 'update',
          data: formData,
        );
      }
    } else {
      print('DEBUG: Offline - adding form data to sync queue');
      // Offline - add to sync queue
      await DatabaseService.instance.addToSyncQueue(
        entityType: 'form_data',
        entityId: formId,
        operation: 'update',
        data: formData,
      );
    }

    return true;
  }

  // SYNC OPERATIONS

  // Sync local changes to cloud
  Future<void> syncToCloud() async {
    if (_isSyncing || !await isOnline()) return;

    _isSyncing = true;
    print('Starting sync to cloud...');

    try {
      final unsyncedItems = await DatabaseService.instance.getUnsyncedItems();
      print('Found ${unsyncedItems.length} items to sync');

      for (var item in unsyncedItems) {
        try {
          await _syncItem(item);
          await DatabaseService.instance.markAsSynced(
            item['id'] as int,
            item['firestore_id'] as String?,
          );
        } catch (e) {
          print('Failed to sync item ${item['id']}: $e');
          // Continue with next item
        }
      }

      // Clean up old synced items
      await DatabaseService.instance.clearSyncedItems();
      print('Sync completed');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncItem(Map<String, dynamic> item) async {
    final entityType = item['entity_type'] as String;
    final operation = item['operation'] as String;
    final dataString = item['data'] as String;
    final data = json.decode(dataString) as Map<String, dynamic>;

    switch (entityType) {
      case 'client':
        if (operation == 'create') {
          final client = Client.fromMap(data);
          await FirestoreService.instance.createClient(client);
        } else if (operation == 'update') {
          final client = Client.fromMap(data);
          await FirestoreService.instance.updateClient(client);
        } else if (operation == 'delete') {
          final id = data['id'] as String;
          await FirestoreService.instance.deleteClient(id);
        }
        break;

      case 'form':
        if (operation == 'create') {
          // Get the local form ID
          final localFormId = item['entity_id'] as int;

          // Get the form from local database
          final localForm = await DatabaseService.instance.getForm(localFormId);
          if (localForm == null) {
            print('ERROR: Form not found in local database');
            return;
          }

          // Get client's Firestore ID
          final localClientId = int.tryParse(localForm.clientId);
          if (localClientId == null) {
            print('ERROR: Invalid client ID in form');
            return;
          }

          final db = await DatabaseService.instance.database;
          final clientResult = await db.query(
            'clients',
            columns: ['firestore_id'],
            where: 'id = ?',
            whereArgs: [localClientId],
          );

          if (clientResult.isEmpty) {
            print('ERROR: Client not found');
            return;
          }

          final clientFirestoreId = clientResult.first['firestore_id'] as String?;
          if (clientFirestoreId == null || clientFirestoreId.isEmpty) {
            print('ERROR: Client has no Firestore ID yet');
            return;
          }

          // Create form in Firebase with client's Firestore ID
          final formForFirebase = localForm.copyWith(clientId: clientFirestoreId);
          final firestoreFormId = await FirestoreService.instance.createForm(formForFirebase);

          // Update local form with Firestore ID
          await DatabaseService.instance.updateFormFirestoreId(localFormId, firestoreFormId);

          print('DEBUG: Synced form from queue - Firestore ID: $firestoreFormId');

        } else if (operation == 'delete') {
          final id = data['id'] as String;
          await FirestoreService.instance.deleteForm(id);
        }
        break;

      case 'form_data':
        final formId = item['entity_id'] as int;

        // Get form's Firestore ID
        final db = await DatabaseService.instance.database;
        final result = await db.query(
          'forms',
          columns: ['firestore_id'],
          where: 'id = ?',
          whereArgs: [formId],
        );

        if (result.isEmpty) {
          print('ERROR: Form not found');
          return;
        }

        final firestoreId = result.first['firestore_id'] as String?;
        if (firestoreId == null || firestoreId.isEmpty) {
          print('ERROR: Form has no Firestore ID yet');
          return;
        }

        if (operation == 'update') {
          await FirestoreService.instance.saveFormData(firestoreId, data);
        }
        break;
    }
  }

  // Sync data from cloud to local (download)
  Future<bool> syncFromCloud() async {
    if (!await isOnline()) return false;

    print('Starting two-way sync from cloud...');

    try {
      // ============================================
      // SYNC CLIENTS
      // ============================================
      final cloudClients = await FirestoreService.instance.getAllClients();
      print('DEBUG: Got ${cloudClients.length} clients from Firestore');

      final localClients = await DatabaseService.instance.getAllClients();
      print('DEBUG: Got ${localClients.length} local clients');

      final cloudFirestoreIds = cloudClients.map((c) => c.id!).toSet();

      final localByFirestoreId = <String, Client>{};
      for (var local in localClients) {
        final firestoreId = await _getClientFirestoreId(local);
        if (firestoreId != null) {
          localByFirestoreId[firestoreId] = local;
        }
      }

      bool hasChanges = false;

      // Add/update clients from cloud
      for (var cloudClient in cloudClients) {
        print('DEBUG: Processing cloud client: ${cloudClient.firstName} ${cloudClient.lastName}');

        if (localByFirestoreId.containsKey(cloudClient.id!)) {
          print('DEBUG: Client already exists locally - skipping');
          continue;
        }

        bool foundMatch = false;
        for (var existing in localClients) {
          final existingFirestoreId = await _getClientFirestoreId(existing);
          if (existingFirestoreId != null) continue;

          if (_areClientsSame(existing, cloudClient)) {
            print('DEBUG: Found matching offline client - linking to Firestore');
            final localId = int.tryParse(existing.id!);
            if (localId != null) {
              await DatabaseService.instance.updateClientFirestoreId(localId, cloudClient.id!);
              hasChanges = true;
              foundMatch = true;
              break;
            }
          }
        }

        if (!foundMatch) {
          print('DEBUG: Creating new local client from cloud');
          await DatabaseService.instance.createClient(cloudClient, firestoreId: cloudClient.id);
          hasChanges = true;
        }
      }

      // Delete local clients that don't exist in Firebase
      for (var localClient in localClients) {
        final firestoreId = await _getClientFirestoreId(localClient);

        print('DEBUG: Checking local client: ${localClient.firstName} ${localClient.lastName}, Firestore ID: $firestoreId');

        if (firestoreId != null && !cloudFirestoreIds.contains(firestoreId)) {
          print('DEBUG: Deleting local client removed from Firebase');
          final localId = int.tryParse(localClient.id!);
          if (localId != null) {
            await DatabaseService.instance.deleteClient(localId);
            hasChanges = true;
          }
        } else if (firestoreId == null) {
          bool existsInCloud = false;
          for (var cloudClient in cloudClients) {
            if (_areClientsSame(localClient, cloudClient)) {
              existsInCloud = true;
              print('DEBUG: Found cloud match for offline client - deleting duplicate');
              final localId = int.tryParse(localClient.id!);
              if (localId != null) {
                await DatabaseService.instance.deleteClient(localId);
                hasChanges = true;
              }
              break;
            }
          }

          if (!existsInCloud) {
            print('DEBUG: WARNING - Found orphaned offline client: ${localClient.firstName} ${localClient.lastName}');
            print('DEBUG: Deleting orphaned client');
            final localId = int.tryParse(localClient.id!);
            if (localId != null) {
              await DatabaseService.instance.deleteClient(localId);
              hasChanges = true;
            }
          }
        }
      }

      // ============================================
      // SYNC FORMS (NEW!)
      // ============================================
      print('DEBUG: Starting forms sync...');

      // Get all forms from Firebase
      final cloudForms = await FirestoreService.instance.getAllForms();
      print('DEBUG: Got ${cloudForms.length} forms from Firestore');

      // Get all local forms
      final db = await DatabaseService.instance.database;
      final localFormMaps = await db.query('forms');
      print('DEBUG: Got ${localFormMaps.length} local forms');

      // Map local forms by Firestore ID
      final localFormsByFirestoreId = <String, Map<String, dynamic>>{};
      for (var formMap in localFormMaps) {
        final firestoreId = formMap['firestore_id'] as String?;
        if (firestoreId != null && firestoreId.isNotEmpty) {
          localFormsByFirestoreId[firestoreId] = formMap;
        }
      }

      final cloudFormFirestoreIds = cloudForms.map((f) => f.id!).toSet();

      // Add/update forms from cloud
      for (var cloudForm in cloudForms) {
        print('DEBUG: Processing cloud form: ${cloudForm.reportNumber}');

        if (localFormsByFirestoreId.containsKey(cloudForm.id!)) {
          print('DEBUG: Form already exists locally - updating data');

          // Update the form data from cloud
          final localFormId = localFormsByFirestoreId[cloudForm.id!]!['id'] as int;

          // Update form metadata if needed
          await db.update(
            'forms',
            {
              'report_number': cloudForm.reportNumber,
              'updated_at': cloudForm.updatedAt.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [localFormId],
          );

          // Update form data from cloud
          if (cloudForm.formData.isNotEmpty) {
            print('DEBUG: Updating form data from cloud');
            await DatabaseService.instance.saveFormData(localFormId, cloudForm.formData);
            hasChanges = true;
          }

          continue;
        }

        // Need to create this form locally
        // First, find the local client ID
        final cloudClientFirestoreId = cloudForm.clientId;
        final localClientResult = await db.query(
          'clients',
          columns: ['id'],
          where: 'firestore_id = ?',
          whereArgs: [cloudClientFirestoreId],
        );

        if (localClientResult.isEmpty) {
          print('DEBUG: WARNING - Form references client that doesn\'t exist locally: $cloudClientFirestoreId');
          continue;
        }

        final localClientId = localClientResult.first['id'] as int;

        // Create form locally with local client ID
        final formForLocal = cloudForm.copyWith(clientId: localClientId.toString());
        final localFormId = await DatabaseService.instance.createForm(
          formForLocal,
          firestoreId: cloudForm.id,
        );

        // Save form data
        if (cloudForm.formData.isNotEmpty) {
          print('DEBUG: Creating form with data from cloud');
          await DatabaseService.instance.saveFormData(localFormId, cloudForm.formData);
        }

        print('DEBUG: Created new local form from cloud with ID: $localFormId');
        hasChanges = true;
      }

      // Delete local forms that don't exist in Firebase
      for (var localFormMap in localFormMaps) {
        final firestoreId = localFormMap['firestore_id'] as String?;

        if (firestoreId != null && !cloudFormFirestoreIds.contains(firestoreId)) {
          print('DEBUG: Deleting local form removed from Firebase');
          final localId = localFormMap['id'] as int;
          await DatabaseService.instance.deleteForm(localId);
          hasChanges = true;
        }
      }

      print('Two-way sync completed. Changes made: $hasChanges');
      return hasChanges;
    } catch (e) {
      print('Failed to sync from cloud: $e');
      return false;
    }
  }

  // Check if two clients are the same person
  bool _areClientsSame(Client client1, Client client2) {
    // Compare multiple fields to be sure
    return client1.firstName.trim().toLowerCase() ==
        client2.firstName.trim().toLowerCase() &&
        client1.lastName.trim().toLowerCase() ==
            client2.lastName.trim().toLowerCase() &&
        client1.email.trim().toLowerCase() ==
            client2.email.trim().toLowerCase() &&
        client1.phone.trim() == client2.phone.trim();
  }

  // Get Firestore ID for a client
  Future<String?> _getClientFirestoreId(Client client) async {
    try {
      final localId = int.tryParse(client.id!);
      if (localId == null) return null;

      final db = await DatabaseService.instance.database;
      final result = await db.query(
          'clients',
          columns: ['firestore_id'],
          where: 'id = ?',
          whereArgs: [localId]
      );

      if (result.isEmpty) return null;
      return result.first['firestore_id'] as String?;
    } catch (e) {
      print('Error getting Firestore ID: $e');
      return null;
    }
  }
}