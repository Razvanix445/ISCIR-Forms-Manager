import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _RaportIscirPage4State extends State<RaportIscirPage4> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _sectionAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _sectionAnimations = List.generate(2, (index) =>
        AnimationController(
          duration: Duration(milliseconds: 800 + (index * 200)),
          vsync: this,
        )
    );

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
            Colors.teal.shade50.withOpacity(0.3),
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
              child: _buildGasAnalysisSection(),
            ),
            const SizedBox(height: 100),
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

  Widget _buildGasAnalysisSection() {
    return _buildModernCard(
      title: 'VI. ANALIZĂ GAZE ARSE',
      icon: Icons.science,
      iconColor: Colors.teal,
      child: Column(
        children: [
          _buildMeasurementFieldWithRadio(
            title: 'CO măsurat',
            fieldKey: 'co_masurat',
            valueKey: 'co_masurat_valoare',
            unit: 'ppm',
            hint: 'Introduceți valoarea măsurată',
          ),

          _buildMeasurementFieldWithRadio(
            title: 'O₂ măsurat',
            fieldKey: 'o2_masurat',
            valueKey: 'o2_masurat_valoare',
            unit: '%',
            hint: 'Introduceți valoarea măsurată',
          ),

          _buildMeasurementFieldWithRadio(
            title: 'NO₂/NO măsurat',
            fieldKey: 'no2_masurat',
            valueKey: 'no2_masurat_valoare',
            unit: 'ppm',
            hint: 'Introduceți valoarea măsurată',
          ),

          _buildMeasurementFieldWithRadio(
            title: 'SO₂/SO măsurat',
            fieldKey: 'so2_masurat',
            valueKey: 'so2_masurat_valoare',
            unit: 'ppm',
            hint: 'Introduceți valoarea măsurată',
          ),

          _buildMeasurementFieldWithRadio(
            title: 'CO₂ procent',
            fieldKey: 'co2_procent',
            valueKey: 'co2_procent_valoare',
            unit: '%',
            hint: 'Introduceți valoarea măsurată',
          ),

          _buildMeasurementFieldWithRadio(
            title: 'Exces de aer',
            fieldKey: 'exces_de_aer',
            valueKey: 'exces_de_aer_valoare',
            unit: '',
            hint: 'Introduceți valoarea măsurată',
          ),

          _buildMeasurementFieldWithRadio(
            title: 'Eficiența arderii',
            fieldKey: 'eficienta_ardere',
            valueKey: 'eficienta_ardere_valoare',
            unit: '%',
            hint: 'Introduceți valoarea măsurată',
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementFieldWithRadio({
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
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
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
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Text field on the left
              Expanded(
                flex: 2,
                child: TextField(
                  controller: widget.controllers[valueKey],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
              const SizedBox(width: 16),
              // Radio buttons on the right
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildRadioOption(label: 'DA', value: 'DA', selectedValue: widget.tripleRadioSelections[fieldKey],
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
                    Expanded(
                      child: _buildRadioOption(label: 'NU',
                        value: 'NU',
                        selectedValue: widget.tripleRadioSelections[fieldKey],
                        onChanged: (value) {
                          setState(() {
                            widget.tripleRadioSelections[fieldKey] = value!;
                          });
                          widget.onDataChanged();
                        },
                        color: Colors.red,),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildRadioOption(label: 'N/A',
                        value: 'N_A',
                        selectedValue: widget.tripleRadioSelections[fieldKey],
                        onChanged: (value) {
                          setState(() {
                            widget.tripleRadioSelections[fieldKey] = value!;
                          });
                          widget.onDataChanged();
                        },
                        color: Colors.orange,),
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
}