import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../models/client.dart';
import '../models/form.dart';
import '../services/firestore_service.dart';

class ExcelGenerationService {
  static final ExcelGenerationService instance = ExcelGenerationService._();
  ExcelGenerationService._();

  Future<void> generateClientReport({
    required int year,
    required int trimester,
    String action = 'download',
  }) async {
    try {
      // print('DEBUG EXCEL: Starting Excel generation for year=$year, trimester=$trimester');

      final allForms = await FirestoreService.instance.getAllForms();
      // print('DEBUG EXCEL: Loaded ${allForms.length} forms from Firebase');

      final filteredForms = _filterFormsByTrimester(allForms, year, trimester);
      // print('DEBUG EXCEL: Filtered to ${filteredForms.length} forms for this trimester');

      filteredForms.sort((a, b) {
        final numA = int.tryParse(a.reportNumber) ?? 0;
        final numB = int.tryParse(b.reportNumber) ?? 0;
        return numA.compareTo(numB);
      });

      // print('DEBUG EXCEL: Forms after sorting:');
      // for (final form in filteredForms) {
      //   print('  - Form ID: ${form.id}, reportNumber: ${form.reportNumber}, formData.report_no: ${form.formData['report_no']}');
      // }

      final excel = Excel.createExcel();

      final sheetName = 'Registru Aparate';
      excel.rename('Sheet1', sheetName);
      final mainSheet = excel[sheetName];

      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        // backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
        fontFamily: getFontFamily(FontFamily.Calibri),
      );

      final headerStyleVertical = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        // backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
        fontFamily: getFontFamily(FontFamily.Calibri),
        rotation: 90, // Vertical text
      );

