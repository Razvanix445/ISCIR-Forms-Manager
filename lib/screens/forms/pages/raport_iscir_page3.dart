import 'package:flutter/material.dart';
import 'package:iscir_forms_app/screens/forms/widgets/triple_radio_tile_with_textfield.dart';

import '../../../models/client.dart';
import '../../../models/form.dart';
import '../widgets/triple_radio_tile.dart';

class RaportIscirPage3 extends StatefulWidget {
  final Client client;
  final ISCIRForm form;
  final Map<String, TextEditingController> controllers;
  final Map<String, bool> checkboxes;
  final Map<String, String> tripleRadioSelections;
  final VoidCallback onDataChanged;

  const RaportIscirPage3({
    super.key,
    required this.client,
    required this.form,
    required this.controllers,
    required this.checkboxes,
    required this.tripleRadioSelections,
    required this.onDataChanged,
  });

  @override
  State<RaportIscirPage3> createState() => _RaportIscirPage3State();
}

class _RaportIscirPage3State extends State<RaportIscirPage3> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5. VERIFICĂRI FUNCȚIONALE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            _buildVerificariLaRece(),
            const SizedBox(height: 24),
            _buildReglatSarcinaAparat(),
            const SizedBox(height: 24),
            _buildVerificariLaCald(),
            const SizedBox(height: 100),
          ],
        )
    );
  }

  Widget _buildVerificariLaRece() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5.1. VERIFICĂRI LA RECE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'verificare_etanseitate',
                title: 'Verificare etanșeitate',
              textController: widget.controllers['verificare_etanseitate_valoare'],
              radioSelection: widget.tripleRadioSelections['verificare_etanseitate'],
              onTextChanged: (value) => widget.onDataChanged(),
              onRadioChanged: (value) {
                setState(() {
                  widget.tripleRadioSelections['verificare_etanseitate'] = value!;
                });
                widget.onDataChanged();
              }
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'circuit_combustibil',
                title: '- circuitul combustibil (presiune statică în bar)',
                textController: widget.controllers['circuit_combustibil_valoare'],
                radioSelection: widget.tripleRadioSelections['circuit_combustibil'],
                onTextChanged: (value) => widget.onDataChanged(),
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['circuit_combustibil'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'circuit_apa',
                title: '- circuit apă (presiune de încercare/timp încercare bar/minute) (unde este cazul)',
                textController: widget.controllers['circuit_apa_valoare'],
                radioSelection: widget.tripleRadioSelections['circuit_apa'],
                onTextChanged: (value) => widget.onDataChanged(),
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['circuit_apa'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'verificare_instalatie',
                title: 'Verificare instalație electrică - tensiune în Volți',
                textController: widget.controllers['verificare_instalatie_valoare'],
                radioSelection: widget.tripleRadioSelections['verificare_instalatie'],
                onTextChanged: (value) => widget.onDataChanged(),
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['verificare_instalatie'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'verificare_legare',
                title: 'Verificarea legării la pământ',
                textController: widget.controllers['verificare_legare_valoare'],
                radioSelection: widget.tripleRadioSelections['verificare_legare'],
                onTextChanged: (value) => widget.onDataChanged(),
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['verificare_legare'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildReglatSarcinaAparat() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5.2. REGLAT SARCINA APARAT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),

            TripleRadioTile(fieldKey: 'reglat_sarcina_aparat',
                title: 'Reglat sarcina aparatului',
                radioSelection: widget.tripleRadioSelections['reglat_sarcina_aparat'],
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['reglat_sarcina_aparat'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificariLaCald() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5.2. VERIFICĂRI LA CALD',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),

            _buildRadioGroup(
              'Tip Tiraj',
              'tip_tiraj',
              ['natural', 'fortat'],
              ['Natural', 'Forțat'],
            ),

            TripleRadioTileWithTextfield(fieldKey: 'tiraj',
                title: 'Tiraj',
                textController: widget.controllers['tiraj_valoare'],
                radioSelection: widget.tripleRadioSelections['tiraj'],
                onTextChanged: (value) => widget.onDataChanged(),
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['tiraj'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'presiune_rampa',
                title: 'Presiunea gazului la intrare pe rampa de gaz (mbar)',
                textController: widget.controllers['presiune_rampa_valoare'],
                radioSelection: widget.tripleRadioSelections['presiune_rampa'],
                onTextChanged: (value) => widget.onDataChanged(),
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['presiune_rampa'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'presiune_arzator',
                title: 'Presiunea gazului la intrare în arzător (mbar)',
                textController: widget.controllers['presiune_arzator_valoare'],
                radioSelection: widget.tripleRadioSelections['presiune_arzator'],
                onTextChanged: (value) => widget.onDataChanged(),
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['presiune_arzator'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'presiune_focar',
                title: 'Presiunea gazului la intrare în focar (mbar)',
                textController: widget.controllers['presiune_focar_valoare'],
                radioSelection: widget.tripleRadioSelections['presiune_focar'],
                onTextChanged: (value) => widget.onDataChanged(),
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['presiune_focar'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'temperatura_gaze_arse',
                title: 'Temperatura gazelor arse (°C)',
                textController: widget.controllers['temperatura_gaze_arse_valoare'],
                radioSelection: widget.tripleRadioSelections['temperatura_gaze_arse'],
                onTextChanged: (value) => widget.onDataChanged(),
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['temperatura_gaze_arse'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'verificare_etanseitate_gaze_arse',
                title: 'Verificarea etanșeității circuitului de gaze arse',
                textController: widget.controllers['verificare_etanseitate_gaze_arse_valoare'],
                radioSelection: widget.tripleRadioSelections['verificare_etanseitate_gaze_arse'],
                onTextChanged: (value) => widget.onDataChanged(),
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['verificare_etanseitate_gaze_arse'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'alte_masuratori',
                title: 'Alte măsurători',
                textController: widget.controllers['alte_masuratori_valoare'],
                radioSelection: widget.tripleRadioSelections['alte_masuratori'],
                onTextChanged: (value) => widget.onDataChanged(),
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['alte_masuratori'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTileWithTextfield(fieldKey: 'verificare_functii_protectie',
                title: 'Verificarea funcțiilor de protecție aparat și instalații anexe',
                textController: widget.controllers['verificare_functii_protectie_valoare'],
                radioSelection: widget.tripleRadioSelections['verificare_functii_protectie'],
                onTextChanged: (value) => widget.onDataChanged(),
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['verificare_functii_protectie'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'Verificarea parametrilor realizați:',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TripleRadioTileWithTextfield(fieldKey: 'verificare_parametru_presiune',
                          title: 'Presiunea agentului termic (bar)',
                          textController: widget.controllers['verificare_parametru_presiune_valoare'],
                          radioSelection: widget.tripleRadioSelections['verificare_parametru_presiune'],
                          onTextChanged: (value) => widget.onDataChanged(),
                          onRadioChanged: (value) {
                            setState(() {
                              widget.tripleRadioSelections['verificare_parametru_presiune'] = value!;
                            });
                            widget.onDataChanged();
                          }
                      ),
                      const SizedBox(height: 12),
                      TripleRadioTileWithTextfield(fieldKey: 'verificare_parametru_temperatura',
                          title: 'Temperatura agentului termic (°C) tur/retur',
                          textController: widget.controllers['verificare_parametru_temperatura_valoare'],
                          radioSelection: widget.tripleRadioSelections['verificare_parametru_temperatura'],
                          onTextChanged: (value) => widget.onDataChanged(),
                          onRadioChanged: (value) {
                            setState(() {
                              widget.tripleRadioSelections['verificare_parametru_temperatura'] = value!;
                            });
                            widget.onDataChanged();
                          }
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioGroup(String title, String key, List<String> values, List<String> labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...values.asMap().entries.map((entry) {
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
}