import 'package:flutter/material.dart';

import '../../../models/client.dart';
import '../../../models/form.dart';
import '../widgets/triple_radio_tile_with_textfield.dart';

class RaportIscirPage4 extends StatefulWidget {
  final Client client;
  final ISCIRForm form;
  final Map<String, TextEditingController> controllers;
  final Map<String, bool> checkboxes;
  final Map<String, String> tripleRadioSelections;
  final VoidCallback onDataChanged;

  const RaportIscirPage4({
    super.key,
    required this.client,
    required this.form,
    required this.controllers,
    required this.checkboxes,
    required this.tripleRadioSelections,
    required this.onDataChanged,
  });

  @override
  State<RaportIscirPage4> createState() => _RaportIscirPage4State();
}

class _RaportIscirPage4State extends State<RaportIscirPage4> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analiza gazelor arse',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            _buildAnalizaGazelorArse(),
            const SizedBox(height: 100),
          ],
        )
    );
  }

  Widget _buildAnalizaGazelorArse() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TripleRadioTileWithTextfield(fieldKey: 'co_masurat',
              title: 'CO măsurat (ppm) (val. limită 100mg/Nmc)',
              textController: widget.controllers['co_masurat_valoare'],
              radioSelection: widget.tripleRadioSelections['co_masurat'],
              onTextChanged: (value) => widget.onDataChanged(),
              onRadioChanged: (value) {
                setState(() {
                  widget.tripleRadioSelections['co_masurat'] = value!;
                });
                widget.onDataChanged();
              }),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'o2_masurat',
              title: 'O2 măsurat %',
              textController: widget.controllers['o2_masurat_valoare'],
              radioSelection: widget.tripleRadioSelections['o2_masurat'],
              onTextChanged: (value) => widget.onDataChanged(),
              onRadioChanged: (value) {
                setState(() {
                  widget.tripleRadioSelections['o2_masurat'] = value!;
                });
                widget.onDataChanged();
              }),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(
              fieldKey: 'no2_masurat',
              title: 'NO2(X) măsurat (ppm) (val. limită 350mg/Nmc)',
              textController: widget.controllers['no2_masurat_valoare'],
              radioSelection: widget.tripleRadioSelections['no2_masurat'],
              onTextChanged: (value) => widget.onDataChanged(),
              onRadioChanged: (value) {
                setState(() {
                  widget.tripleRadioSelections['no2_masurat'] = value!;
                });
                widget.onDataChanged();
              },
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(
              fieldKey: 'so2_masurat',
              title: 'SO2(X) măsurat (ppm) (val. limită 35mg/Nmc)',
              textController: widget.controllers['so2_masurat_valoare'],
              radioSelection: widget.tripleRadioSelections['so2_masurat'],
              onTextChanged: (value) => widget.onDataChanged(),
              onRadioChanged: (value) {
                setState(() {
                  widget.tripleRadioSelections['so2_masurat'] = value!;
                });
                widget.onDataChanged();
              },
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(
              fieldKey: 'co2_procent',
              title: 'CO2 %',
              textController: widget.controllers['co2_procent_valoare'],
              radioSelection: widget.tripleRadioSelections['co2_procent'],
              onTextChanged: (value) => widget.onDataChanged(),
              onRadioChanged: (value) {
                setState(() {
                  widget.tripleRadioSelections['co2_procent'] = value!;
                });
                widget.onDataChanged();
              },
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(
              fieldKey: 'exces_de_aer',
              title: 'Exces de aer',
              textController: widget.controllers['exces_de_aer_valoare'],
              radioSelection: widget.tripleRadioSelections['exces_de_aer'],
              onTextChanged: (value) => widget.onDataChanged(),
              onRadioChanged: (value) {
                setState(() {
                  widget.tripleRadioSelections['exces_de_aer'] = value!;
                });
                widget.onDataChanged();
              },
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(
              fieldKey: 'eficienta_ardere',
              title: 'Eficiență ardere %',
              textController: widget.controllers['eficienta_ardere_valoare'],
              radioSelection: widget.tripleRadioSelections['eficienta_ardere'],
              onTextChanged: (value) => widget.onDataChanged(),
              onRadioChanged: (value) {
                setState(() {
                  widget.tripleRadioSelections['eficienta_ardere'] = value!;
                });
                widget.onDataChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
