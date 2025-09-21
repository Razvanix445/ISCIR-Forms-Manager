import 'package:flutter/material.dart';
import '../tools/coordinate_mapping_tool.dart';

class CoordinateMappingScreen extends StatelessWidget {
  const CoordinateMappingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Coordinate Mapping'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PDF Template Coordinate Mapping',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Use this tool to map form fields to their positions on the PDF template.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimpleCoordinateMappingTool(
                      // templateAssetPath: 'assets/templates/raport_iscir.png',
                      templateAssetPath: 'assets/templates/anexa4_template.png',
                      formType: 'Raport ISCIR',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Map Raport ISCIR Coordinates'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text('1. Click the button above to open the mapping tool'),
                  Text('2. Enter field names (like "client_name", "producator", etc.)'),
                  Text('3. Click "Start Mapping" and drag rectangles over form fields'),
                  Text('4. Use zoom/pan to position precisely'),
                  Text('5. Export the coordinates when done'),
                  Text('6. Copy the JSON output to use in your PDF generator'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}