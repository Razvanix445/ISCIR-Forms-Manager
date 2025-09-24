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

class _RaportIscirPage2State extends State<RaportIscirPage2> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _sectionAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create animations for each section
    _sectionAnimations = List.generate(2, (index) =>
        AnimationController(
          duration: Duration(milliseconds: 800 + (index * 200)),
          vsync: this,
        )
    );

    // Start animations
    _animationController.forward();
    for (int i = 0; i < _sectionAnimations.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _sectionAnimations[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _sectionAnimations) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8FAFC),
            Colors.purple.shade50.withOpacity(0.3),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedSection(
              index: 0,
              child: _buildDocumentVerificationSection(),
            ),
            const SizedBox(height: 24),
            _buildAnimatedSection(
              index: 1,
              child: _buildWorkVerificationSection(),
            ),
            const SizedBox(height: 100), // Space for floating buttons
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _sectionAnimations[index],
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _sectionAnimations[index].value)),
          child: Opacity(
            opacity: _sectionAnimations[index].value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildDocumentVerificationSection() {
    return _buildModernCard(
      title: '3. VERIFICAREA DOCUMENTELOR',
      icon: Icons.description,
      iconColor: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Există:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 16),

          _buildModernTripleRadio(
            title: 'Instrucțiuni de instalare, montare, reglare, utilizare și întreținere furnizate de producător',
            fieldKey: 'exista_instructiuni',
            selectedValue: widget.tripleRadioSelections['exista_instructiuni'],
            onChanged: (value) {
              setState(() {
                widget.tripleRadioSelections['exista_instructiuni'] = value!;
              });
              widget.onDataChanged();
            },
          ),

          _buildModernTripleRadio(
            title: 'Declarație de conformitate pentru instalare/montare/reparare aparat',
            fieldKey: 'exista_declaratie',
            selectedValue: widget.tripleRadioSelections['exista_declaratie'],
            onChanged: (value) {
              setState(() {
                widget.tripleRadioSelections['exista_declaratie'] = value!;
              });
              widget.onDataChanged();
            },
          ),

          _buildModernTripleRadio(
            title: 'Schemă termodinamică',
            fieldKey: 'exista_schema',
            selectedValue: widget.tripleRadioSelections['exista_schema'],
            onChanged: (value) {
              setState(() {
                widget.tripleRadioSelections['exista_schema'] = value!;
              });
              widget.onDataChanged();
            },
          ),

          _buildModernTripleRadio(
            title: 'Documentație de reparare',
            fieldKey: 'exista_documentatie',
            selectedValue: widget.tripleRadioSelections['exista_documentatie'],
            onChanged: (value) {
              setState(() {
                widget.tripleRadioSelections['exista_documentatie'] = value!;
              });
              widget.onDataChanged();
            },
          ),

          _buildModernTripleRadio(
            title: 'Aviz de combustibil',
            fieldKey: 'exista_aviz',
            selectedValue: widget.tripleRadioSelections['exista_aviz'],
            onChanged: (value) {
              setState(() {
                widget.tripleRadioSelections['exista_aviz'] = value!;
              });
              widget.onDataChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkVerificationSection() {
    return _buildModernCard(
      title: '4. VERIFICAREA LUCRĂRILOR EFECTUATE',
      icon: Icons.build_circle,
      iconColor: Colors.orange,
      child: Column(
        children: [
          _buildModernTripleRadio(
            title: 'Aparatul este instalat/montat conform instrucțiunilor de instalare/montare',
            fieldKey: 'aparat_instalat',
            selectedValue: widget.tripleRadioSelections['aparat_instalat'],
            onChanged: (value) {
              setState(() {
                widget.tripleRadioSelections['aparat_instalat'] = value!;
              });
              widget.onDataChanged();
            },
          ),

          _buildModernTripleRadio(
            title: 'Aparatul este reparat conform documentației de reparare',
            fieldKey: 'aparat_reparat',
            selectedValue: widget.tripleRadioSelections['aparat_reparat'],
            onChanged: (value) {
              setState(() {
                widget.tripleRadioSelections['aparat_reparat'] = value!;
              });
              widget.onDataChanged();
            },
          ),

          const SizedBox(height: 20),

          // Connection verification subsection
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.green.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green,
                            Colors.green.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.electrical_services, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Racordări corecte:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildModernTripleRadio(
                  title: 'Gaze',
                  fieldKey: 'gaze',
                  selectedValue: widget.tripleRadioSelections['gaze'],
                  onChanged: (value) {
                    setState(() {
                      widget.tripleRadioSelections['gaze'] = value!;
                    });
                    widget.onDataChanged();
                  },
                ),

                _buildModernTripleRadio(
                  title: 'Electricitate',
                  fieldKey: 'electricitate',
                  selectedValue: widget.tripleRadioSelections['electricitate'],
                  onChanged: (value) {
                    setState(() {
                      widget.tripleRadioSelections['electricitate'] = value!;
                    });
                    widget.onDataChanged();
                  },
                ),

                _buildModernTripleRadio(
                  title: 'Apă',
                  fieldKey: 'apa',
                  selectedValue: widget.tripleRadioSelections['apa'],
                  onChanged: (value) {
                    setState(() {
                      widget.tripleRadioSelections['apa'] = value!;
                    });
                    widget.onDataChanged();
                  },
                ),

                _buildModernTripleRadio(
                  title: 'Evacuare gaze arse',
                  fieldKey: 'evacuare_gaze_arse',
                  selectedValue: widget.tripleRadioSelections['evacuare_gaze_arse'],
                  onChanged: (value) {
                    setState(() {
                      widget.tripleRadioSelections['evacuare_gaze_arse'] = value!;
                    });
                    widget.onDataChanged();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildModernTripleRadio(
            title: 'Tipul de combustibil este corespunzător categoriei aparatului',
            fieldKey: 'tip_combustibil_corespunzator',
            selectedValue: widget.tripleRadioSelections['tip_combustibil_corespunzator'],
            onChanged: (value) {
              setState(() {
                widget.tripleRadioSelections['tip_combustibil_corespunzator'] = value!;
              });
              widget.onDataChanged();
            },
          ),

          _buildModernTripleRadio(
            title: 'Asigurarea aerului de ardere prin priza de aer/tubulatura aer',
            fieldKey: 'asigurare_aer',
            selectedValue: widget.tripleRadioSelections['asigurare_aer'],
            onChanged: (value) {
              setState(() {
                widget.tripleRadioSelections['asigurare_aer'] = value!;
              });
              widget.onDataChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor,
                      iconColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildModernTripleRadio({
    required String title,
    required String fieldKey,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // DA option
              Expanded(
                child: _buildRadioOption(
                  label: 'DA',
                  value: 'DA',
                  selectedValue: selectedValue,
                  onChanged: onChanged,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),

              // NU option
              Expanded(
                child: _buildRadioOption(
                  label: 'NU',
                  value: 'NU',
                  selectedValue: selectedValue,
                  onChanged: onChanged,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),

              // N/A option
              Expanded(
                child: _buildRadioOption(
                  label: 'N/A',
                  value: 'N_A',
                  selectedValue: selectedValue,
                  onChanged: onChanged,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required String value,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    required Color color,
  }) {
    final isSelected = value == selectedValue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        )
            : null,
        color: isSelected ? null : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}