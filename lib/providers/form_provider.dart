import 'package:flutter/foundation.dart';
import '../models/form.dart';
import '../services/firestore_service.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';

class FormProvider with ChangeNotifier {
  List<ISCIRForm> _forms = [];
  bool _isLoading = false;
  String? _error;

  List<ISCIRForm> get forms => _forms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load forms for a specific client (using LOCAL client ID)
  Future<void> loadFormsByClient(String clientId) async {
    print('DEBUG: loadFormsByClient called with clientId: $clientId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Convert string ID to int (local ID)
      final localClientId = int.tryParse(clientId);

      if (localClientId == null) {
        print('ERROR: Invalid client ID: $clientId');
        _error = 'Invalid client ID';
        _forms = [];
        return;
      }

      // Load forms from LOCAL database using SyncService
      _forms = await SyncService.instance.loadFormsByClient(localClientId);
      print('DEBUG: Loaded ${_forms.length} forms for client $localClientId');
    } catch (e) {
      print('ERROR: Failed to load forms: $e');
      _error = 'Failed to load forms: $e';
      _forms = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new form
  Future<bool> createForm({
    required String clientId,
    required FormType formType,
    required String reportNumber,
    required DateTime reportDate,
  }) async {
    print('DEBUG: FormProvider.createForm called for client: $clientId');

    try {
      final localClientId = int.tryParse(clientId);
      if (localClientId == null) {
        print('ERROR: Invalid client ID: $clientId');
        _error = 'Invalid client ID';
        notifyListeners();
        return false;
      }

      final now = DateTime.now();

      // Generate auto report number
      final totalCount = await DatabaseService.instance.getTotalFormsCount();
      const int STARTING_REPORT_NUMBER = 23;
      final nextNumber = totalCount + STARTING_REPORT_NUMBER;
      final autoReportNumber = nextNumber.toString();

      print('DEBUG: Generated report number: $autoReportNumber');

      final form = ISCIRForm(
        clientId: clientId, // This is the LOCAL client ID as string
        formType: formType,
        reportNumber: autoReportNumber,
        reportDate: reportDate,
        createdAt: now,
        updatedAt: now,
      );

      // Use SyncService to create form - returns LOCAL form ID
      final localFormIdStr = await SyncService.instance.createForm(form, localClientId);
      print('DEBUG: SyncService returned form ID: $localFormIdStr');

      // Parse the local form ID
      final localFormId = int.tryParse(localFormIdStr);
      if (localFormId == null) {
        print('ERROR: Invalid form ID returned: $localFormIdStr');
        _error = 'Failed to create form';
        notifyListeners();
        return false;
      }

      // Save initial form data
      final autoData = {
        'report_no': autoReportNumber,
        'today_date': '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
      };

      print('DEBUG: Saving form data for local form ID: $localFormId');
      await SyncService.instance.saveFormData(localFormId, autoData);
      print('DEBUG: Form data saved successfully');

      // Reload forms list to show the new form
      print('DEBUG: Reloading forms for client: $clientId');
      await loadFormsByClient(clientId);
      print('DEBUG: Forms reloaded. Total forms: ${_forms.length}');

      return true;
    } catch (e) {
      print('ERROR: Failed to create form: $e');
      _error = 'Failed to create form: $e';
      notifyListeners();
      return false;
    }
  }

  // Save form field data
  Future<bool> saveFormField(String formId, String fieldName, dynamic fieldValue) async {
    try {
      final formIdInt = int.tryParse(formId);
      if (formIdInt == null) {
        _error = 'Invalid form ID';
        notifyListeners();
        return false;
      }

      // Save individual field
      await DatabaseService.instance.saveFormField(formIdInt, fieldName, fieldValue);

      // Sync if online
      final formData = await DatabaseService.instance.getFormData(formIdInt);
      await SyncService.instance.saveFormData(formIdInt, formData);

      return true;
    } catch (e) {
      _error = 'Failed to save field: $e';
      notifyListeners();
      return false;
    }
  }

  // Save multiple form fields at once
  Future<bool> saveFormData(String formId, Map<String, dynamic> formData) async {
    try {
      final formIdInt = int.tryParse(formId);
      if (formIdInt == null) {
        _error = 'Invalid form ID';
        notifyListeners();
        return false;
      }

      await SyncService.instance.saveFormData(formIdInt, formData);

      // Update local form
      final index = _forms.indexWhere((f) => f.id == formId);
      if (index != -1) {
        _forms[index] = _forms[index].copyWith(
          formData: formData,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = 'Failed to save form data: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete form
  Future<bool> deleteForm(String formId) async {
    try {
      final formIdInt = int.tryParse(formId);
      if (formIdInt == null) {
        _error = 'Invalid form ID';
        notifyListeners();
        return false;
      }

      // Use SyncService instead of FirestoreService directly
      await SyncService.instance.deleteForm(formIdInt);

      _forms.removeWhere((f) => f.id == formId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete form: $e';
      notifyListeners();
      return false;
    }
  }

  // Helper to get Firestore ID
  Future<String?> _getFormFirestoreId(int formId) async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query(
        'forms',
        columns: ['firestore_id'],
        where: 'id = ?',
        whereArgs: [formId],
      );

      if (result.isEmpty) return null;
      return result.first['firestore_id'] as String?;
    } catch (e) {
      print('Error getting form Firestore ID: $e');
      return null;
    }
  }

  // Get specific form by ID
  ISCIRForm? getFormById(String id) {
    try {
      return _forms.firstWhere((form) => form.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
