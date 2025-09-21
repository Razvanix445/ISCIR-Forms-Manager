import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../models/client.dart';
import '../../../models/form.dart';
import '../widgets/drawing_signature_widget.dart';

class RaportIscirPage5 extends StatefulWidget {
  final Client client;
  final ISCIRForm form;
  final Map<String, TextEditingController> controllers;
  final Map<String, bool> checkboxes;
  final Map<String, String> tripleRadioSelections;
  final Map<String, Uint8List?> signatures;
  final VoidCallback onDataChanged;
  final Function(String, Uint8List?) onSignatureChanged;

  const RaportIscirPage5({
    super.key,
    required this.client,
    required this.form,
    required this.controllers,
    required this.checkboxes,
    required this.tripleRadioSelections,
    required this.signatures,
    required this.onDataChanged,
    required this.onSignatureChanged,
  });

  @override
  State<RaportIscirPage5> createState() => _RaportIscirPage5State();
}

class _RaportIscirPage5State extends State<RaportIscirPage5> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '6. CONCLUZII',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            _buildRadioGroup(
              'Aparatul îndeplinește/nu îndeplinește condițiile de funcționare conform prevederilor PT A1',
              'aparat_admis',
              ['admis', 'respins'],
              ['Admis', 'Respins'],
            ),
            const SizedBox(height: 24),

            _buildSignaturesSection(),

            const SizedBox(height: 100),
          ],
        )
    );
  }

  Widget _buildRadioGroup(String title, String key, List<String> values,
      List<String> labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...values
            .asMap()
            .entries
            .map((entry) {
          int index = entry.key;
          String value = entry.value;
          return RadioListTile<String>(
            title: Text(labels[index], style: const TextStyle(fontSize: 14)),
            value: value,
            groupValue: widget.tripleRadioSelections[key],
            onChanged: (selectedValue) {
              setState(() {
                widget.tripleRadioSelections[key] = selectedValue!;
              });
              widget.onDataChanged(); // Trigger auto-save
            },
            dense: true,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSignaturesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SEMNĂTURI',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),

            // User/Client Signature
            _buildSignatureField(
              context,
              'Deținător/Utilizator',
              'semnatura_utilizator',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureField(BuildContext context, String label, String key) {
    final existingSignature = widget.signatures[key];
    print('Building signature field for $key, has signature: ${existingSignature != null}');

    return DrawingSignatureField(
      label: label,
      signatureKey: key,
      onSignatureChanged: widget.onSignatureChanged,
      existingSignature: existingSignature,
      height: 100,
    );
  }
}