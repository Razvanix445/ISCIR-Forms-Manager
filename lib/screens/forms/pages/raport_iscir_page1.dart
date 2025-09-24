import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/client.dart';
import '../../../models/form.dart';

class RaportIscirPage1 extends StatefulWidget {
  final Client client;
  final ISCIRForm form;
  final Map<String, TextEditingController> controllers;
  final Map<String, bool> checkboxes;
  final Map<String, String> radioSelections;
  final VoidCallback onDataChanged;

  const RaportIscirPage1({
    super.key,
    required this.client,
    required this.form,
    required this.controllers,
    required this.checkboxes,
    required this.radioSelections,
    required this.onDataChanged,
  });

  @override
  State<RaportIscirPage1> createState() => _RaportIscirPage1State();
}

class _RaportIscirPage1State extends State<RaportIscirPage1> with TickerProviderStateMixin {
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
    _sectionAnimations = List.generate(4, (index) =>
        AnimationController(
          duration: Duration(milliseconds: 800 + (index * 200)),
          vsync: this,
        )
    );

    // Start animations
    _animationController.forward();
    for (int i = 0; i < _sectionAnimations.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
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
            Colors.blue.shade50.withOpacity(0.3),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildAnimatedSection(
            //   index: 0,
            //   child: _buildHeaderSection(),
            // ),
            // const SizedBox(height: 24),
            _buildAnimatedSection(
              index: 2,
              child: _buildOperationSection(),
            ),
            const SizedBox(height: 24),
            _buildAnimatedSection(
              index: 3,
              child: _buildEquipmentDataSection(),
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

  Widget _buildOperationSection() {
    return _buildModernCard(
      title: 'Operația efectuată',
      icon: Icons.build_circle,
      iconColor: Colors.orange,
      child: Column(
        children: [
          // Main checkbox for "Admiterea funcționării"
          _buildModernCheckbox(
            title: 'Admiterea funcționării',
            value: widget.checkboxes['operatia_admitere'] ?? false,
            onChanged: (value) {
              setState(() {
                widget.checkboxes['operatia_admitere'] = value ?? false;
                // Clear radio selection when unchecked
                if (!value!) {
                  widget.radioSelections['tip_aparat'] = '';
                }
              });
              widget.onDataChanged();
            },
          ),

          // CONDITIONAL RADIO BUTTONS
          if (widget.checkboxes['operatia_admitere'] == true) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.only(left: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.blue.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tip aparat:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildModernRadioOption(
                    title: 'Aparat nou',
                    value: 'nou',
                    groupValue: widget.radioSelections['tip_aparat'],
                    onChanged: (value) {
                      setState(() {
                        widget.radioSelections['tip_aparat'] = value!;
                      });
                      widget.onDataChanged();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildModernRadioOption(
                    title: 'Aparat vechi',
                    value: 'vechi',
                    groupValue: widget.radioSelections['tip_aparat'],
                    onChanged: (value) {
                      setState(() {
                        widget.radioSelections['tip_aparat'] = value!;
                      });
                      widget.onDataChanged();
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Other checkboxes (independent)
          _buildModernCheckbox(
            title: 'Verificare tehnică periodică',
            value: widget.checkboxes['operatia_vtp'] ?? false,
            onChanged: (value) {
              setState(() {
                widget.checkboxes['operatia_vtp'] = value ?? false;
              });
              widget.onDataChanged();
            },
          ),

          const SizedBox(height: 12),

          _buildModernCheckbox(
            title: 'Repunere în funcțiune după reparare',
            value: widget.checkboxes['operatia_repunere'] ?? false,
            onChanged: (value) {
              setState(() {
                widget.checkboxes['operatia_repunere'] = value ?? false;
              });
              widget.onDataChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentDataSection() {
    return _buildModernCard(
      title: '2. DATE PRIVIND INSTALAȚIA DE ARDERE',
      icon: Icons.precision_manufacturing,
      iconColor: Colors.green,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                  _buildModernDropdownField(
                    key: 'producator',
                    label: 'Producător',
                    icon: Icons.factory,
                    options: [
                      'Ariston', 'Baxi', 'Beretta', 'Bosch', 'Buderus',
                      'Chaffoteaux', 'Ferroli', 'Immergas', 'Junkers', 'Motan',
                      'Protherm', 'Riello', 'Saunier Duval', 'Vaillant',
                      'Viessmann', 'Westen', 'Altul',
                    ],
                    showOtherOption: true,
                  ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child:
                  _buildModernTextField(
                    key: 'serie_an_fabricatie',
                    label: 'Serie/An fabricație',
                    icon: Icons.tag,
                  ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                  _buildModernTextField(
                    key: 'tip',
                    label: 'Tip',
                    icon: Icons.category,
                  ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child:
                  _buildModernTextField(
                    key: 'putere',
                    label: 'Putere (kW)',
                    icon: Icons.power,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                  ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                  _buildModernTextField(
                    key: 'model',
                    label: 'Model',
                    icon: Icons.precision_manufacturing,
                  ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child:
                  _buildModernTextField(
                    key: 'tip_combustibil',
                    label: 'Tip combustibil',
                    icon: Icons.local_gas_station,
                  ),
              ),
            ],
          ),


          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                  _buildModernRadioGroup(
                    title: 'Cu aer',
                    key: 'cu_aer',
                    values: ['aspirat', 'insuflat'],
                    labels: ['Aspirat', 'Insuflat'],
                  ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child:
                  _buildModernRadioGroup(
                    title: 'Cu alimentare',
                    key: 'cu_alimentare',
                    values: ['manuala', 'automata'],
                    labels: ['Manuală', 'Automată'],
                  ),
              )
            ]
          )
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

  Widget _buildModernTextField({
    required String key,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controllers[key],
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: (value) => widget.onDataChanged(),
            decoration: InputDecoration(
              hintText: 'Introduceți $label',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdownField({
    required String key,
    required String label,
    required IconData icon,
    required List<String> options,
    bool showOtherOption = false,
  }) {
    final dropdownValue = widget.radioSelections[key] ?? '';
    final textValue = widget.controllers[key]?.text ?? '';
    final isOtherSelected = showOtherOption && dropdownValue == 'Altul';

    String? displayValue;
    if (dropdownValue.isEmpty) {
      displayValue = null;
    } else if (options.contains(dropdownValue)) {
      displayValue = dropdownValue;
    } else {
      displayValue = 'Altul';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: displayValue,
            decoration: InputDecoration(
              hintText: 'Selectează $label',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            hint: Text('Selectează $label'),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                if (newValue == 'Altul') {
                  widget.radioSelections[key] = 'Altul';
                } else {
                  widget.radioSelections[key] = newValue ?? '';
                  widget.controllers[key]?.clear();
                }
              });
              widget.onDataChanged();
            },
            isExpanded: true,
          ),
        ),

        // Text field for "Altul" option
        if (isOtherSelected) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: widget.controllers[key],
              decoration: InputDecoration(
                hintText: 'Introduceți $label',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.orange.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) => widget.onDataChanged(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModernCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: value ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Theme.of(context).colorScheme.primary.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: value ? Theme.of(context).colorScheme.primary : Colors.black87,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget _buildModernRadioOption({
    required String title,
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.grey.shade200,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blue.shade700 : Colors.black87,
          ),
        ),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: Colors.blue,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _buildModernRadioGroup({
    required String title,
    required String key,
    required List<String> values,
    required List<String> labels,
  }) {
    return Column(
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: values.asMap().entries.map((entry) {
              int index = entry.key;
              String value = entry.value;
              final isSelected = value == widget.radioSelections[key];

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.5) : Colors.grey.shade200,
                  ),
                ),
                child: RadioListTile<String>(
                  title: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                    ),
                  ),
                  value: value,
                  groupValue: widget.radioSelections[key],
                  onChanged: (selectedValue) {
                    setState(() {
                      widget.radioSelections[key] = selectedValue!;
                    });
                    widget.onDataChanged();
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}