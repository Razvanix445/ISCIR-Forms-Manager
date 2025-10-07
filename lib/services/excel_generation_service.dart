import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/client.dart';
import '../models/form.dart';
import '../services/firestore_service.dart';

class ExcelGenerationService {
  static final ExcelGenerationService instance = ExcelGenerationService._();
  ExcelGenerationService._();

  Future<void> generateClientReport({
    required int year,
    required int trimester,
  }) async {
    try {
      // Get all forms (not clients!)
      final allForms = await FirestoreService.instance.getAllForms();

      // Filter forms by trimester
      final filteredForms = _filterFormsByTrimester(allForms, year, trimester);

      // Create Excel workbook
      final excel = Excel.createExcel();

      // Create new sheet
      final sheetName = 'Registru Aparate';
      excel.rename('Sheet1', sheetName);
      final mainSheet = excel[sheetName];

      // Define header styles
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

      final subHeaderStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        // backgroundColorHex: ExcelColor.fromHexString('#E8E8E8'),
        fontFamily: getFontFamily(FontFamily.Calibri),
      );

      final subHeaderStyleVertical = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        // backgroundColorHex: ExcelColor.fromHexString('#E8E8E8'),
        fontFamily: getFontFamily(FontFamily.Calibri),
        rotation: 90, // Vertical text
      );

      // Row 0: Main headers with merged cells
      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
      _setCell(mainSheet, 0, 0, 'Nr. Înregistrare', headerStyleVertical);

      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1));
      _setCell(mainSheet, 1, 0, 'Deținător/ Utilizator', headerStyleVertical);

      // Locul funcționării (3 columns merged)
      mainSheet.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0));
      _setCell(mainSheet, 2, 0, 'Locul funcționării aparatului', headerStyle);

      _setCell(mainSheet, 5, 0, 'Operația efectuată', headerStyle);

      // Caracteristicile (2 columns merged)
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

      // Row 1: Sub-headers
      _setCell(mainSheet, 2, 1, 'Localitatea/ Județ', subHeaderStyleVertical);
      _setCell(mainSheet, 3, 1, 'Strada, Nr.', subHeaderStyleVertical);
      _setCell(mainSheet, 4, 1, 'Bl., sc., et., ap.', subHeaderStyleVertical);
      _setCell(mainSheet, 5, 1, 'Admiterea funcționării, VTP, Reparare', subHeaderStyleVertical);
      _setCell(mainSheet, 6, 1, 'Tip', subHeaderStyleVertical);
      _setCell(mainSheet, 7, 1, 'Parametrii principali', subHeaderStyleVertical);

      // Row 2: Column numbers
      final numberStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        fontFamily: getFontFamily(FontFamily.Calibri),
      );
      for (int i = 0; i < 14; i++) {
        _setCell(mainSheet, i, 2, (i + 1).toString(), numberStyle);
      }

      // Data rows - ONE ROW PER FORM
      int currentRow = 3;
      int entryNumber = 1;

      for (final form in filteredForms) {
        // Get client info for this form
        final client = await FirestoreService.instance.getClient(form.clientId);

        if (client != null) {
          await _addFormRow(mainSheet, currentRow, entryNumber, client, form);
          currentRow++;
          entryNumber++;
        }
      }

      // Set column widths
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

      // Save and share the file
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode Excel file');

      final directory = await getTemporaryDirectory();
      final now = DateTime.now();
      final trimesterName = _getTrimesterName(trimester);
      final fileName = 'Registru_Aparate_${trimesterName}_${year}.xlsx';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Share the file
      await Share.shareXFiles([XFile(filePath)], text: 'Registru Evidență Aparate');

    } catch (e) {
      print('Error generating Excel report: $e');
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

    // Column 0: Entry number (1, 2, 3, 4...)
    _setCell(sheet, 0, row, entryNumber.toString(), centerStyle);

    // Column 1: Deținător/Utilizator - from form data OR client
    final detinator = formData['detinator_client'] ?? '${client.firstName} ${client.lastName}';
    _setCell(sheet, 1, row, detinator, dataStyle);

    // Column 2: Localitatea/Județ - from form data OR client
    final localitatea = formData['localitate_client'] ?? client.address;
    _setCell(sheet, 2, row, localitatea, dataStyle);

    // Column 3: Strada, Nr. - from form data OR client
    final strada = formData['adresa_client'] ?? client.street;
    _setCell(sheet, 3, row, strada, dataStyle);

    // Column 4: Bl., sc., et., ap. - usually empty
    _setCell(sheet, 4, row, '', dataStyle);

    // Column 5: Operația (full text: Admiterea funcționării, VTP, or Reparare)
    String operation = 'VTP';
    if (formData['operatia_admitere'] == true) {
      operation = 'Admiterea funcționării';
    } else if (formData['operatia_vtp'] == true) {
      operation = 'VTP';
    } else if (formData['operatia_repunere'] == true) {
      operation = 'Reparare';
    }
    _setCell(sheet, 5, row, operation, dataStyle);

    // Column 6: Tip (model of equipment)
    final tip = formData['model'] ?? formData['tip'] ?? 'C12';
    _setCell(sheet, 6, row, tip, dataStyle);

    // Column 7: Parametrii principali (CO, O2, NO, CO2, Ea, u)
    final params = _buildParametersString(formData);
    _setCell(sheet, 7, row, params, dataStyle);

    // Column 8: Nr. De fabricație/ an de fabricație
    final nrFabricatie = formData['serie_an_fabricatie'] ?? '';
    _setCell(sheet, 8, row, nrFabricatie, dataStyle);

    // Column 9: Producător/Furnizor
    final producator = formData['producator'] ?? '';
    _setCell(sheet, 9, row, producator, dataStyle);

    // Column 10: Raport de verificare Nr./Data
    final reportInfo = '${form.reportNumber}/${_formatDate(form.reportDate)}';
    _setCell(sheet, 10, row, reportInfo, dataStyle);

    // Column 11: Livret aparat Nr. Înregistrare/data (usually empty)
    _setCell(sheet, 11, row, '', dataStyle);

    // Column 12: Scadența următoarei verificări (2 years from report date)
    final nextVerification = form.reportDate.add(Duration(days: 365 * 2));
    _setCell(sheet, 12, row, _formatDate(nextVerification), centerStyle);

    // Column 13: Observații
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

    // Use the _valoare fields which contain the actual measured values
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

    return forms.where((form) {
      final reportDate = form.reportDate;
      return reportDate.isAfter(dateRange['start']!.subtract(Duration(days: 1))) &&
          reportDate.isBefore(dateRange['end']!.add(Duration(days: 1)));
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