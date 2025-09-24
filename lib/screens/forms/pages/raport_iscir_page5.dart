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

class _RaportIscirPage5State extends State<RaportIscirPage5> with TickerProviderStateMixin {
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
            Colors.purple[50]?.withOpacity(0.3) ?? Colors.purple.withOpacity(0.05),
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
              child: _buildConclusionSection(),
            ),
            const SizedBox(height: 24),
            _buildAnimatedSection(
              index: 1,
              child: _buildSignaturesSection(),
            ),
            const SizedBox(height: 100), // Space for navigation buttons
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

  Widget _buildConclusionSection() {
    return _buildModernCard(
      title: 'VI. CONCLUZII',
      icon: Icons.fact_check,
      iconColor: Colors.purple,
      child: Column(
        children: [
          _buildConclusionField(),
        ],
      ),
    );
  }

  Widget _buildConclusionField() {
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
          Row(
            children: [
              // Icon at the beginning
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.assignment_turned_in,
                  size: 16,
                  color: Colors.purple[700],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Aparatul îndeplinește/nu îndeplinește condițiile de funcționare conform prevederilor PT A1',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildConclusionRadioButton('admis', 'ADMIS', Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildConclusionRadioButton('respins', 'RESPINS', Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConclusionRadioButton(String value, String label, Color color) {
    final isSelected = widget.tripleRadioSelections['aparat_admis'] == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          widget.tripleRadioSelections['aparat_admis'] = value;
        });
        widget.onDataChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
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
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignaturesSection() {
    return _buildModernCard(
      title: 'SEMNĂTURI',
      icon: Icons.draw,
      iconColor: Colors.blue,
      child: Column(
        children: [
          _buildSignatureField(
            'Deținător/Utilizator',
            'semnatura_utilizator',
            Icons.person,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureField(String title, String signatureKey, IconData icon, Color iconColor) {
    final existingSignature = widget.signatures[signatureKey];

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: iconColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DrawingSignatureField(
            label: '',
            signatureKey: signatureKey,
            onSignatureChanged: widget.onSignatureChanged,
            existingSignature: existingSignature,
            height: 120,
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
}