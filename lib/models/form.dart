import 'package:flutter/material.dart';

enum FormType {
  raportIscir('Anexa 3', 'Raport de verificări');

  const FormType(this.code, this.description);
  final String code;
  final String description;

  String get templatePath => 'assets/templates/raport_iscir.pdf';

  IconData get icon => Icons.assignment;
}

class ISCIRForm {
  final String? id;
  final String clientId;
  final FormType formType;
  final String reportNumber;
  final DateTime reportDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> formData;

  ISCIRForm({
    this.id,
    required this.clientId,
    this.formType = FormType.raportIscir,
    required this.reportNumber,
    required this.reportDate,
    required this.createdAt,
    required this.updatedAt,
    this.formData = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'client_id': clientId,
      'form_type': formType.code,
      'report_number': reportNumber,
      'report_date': reportDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'clientId': clientId,
      'formType': formType.code,
      'reportNumber': reportNumber,
      'reportDate': reportDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'formData': formData,
    };
  }

  factory ISCIRForm.fromMap(Map<String, dynamic> map) {
    return ISCIRForm(
      id: map['id']?.toString(),
      clientId: map['client_id']?.toString() ?? map['clientId']?.toString() ?? '',
      formType: FormType.raportIscir, // Always raportIscir now
      reportNumber: map['report_number'] ?? map['reportNumber'] ?? '',
      reportDate: DateTime.parse(map['report_date'] ?? map['reportDate']),
      createdAt: DateTime.parse(map['created_at'] ?? map['createdAt']),
      updatedAt: DateTime.parse(map['updated_at'] ?? map['updatedAt']),
      formData: map['form_data'] as Map<String, dynamic>? ??
          map['formData'] as Map<String, dynamic>? ?? {},
    );
  }

  ISCIRForm copyWith({
    String? id,
    String? clientId,
    FormType? formType,
    String? reportNumber,
    DateTime? reportDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? formData,
  }) {
    return ISCIRForm(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      formType: formType ?? this.formType,
      reportNumber: reportNumber ?? this.reportNumber,
      reportDate: reportDate ?? this.reportDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      formData: formData ?? this.formData,
    );
  }

  @override
  String toString() {
    return 'ISCIRForm{id: $id, clientId: $clientId, type: ${formType.code}, reportNumber: $reportNumber}';
  }
}