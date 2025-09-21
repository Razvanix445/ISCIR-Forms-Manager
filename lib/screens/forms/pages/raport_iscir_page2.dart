import 'package:flutter/material.dart';

import '../../../models/client.dart';
import '../../../models/form.dart';
import '../widgets/triple_radio_tile.dart';

class RaportIscirPage2 extends StatefulWidget {
  final Client client;
  final ISCIRForm form;
  final Map<String, TextEditingController> controllers;
  final Map<String, bool> checkboxes;
  final Map<String, String> tripleRadioSelections;
  final VoidCallback onDataChanged;

  const RaportIscirPage2({
    super.key,
    required this.client,
    required this.form,
    required this.controllers,
    required this.checkboxes,
    required this.tripleRadioSelections,
    required this.onDataChanged,
  });

  @override
  State<RaportIscirPage2> createState() => _RaportIscirPage2State();
}

class _RaportIscirPage2State extends State<RaportIscirPage2> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripleRadioSection3(),
            const SizedBox(height: 24),
            _buildTripleRadioSection4(),
            const SizedBox(height: 100),
          ],
        )
    );
  }

  Widget _buildTripleRadioSection3() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3. VERIFICAREA DOCUMENTELOR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Există:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),

            TripleRadioTile(fieldKey: 'exista_instructiuni',
                title: 'Instrucțiuni de instalare, montare, reglare, utilizare și întreținere furnizate de producător',
                radioSelection: widget.tripleRadioSelections['exista_instructiuni'],
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['exista_instructiuni'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTile(fieldKey: 'exista_declaratie',
                title: 'Declarație de conformitate pentru instalare/montare/reparare aparat',
                radioSelection: widget.tripleRadioSelections['exista_declaratie'],
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['exista_declaratie'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTile(fieldKey: 'exista_schema',
                title: 'Schema termodinamică',
                radioSelection: widget.tripleRadioSelections['exista_schema'],
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['exista_schema'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTile(fieldKey: 'exista_documentatie',
                title: 'Documentație de reparare',
                radioSelection: widget.tripleRadioSelections['exista_documentatie'],
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['exista_documentatie'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTile(fieldKey: 'exista_aviz',
                title: 'Aviz de combustibil',
                radioSelection: widget.tripleRadioSelections['exista_aviz'],
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['exista_aviz'] = value!;
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

  Widget _buildTripleRadioSection4() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '4. VERIFICAREA LUCRĂRILOR EFECTUATE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            TripleRadioTile(fieldKey: 'aparat_instalat',
                title: 'Aparatul este instalat/montat conform instrucțiunilor de instalare/montare',
                radioSelection: widget.tripleRadioSelections['aparat_instalat'],
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['aparat_instalat'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTile(fieldKey: 'aparat_reparat',
                title: 'Aparatul este reparat conform documentației de reparare',
                radioSelection: widget.tripleRadioSelections['aparat_reparat'],
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['aparat_reparat'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'Racordări corecte:',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 16,
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

                      TripleRadioTile(fieldKey: 'gaze',
                          title: 'gaze',
                          radioSelection: widget.tripleRadioSelections['gaze'],
                          onRadioChanged: (value) {
                            setState(() {
                              widget.tripleRadioSelections['gaze'] = value!;
                            });
                            widget.onDataChanged();
                          }
                      ),
                      const SizedBox(height: 12),

                      TripleRadioTile(fieldKey: 'electricitate',
                          title: 'electricitate',
                          radioSelection: widget.tripleRadioSelections['electricitate'],
                          onRadioChanged: (value) {
                            setState(() {
                              widget.tripleRadioSelections['electricitate'] = value!;
                            });
                            widget.onDataChanged();
                          }
                      ),
                      const SizedBox(height: 12),

                      TripleRadioTile(fieldKey: 'apa',
                          title: 'apa',
                          radioSelection: widget.tripleRadioSelections['apa'],
                          onRadioChanged: (value) {
                            setState(() {
                              widget.tripleRadioSelections['apa'] = value!;
                            });
                            widget.onDataChanged();
                          }
                      ),
                      const SizedBox(height: 12),

                      TripleRadioTile(fieldKey: 'evacuare_gaze_arse',
                          title: 'evacuare gaze arse',
                          radioSelection: widget.tripleRadioSelections['evacuare_gaze_arse'],
                          onRadioChanged: (value) {
                            setState(() {
                              widget.tripleRadioSelections['evacuare_gaze_arse'] = value!;
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

            TripleRadioTile(fieldKey: 'tip_combustibil_corespunzator',
                title: 'Tipul de combustibil este corespunzător categoriei aparatului',
                radioSelection: widget.tripleRadioSelections['tip_combustibil_corespunzator'],
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['tip_combustibil_corespunzator'] = value!;
                  });
                  widget.onDataChanged();
                }
            ),
            const SizedBox(height: 12),

            TripleRadioTile(fieldKey: 'asigurare_aer',
                title: 'Asigurarea aerului de ardere prin priza de aer/tubulatura aer',
                radioSelection: widget.tripleRadioSelections['asigurare_aer'],
                onRadioChanged: (value) {
                  setState(() {
                    widget.tripleRadioSelections['asigurare_aer'] = value!;
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
}