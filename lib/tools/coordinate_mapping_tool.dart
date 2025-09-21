import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:convert';

/// Simple coordinate mapping tool without problematic parameters
class SimpleCoordinateMappingTool extends StatefulWidget {
  final String templateAssetPath;
  final String formType;

  const SimpleCoordinateMappingTool({
    super.key,
    required this.templateAssetPath,
    required this.formType,
  });

  @override
  State<SimpleCoordinateMappingTool> createState() => _SimpleCoordinateMappingToolState();
}

class _SimpleCoordinateMappingToolState extends State<SimpleCoordinateMappingTool> {
  Uint8List? _templateImage;
  final List<SimpleFieldMapping> _mappedFields = [];
  String _currentFieldName = '';
  bool _isMapping = false;
  SimpleFieldMapping? _selectedField;
  double _imageScale = 1.0;
  Offset _imageOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      final ByteData data = await rootBundle.load(widget.templateAssetPath);
      setState(() {
        _templateImage = data.buffer.asUint8List();
      });
    } catch (e) {
      _showMessage('Error loading template: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map ${widget.formType} Coordinates'),
        actions: [
          IconButton(
            onPressed: _exportMappings,
            icon: const Icon(Icons.download),
            tooltip: 'Export Mappings',
          ),
          IconButton(
            onPressed: _importMappings,
            icon: const Icon(Icons.upload),
            tooltip: 'Import Mappings',
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 300,
            color: Colors.grey.shade100,
            child: _buildControlPanel(),
          ),
          Expanded(
            child: _buildImageViewer(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Field Mapping Tool',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Field',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Field Name',
                      hintText: 'e.g., client_name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => _currentFieldName = value,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _currentFieldName.isEmpty ? null : _startMapping,
                      icon: Icon(_isMapping ? Icons.stop : Icons.add),
                      label: Text(_isMapping ? 'Stop Mapping' : 'Start Mapping'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Mapped Fields (${_mappedFields.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: _mappedFields.length,
              itemBuilder: (context, index) {
                final field = _mappedFields[index];
                final isSelected = _selectedField == field;

                return Card(
                  color: isSelected ? Colors.blue.shade50 : null,
                  child: ListTile(
                    dense: true,
                    title: Text(
                      field.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      'X: ${field.x.toStringAsFixed(1)}, Y: ${field.y.toStringAsFixed(1)}\n'
                          'W: ${field.width.toStringAsFixed(1)}, H: ${field.height.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _selectField(field),
                          icon: Icon(
                            isSelected ? Icons.visibility : Icons.visibility_outlined,
                            size: 18,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _deleteField(field),
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        ),
                      ],
                    ),
                    onTap: () => _selectField(field),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '1. Enter field name\n'
                      '2. Click "Start Mapping"\n'
                      '3. Click and drag on the image to define the field area\n'
                      '4. Use zoom and pan to position precisely\n'
                      '5. Export mappings when done',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer() {
    if (_templateImage == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      color: Colors.grey.shade200,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _adjustZoom(-0.1),
                  icon: const Icon(Icons.zoom_out),
                ),
                Text('${(_imageScale * 100).toInt()}%'),
                IconButton(
                  onPressed: () => _adjustZoom(0.1),
                  icon: const Icon(Icons.zoom_in),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _resetView,
                  child: const Text('Reset View'),
                ),
                const Spacer(),
                if (_isMapping)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Mapping: $_currentFieldName',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: GestureDetector(
              onPanStart: _isMapping ? _onMapStart : _onPanStart,
              onPanUpdate: _isMapping ? _onMapUpdate : _onPanUpdate,
              onPanEnd: _isMapping ? _onMapEnd : null,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    Positioned(
                      left: _imageOffset.dx,
                      top: _imageOffset.dy,
                      child: Transform.scale(
                        scale: _imageScale,
                        child: Image.memory(_templateImage!),
                      ),
                    ),
                    ..._buildFieldOverlays(),
                    if (_isMapping && _currentMapping != null)
                      _buildCurrentMappingOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFieldOverlays() {
    return _mappedFields.map((field) {
      final isSelected = _selectedField == field;

      return Positioned(
        left: _imageOffset.dx + (field.x * _imageScale),
        top: _imageOffset.dy + (field.y * _imageScale),
        width: field.width * _imageScale,
        height: field.height * _imageScale,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.red,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: isSelected ? Colors.blue : Colors.red,
              child: Text(
                field.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildCurrentMappingOverlay() {
    if (_currentMapping == null) return const SizedBox();

    final mapping = _currentMapping!;
    return Positioned(
      left: _imageOffset.dx + (mapping.x * _imageScale),
      top: _imageOffset.dy + (mapping.y * _imageScale),
      width: mapping.width * _imageScale,
      height: mapping.height * _imageScale,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            color: Colors.green,
            child: Text(
              _currentFieldName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Mapping state
  SimpleFieldMapping? _currentMapping;
  Offset? _mappingStart;

  void _startMapping() {
    setState(() {
      _isMapping = true;
    });
  }

  void _onMapStart(DragStartDetails details) {
    _mappingStart = details.localPosition;
    _currentMapping = null;
  }

  void _onMapUpdate(DragUpdateDetails details) {
    if (_mappingStart == null) return;

    final start = _mappingStart!;
    final current = details.localPosition;

    final imageStartX = (start.dx - _imageOffset.dx) / _imageScale;
    final imageStartY = (start.dy - _imageOffset.dy) / _imageScale;
    final imageCurrentX = (current.dx - _imageOffset.dx) / _imageScale;
    final imageCurrentY = (current.dy - _imageOffset.dy) / _imageScale;

    final x = imageStartX < imageCurrentX ? imageStartX : imageCurrentX;
    final y = imageStartY < imageCurrentY ? imageStartY : imageCurrentY;
    final width = (imageStartX - imageCurrentX).abs();
    final height = (imageStartY - imageCurrentY).abs();

    setState(() {
      _currentMapping = SimpleFieldMapping(
        name: _currentFieldName,
        x: x,
        y: y,
        width: width,
        height: height,
      );
    });
  }

  void _onMapEnd(DragEndDetails details) {
    if (_currentMapping != null &&
        _currentMapping!.width > 10 &&
        _currentMapping!.height > 5) {

      setState(() {
        _mappedFields.add(_currentMapping!);
        _currentMapping = null;
        _isMapping = false;
        _currentFieldName = '';
      });

      _showSuccessMessage('Field "${_currentMapping!.name}" mapped successfully');
    } else {
      setState(() {
        _currentMapping = null;
        _isMapping = false;
      });

      _showErrorMessage('Field too small, please try again');
    }
  }

  void _onPanStart(DragStartDetails details) {
    // Store initial pan position
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _imageOffset += details.delta;
    });
  }

  void _adjustZoom(double delta) {
    setState(() {
      _imageScale = (_imageScale + delta).clamp(0.1, 3.0);
    });
  }

  void _resetView() {
    setState(() {
      _imageScale = 1.0;
      _imageOffset = Offset.zero;
    });
  }

  void _selectField(SimpleFieldMapping field) {
    setState(() {
      _selectedField = _selectedField == field ? null : field;
    });
  }

  void _deleteField(SimpleFieldMapping field) {
    setState(() {
      _mappedFields.remove(field);
      if (_selectedField == field) {
        _selectedField = null;
      }
    });
  }

  void _exportMappings() {
    final mappings = _mappedFields.map((field) => {
      'name': field.name,
      'x': field.x,
      'y': field.y,
      'width': field.width,
      'height': field.height,
    }).toList();

    final jsonString = const JsonEncoder.withIndent('  ').convert({
      'formType': widget.formType,
      'templatePath': widget.templateAssetPath,
      'mappings': mappings,
    });

    Clipboard.setData(ClipboardData(text: jsonString));
    _showSuccessMessage('Mappings copied to clipboard!');
  }

  void _importMappings() {
    showDialog(
      context: context,
      builder: (context) {
        String jsonText = '';
        return AlertDialog(
          title: const Text('Import Mappings'),
          content: TextField(
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Paste JSON mappings here...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => jsonText = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  final json = jsonDecode(jsonText);
                  final mappings = (json['mappings'] as List).map((m) =>
                      SimpleFieldMapping(
                        name: m['name'],
                        x: m['x'].toDouble(),
                        y: m['y'].toDouble(),
                        width: m['width'].toDouble(),
                        height: m['height'].toDouble(),
                      )
                  ).toList();

                  setState(() {
                    _mappedFields.clear();
                    _mappedFields.addAll(mappings);
                  });

                  Navigator.pop(context);
                  _showSuccessMessage('Mappings imported successfully!');
                } catch (e) {
                  _showErrorMessage('Error importing mappings: $e');
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }
}

class SimpleFieldMapping {
  final String name;
  final double x;
  final double y;
  final double width;
  final double height;

  SimpleFieldMapping({
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}