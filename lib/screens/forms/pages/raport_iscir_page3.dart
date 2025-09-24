import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _RaportIscirPage3State extends State<RaportIscirPage3> with TickerProviderStateMixin {
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
    _sectionAnimations = List.generate(3, (index) =>
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
            Colors.green.shade50.withOpacity(0.3),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // // Page title
            // Container(
            //   padding: const EdgeInsets.all(20),
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [
            //         Colors.green.withOpacity(0.1),
            //         Colors.green.withOpacity(0.05),
            //       ],
            //     ),
            //     borderRadius: BorderRadius.circular(16),
            //     border: Border.all(color: Colors.green.withOpacity(0.2)),
            //   ),
            //   child: Row(
            //     children: [
            //       Container(
            //         padding: const EdgeInsets.all(10),
            //         decoration: BoxDecoration(
            //           gradient: LinearGradient(
            //             colors: [Colors.green, Colors.green.shade600],
            //           ),
            //           borderRadius: BorderRadius.circular(10),
            //         ),
            //         child: const Icon(Icons.build, color: Colors.white, size: 20),
            //       ),
            //       const SizedBox(width: 12),
            //       const Text(
            //         '5. VERIFICĂRI FUNCȚIONALE',
            //         style: TextStyle(
            //           fontSize: 20,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.green,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 24),

            _buildAnimatedSection(
              index: 0,
              child: _buildColdVerificationsSection(),
            ),
            const SizedBox(height: 24),
            _buildAnimatedSection(
              index: 1,
              child: _buildLoadAdjustmentSection(),
            ),
            const SizedBox(height: 24),
            _buildAnimatedSection(
              index: 2,
              child: _buildHotVerificationsSection(),
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

  Widget _buildColdVerificationsSection() {
    return _buildModernCard(
      title: '5.1. VERIFICĂRI LA RECE',
      icon: Icons.ac_unit,
      iconColor: Colors.blue,
      child: Column(
        children: [
          _buildMeasurementField(
            title: 'Verificare etanșeitate',
            fieldKey: 'verificare_etanseitate',
            valueKey: 'verificare_etanseitate_valoare',
            unit: '',
            hint: 'Introduceți valoarea măsurată',
          ),

          _buildMeasurementField(
            title: '- circuitul combustibil (presiune statică în bar)',
            fieldKey: 'circuit_combustibil',
            valueKey: 'circuit_combustibil_valoare',
            unit: 'bar',
            hint: 'Introduceți valoarea măsurată',
          ),

          _buildMeasurementField(
            title: '- circuit apă (presiune de încercare/timp încercare bar/minute) (unde este cazul)',
            fieldKey: 'circuit_apa',
            valueKey: 'circuit_apa_valoare',
            unit: 'bar/min',
            hint: 'Introduceți valoarea măsurată',
          ),

          _buildMeasurementField(
            title: 'Verificare instalație electrică - tensiune în Volți',
            fieldKey: 'verificare_instalatie',
            valueKey: 'verificare_instalatie_valoare',
            unit: 'V',
            hint: 'Introduceți valoarea măsurată',
          ),

          _buildMeasurementField(
            title: 'Verificarea legării la pământ',
            fieldKey: 'verificare_legare',
            valueKey: 'verificare_legare_valoare',
            unit: 'Ω',
            hint: 'Introduceți valoarea măsurată',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadAdjustmentSection() {
    return _buildModernCard(
      title: '5.2. REGLAT SARCINA APARAT',
      icon: Icons.tune,
      iconColor: Colors.orange,
      child: Column(
        children: [
          _buildModernTripleRadio(
            title: 'Reglat sarcina aparatului',
            fieldKey: 'reglat_sarcina_aparat',
            selectedValue: widget.tripleRadioSelections['reglat_sarcina_aparat'],
            onChanged: (value) {
              setState(() {
                widget.tripleRadioSelections['reglat_sarcina_aparat'] = value!;
              });
              widget.onDataChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHotVerificationsSection() {
    return _buildModernCard(
      title: '5.3. VERIFICĂRI LA CALD',
      icon: Icons.local_fire_department,
      iconColor: Colors.red,
      child: Column(
        children: [
        // Tip Tiraj selection
        _buildModernRadioGroup(
        title: 'Tip Tiraj',
        fieldKey: 'tip_tiraj',
        values: ['natural', 'fortat'],
        labels: ['Natural', 'Forțat'],
      ),

      const SizedBox(height: 16),

      _buildMeasurementField(
        title: 'Tiraj',
        fieldKey: 'tiraj',
        valueKey: 'tiraj_valoare',
        unit: 'Pa',
        hint: 'Introduceți valoarea măsurată',
      ),

      _buildMeasurementField(
        title: 'Presiunea gazului la intrare pe rampa de gaz (mbar)',
        fieldKey: 'presiune_rampa',
        valueKey: 'presiune_rampa_valoare',
        unit: 'mbar',
        hint: 'Introduceți valoarea măsurată',
      ),

      _buildMeasurementField(
        title: 'Presiunea gazului la intrare în arzător (mbar)',
        fieldKey: 'presiune_arzator',
        valueKey: 'presiune_arzator_valoare',
        unit: 'mbar',
        hint: 'Introduceți valoarea măsurată',
      ),

      _buildMeasurementField(
        title: 'Presiunea gazului la intrare în focar (mbar)',
        fieldKey: 'presiune_focar',
        valueKey: 'presiune_focar_valoare',
        unit: 'mbar',
        hint: 'Introduceți valoarea măsurată',
      ),

      _buildMeasurementField(
        title: 'Temperatura gazelor arse (°C)',
        fieldKey: 'temperatura_gaze_arse',
        valueKey: 'temperatura_gaze_arse_valoare',
        unit: '°C',
        hint: 'Introduceți valoarea măsurată',
      ),

      _buildMeasurementField(
        title: 'Verificarea etanșeității circuitului de gaze arse',
        fieldKey: 'verificare_etanseitate_gaze_arse',
        valueKey: 'verificare_etanseitate_gaze_arse_valoare',
        unit: '',
        hint: 'Introduceți valoarea măsurată',
      ),

      _buildMeasurementField(
        title: 'Alte măsurători',
        fieldKey: 'alte_masuratori',
        valueKey: 'alte_masuratori_valoare',
        unit: '',
        hint: 'Introduceți alte măsurători',
      ),

      _buildMeasurementField(
        title: 'Verificarea funcțiilor de protecție aparat și instalații anexe',
        fieldKey: 'verificare_functii_protectie',
        valueKey: 'verificare_functii_protectie_valoare',
        unit: '',
        hint: 'Introduceți valoarea măsurată',
      ),

      const SizedBox(height: 20),

      // Parameters subsection
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
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
                      Colors.purple,
                      Colors.purple.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.thermostat, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Verificarea parametrilor realizați:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildMeasurementField(
            title: 'Presiunea agentului termic (bar)',
            fieldKey: 'verificare_parametru_presiune',
            valueKey: 'verificare_parametru_presiune_valoare',
            unit: 'bar',
            hint: 'Introduceți valoarea măsurată',
          ),

          _buildMeasurementField(
            title: 'Temperatura agentului termic (°C) tur/retur',
            fieldKey: 'verificare_parametru_temperatura',
            valueKey: 'verificare_parametru_temperatura_valoare',
            unit: '°C',
            hint: 'Introduceți valoarea măsurată',
          ),
        ],
      ),
    ),
    ],
    ),
    );
  }

  Widget _buildMeasurementField({
    required String title,
    required String fieldKey,
    required String valueKey,
    required String unit,
    required String hint,
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
              // Value input field
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: widget.controllers[valueKey],
                    keyboardType: TextInputType.number, // 🔢 NUMERIC KEYBOARD
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,/\-\s]')), // Allow numbers, decimals, slashes, spaces
                    ],
                    onChanged: (value) => widget.onDataChanged(),
                    decoration: InputDecoration(
                      hintText: hint,
                      suffixText: unit.isNotEmpty ? unit : null,
                      suffixStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.straighten,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Radio buttons
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    // DA option
                    Expanded(
                      child: _buildRadioOption(
                        label: 'DA',
                        value: 'DA',
                        selectedValue: widget.tripleRadioSelections[fieldKey],
                        onChanged: (value) {
                          setState(() {
                            widget.tripleRadioSelections[fieldKey] = value!;
                          });
                          widget.onDataChanged();
                        },
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 4),

                    // NU option
                    Expanded(
                      child: _buildRadioOption(
                        label: 'NU',
                        value: 'NU',
                        selectedValue: widget.tripleRadioSelections[fieldKey],
                        onChanged: (value) {
                          setState(() {
                            widget.tripleRadioSelections[fieldKey] = value!;
                          });
                          widget.onDataChanged();
                        },
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 4),

                    // N/A option
                    Expanded(
                      child: _buildRadioOption(
                        label: 'N/A',
                        value: 'N_A',
                        selectedValue: widget.tripleRadioSelections[fieldKey],
                        onChanged: (value) {
                          setState(() {
                            widget.tripleRadioSelections[fieldKey] = value!;
                          });
                          widget.onDataChanged();
                        },
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildModernRadioGroup({
    required String title,
    required String fieldKey,
    required List<String> values,
    required List<String> labels,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: values.asMap().entries.map((entry) {
              int index = entry.key;
              String value = entry.value;
              final isSelected = value == widget.tripleRadioSelections[fieldKey];

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: isSelected ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ) : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    ),
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    value: value,
                    groupValue: widget.tripleRadioSelections[fieldKey],
                    onChanged: (selectedValue) {
                      setState(() {
                        widget.tripleRadioSelections[fieldKey] = selectedValue!;
                      });
                      widget.onDataChanged();
                    },
                    activeColor: Colors.white,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              );
            }).toList(),
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        )
            : null,
        color: isSelected ? null : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}