      final subHeaderStyleVertical = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        // backgroundColorHex: ExcelColor.fromHexString('#E8E8E8'),
        fontFamily: getFontFamily(FontFamily.Calibri),
        rotation: 90, // Vertical text
      );

      /// Row 0: Main headers with merged cells
      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
      _setCell(mainSheet, 0, 0, 'Nr. Înregistrare', headerStyleVertical);

      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1));
      _setCell(mainSheet, 1, 0, 'Deținător/ Utilizator', headerStyleVertical);

      /// Locul funcționării (3 columns merged)
      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0));
      _setCell(mainSheet, 2, 0, 'Locul funcționării aparatului', headerStyle);

      _setCell(mainSheet, 5, 0, 'Operația efectuată', headerStyle);

      /// Caracteristicile (2 columns merged)
      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0));
      _setCell(mainSheet, 6, 0, 'Caracteristicile aparatului', headerStyle);

      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 1));
      _setCell(mainSheet, 8, 0, 'Nr. De fabricație/ an de fabricație', headerStyleVertical);

      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 1));
      _setCell(mainSheet, 9, 0, 'Producator/ Furnizor', headerStyleVertical);

      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 1));
      _setCell(mainSheet, 10, 0, 'Raport de verificare Nr./ Data', headerStyleVertical);

      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 1));
      _setCell(mainSheet, 11, 0, 'Livret aparat Nr. Înregistrare/ data', headerStyleVertical);

      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: 1));
      _setCell(mainSheet, 12, 0, 'Scadența următoarei verificări', headerStyleVertical);

      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: 1));
      _setCell(mainSheet, 13, 0, 'Observații', headerStyleVertical);

      /// Row 1: Sub-headers
      _setCell(mainSheet, 2, 1, 'Localitatea/ Județ', subHeaderStyleVertical);
      _setCell(mainSheet, 3, 1, 'Strada, Nr.', subHeaderStyleVertical);
      _setCell(mainSheet, 4, 1, 'Bl., sc., et., ap.', subHeaderStyleVertical);
      _setCell(mainSheet, 5, 1, 'Admiterea funcționării, VTP, Reparare', subHeaderStyleVertical);
      _setCell(mainSheet, 6, 1, 'Tip', subHeaderStyleVertical);
      _setCell(mainSheet, 7, 1, 'Parametrii principali', subHeaderStyleVertical);

      /// Row 2: Column numbers
      final numberStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        fontFamily: getFontFamily(FontFamily.Calibri),
      );
      for (int i = 0; i < 14; i++) {
        _setCell(mainSheet, i, 2, (i + 1).toString(), numberStyle);
      }

      /// Data rows - ONE ROW PER FORM
      int currentRow = 3;
      int entryNumber = 1;

      for (final form in filteredForms) {
        final client = await FirestoreService.instance.getClient(form.clientId);

        if (client != null) {
          await _addFormRow(mainSheet, currentRow, entryNumber, client, form);
          currentRow++;
          entryNumber++;
        }
      }

      mainSheet.setColumnWidth(0, 15);
      mainSheet.setColumnWidth(1, 25);
      mainSheet.setColumnWidth(2, 20);
      mainSheet.setColumnWidth(3, 20);
      mainSheet.setColumnWidth(4, 15);
      mainSheet.setColumnWidth(5, 20);
      mainSheet.setColumnWidth(6, 15);
      mainSheet.setColumnWidth(7, 45);
      mainSheet.setColumnWidth(8, 20);
      mainSheet.setColumnWidth(9, 18);
      mainSheet.setColumnWidth(10, 20);
      mainSheet.setColumnWidth(11, 20);
      mainSheet.setColumnWidth(12, 20);
      mainSheet.setColumnWidth(13, 20);

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode Excel file');

      final trimesterName = _getTrimesterName(trimester);
      final fileName = 'Registru_Aparate_${trimesterName}_${year}.xlsx';

      if (action == 'share') {
        // Share using system share dialog
        await _shareExcel(bytes, fileName);
      } else {
        // Save directly to Downloads
        await _saveExcelToDownloads(bytes, fileName);
      }

    } catch (e) {
      print('Error generating Excel report: $e');
      rethrow;
    }
  }

  /// Share Excel file using system share dialog
  Future<void> _shareExcel(List<int> excelBytes, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(excelBytes);

      await Share.shareXFiles([XFile(filePath)], text: 'Registru Evidenta Aparate');
      print('✅ Excel shared successfully');
    } catch (e) {
      print('❌ Error sharing Excel: $e');
      rethrow;
    }
  }

  /// Save Excel file directly to Downloads folder
  Future<String?> _saveExcelToDownloads(List<int> excelBytes, String fileName) async {
    try {
      final params = SaveFileDialogParams(
        data: Uint8List.fromList(excelBytes),
        fileName: fileName,
        mimeTypesFilter: ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
      );

      final filePath = await FlutterFileDialog.saveFile(params: params);

      if (filePath != null) {
        print('✅ Excel saved to: $filePath');
        return filePath;
      } else {
        throw Exception('User cancelled save');
      }
    } catch (e) {
      print('❌ Error saving Excel: $e');
      rethrow;
    }
  }

  Future<void> _addFormRow(
      Sheet sheet,
      int row,
      int entryNumber,
      Client client,
      ISCIRForm form,
      ) async {
    // print('DEBUG EXCEL ROW: Adding row $row for form ${form.id}');
    // print('  - form.reportNumber: ${form.reportNumber}');
    // print('  - form.formData keys: ${form.formData.keys.toList()}');
    // print('  - form.formData.report_no: ${form.formData['report_no']}');

    final dataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      fontFamily: getFontFamily(FontFamily.Calibri),
    );

    final centerStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontFamily: getFontFamily(FontFamily.Calibri),
    );

    final formData = form.formData;

    /// Column 0: Entry number
    _setCell(sheet, 0, row, entryNumber.toString(), centerStyle);

    /// Column 1: Deținător/Utilizator
    final detinator = formData['detinator_client'] ?? '${client.firstName} ${client.lastName}';
    _setCell(sheet, 1, row, detinator, dataStyle);

    /// Column 2: Localitatea/Județ
    final localitatea = formData['localitate_client'] ?? client.address;
    _setCell(sheet, 2, row, localitatea, dataStyle);

    /// Column 3: Strada, Nr.
    final strada = formData['adresa_client'] ?? client.street;
    _setCell(sheet, 3, row, strada, dataStyle);

    /// Column 4: Bl., sc., et., ap.
    _setCell(sheet, 4, row, '', dataStyle);

    /// Column 5: Operația (Admiterea funcționării, VTP, or Reparare)
    String operation = 'VTP';
    if (formData['operatia_admitere'] == true) {
      operation = 'Admiterea funcționării';
    } else if (formData['operatia_vtp'] == true) {
      operation = 'VTP';
    } else if (formData['operatia_repunere'] == true) {
      operation = 'Reparare';
    }
    _setCell(sheet, 5, row, operation, dataStyle);

    /// Column 6: Tip (model of equipment)
    final tip = formData['model'] ?? formData['tip'] ?? 'C12';
    _setCell(sheet, 6, row, tip, dataStyle);

    /// Column 7: Parametrii principali (CO, O2, NO, CO2, Ea, u)
    final params = _buildParametersString(formData);
    _setCell(sheet, 7, row, params, dataStyle);

    /// Column 8: Nr. De fabricație/ an de fabricație
    final nrFabricatie = formData['serie_an_fabricatie'] ?? '';
    _setCell(sheet, 8, row, nrFabricatie, dataStyle);

    /// Column 9: Producător/Furnizor
    final producator = formData['producator'] ?? '';
    _setCell(sheet, 9, row, producator, dataStyle);

    /// Column 10: Raport de verificare Nr./Data
    final reportInfo = '${form.reportNumber}/${_formatDate(form.reportDate)}';
    print('DEBUG EXCEL: Column 10 reportInfo = "$reportInfo"');
    _setCell(sheet, 10, row, reportInfo, dataStyle);

    /// Column 11: Livret aparat Nr. Înregistrare/data
    _setCell(sheet, 11, row, '', dataStyle);

    /// Column 12: Scadența următoarei verificări (2 years from report date)
    final nextVerification = form.reportDate.add(Duration(days: 365 * 2));
    _setCell(sheet, 12, row, _formatDate(nextVerification), centerStyle);

    /// Column 13: Observații
    String obs = '';
    if (formData['aparat_admis'] == 'admis') {
      obs = 'Aparat admis';
    } else if (formData['aparat_admis'] == 'respins') {
      obs = 'Aparat respins';
    }
    _setCell(sheet, 13, row, obs, dataStyle);
  }

  String _buildParametersString(Map<String, dynamic> formData) {
    List<String> params = [];

    if (formData['co_masurat_valoare'] != null && formData['co_masurat_valoare'].toString().isNotEmpty) {
      params.add('CO:${formData['co_masurat_valoare']}');
    }
    if (formData['o2_masurat_valoare'] != null && formData['o2_masurat_valoare'].toString().isNotEmpty) {
      params.add('O2:${formData['o2_masurat_valoare']}');
    }
    if (formData['no2_masurat_valoare'] != null && formData['no2_masurat_valoare'].toString().isNotEmpty) {
      params.add('NO:${formData['no2_masurat_valoare']}');
    }
    if (formData['co2_procent_valoare'] != null && formData['co2_procent_valoare'].toString().isNotEmpty) {
      params.add('CO2:${formData['co2_procent_valoare']}');
    }
    if (formData['exces_de_aer_valoare'] != null && formData['exces_de_aer_valoare'].toString().isNotEmpty) {
      params.add('Ea:${formData['exces_de_aer_valoare']}');
    }
    if (formData['eficienta_ardere_valoare'] != null && formData['eficienta_ardere_valoare'].toString().isNotEmpty) {
      params.add('u:${formData['eficienta_ardere_valoare']}');
    }

    return params.join(', ');
  }

  void _setCell(Sheet sheet, int col, int row, String value, CellStyle style) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    cell.cellStyle = style;
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  List<ISCIRForm> _filterFormsByTrimester(List<ISCIRForm> forms, int year, int trimester) {
    final dateRange = _getTrimesterDateRange(year, trimester);

    // print('DEBUG FILTER: Trimester $trimester/$year range: ${_formatDate(dateRange['start']!)} to ${_formatDate(dateRange['end']!)}');

    return forms.where((form) {
      final reportDate = form.reportDate;
      final isInRange = reportDate.isAfter(dateRange['start']!.subtract(Duration(days: 1))) &&
          reportDate.isBefore(dateRange['end']!.add(Duration(days: 1)));

      // print('  Form ${form.id} (reportNumber: ${form.reportNumber}): reportDate=${_formatDate(reportDate)}, inRange=$isInRange');

      return isInRange;
    }).toList();
  }

  Map<String, DateTime> _getTrimesterDateRange(int year, int trimester) {
    DateTime start, end;

    switch (trimester) {
      case 1: // January - March
        start = DateTime(year, 1, 1);
        end = DateTime(year, 3, 31);
        break;
      case 2: // April - June
        start = DateTime(year, 4, 1);
        end = DateTime(year, 6, 30);
        break;
      case 3: // July - September
        start = DateTime(year, 7, 1);
        end = DateTime(year, 9, 30);
        break;
      case 4: // October - December
        start = DateTime(year, 10, 1);
        end = DateTime(year, 12, 31);
        break;
      default:
        start = DateTime(year, 1, 1);
        end = DateTime(year, 12, 31);
    }

    return {'start': start, 'end': end};
  }

  String _getTrimesterName(int trimester) {
    return 'Trimestrul_$trimester';
  }
}