import 'package:flutter/foundation.dart';
import '../models/form.dart';
import '../services/database_service.dart';

class FormProvider with ChangeNotifier {
  List<ISCIRForm> _forms = [];
  bool _isLoading = false;
  String? _error;

  List<ISCIRForm> get forms => _forms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load forms for a specific client
  Future<void> loadFormsByClient(int clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _forms = await DatabaseService.instance.getFormsByClient(clientId);
    } catch (e) {
      _error = 'Failed to load forms: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new form
  Future<bool> createForm({
    required int clientId,
    required FormType formType,
    required String reportNumber,
    required DateTime reportDate,
  }) async {
    try {
      final now = DateTime.now();
      final autoReportNumber = await _generateAutoReportNumber();

      final form = ISCIRForm(
        clientId: clientId,
        formType: formType,
        reportNumber: autoReportNumber,
        reportDate: reportDate,
        createdAt: now,
        updatedAt: now,
      );

      final id = await DatabaseService.instance.createForm(form);
      final newForm = form.copyWith(id: id);
      final autoData = {
        'report_no': autoReportNumber,
        'today_date': '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
      };
      await DatabaseService.instance.saveFormData(id, autoData);

      _forms.insert(0, newForm.copyWith(formData: autoData));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create form: $e';
      notifyListeners();
      return false;
    }
  }

  Future<String> _generateAutoReportNumber() async {
    const int STARTING_REPORT_NUMBER = 23;

    final totalCount = await DatabaseService.instance.getTotalFormsCount();
    final nextNumber = totalCount + STARTING_REPORT_NUMBER;
    return nextNumber.toString();
  }

  // Save form field data
  Future<bool> saveFormField(int formId, String fieldName, String? value) async {
    try {
      await DatabaseService.instance.saveFormField(formId, fieldName, value);

      // Update the form in memory
      final formIndex = _forms.indexWhere((f) => f.id == formId);
      if (formIndex != -1) {
        final updatedFormData = Map<String, dynamic>.from(_forms[formIndex].formData);
        updatedFormData[fieldName] = value;
        _forms[formIndex] = _forms[formIndex].copyWith(
          formData: updatedFormData,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Failed to save form field: $e';
      notifyListeners();
      return false;
    }
  }

  // Save multiple form fields at once
  Future<bool> saveFormData(int formId, Map<String, dynamic> newFormData) async {
    try {
      // Get existing form data first
      final existingData = await DatabaseService.instance.getFormData(formId);

      // Merge new data with existing data
      final mergedData = Map<String, dynamic>.from(existingData);
      mergedData.addAll(newFormData); // This adds/updates only the new fields

      // Save the merged data
      await DatabaseService.instance.saveFormData(formId, mergedData);

      // Update the form in memory
      final formIndex = _forms.indexWhere((f) => f.id == formId);
      if (formIndex != -1) {
        _forms[formIndex] = _forms[formIndex].copyWith(
          formData: mergedData, // Use merged data
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
  Future<bool> deleteForm(int formId) async {
    try {
      await DatabaseService.instance.deleteForm(formId);
      _forms.removeWhere((form) => form.id == formId);

      // Recalculate all report numbers after deletion
      await _recalculateReportNumbers();

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete form: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _recalculateReportNumbers() async {
    try {
      // Get all forms ordered by creation date
      final allForms = await DatabaseService.instance.getAllFormsOrderedByCreation();

      final currentYear = DateTime.now().year;

      // Update each form with new sequential number
      for (int i = 0; i < allForms.length; i++) {
        final form = allForms[i];
        final newReportNumber = '${(i + 1).toString().padLeft(3, '0')}/$currentYear';

        // Update report number in forms table
        await DatabaseService.instance.updateFormReportNumber(form.id!, newReportNumber);

        // Update report_no in form_data table
        await DatabaseService.instance.saveFormField(form.id!, 'report_no', newReportNumber);
      }

      print('Recalculated report numbers for ${allForms.length} forms');

    } catch (e) {
      print('Error recalculating report numbers: $e');
    }
  }

  // Get specific form by ID
  ISCIRForm? getFormById(int formId) {
    try {
      return _forms.firstWhere((form) => form.id == formId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}