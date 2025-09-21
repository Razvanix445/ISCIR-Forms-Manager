import 'package:flutter/material.dart';

import '../../models/client.dart';
import '../../models/form.dart';

class PdfSelectionDialog extends StatelessWidget {
  final ISCIRForm form;
  final Client client;
  final Map<String, dynamic> formData;

  const PdfSelectionDialog({
    super.key,
    required this.form,
    required this.client,
    required this.formData,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selectează PDF pentru Generare'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Alege ce document vrei să generezi:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),

          // Raport ISCIR Option
          Card(
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
              title: const Text(
                'Raport ISCIR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Completează raportul de verificări',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () => Navigator.pop(context, 'raport_iscir'),
            ),
          ),

          const SizedBox(height: 12),

          // Anexa 4 Option
          Card(
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.list_alt,
                  color: Colors.green,
                  size: 30,
                ),
              ),
              title: const Text(
                'Anexa 4',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Registrul de evidență a aparatelor',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () => Navigator.pop(context, 'anexa4'),
            ),
          ),

          const SizedBox(height: 20),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ambele documente folosesc aceleași date din formular.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Renunță'),
        ),
      ],
    );
  }
}