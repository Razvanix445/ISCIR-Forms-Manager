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

  void initialize() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
          if (result.contains(ConnectivityResult.mobile) ||
              result.contains(ConnectivityResult.wifi)) {
            syncToCloud();
          }
        });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);
  }

  /// CLIENT OPERATIONS

  Future<String> createClient(Client client) async {
    final localId = await DatabaseService.instance.createClient(client);

    if (await isOnline()) {
      try {
        final firestoreId = await FirestoreService.instance.createClient(
            client);

        await DatabaseService.instance.updateClientFirestoreId(
            localId, firestoreId);

        return firestoreId;
      } catch (e) {
        print('Failed to sync client to cloud: $e');
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'client',
          entityId: localId,
          operation: 'create',
          data: client.toMap(),
        );
        return localId.toString();
      }
    } else {
      await DatabaseService.instance.addToSyncQueue(
        entityType: 'client',
        entityId: localId,
        operation: 'create',
        data: client.toMap(),
      );
      return localId.toString();
    }
  }

  Future<List<Client>> loadClients() async {
    final localClients = await DatabaseService.instance.getAllClients();

    if (await isOnline()) {
      final hasChanges = await syncFromCloud();

      if (hasChanges) {
        return await DatabaseService.instance.getAllClients();
      }
    }

    return localClients;
  }

  Future<List<Client>> getRecentClients({int limit = 15}) async {
    // First try to get recent clients from local database (fast)
    final localRecent = await DatabaseService.instance.getRecentClients(limit: limit);

    // If we have enough local clients, return them immediately
    if (localRecent.length >= limit) {
      return localRecent;
    }

    // Only sync with cloud if we need more clients and we're online
    if (await isOnline()) {
      try {
        // Get recent clients from Firestore
        final cloudRecent = await FirestoreService.instance.getRecentClients(limit: limit);

        // Sync them to local database
        for (var client in cloudRecent) {
          await DatabaseService.instance.createClient(
            client,
            firestoreId: client.id,
          );
        }

        // Return fresh local results
        return await DatabaseService.instance.getRecentClients(limit: limit);
      } catch (e) {
        print('Failed to sync recent clients: $e');
        // Return whatever we have locally
        return localRecent;
      }
    }

    return localRecent;
  }

  Future<List<Client>> searchClients(String query) async {
    // Always search locally first for immediate results
    final localResults = await DatabaseService.instance.searchClients(query);

    if (await isOnline()) {
      try {
        // Search all clients from Firestore (this searches the entire cloud database)
        final cloudResults = await FirestoreService.instance.searchClients(query);

        // Get existing local Firestore IDs to avoid duplicates
        final db = await DatabaseService.instance.database;
        final existingFirestoreIds = await db.query(
          'clients',
          columns: ['firestore_id'],
          where: 'firestore_id IS NOT NULL AND firestore_id != ""',
        );

        final localFirestoreIdSet = existingFirestoreIds
            .map((row) => row['firestore_id'] as String)
            .toSet();

        // Add cloud clients that aren't already stored locally
        for (var cloudClient in cloudResults) {
          if (!localFirestoreIdSet.contains(cloudClient.id)) {
            await DatabaseService.instance.createClient(
              cloudClient,
              firestoreId: cloudClient.id,
            );
          }
        }

        // Return fresh search results from local DB (now includes newly added cloud clients)
        return await DatabaseService.instance.searchClients(query);
      } catch (e) {
        print('Failed to search cloud clients: $e');
        // Return local results if cloud search fails
        return localResults;
      }
    }

    return localResults;
  }

  Future<bool> updateClient(Client client) async {
    print('DEBUG: updateClient called for client ID: ${client.id}');

    final localId = int.tryParse(client.id!);
    if (localId == null) {
      print('ERROR: Invalid local ID: ${client.id}');
      return false;
    }

    await DatabaseService.instance.updateClient(client);
    print('DEBUG: Updated local client with local ID: $localId');

    if (await isOnline()) {
      try {
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
          await DatabaseService.instance.addToSyncQueue(
            entityType: 'client',
            entityId: localId,
            operation: 'update',
            data: client.toMap(),
          );
          return true;
        }

        print('DEBUG: Found Firestore ID: $firestoreId');

        final clientForFirebase = client.copyWith(id: firestoreId);
        await FirestoreService.instance.updateClient(clientForFirebase);

        print('DEBUG: Successfully updated client in Firebase');
        return true;
      } catch (e) {
        print('ERROR: Failed to sync update to cloud: $e');
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'client',
          entityId: localId,
          operation: 'update',
          data: client.toMap(),
        );
      }
    } else {
      print('DEBUG: Offline - adding update to sync queue');
      await DatabaseService.instance.addToSyncQueue(
        entityType: 'client',
        entityId: localId,
        operation: 'update',
        data: client.toMap(),
      );
    }

    return true;
  }

  Future<bool> deleteClient(String clientId) async {
    print('DEBUG: deleteClient called for client ID: $clientId');

    final localId = int.tryParse(clientId);
    if (localId == null) {
      print('ERROR: Invalid local ID: $clientId');
      return false;
    }

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

    await DatabaseService.instance.deleteClient(localId);
    print('DEBUG: Deleted client from local database');

    if (await isOnline()) {
      try {
        if (firestoreId != null && firestoreId.isNotEmpty) {
          print('DEBUG: Deleting from Firestore with ID: $firestoreId');
          await FirestoreService.instance.deleteClient(firestoreId);
          print('DEBUG: Successfully deleted from Firebase');
          return true;
        } else {
          print('DEBUG: Client has no Firestore ID - was created offline and never synced');
          return true;
        }
      } catch (e) {
        print('ERROR: Failed to sync delete to cloud: $e');
        if (firestoreId != null && firestoreId.isNotEmpty) {
          await DatabaseService.instance.addToSyncQueue(
            entityType: 'client',
            entityId: localId,
            operation: 'delete',
            data: {'id': firestoreId},
          );
        }
      }
    } else {
      print('DEBUG: Offline - adding delete to sync queue');
      if (firestoreId != null && firestoreId.isNotEmpty) {
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'client',
          entityId: localId,
          operation: 'delete',
          data: {'id': firestoreId},
        );
      }
    }

    return true;
  }

  /// FORM OPERATIONS

  Future<String> createForm(ISCIRForm form, int localClientId) async {
    print('DEBUG: createForm in SyncService - LOCAL client ID: $localClientId');

    final formForLocal = form.copyWith(clientId: localClientId.toString());

    final localFormId = await DatabaseService.instance.createForm(formForLocal);
    print('DEBUG: Created form in local DB with ID: $localFormId');

    if (await isOnline()) {
      try {
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

          final formForFirebase = formForLocal.copyWith(clientId: clientFirestoreId);
          final firestoreFormId = await FirestoreService.instance.createForm(formForFirebase);

          print('DEBUG: Created form in Firebase with ID: $firestoreFormId');

          await DatabaseService.instance.updateFormFirestoreId(localFormId, firestoreFormId);
          print('DEBUG: Linked local form $localFormId to Firestore ID $firestoreFormId');
        } else {
          print('DEBUG: Client has no Firestore ID yet - client was created offline');
          await DatabaseService.instance.addToSyncQueue(
            entityType: 'form',
            entityId: localFormId,
            operation: 'create',
            data: formForLocal.toMap(),
          );
        }
      } catch (e) {
        print('ERROR: Failed to sync form to cloud: $e');
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'form',
          entityId: localFormId,
          operation: 'create',
          data: formForLocal.toMap(),
        );
      }
    } else {
      print('DEBUG: Offline - adding form to sync queue');
      await DatabaseService.instance.addToSyncQueue(
        entityType: 'form',
        entityId: localFormId,
        operation: 'create',
        data: formForLocal.toMap(),
      );
    }

    return localFormId.toString();
  }

  Future<bool> updateForm(ISCIRForm form) async {
    print('DEBUG: updateForm called for form ID: ${form.id}');

    final localId = int.tryParse(form.id!);
    if (localId == null) {
      print('ERROR: Invalid local ID: ${form.id}');
      return false;
    }

    await DatabaseService.instance.updateForm(form);
    print('DEBUG: Updated local form with local ID: $localId');

    if (await isOnline()) {
      try {
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

        final localClientId = int.tryParse(form.clientId);
        String? clientFirestoreId = form.clientId;

        if (localClientId != null) {
          final clientResult = await db.query(
            'clients',
            columns: ['firestore_id'],
            where: 'id = ?',
            whereArgs: [localClientId],
          );

          if (clientResult.isNotEmpty) {
            clientFirestoreId = clientResult.first['firestore_id'] as String?;
            print('DEBUG: Converted clientId $localClientId to Firestore ID: $clientFirestoreId');
          }
        }

        final formForFirebase = form.copyWith(
          id: firestoreId,
          clientId: clientFirestoreId ?? form.clientId,
        );
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

  Future<bool> deleteForm(int formId) async {
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
      }
    } catch (e) {
      print('ERROR: Failed to get Firestore ID: $e');
    }

    await DatabaseService.instance.deleteForm(formId);

    if (await isOnline() && firestoreId != null && firestoreId.isNotEmpty) {
      try {
        await FirestoreService.instance.deleteForm(firestoreId);
        return true;
      } catch (e) {
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'form',
          entityId: formId,
          operation: 'delete',
          data: {'id': firestoreId},
        );
      }
    } else if (firestoreId != null && firestoreId.isNotEmpty) {
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

  Future<List<ISCIRForm>> loadFormsByClient(int clientId) async {
    return await DatabaseService.instance.getFormsByClientId(clientId);
  }

  Future<bool> saveFormData(int formId, Map<String, dynamic> formData) async {
    await DatabaseService.instance.saveFormData(formId, formData);

    if (await isOnline()) {
      try {
        final db = await DatabaseService.instance.database;
        final result = await db.query(
          'forms',
          columns: ['firestore_id'],
          where: 'id = ?',
          whereArgs: [formId],
        );

        if (result.isEmpty) {
          return false;
        }

        final firestoreId = result.first['firestore_id'] as String?;

        if (firestoreId == null || firestoreId.isEmpty) {
          await DatabaseService.instance.addToSyncQueue(
            entityType: 'form_data',
            entityId: formId,
            operation: 'update',
            data: formData,
          );
          return true;
        }

        await FirestoreService.instance.saveFormData(firestoreId, formData);

        return true;
      } catch (e) {
        await DatabaseService.instance.addToSyncQueue(
          entityType: 'form_data',
          entityId: formId,
          operation: 'update',
          data: formData,
        );
      }
    } else {
      await DatabaseService.instance.addToSyncQueue(
        entityType: 'form_data',
        entityId: formId,
        operation: 'update',
        data: formData,
      );
    }

    return true;
  }

  /// SYNC OPERATIONS

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
        }
      }

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
          final localFormId = item['entity_id'] as int;
          print('DEBUG SYNC: Syncing form creation for local form ID: $localFormId');

          final localForm = await DatabaseService.instance.getForm(localFormId);
          if (localForm == null) {
            print('DEBUG SYNC: ❌ Form not found in local DB');
            return;
          }

          final localClientId = int.tryParse(localForm.clientId);
          if (localClientId == null) {
            print('DEBUG SYNC: ❌ Invalid clientId: ${localForm.clientId}');
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
            print('DEBUG SYNC: ❌ Client $localClientId not found in local DB');
            return;
          }

          final clientFirestoreId = clientResult.first['firestore_id'] as String?;
          if (clientFirestoreId == null || clientFirestoreId.isEmpty) {
            print('DEBUG SYNC: ❌ Client $localClientId has no Firestore ID yet - client needs to sync first');
            throw Exception('Client not synced yet - will retry later');
          }

          print('DEBUG SYNC: ✅ Client Firestore ID: $clientFirestoreId');
          final formForFirebase = localForm.copyWith(clientId: clientFirestoreId);
          final firestoreFormId = await FirestoreService.instance.createForm(formForFirebase);
          print('DEBUG SYNC: ✅ Form created in Firebase with ID: $firestoreFormId');

          await DatabaseService.instance.updateFormFirestoreId(localFormId, firestoreFormId);

        } else if (operation == 'delete') {
          final id = data['id'] as String;
          await FirestoreService.instance.deleteForm(id);
        }
        break;

      case 'form_data':
        final formId = item['entity_id'] as int;

        final db = await DatabaseService.instance.database;
        final result = await db.query(
          'forms',
          columns: ['firestore_id'],
          where: 'id = ?',
          whereArgs: [formId],
        );

        if (result.isEmpty) {
          return;
        }

        final firestoreId = result.first['firestore_id'] as String?;
        if (firestoreId == null || firestoreId.isEmpty) {
          return;
        }

        if (operation == 'update') {
          await FirestoreService.instance.saveFormData(firestoreId, data);
        }
        break;
    }
  }

  Future<bool> syncFromCloud() async {
    if (!await isOnline()) return false;

    print('Starting two-way sync from cloud...');

    try {
      /// ============================================
      /// SYNC CLIENTS
      /// ============================================
      final cloudClients = await FirestoreService.instance.getAllClients();

      final localClients = await DatabaseService.instance.getAllClients();

      final cloudFirestoreIds = cloudClients.map((c) => c.id!).toSet();

      final localByFirestoreId = <String, Client>{};
      for (var local in localClients) {
        final firestoreId = await _getClientFirestoreId(local);
        if (firestoreId != null) {
          localByFirestoreId[firestoreId] = local;
        }
      }

      bool hasChanges = false;

      for (var cloudClient in cloudClients) {

        if (localByFirestoreId.containsKey(cloudClient.id!)) {
          continue;
        }

        bool foundMatch = false;
        for (var existing in localClients) {
          final existingFirestoreId = await _getClientFirestoreId(existing);
          if (existingFirestoreId != null) continue;

          if (_areClientsSame(existing, cloudClient)) {
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
          await DatabaseService.instance.createClient(cloudClient, firestoreId: cloudClient.id);
          hasChanges = true;
        }
      }

      for (var localClient in localClients) {
        final firestoreId = await _getClientFirestoreId(localClient);

        if (firestoreId != null && !cloudFirestoreIds.contains(firestoreId)) {
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
              final localId = int.tryParse(localClient.id!);
              if (localId != null) {
                await DatabaseService.instance.deleteClient(localId);
                hasChanges = true;
              }
              break;
            }
          }

          if (!existsInCloud) {
            final localId = int.tryParse(localClient.id!);
            if (localId != null) {
              await DatabaseService.instance.deleteClient(localId);
              hasChanges = true;
            }
          }
        }
      }

      /// ============================================
      /// SYNC FORMS
      /// ============================================
      final cloudForms = await FirestoreService.instance.getAllForms();

      final db = await DatabaseService.instance.database;
      final localFormMaps = await db.query('forms');

      final localFormsByFirestoreId = <String, Map<String, dynamic>>{};
      for (var formMap in localFormMaps) {
        final firestoreId = formMap['firestore_id'] as String?;
        if (firestoreId != null && firestoreId.isNotEmpty) {
          localFormsByFirestoreId[firestoreId] = formMap;
        }
      }

      final cloudFormFirestoreIds = cloudForms.map((f) => f.id!).toSet();

      for (var cloudForm in cloudForms) {

        if (localFormsByFirestoreId.containsKey(cloudForm.id!)) {

          final localFormId = localFormsByFirestoreId[cloudForm.id!]!['id'] as int;

          await db.update(
            'forms',
            {
              'report_number': cloudForm.reportNumber,
              'updated_at': cloudForm.updatedAt.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [localFormId],
          );

          if (cloudForm.formData.isNotEmpty) {
            await DatabaseService.instance.saveFormData(localFormId, cloudForm.formData);
            hasChanges = true;
          }

          continue;
        }

        final cloudClientFirestoreId = cloudForm.clientId;
        final localClientResult = await db.query(
          'clients',
          columns: ['id'],
          where: 'firestore_id = ?',
          whereArgs: [cloudClientFirestoreId],
        );

        if (localClientResult.isEmpty) {
          continue;
        }

        final localClientId = localClientResult.first['id'] as int;

        final formForLocal = cloudForm.copyWith(clientId: localClientId.toString());
        final localFormId = await DatabaseService.instance.createForm(
          formForLocal,
          firestoreId: cloudForm.id,
        );

        if (cloudForm.formData.isNotEmpty) {
          await DatabaseService.instance.saveFormData(localFormId, cloudForm.formData);
        }

        hasChanges = true;
      }

      for (var localFormMap in localFormMaps) {
        final firestoreId = localFormMap['firestore_id'] as String?;

        if (firestoreId != null && !cloudFormFirestoreIds.contains(firestoreId)) {
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

  bool _areClientsSame(Client client1, Client client2) {
    return client1.firstName.trim().toLowerCase() ==
        client2.firstName.trim().toLowerCase() &&
        client1.lastName.trim().toLowerCase() ==
            client2.lastName.trim().toLowerCase() &&
        client1.email.trim().toLowerCase() ==
            client2.email.trim().toLowerCase() &&
        client1.phone.trim() == client2.phone.trim();
  }

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