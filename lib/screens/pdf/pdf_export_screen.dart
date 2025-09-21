import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/form.dart';
import '../../models/client.dart';
import '../../services/pdf_generation_service.dart';

class PdfExportScreen extends StatefulWidget {
  final ISCIRForm form;
  final Client client;
  final Map<String, dynamic> formData;
  final String selectedPdfType;

  const PdfExportScreen({
    super.key,
    required this.form,
    required this.client,
    required this.formData,
    this.selectedPdfType = 'raport_iscir',
  });

  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  Uint8List? _currentPdfBytes;
  bool _isGenerating = false;
  String _currentFileName = '';

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Export ${_getPdfDisplayName(widget.selectedPdfType)}'),
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        actions: [
          if (_currentPdfBytes != null) ...[
            IconButton(
              onPressed: _regeneratePdf,
              icon: const Icon(Icons.refresh),
              tooltip: 'Regenerează PDF',
            ),
            // Quick switch button
            IconButton(
              onPressed: _quickSwitchPdf,
              icon: Icon(
                widget.selectedPdfType == 'raport_iscir'
                    ? Icons.list_alt
                    : Icons.assignment,
              ),
              tooltip: 'Schimbă cu ${widget.selectedPdfType == 'raport_iscir'
                  ? 'Anexa 4'
                  : 'Raport ISCIR'}',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // PDF Type indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getPdfColor(widget.selectedPdfType).withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: _getPdfColor(widget.selectedPdfType).withOpacity(0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getPdfIcon(widget.selectedPdfType),
                      color: _getPdfColor(widget.selectedPdfType),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPdfDisplayName(widget.selectedPdfType),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getPdfColor(widget.selectedPdfType),
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            _getPdfDescription(widget.selectedPdfType),
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // PDF Preview
              Expanded(
                child: _buildPdfPreview(),
              ),
            ],
          ),

          if (_currentPdfBytes != null) _buildFloatingActionButtons(),
        ],
      ),

      floatingActionButton: null,
    );
  }

  void _quickSwitchPdf() {
    final newType = widget.selectedPdfType == 'raport_iscir'
        ? 'anexa4'
        : 'raport_iscir';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PdfExportScreen(
              form: widget.form,
              client: widget.client,
              formData: widget.formData,
              selectedPdfType: newType,
            ),
      ),
    );
  }

  // Helper methods for PDF type information
  String _getPdfDisplayName(String pdfType) {
    switch (pdfType) {
      case 'raport_iscir':
        return 'Raport ISCIR';
      case 'anexa4':
        return 'Anexa 4';
      default:
        return 'PDF Document';
    }
  }

  String _getPdfDescription(String pdfType) {
    switch (pdfType) {
      case 'raport_iscir':
        return 'Raport de verificări';
      case 'anexa4':
        return 'Registru de evidență a aparatelor';
      default:
        return 'Document PDF';
    }
  }

  IconData _getPdfIcon(String pdfType) {
    switch (pdfType) {
      case 'raport_iscir':
        return Icons.assignment;
      case 'anexa4':
        return Icons.list_alt;
      default:
        return Icons.description;
    }
  }

  Color _getPdfColor(String pdfType) {
    switch (pdfType) {
      case 'raport_iscir':
        return Colors.blue;
      case 'anexa4':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPdfPreview() {
    if (_isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _getPdfColor(widget.selectedPdfType),
            ),
            const SizedBox(height: 16),
            Text('Se generează ${_getPdfDisplayName(widget.selectedPdfType)}...'),
            const SizedBox(height: 8),
            const Text(
              'Se folosesc datele preexistente din formular.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_currentPdfBytes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Failed to generate ${_getPdfDisplayName(
                widget.selectedPdfType)}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _regeneratePdf,
              child: const Text('Reîncearcă'),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: PdfPreview(
          build: (format) => _currentPdfBytes!,
          allowSharing: false,
          allowPrinting: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          useActions: false,
          maxPageWidth: 700,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Share button
          FloatingActionButton(
            heroTag: "share_button",
            onPressed: _sharePdf,
            backgroundColor: Colors.purple,
            child: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Partajează PDF',
          ),

          const SizedBox(height: 12),

          // Print button
          FloatingActionButton(
            heroTag: "print_button",
            onPressed: _printPdf,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Imprimă PDF',
          ),

          const SizedBox(height: 12),

          // Switch PDF type button
          FloatingActionButton(
            heroTag: "switch_button",
            onPressed: _quickSwitchPdf,
            backgroundColor: _getPdfColor(widget.selectedPdfType),
            child: Icon(
              widget.selectedPdfType == 'raport_iscir' ? Icons.list_alt : Icons.assignment,
              color: Colors.white,
            ),
            tooltip: 'Generează ${widget.selectedPdfType == 'raport_iscir' ? 'Anexa 4' : 'Anexa 3'}',
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGenerating = true;
      _currentPdfBytes = null;
    });

    try {
      print('Starting PDF generation for ${widget.selectedPdfType}...');
      print('Form data keys: ${widget.formData.keys.toList()}');
      print('Client: ${widget.client.name}');

      final pdfService = SimplePdfGenerationService.instance;

      final pdfBytes = await pdfService.generateOfficialPdf(
        form: widget.form,
        client: widget.client,
        formData: widget.formData,
        specificPdfType: widget.selectedPdfType,
      );

      // Generate filename based on PDF type
      _currentFileName = _generateSafeFileName();

      setState(() {
        _currentPdfBytes = pdfBytes;
        _isGenerating = false;
      });
    } catch (e) {
      print('Error generating PDF: $e');
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _generateSafeFileName() {
    final pdfTypeName = widget.selectedPdfType.replaceAll('_', '');
    final clientName = widget.client.name.replaceAll(' ', '_').replaceAll(
        '/', '_');
    final reportNumber = widget.form.reportNumber.replaceAll('/', '_');
    final dateStr = DateTime.now().toIso8601String().split('T')[0];

    return '${pdfTypeName}_${clientName}_${reportNumber}_$dateStr.pdf';
  }

  Future<void> _regeneratePdf() async {
    await _generatePdf();
  }

  Future<void> _sharePdf() async {
    try {
      final pdfService = SimplePdfGenerationService.instance;
      await pdfService.sharePdf(_currentPdfBytes!, _currentFileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    if (_currentPdfBytes == null) return;

    try {
      final pdfService = SimplePdfGenerationService.instance;
      await pdfService.printPdf(
        _currentPdfBytes!,
        '${widget.client.firstName}_${widget.client.lastName}_${_getPdfDisplayName(widget.selectedPdfType)}_No.${widget.form.reportNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

extension FormExportExtension on State {
  void navigateToPdfExport({
    required ISCIRForm form,
    required Client client,
    required Map<String, dynamic> formData,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfExportScreen(
          form: form,
          client: client,
          formData: formData,
        ),
      ),
    );
  }
}