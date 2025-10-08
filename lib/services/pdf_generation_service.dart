import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/form.dart';
import '../models/client.dart';

class SimplePdfGenerationService {
  static final SimplePdfGenerationService instance = SimplePdfGenerationService
      ._init();

  SimplePdfGenerationService._init();

  Future<Uint8List> _generateRaportIscirPdf(ISCIRForm form, Client client,
      Map<String, dynamic> formData) async {
    final pdf = pw.Document();

    try {
      final ByteData templateData = await rootBundle.load(
          'assets/templates/raport_iscir.png');
      final Uint8List templateBytes = templateData.buffer.asUint8List();
      final pw.MemoryImage templateImage = pw.MemoryImage(templateBytes);

      final image = await _decodeImageFromList(templateBytes);
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();

      final pdfWidth = PdfPageFormat.a4.width;
      final pdfHeight = PdfPageFormat.a4.height;

      final scaleX = pdfWidth / imageWidth;
      final scaleY = pdfHeight / imageHeight;

      print(
          'Raport ISCIR PDF - Image: ${imageWidth}x$imageHeight, PDF: ${pdfWidth}x$pdfHeight, Scale: ${scaleX}x$scaleY');

      final fontData = await rootBundle.load(
          'assets/fonts/NotoSans-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                pw.Image(templateImage, fit: pw.BoxFit.fill),

                ..._buildRaportIscirFieldOverlays(
                    formData, client, ttf, scaleX, scaleY),
              ],
            );
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      print('Error generating Raport ISCIR PDF: $e');
      rethrow;
    }
  }

  List<pw.Widget> _buildRaportIscirFieldOverlays(Map<String, dynamic> formData,
      Client client,
      pw.Font font,
      double scaleX,
      double scaleY,) {
    List<pw.Widget> overlays = [];
    final fieldPositions = _getRaportIscirFieldPositions();

    print('Building Raport ISCIR overlays...');
    print('Available field positions: ${fieldPositions.keys.length}');
    print('Form data keys: ${formData.keys.toList()}');

    /// === CLIENT INFORMATION FIELDS ===
    _addTextOverlay(
        overlays,
        'nume_client',
        client.lastName,
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'prenume_client',
        client.firstName,
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'localitate_client',
        client.address,
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'adresa_client',
        client.street,
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'telefon_client',
        client.phone,
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'email_client',
        client.email,
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'loc_aparat_client',
        client.installationLocation,
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'detinator_client',
        client.holder,
        fieldPositions,
        font,
        scaleX,
        scaleY);

    /// === AUTO-GENERATED FIELDS ===
    _addTextOverlay(
        overlays,
        'report_no',
        formData['report_no'],
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'today_date',
        formData['today_date'],
        fieldPositions,
        font,
        scaleX,
        scaleY);

    /// === PAGE 1 EQUIPMENT FIELDS ===
    _addTextOverlay(
        overlays,
        'producator',
        _getFieldValue(formData, 'producator'),
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'tip',
        formData['tip'],
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'model',
        formData['model'],
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'serie_an_fabricatie',
        formData['serie_an_fabricatie'],
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'putere',
        formData['putere'],
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'tip_combustibil',
        formData['tip_combustibil'],
        fieldPositions,
        font,
        scaleX,
        scaleY);

    /// === SIMPLE TEXT VALUE FIELDS (cu_aer, cu_alimentare, tip_tiraj) ===
    _addTextOverlay(
        overlays,
        'cu_aer',
        formData['cu_aer'],
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'cu_alimentare',
        formData['cu_alimentare'],
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'tip_tiraj',
        formData['tip_tiraj'],
        fieldPositions,
        font,
        scaleX,
        scaleY);

    /// === PAGE 1 CONDITIONAL CHECKMARKS ===
    _addConditionalApparatCheckmarks(
        overlays, formData, fieldPositions, scaleX, scaleY);

    /// === PAGE 1 OPERATION CHECKMARKS ===
    _addOperationCheckmarks(overlays, formData, fieldPositions, scaleX, scaleY);

    /// === PAGE 2 TRIPLE RADIO CHECKMARKS ===
    _addTripleRadioCheckmarks(
        overlays, formData, fieldPositions, scaleX, scaleY);

    /// === PAGE 3 MEASUREMENT VALUES ===
    _addMeasurementFieldsAndCheckmarks(
        overlays, formData, fieldPositions, font, scaleX, scaleY);

    /// === PAGE 4 ANALYSIS VALUES ===
    _addAnalysisFieldsAndCheckmarks(
        overlays, formData, fieldPositions, font, scaleX, scaleY);

    /// === PAGE 5 AUTO FIELDS ===
    _addTextOverlay(
        overlays,
        'scadenta_verificare',
        formData['scadenta_verificare'],
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'nume_utilizator',
        formData['nume_utilizator'],
        fieldPositions,
        font,
        scaleX,
        scaleY);
    _addTextOverlay(
        overlays,
        'nume_personal_instruit',
        formData['nume_personal_instruit'],
        fieldPositions,
        font,
        scaleX,
        scaleY);

    /// === PAGE 5 CONCLUSION CHECKMARK ===
    _addConclusionCheckmark(overlays, formData, fieldPositions, scaleX, scaleY);

    /// === PAGE 5 SIGNATURES ===
    _addSignatureOverlays(overlays, formData, fieldPositions, scaleX, scaleY);

    print('Created ${overlays.length} overlays for Raport ISCIR');
    return overlays;
  }

  String _getFieldValue(Map<String, dynamic> formData, String key) {
    final value = formData[key]?.toString() ?? '';

    if (key == 'producator') {
      final dropdownOptions = [
        'Ariston', 'Baxi', 'Beretta', 'Bosch', 'Buderus',
        'Chaffoteaux', 'Ferroli', 'Immergas', 'Junkers', 'Motan',
        'Protherm', 'Riello', 'Saunier Duval', 'Vaillant', 'Viessmann', 'Westen'
      ];

      if (dropdownOptions.contains(value)) {
        return value;
      } else {
        return value;
      }
    }

    return value;
  }

  void _addConditionalApparatCheckmarks(List<pw.Widget> overlays,
      Map<String, dynamic> formData,
      Map<String, FieldPosition> positions,
      double scaleX,
      double scaleY,) {
    final operatiaAdmitere = formData['operatia_admitere'] == true;

    if (operatiaAdmitere) {
      final tipAparat = formData['tip_aparat']?.toString() ?? '';

      if (tipAparat == 'nou' && positions.containsKey('tip_aparat_nou')) {
        overlays.add(
            _createCheckmark(positions['tip_aparat_nou']!, scaleX, scaleY));
      } else
      if (tipAparat == 'vechi' && positions.containsKey('tip_aparat_vechi')) {
        overlays.add(
            _createCheckmark(positions['tip_aparat_vechi']!, scaleX, scaleY));
      }
    }
  }

  void _addOperationCheckmarks(List<pw.Widget> overlays,
      Map<String, dynamic> formData,
      Map<String, FieldPosition> positions,
      double scaleX,
      double scaleY,) {
    if (formData['operatia_vtp'] == true &&
        positions.containsKey('operatia_vtp')) {
      overlays.add(
          _createCheckmark(positions['operatia_vtp']!, scaleX, scaleY));
    }

    if (formData['operatia_repunere'] == true &&
        positions.containsKey('operatia_repunere')) {
      overlays.add(
          _createCheckmark(positions['operatia_repunere']!, scaleX, scaleY));
    }
  }

  void _addTripleRadioCheckmarks(List<pw.Widget> overlays,
      Map<String, dynamic> formData,
      Map<String, FieldPosition> positions,
      double scaleX,
      double scaleY,) {
    final tripleRadioFields = [
      'exista_instructiuni', 'exista_declaratie', 'exista_schema',
      'exista_documentatie', 'exista_aviz', 'aparat_instalat',
      'aparat_reparat', 'gaze', 'electricitate', 'apa',
      'evacuare_gaze_arse', 'tip_combustibil_corespunzator', 'asigurare_aer',
    ];

    for (String fieldName in tripleRadioFields) {
      final value = formData[fieldName]?.toString() ?? 'N_A';
      String suffix = '';

      if (value == 'DA') {
        suffix = '_da';
      } else if (value == 'NU') {
        suffix = '_nu';
      } else if (value == 'N_A') {
        suffix = '_na';
      }

      if (suffix.isNotEmpty) {
        final checkboxKey = '${fieldName}${suffix}';
        if (positions.containsKey(checkboxKey)) {
          overlays.add(
              _createCheckmark(positions[checkboxKey]!, scaleX, scaleY));
        }
      }
    }
  }

  void _addMeasurementFieldsAndCheckmarks(List<pw.Widget> overlays,
      Map<String, dynamic> formData,
      Map<String, FieldPosition> positions,
      pw.Font font,
      double scaleX,
      double scaleY,) {
    final measurementFields = [
      'verificare_etanseitate',
      'circuit_combustibil',
      'circuit_apa',
      'verificare_instalatie',
      'verificare_legare',
      'reglat_sarcina_aparat',
      'tiraj',
      'presiune_rampa',
      'presiune_arzator',
      'presiune_focar',
      'temperatura_gaze_arse',
      'verificare_etanseitate_gaze_arse',
      'alte_masuratori',
      'verificare_functii_protectie',
      'verificare_parametru_presiune',
      'verificare_parametru_temperatura',
    ];

    for (String fieldName in measurementFields) {
      final valueKey = '${fieldName}_valoare';
      _addTextOverlay(
          overlays,
          valueKey,
          formData[valueKey],
          positions,
          font,
          scaleX,
          scaleY);

      final radioValue = formData[fieldName]?.toString() ?? 'N_A';
      String suffix = '';

      if (radioValue == 'DA') {
        suffix = '_da';
      } else if (radioValue == 'NU') {
        suffix = '_nu';
      } else if (radioValue == 'N_A') {
        suffix = '_na';
      }

      if (suffix.isNotEmpty) {
        final checkboxKey = '${fieldName}${suffix}';
        if (positions.containsKey(checkboxKey)) {
          overlays.add(
              _createCheckmark(positions[checkboxKey]!, scaleX, scaleY));
        }
      }
    }
  }

  void _addAnalysisFieldsAndCheckmarks(List<pw.Widget> overlays,
      Map<String, dynamic> formData,
      Map<String, FieldPosition> positions,
      pw.Font font,
      double scaleX,
      double scaleY,) {
    final analysisFields = [
      'co_masurat', 'o2_masurat', 'no2_masurat', 'so2_masurat',
      'co2_procent', 'exces_de_aer', 'eficienta_ardere',
    ];

    for (String fieldName in analysisFields) {
      final valueKey = '${fieldName}_valoare';
      _addTextOverlay(
          overlays,
          valueKey,
          formData[valueKey],
          positions,
          font,
          scaleX,
          scaleY);

      final radioValue = formData[fieldName]?.toString() ?? 'N_A';
      String suffix = '';

      if (radioValue == 'DA') {
        suffix = '_da';
      } else if (radioValue == 'NU') {
        suffix = '_nu';
      } else if (radioValue == 'N_A') {
        suffix = '_na';
      }

      if (suffix.isNotEmpty) {
        final checkboxKey = '${fieldName}${suffix}';
        if (positions.containsKey(checkboxKey)) {
          overlays.add(
              _createCheckmark(positions[checkboxKey]!, scaleX, scaleY));
        }
      }
    }
  }

  void _addConclusionCheckmark(List<pw.Widget> overlays,
      Map<String, dynamic> formData,
      Map<String, FieldPosition> positions,
      double scaleX,
      double scaleY,) {
    final conclusion = formData['aparat_admis']?.toString() ?? 'admis';

    if (positions.containsKey('aparat_admis')) {
      final position = positions['aparat_admis']!;

      overlays.add(
        pw.Positioned(
          left: position.x * scaleX,
          top: position.y * scaleY,
          child: pw.Container(
            width: position.width * scaleX,
            height: position.height * scaleY,
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                conclusion == 'admis' ? 'Admis' : 'Respins',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  void _addSignatureOverlays(List<pw.Widget> overlays,
      Map<String, dynamic> formData,
      Map<String, FieldPosition> positions,
      double scaleX,
      double scaleY,) {
    final signaturesData = formData['page5_signatures'];

    if (signaturesData != null && signaturesData is Map<String, dynamic>) {
      final utilizatorSignature = signaturesData['semnatura_utilizator'];
      if (utilizatorSignature != null && utilizatorSignature is String) {
        try {
          final signatureBytes = base64Decode(utilizatorSignature);
          final signatureImage = pw.MemoryImage(signatureBytes);

          if (positions.containsKey('semnatura_utilizator')) {
            overlays.add(_createSignatureOverlay(
                positions['semnatura_utilizator']!, signatureImage, scaleX,
                scaleY));
          }

          if (positions.containsKey('semnatura_instruit')) {
            overlays.add(_createSignatureOverlay(
                positions['semnatura_instruit']!, signatureImage, scaleX,
                scaleY));
          }
        } catch (e) {
          print('Error decoding utilizator signature: $e');
        }
      }

      final rslSignature = signaturesData['semnatura_rsl'];
      if (rslSignature != null && rslSignature is String &&
          positions.containsKey('semnatura_rsl')) {
        try {
          final signatureBytes = base64Decode(rslSignature);
        } catch (e) {
          print('Error decoding RSL signature: $e');
        }
      }
    }
  }

  pw.Widget _createSignatureOverlay(FieldPosition position,
      pw.MemoryImage signatureImage, double scaleX, double scaleY) {
    return pw.Positioned(
      left: position.x * scaleX,
      top: position.y * scaleY,
      child: pw.SizedBox(
        width: position.width * scaleX,
        height: position.height * scaleY,
        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
      ),
    );
  }

  Map<String, FieldPosition> _getRaportIscirFieldPositions() {
    return {
      /// CLIENT INFO
      'nume_client': FieldPosition(x: 473.99999999999994,
          y: 525.3333333333351,
          width: 784.6666666666665,
          height: 40.66666666666674),
      'prenume_client': FieldPosition(x: 504.0,
          y: 572.6666666666684,
          width: 756.0,
          height: 38.66666666666663),
      'localitate_client': FieldPosition(x: 500.66666666666663,
          y: 616.0000000000018,
          width: 759.3333333333334,
          height: 42.66666666666663),
      'adresa_client': FieldPosition(x: 456.6666666666668,
          y: 663.3333333333356,
          width: 803.3333333333333,
          height: 41.33333333333337),
      'telefon_client': FieldPosition(x: 424.0000000000001,
          y: 711.3333333333356,
          width: 835.9999999999999,
          height: 41.33333333333337),
      'email_client': FieldPosition(x: 477.3333333333334,
          y: 756.0000000000023,
          width: 782.6666666666665,
          height: 41.33333333333337),
      'loc_aparat_client': FieldPosition(x: 721.3333333333335,
          y: 801.3333333333334,
          width: 537.3333333333333,
          height: 43.33333333333337),
      'detinator_client': FieldPosition(x: 539.3333333333335,
          y: 849.3333333333335,
          width: 720.6666666666667,
          height: 41.33333333333326),

      /// AUTO GENERATED
      'report_no': FieldPosition(x: 1033.3333333333367,
          y: 336.6666666666687,
          width: 159.33333333333326,
          height: 41.33333333333337),
      'today_date': FieldPosition(x: 1308.66666666667,
          y: 336.00000000000205,
          width: 342.66666666666674,
          height: 42.0),

      /// OPERATION CHECKMARKS
      'tip_aparat_nou': FieldPosition(x: 952.0000000000057,
          y: 383.3333333333354,
          width: 112.66666666666674,
          height: 43.333333333333314),
      'tip_aparat_vechi': FieldPosition(x: 952.0000000000057,
          y: 430.00000000000205,
          width: 114.66666666666674,
          height: 42.666666666666686),
      'operatia_vtp': FieldPosition(x: 1546.6666666666802,
          y: 383.3333333333356,
          width: 112.66666666666652,
          height: 86.66666666666669),
      'operatia_repunere': FieldPosition(x: 2270.0000000000264,
          y: 382.0000000000023,
          width: 111.33333333333348,
          height: 88.0),

      /// EQUIPMENT FIELDS
      'producator': FieldPosition(x: 1555.3333333333712,
          y: 524.6666666666683,
          width: 784.0,
          height: 41.33333333333326),
      'tip': FieldPosition(x: 1554.6666666667047,
          y: 570.6666666666683,
          width: 785.3333333333335,
          height: 40.0),
      'model': FieldPosition(x: 1555.3333333333712,
          y: 614.0000000000016,
          width: 786.0,
          height: 42.66666666666674),
      'serie_an_fabricatie': FieldPosition(x: 1635.333333333374,
          y: 661.3333333333359,
          width: 706.666666666667,
          height: 41.33333333333337),
      'putere': FieldPosition(x: 1926.000000000041,
          y: 707.3333333333359,
          width: 418.0,
          height: 42.66666666666663),
      'cu_aer': FieldPosition(x: 1616.6666666667074,
          y: 754.6666666666692,
          width: 728.6666666666665,
          height: 42.0),
      'tip_combustibil': FieldPosition(x: 1618.000000000041,
          y: 800.0000000000025,
          width: 727.333333333333,
          height: 44.0),
      'cu_alimentare': FieldPosition(x: 1619.3333333333758,
          y: 847.3333333333326,
          width: 728.666666666667,
          height: 42.666666666666515),

      /// PAGE 2 TRIPLE RADIOS - Document Verification
      'exista_instructiuni_da': FieldPosition(x: 2042.6666666667238,
          y: 984.6666666666648,
          width: 108.66666666666697,
          height: 43.33333333333337),
      'exista_instructiuni_nu': FieldPosition(x: 2156.0000000000573,
          y: 984.6666666666648,
          width: 110.66666666666697,
          height: 45.999999999999886),
      'exista_instructiuni_na': FieldPosition(x: 2269.3333333333903,
          y: 985.9999999999981,
          width: 115.33333333333394,
          height: 43.33333333333337),

      'exista_declaratie_da': FieldPosition(x: 2042.6666666667325,
          y: 1031.3333333333285,
          width: 108.66666666666652,
          height: 46.0),
      'exista_declaratie_nu': FieldPosition(x: 2156.0000000000655,
          y: 1031.3333333333285,
          width: 111.33333333333348,
          height: 43.333333333333485),
      'exista_declaratie_na': FieldPosition(x: 2269.333333333399,
          y: 1031.3333333333285,
          width: 116.0,
          height: 43.333333333333485),

      'exista_schema_da': FieldPosition(x: 2042.6666666667325,
          y: 1075.9999999999952,
          width: 110.0,
          height: 46.0),
      'exista_schema_nu': FieldPosition(x: 2156.0000000000655,
          y: 1077.3333333333285,
          width: 110.0,
          height: 43.333333333333485),
      'exista_schema_na': FieldPosition(x: 2270.6666666667325,
          y: 1077.3333333333285,
          width: 114.66666666666652,
          height: 44.66666666666674),

      'exista_documentatie_da': FieldPosition(x: 2044.666666666753,
          y: 1123.9999999999925,
          width: 106.66666666666652,
          height: 44.0),
      'exista_documentatie_nu': FieldPosition(x: 2156.666666666753,
          y: 1123.9999999999925,
          width: 108.66666666666652,
          height: 42.66666666666674),
      'exista_documentatie_na': FieldPosition(x: 2270.0000000000864,
          y: 1123.333333333326,
          width: 114.66666666666652,
          height: 43.33333333333326),

      'exista_aviz_da': FieldPosition(x: 2044.666666666753,
          y: 1169.9999999999925,
          width: 106.66666666666652,
          height: 44.66666666666674),
      'exista_aviz_nu': FieldPosition(x: 2156.666666666753,
          y: 1171.333333333326,
          width: 108.0,
          height: 43.33333333333326),
      'exista_aviz_na': FieldPosition(x: 2270.000000000084,
          y: 1169.9999999999916,
          width: 114.66666666666697,
          height: 43.33333333333326),

      /// PAGE 2 TRIPLE RADIOS - Work Verification
      'aparat_instalat_da': FieldPosition(x: 2043.3333333334158,
          y: 1263.9999999999898,
          width: 109.33333333333303,
          height: 43.333333333333485),
      'aparat_instalat_nu': FieldPosition(x: 2156.0000000000823,
          y: 1263.9999999999898,
          width: 110.0,
          height: 43.333333333333485),
      'aparat_instalat_na': FieldPosition(x: 2269.333333333416,
          y: 1263.9999999999898,
          width: 116.66666666666652,
          height: 45.333333333333485),

      'aparat_reparat_da': FieldPosition(x: 2043.3333333334158,
          y: 1309.3333333333233,
          width: 110.0,
          height: 44.666666666666515),
      'aparat_reparat_nu': FieldPosition(x: 2156.0000000000823,
          y: 1310.6666666666565,
          width: 110.0,
          height: 43.33333333333326),
      'aparat_reparat_na': FieldPosition(x: 2270.666666666749,
          y: 1311.9999999999898,
          width: 113.33333333333348,
          height: 42.0),

      'gaze_da': FieldPosition(x: 2042.6666666667488,
          y: 1356.6666666666565,
          width: 110.0,
          height: 43.33333333333326),
      'gaze_nu': FieldPosition(x: 2156.0000000000823,
          y: 1356.6666666666565,
          width: 110.0,
          height: 43.33333333333326),
      'gaze_na': FieldPosition(x: 2269.333333333416,
          y: 1357.3333333333233,
          width: 114.66666666666652,
          height: 44.0),

      'electricitate_da': FieldPosition(x: 2044.0000000000823,
          y: 1401.9999999999866,
          width: 107.33333333333303,
          height: 44.666666666666515),
      'electricitate_nu': FieldPosition(x: 2157.3333333334153,
          y: 1403.9999999999866,
          width: 108.66666666666697,
          height: 41.33333333333326),
      'electricitate_na': FieldPosition(x: 2270.666666666749,
          y: 1401.9999999999866,
          width: 113.33333333333303,
          height: 44.666666666666515),

      'apa_da': FieldPosition(x: 2044.0000000000823,
          y: 1447.3333333333198,
          width: 107.33333333333303,
          height: 44.0),
      'apa_nu': FieldPosition(x: 2154.666666666749,
          y: 1448.666666666653,
          width: 111.33333333333348,
          height: 44.0),
      'apa_na': FieldPosition(x: 2268.0000000000823,
          y: 1447.3333333333198,
          width: 117.33333333333348,
          height: 45.33333333333326),

      'evacuare_gaze_arse_da': FieldPosition(x: 2042.6666666667488,
          y: 1493.9999999999843,
          width: 109.33333333333348,
          height: 43.333333333333485),
      'evacuare_gaze_arse_nu': FieldPosition(x: 2155.3333333334153,
          y: 1493.9999999999843,
          width: 113.33333333333348,
          height: 42.66666666666674),
      'evacuare_gaze_arse_na': FieldPosition(x: 2268.6666666667525,
          y: 1494.6666666666508,
          width: 117.33333333333348,
          height: 43.33333333333326),

      'tip_combustibil_corespunzator_da': FieldPosition(x: 2043.3333333334208,
          y: 1541.333333333317,
          width: 108.66666666666652,
          height: 41.33333333333326),
      'tip_combustibil_corespunzator_nu': FieldPosition(x: 2155.333333333421,
          y: 1539.9999999999834,
          width: 111.33333333333348,
          height: 44.0),
      'tip_combustibil_corespunzator_na': FieldPosition(x: 2268.6666666667543,
          y: 1539.9999999999834,
          width: 118.0,
          height: 46.0),

      'asigurare_aer_da': FieldPosition(x: 2042.0000000000873,
          y: 1587.333333333317,
          width: 110.0,
          height: 43.33333333333326),
      'asigurare_aer_nu': FieldPosition(x: 2156.6666666667543,
          y: 1585.9999999999834,
          width: 110.0,
          height: 44.66666666666674),
      'asigurare_aer_na': FieldPosition(x: 2268.6666666667543,
          y: 1585.9999999999834,
          width: 116.0,
          height: 46.0),

      /// PAGE 3 MEASUREMENTS - Values and Checkmarks
      'verificare_etanseitate_valoare': FieldPosition(x: 1724.6666666667543,
          y: 1726.6666666666445,
          width: 316.0,
          height: 44.0),
      'verificare_etanseitate_da': FieldPosition(x: 2042.0000000000873,
          y: 1726.6666666666445,
          width: 112.0,
          height: 44.66666666666674),
      'verificare_etanseitate_nu': FieldPosition(x: 2156.6666666667584,
          y: 1727.333333333311,
          width: 109.33333333333303,
          height: 42.66666666666674),
      'verificare_etanseitate_na': FieldPosition(x: 2269.333333333425,
          y: 1726.6666666666442,
          width: 115.33333333333348,
          height: 44.66666666666674),

      'circuit_combustibil_valoare': FieldPosition(x: 1725.333333333425,
          y: 1771.9999999999777,
          width: 314.6666666666665,
          height: 46.0),
      'circuit_combustibil_da': FieldPosition(x: 2042.6666666667584,
          y: 1771.9999999999777,
          width: 110.0,
          height: 44.666666666666515),
      'circuit_combustibil_nu': FieldPosition(x: 2154.6666666667584,
          y: 1771.9999999999777,
          width: 113.33333333333303,
          height: 46.0),
      'circuit_combustibil_na': FieldPosition(x: 2268.0000000000914,
          y: 1771.9999999999777,
          width: 118.0,
          height: 46.0),

      'circuit_apa_valoare': FieldPosition(x: 1726.0000000000882,
          y: 1817.999999999976,
          width: 314.0,
          height: 44.666666666666515),
      'circuit_apa_da': FieldPosition(x: 2043.3333333334217,
          y: 1816.6666666666424,
          width: 111.33333333333303,
          height: 46.0),
      'circuit_apa_nu': FieldPosition(x: 2155.3333333334217,
          y: 1817.999999999976,
          width: 112.66666666666652,
          height: 44.666666666666515),
      'circuit_apa_na': FieldPosition(x: 2270.000000000088,
          y: 1819.3333333333092,
          width: 117.33333333333303,
          height: 43.33333333333326),

      'verificare_instalatie_valoare': FieldPosition(x: 1726.6666666667684,
          y: 1861.9999999999711,
          width: 314.6666666666665,
          height: 46.666666666666515),
      'verificare_instalatie_da': FieldPosition(x: 2043.333333333435,
          y: 1862.6666666666376,
          width: 109.33333333333348,
          height: 47.333333333333485),
      'verificare_instalatie_nu': FieldPosition(x: 2156.000000000102,
          y: 1862.6666666666376,
          width: 112.0,
          height: 47.333333333333485),
      'verificare_instalatie_na': FieldPosition(x: 2269.333333333435,
          y: 1862.6666666666376,
          width: 116.66666666666697,
          height: 47.333333333333485),

      'verificare_legare_valoare': FieldPosition(x: 1724.0000000001019,
          y: 1908.6666666666376,
          width: 316.0,
          height: 46.0),
      'verificare_legare_da': FieldPosition(x: 2041.333333333435,
          y: 1909.9999999999711,
          width: 112.0,
          height: 44.666666666666515),
      'verificare_legare_nu': FieldPosition(x: 2156.000000000102,
          y: 1911.3333333333044,
          width: 110.0,
          height: 43.33333333333326),
      'verificare_legare_na': FieldPosition(x: 2269.333333333435,
          y: 1909.9999999999711,
          width: 116.66666666666697,
          height: 44.666666666666515),

      'reglat_sarcina_aparat_da': FieldPosition(x: 2042.6666666667775,
          y: 1953.9999999999686,
          width: 110.0,
          height: 47.33333333333326),
      'reglat_sarcina_aparat_nu': FieldPosition(x: 2156.000000000111,
          y: 1956.6666666666351,
          width: 110.0,
          height: 44.66666666666674),
      'reglat_sarcina_aparat_na': FieldPosition(x: 2269.333333333444,
          y: 1955.3333333333019,
          width: 116.0,
          height: 47.33333333333326),

      'tip_tiraj': FieldPosition(x: 577.3333333334396,
          y: 2047.9999999999652,
          width: 358.66666666666663,
          height: 44.66666666666674),
      'tiraj_valoare': FieldPosition(x: 1724.0000000001232,
          y: 2048.6666666666324,
          width: 316.66666666666697,
          height: 46.0),
      'tiraj_da': FieldPosition(x: 2042.6666666667902,
          y: 2048.6666666666324,
          width: 112.0,
          height: 46.0),
      'tiraj_nu': FieldPosition(x: 2156.0000000001232,
          y: 2048.6666666666324,
          width: 111.33333333333348,
          height: 45.33333333333303),
      'tiraj_na': FieldPosition(x: 2270.66666666679,
          y: 2048.6666666666324,
          width: 114.66666666666652,
          height: 46.0),

      'presiune_rampa_valoare': FieldPosition(x: 1724.0000000001119,
          y: 2094.66666666663,
          width: 317.3333333333335,
          height: 46.0),
      'presiune_rampa_da': FieldPosition(x: 2044.0000000001091,
          y: 2094.66666666663,
          width: 110.0,
          height: 46.666666666666515),
      'presiune_rampa_nu': FieldPosition(x: 2156.000000000109,
          y: 2095.9999999999636,
          width: 111.33333333333348,
          height: 44.666666666666515),
      'presiune_rampa_na': FieldPosition(x: 2270.000000000109,
          y: 2095.9999999999636,
          width: 115.33333333333348,
          height: 45.33333333333303),

      'presiune_arzator_valoare': FieldPosition(x: 1724.6666666667759,
          y: 2140.66666666663,
          width: 317.33333333333326,
          height: 46.666666666666515),
      'presiune_arzator_da': FieldPosition(x: 2042.666666666776,
          y: 2142.66666666663,
          width: 111.33333333333303,
          height: 46.0),
      'presiune_arzator_nu': FieldPosition(x: 2156.6666666667793,
          y: 2141.9999999999623,
          width: 110.0,
          height: 46.0),
      'presiune_arzator_na': FieldPosition(x: 2270.000000000113,
          y: 2143.3333333332957,
          width: 116.66666666666652,
          height: 45.333333333333485),

      'presiune_focar_valoare': FieldPosition(x: 1724.0000000001064,
          y: 2187.3333333332976,
          width: 317.3333333333335,
          height: 46.0),
      'presiune_focar_da': FieldPosition(x: 2042.666666666773,
          y: 2188.6666666666306,
          width: 110.0,
          height: 44.66666666666697),
      'presiune_focar_nu': FieldPosition(x: 2156.0000000001064,
          y: 2188.6666666666306,
          width: 111.33333333333348,
          height: 44.66666666666697),
      'presiune_focar_na': FieldPosition(x: 2268.666666666773,
          y: 2189.999999999964,
          width: 116.66666666666652,
          height: 44.666666666666515),

      'temperatura_gaze_arse_valoare': FieldPosition(x: 1724.0000000001064,
          y: 2232.6666666666306,
          width: 316.66666666666697,
          height: 46.0),
      'temperatura_gaze_arse_da': FieldPosition(x: 2042.6666666667734,
          y: 2233.999999999964,
          width: 110.0,
          height: 44.666666666666515),
      'temperatura_gaze_arse_nu': FieldPosition(x: 2154.6666666667734,
          y: 2233.999999999964,
          width: 112.66666666666652,
          height: 44.666666666666515),
      'temperatura_gaze_arse_na': FieldPosition(x: 2269.33333333344,
          y: 2233.999999999964,
          width: 116.0,
          height: 46.0),

      'verificare_etanseitate_gaze_arse_valoare': FieldPosition(
          x: 1724.0000000001064,
          y: 2278.6666666666306,
          width: 315.3333333333335,
          height: 46.66666666666697),
      'verificare_etanseitate_gaze_arse_da': FieldPosition(x: 2041.33333333344,
          y: 2278.6666666666306,
          width: 111.33333333333348,
          height: 46.0),
      'verificare_etanseitate_gaze_arse_nu': FieldPosition(
          x: 2154.6666666667734,
          y: 2279.999999999964,
          width: 112.66666666666652,
          height: 44.666666666666515),
      'verificare_etanseitate_gaze_arse_na': FieldPosition(x: 2268.666666666773,
          y: 2280.6666666666306,
          width: 118.0,
          height: 44.666666666666515),

      'alte_masuratori_valoare': FieldPosition(x: 1724.6666666667732,
          y: 2325.999999999964,
          width: 315.9999999999998,
          height: 44.0),
      'alte_masuratori_da': FieldPosition(x: 2042.0000000001064,
          y: 2325.999999999964,
          width: 110.0,
          height: 44.0),
      'alte_masuratori_nu': FieldPosition(x: 2155.33333333344,
          y: 2327.333333333297,
          width: 112.0,
          height: 43.333333333333485),
      'alte_masuratori_na': FieldPosition(x: 2268.666666666773,
          y: 2325.999999999964,
          width: 118.0,
          height: 46.0),

      'verificare_functii_protectie_valoare': FieldPosition(
          x: 1724.6666666667704,
          y: 2370.666666666639,
          width: 316.66666666666674,
          height: 46.0),
      'verificare_functii_protectie_da': FieldPosition(x: 2043.3333333334372,
          y: 2370.666666666639,
          width: 110.0,
          height: 47.333333333333485),
      'verificare_functii_protectie_nu': FieldPosition(x: 2154.66666666677,
          y: 2370.666666666639,
          width: 113.33333333333348,
          height: 47.333333333333485),
      'verificare_functii_protectie_na': FieldPosition(x: 2268.66666666677,
          y: 2370.666666666639,
          width: 118.00000000000045,
          height: 48.0),

      'verificare_parametru_presiune_valoare': FieldPosition(
          x: 1726.0000000001037,
          y: 2417.9999999999723,
          width: 316.0,
          height: 45.333333333333485),
      'verificare_parametru_presiune_da': FieldPosition(x: 2043.3333333334372,
          y: 2418.666666666639,
          width: 110.66666666666697,
          height: 44.66666666666697),
      'verificare_parametru_presiune_nu': FieldPosition(x: 2155.333333333437,
          y: 2418.666666666639,
          width: 112.66666666666697,
          height: 46.0),
      'verificare_parametru_presiune_na': FieldPosition(x: 2270.000000000104,
          y: 2417.9999999999723,
          width: 116.66666666666652,
          height: 48.0),

      'verificare_parametru_temperatura_valoare': FieldPosition(
          x: 1725.3333333334417,
          y: 2464.6666666666406,
          width: 314.66666666666697,
          height: 46.0),
      'verificare_parametru_temperatura_da': FieldPosition(
          x: 2042.6666666667752,
          y: 2465.999999999974,
          width: 110.0,
          height: 44.666666666666515),
      'verificare_parametru_temperatura_nu': FieldPosition(
          x: 2155.3333333334485,
          y: 2466.666666666641,
          width: 110.0,
          height: 43.33333333333303),
      'verificare_parametru_temperatura_na': FieldPosition(x: 2268.666666666782,
          y: 2465.3333333333076,
          width: 116.0,
          height: 46.0),


      /// PAGE 4 GAS ANALYSIS
      'co_masurat_valoare': FieldPosition(x: 1724.666666666781,
          y: 2510.666666666646,
          width: 316.0,
          height: 48.666666666666515),
      'co_masurat_da': FieldPosition(x: 2042.0000000001146,
          y: 2510.666666666646,
          width: 111.33333333333303,
          height: 47.33333333333303),
      'co_masurat_nu': FieldPosition(x: 2155.3333333334476,
          y: 2510.666666666646,
          width: 112.66666666666697,
          height: 48.666666666666515),
      'co_masurat_na': FieldPosition(x: 2268.6666666667816,
          y: 2511.999999999979,
          width: 119.33333333333303,
          height: 46.0),

      'o2_masurat_valoare': FieldPosition(x: 1723.3333333334494,
          y: 2557.999999999982,
          width: 318.6666666666665,
          height: 47.333333333333485),
      'o2_masurat_da': FieldPosition(x: 2042.000000000116,
          y: 2557.999999999982,
          width: 112.0,
          height: 47.333333333333485),
      'o2_masurat_nu': FieldPosition(x: 2155.3333333334494,
          y: 2556.6666666666483,
          width: 112.0,
          height: 47.333333333333485),
      'o2_masurat_na': FieldPosition(x: 2268.6666666667825,
          y: 2559.3333333333153,
          width: 118.0,
          height: 46.0),

      'no2_masurat_valoare': FieldPosition(x: 1724.6666666667825,
          y: 2602.6666666666483,
          width: 317.3333333333335,
          height: 48.0),
      'no2_masurat_da': FieldPosition(x: 2042.6666666667825,
          y: 2603.999999999982,
          width: 111.33333333333348,
          height: 46.0),
      'no2_masurat_nu': FieldPosition(x: 2155.3333333334494,
          y: 2605.3333333333153,
          width: 110.66666666666652,
          height: 45.33333333333303),
      'no2_masurat_na': FieldPosition(x: 2270.000000000116,
          y: 2605.3333333333153,
          width: 116.66666666666652,
          height: 46.666666666666515),

      'so2_masurat_valoare': FieldPosition(x: 1723.3333333334494,
          y: 2650.6666666666483,
          width: 318.6666666666665,
          height: 44.66666666666697),
      'so2_masurat_da': FieldPosition(x: 2042.000000000116,
          y: 2649.999999999982,
          width: 112.0,
          height: 45.333333333333485),
      'so2_masurat_nu': FieldPosition(x: 2155.3333333334494,
          y: 2650.6666666666483,
          width: 113.33333333333303,
          height: 44.66666666666697),
      'so2_masurat_na': FieldPosition(x: 2270.000000000116,
          y: 2650.6666666666483,
          width: 116.66666666666652,
          height: 44.66666666666697),

      'co2_procent_valoare': FieldPosition(x: 1724.666666666787,
          y: 2695.3333333333194,
          width: 318.0,
          height: 46.66666666666697),
      'co2_procent_da': FieldPosition(x: 2042.666666666787,
          y: 2695.3333333333194,
          width: 111.33333333333303,
          height: 48.0),
      'co2_procent_nu': FieldPosition(x: 2154.6666666667875,
          y: 2695.33333333332,
          width: 114.66666666666652,
          height: 47.33333333333303),
      'co2_procent_na': FieldPosition(x: 2270.6666666667875,
          y: 2695.33333333332,
          width: 116.66666666666652,
          height: 48.666666666666515),

      'exces_de_aer_valoare': FieldPosition(x: 1725.33333333345,
          y: 2741.999999999987,
          width: 317.3333333333335,
          height: 46.0),
      'exces_de_aer_da': FieldPosition(x: 2042.6666666667834,
          y: 2741.3333333333203,
          width: 111.33333333333348,
          height: 45.33333333333303),
      'exces_de_aer_nu': FieldPosition(x: 2154.6666666667834,
          y: 2741.3333333333203,
          width: 113.33333333333303,
          height: 46.666666666666515),
      'exces_de_aer_na': FieldPosition(x: 2269.3333333334504,
          y: 2741.999999999987,
          width: 116.66666666666606,
          height: 48.666666666666515),

      'eficienta_ardere_valoare': FieldPosition(x: 1725.333333333454,
          y: 2787.9999999999886,
          width: 316.0,
          height: 46.0),
      'eficienta_ardere_da': FieldPosition(x: 2042.6666666667875,
          y: 2786.666666666655,
          width: 111.33333333333348,
          height: 47.333333333333485),
      'eficienta_ardere_nu': FieldPosition(x: 2156.000000000121,
          y: 2789.3333333333217,
          width: 113.33333333333303,
          height: 44.66666666666697),
      'eficienta_ardere_na': FieldPosition(x: 2269.333333333454,
          y: 2789.3333333333217,
          width: 116.66666666666697,
          height: 44.66666666666697),

      /// PAGE 5 CONCLUSION AND SIGNATURES
      'aparat_admis': FieldPosition(x: 2155.3333333334617,
          y: 2833.9999999999927,
          width: 231.33333333333348,
          height: 49.333333333333485),
      'scadenta_verificare': FieldPosition(x: 2154.666666666807,
          y: 2881.33333333333,
          width: 232.66666666666652,
          height: 48.666666666666515),
      'nume_utilizator': FieldPosition(x: 1298.0000000001487,
          y: 2977.33333333334,
          width: 917.3333333333335,
          height: 46.0),
      'nume_personal_instruit': FieldPosition(x: 1299.3333333334822,
          y: 3023.33333333334,
          width: 916.0,
          height: 47.33333333333303),

      /// SIGNATURES
      'semnatura_instruit': FieldPosition(x: 1467.999999999996,
          y: 3069.33333333334,
          width: 308.6666666666665,
          height: 89.33333333333303),
      'semnatura_utilizator': FieldPosition(x: 1430.0000000001608,
          y: 3204.00000000002,
          width: 428.66666666666674,
          height: 172.66666666666652),
    };
  }

  void _addTextOverlay(List<pw.Widget> overlays,
      String fieldName,
      dynamic value,
      Map<String, FieldPosition> positions,
      pw.Font font,
      double scaleX,
      double scaleY, {
        bool centered = false,
        double fontSize = 8,
      }) {
    if (positions.containsKey(fieldName) && value != null && value
        .toString()
        .isNotEmpty) {
      final position = positions[fieldName]!;

      final scaledX = position.x * scaleX;
      final scaledY = position.y * scaleY;
      final scaledWidth = position.width * scaleX;
      final scaledHeight = position.height * scaleY;

      overlays.add(
        pw.Positioned(
          left: scaledX,
          top: scaledY,
          child: pw.Container(
            width: scaledWidth,
            height: scaledHeight,
            child: pw.Align(
              alignment: centered ? pw.Alignment.center : pw.Alignment
                  .centerLeft,
              child: pw.Text(
                value.toString(),
                style: pw.TextStyle(
                  font: font,
                  fontSize: fontSize,
                  color: PdfColors.black,
                ),
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
              ),
            ),
          ),
        ),
      );
    }
  }

  pw.Widget _createCheckmark(FieldPosition position, double scaleX,
      double scaleY) {
    return pw.Positioned(
      left: position.x * scaleX,
      top: position.y * scaleY,
      child: pw.SizedBox(
        width: position.width * scaleX,
        height: position.height * scaleY,
        child: pw.Center(
          child: pw.Text(
            'X',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),
      ),
    );
  }

  /// Generate official PDF for any form type
  Future<Uint8List> generateOfficialPdf({
    required ISCIRForm form,
    required Client client,
    required Map<String, dynamic> formData,
    String? specificPdfType
  }) async {
    return await _generateRaportIscirPdf(form, client, formData);
  }

  /// Helper method to decode image from bytes
  Future<ui.Image> _decodeImageFromList(Uint8List bytes) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  /// Print PDF using system printer
  Future<void> printPdf(Uint8List pdfBytes, String jobName) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: jobName,
    );
  }

  /// Share PDF using printing package
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }
}

/// Class to define field positions on the PDF template
class FieldPosition {
  final double x;
  final double y;
  final double width;
  final double height;

  FieldPosition({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}