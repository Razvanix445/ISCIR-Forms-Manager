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

class _PdfExportScreenState extends State<PdfExportScreen> with TickerProviderStateMixin {
  Uint8List? _currentPdfBytes;
  bool _isGenerating = false;
  String _currentFileName = '';

  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generatePdf();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8FAFC),
              _getPdfColor(widget.selectedPdfType).withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildModernHeader(),
            Expanded(
              child: _buildPdfContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: _buildFloatingActions(),
          );
        },
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getPdfColor(widget.selectedPdfType),
            _getPdfColor(widget.selectedPdfType).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getPdfColor(widget.selectedPdfType).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Înapoi',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export ${_getPdfDisplayName(widget.selectedPdfType)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.client.name} - ${widget.form.reportNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfContent() {
    return _buildPdfPreview();
  }

  Widget _buildPdfPreview() {
    if (_isGenerating) {
      return Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getPdfColor(widget.selectedPdfType).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getPdfColor(widget.selectedPdfType),
                ),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Se generează ${_getPdfDisplayName(widget.selectedPdfType)}...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _getPdfColor(widget.selectedPdfType),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Se folosesc datele din formular pentru generarea documentului',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_currentPdfBytes == null) {
      return Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Eroare la generarea ${_getPdfDisplayName(widget.selectedPdfType)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _regeneratePdf,
              icon: const Icon(Icons.refresh),
              label: const Text('Încearcă din nou'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_fabAnimationController.isCompleted) {
      _fabAnimationController.forward();
    }

    return Container(
      color: Colors.white,
      child: InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 0.8,
        maxScale: 4.0,
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

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFAB(
          icon: Icons.download,
          color: Colors.blue,
          onPressed: _downloadPdf,
          tooltip: 'Descarcă',
          delay: 0,
        ),
        const SizedBox(height: 12),
        _buildFAB(
          icon: Icons.share,
          color: Colors.green,
          onPressed: _sharePdf,
          tooltip: 'Partajează',
          delay: 100,
        ),
        const SizedBox(height: 12),
        _buildFAB(
          icon: Icons.print,
          color: Colors.purple,
          onPressed: _printPdf,
          tooltip: 'Imprimă',
          delay: 200,
        ),
      ],
    );
  }

  Widget _buildFAB({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: FloatingActionButton(
            heroTag: tooltip,
            onPressed: onPressed,
            backgroundColor: color,
            tooltip: tooltip,
            child: Icon(icon, color: Colors.white),
          ),
        );
      },
    );
  }

  String _getPdfDisplayName(String pdfType) {
    return 'Raport ISCIR';
  }

  Color _getPdfColor(String pdfType) {
    return Colors.blue;
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGenerating = true;
      _currentPdfBytes = null;
    });

    _animationController.forward();

    try {
      final pdfService = SimplePdfGenerationService.instance;
      final pdfBytes = await pdfService.generateOfficialPdf(
        form: widget.form,
        client: widget.client,
        formData: widget.formData,
        specificPdfType: 'raport_iscir',
      );

      _currentFileName = _generateSafeFileName();

      setState(() {
        _currentPdfBytes = pdfBytes;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      _showErrorSnackBar('Eroare la generarea PDF: $e');
    }
  }

  String _generateSafeFileName() {
    final clientName = widget.client.name.replaceAll(' ', '_').replaceAll('/', '_');
    final reportNumber = widget.form.reportNumber.replaceAll('/', '_');
    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    return 'RaportISCIR_${clientName}_${reportNumber}_$dateStr.pdf';
  }

  Future<void> _regeneratePdf() async {
    await _generatePdf();
  }

  Future<void> _sharePdf() async {
    try {
      final pdfService = SimplePdfGenerationService.instance;
      await pdfService.sharePdf(_currentPdfBytes!, _currentFileName);
    } catch (e) {
      _showErrorSnackBar('Eroare la partajarea PDF: $e');
    }
  }

  Future<void> _printPdf() async {
    if (_currentPdfBytes == null) return;
    try {
      final pdfService = SimplePdfGenerationService.instance;
      await pdfService.printPdf(_currentPdfBytes!, _currentFileName);
    } catch (e) {
      _showErrorSnackBar('Eroare la imprimare: $e');
    }
  }

  Future<void> _downloadPdf() async {
    if (_currentPdfBytes == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Se salveaza PDF...'),
            ],
          ),
        ),
      ),
    );

    try {
      final pdfService = SimplePdfGenerationService.instance;
      await pdfService.savePdfToDevice(_currentPdfBytes!, _currentFileName);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success message with file location
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('PDF salvat in folderul Download!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      _showErrorSnackBar('Eroare la salvarea PDF: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}