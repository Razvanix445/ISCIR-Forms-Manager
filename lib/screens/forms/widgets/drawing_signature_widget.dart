import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingSignatureWidget extends StatefulWidget {
  final String title;
  final Function(Uint8List?) onSignatureSaved;

  const DrawingSignatureWidget({
    super.key,
    required this.title,
    required this.onSignatureSaved,
  });

  @override
  State<DrawingSignatureWidget> createState() => _DrawingSignatureWidgetState();
}

class _DrawingSignatureWidgetState extends State<DrawingSignatureWidget> {
  final GlobalKey _signatureKey = GlobalKey();
  List<Offset?> _points = <Offset?>[];
  bool _isEmpty = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _clearSignature,
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Draw your signature below with your finger',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: RepaintBoundary(
                key: _signatureKey,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                  ),
                  child: Listener(
                    onPointerDown: (PointerDownEvent event) {
                      final RenderBox renderBox = _signatureKey.currentContext!.findRenderObject() as RenderBox;
                      final localPosition = renderBox.globalToLocal(event.position);
                      setState(() {
                        _points.add(localPosition);
                        _isEmpty = false;
                      });
                    },
                    onPointerMove: (PointerMoveEvent event) {
                      final RenderBox renderBox = _signatureKey.currentContext!.findRenderObject() as RenderBox;
                      final localPosition = renderBox.globalToLocal(event.position);
                      setState(() {
                        _points.add(localPosition);
                      });
                    },
                    onPointerUp: (PointerUpEvent event) {
                      setState(() {
                        _points.add(null); // Mark end of stroke
                      });
                    },
                    child: CustomPaint(
                      painter: SignaturePainter(_points),
                      size: Size.infinite,
                      child: Container(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearSignature,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isEmpty ? null : _saveSignature,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Signature'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
      _isEmpty = true;
    });
  }

  Future<void> _saveSignature() async {
    if (_isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw your signature before saving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving signature...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Convert signature to image
      RenderRepaintBoundary boundary = _signatureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? signature = byteData?.buffer.asUint8List();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (signature != null && mounted) {
        widget.onSignatureSaved(signature);
        Navigator.of(context).pop(signature);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving signature: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Updated SignatureField component
class DrawingSignatureField extends StatefulWidget {
  final String label;
  final String signatureKey;
  final Function(String, Uint8List?) onSignatureChanged;
  final Uint8List? existingSignature;
  final double height;

  const DrawingSignatureField({
    super.key,
    required this.label,
    required this.signatureKey,
    required this.onSignatureChanged,
    this.existingSignature,
    this.height = 120,
  });

  @override
  State<DrawingSignatureField> createState() => _DrawingSignatureFieldState();
}

class _DrawingSignatureFieldState extends State<DrawingSignatureField> {
  Uint8List? _currentSignature;

  @override
  void initState() {
    super.initState();
    _currentSignature = widget.existingSignature;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],

        GestureDetector(
          onTap: _openSignaturePad,
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: _currentSignature != null
                    ? Colors.green.shade300
                    : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: _currentSignature != null
                  ? Colors.green.shade50
                  : Colors.grey.shade50,
            ),
            child: Stack(
              children: [
                if (_currentSignature != null)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: Image.memory(
                      _currentSignature!,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Colors.grey,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap to Sign',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_currentSignature != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _clearSignature,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSignaturePad() async {
    print('Opening signature pad for key: ${widget.signatureKey}');

    final result = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (context) => DrawingSignatureWidget(
          title: widget.label.isNotEmpty ? widget.label : 'Signature',
          onSignatureSaved: (signature) {
            print('Signature saved callback triggered');
          },
        ),
      ),
    );

    print('Signature pad returned result: ${result != null}');

    if (result != null) {
      print('Calling onSignatureChanged with key: ${widget.signatureKey}');
      setState(() {
        _currentSignature = result;
      });
      widget.onSignatureChanged(widget.signatureKey, result);
    }
  }

  void _clearSignature() {
    setState(() {
      _currentSignature = null;
    });
    widget.onSignatureChanged(widget.signatureKey, null);
  }
}