import 'package:flutter/material.dart';

enum FormType {
  // anexa3Part1('Anexa 3 Part 1', 'Raport de verificări - Partea 1'),
  // anexa3Part2('Anexa 3 Part 2', 'Raport de verificări - Partea 2'),
  raportIscir('Anexa 3', 'Raport de verificări'),
  anexa4('Anexa 4', 'Registrul de evidență a aparatelor');

  const FormType(this.code, this.description);
  final String code;
  final String description;

  // Get the PDF template path for each form type
  String get templatePath {
    switch (this) {
      // case FormType.anexa3Part1:
      //   return 'assets/templates/anexa3_part1.pdf';
      // case FormType.anexa3Part2:
      //   return 'assets/templates/anexa3_part2.pdf';
      case FormType.raportIscir:
        return 'assets/templates/raport_iscir.pdf';
      case FormType.anexa4:
        return 'assets/templates/anexa4_template.pdf';
    }
  }

  IconData get icon {
    switch (this) {
      // case FormType.anexa3Part1:
      //   return Icons.assignment;
      // case FormType.anexa3Part2:
      //   return Icons.assignment_turned_in;
      case FormType.raportIscir:
        return Icons.assignment;
      case FormType.anexa4:
        return Icons.list_alt;
    }
  }
}

class ISCIRForm {
  final int? id;
  final int clientId;
  final FormType formType;
  final String reportNumber;
  final DateTime reportDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> formData;

  ISCIRForm({
    this.id,
    required this.clientId,
    required this.formType,
    required this.reportNumber,
    required this.reportDate,
    required this.createdAt,
    required this.updatedAt,
    this.formData = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'form_type': formType.code,
      'report_number': reportNumber,
      'report_date': reportDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ISCIRForm.fromMap(Map<String, dynamic> map) {
    return ISCIRForm(
      id: map['id']?.toInt(),
      clientId: map['client_id']?.toInt() ?? 0,
      formType: FormType.values.firstWhere(
            (type) => type.code == map['form_type'],
        orElse: () => FormType.raportIscir,
      ),
      reportNumber: map['report_number'] ?? '',
      reportDate: DateTime.parse(map['report_date']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      formData: {},
    );
  }

  ISCIRForm copyWith({
    int? id,
    int? clientId,
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