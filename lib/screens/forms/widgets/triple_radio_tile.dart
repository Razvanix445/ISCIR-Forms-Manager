import 'package:flutter/material.dart';

class TripleRadioTile extends StatelessWidget {
  final String fieldKey;
  final String title;
  final String? radioSelection;
  final ValueChanged<String?> onRadioChanged;

  const TripleRadioTile({
    super.key,
    required this.fieldKey,
    required this.title,
    this.radioSelection,
    required this.onRadioChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          Row(
            children: [

              Expanded(
                child: RadioListTile<String>(
                  title: const Text('DA'),
                  value: 'DA',
                  groupValue: radioSelection,
                  onChanged: (value) {
                    if (value != null && onRadioChanged != null) {
                      onRadioChanged(value);
                    }
                  },
                  dense: true,
                ),
              ),

              Expanded(
                child: RadioListTile<String>(
                  title: const Text('NU'),
                  value: 'NU',
                  groupValue: radioSelection,
                  onChanged: (value) {
                    if (value != null && onRadioChanged != null) {
                      onRadioChanged(value);
                    }
                  },
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('N/A'),
                  value: 'N_A',
                  groupValue: radioSelection,
                  onChanged: (value) {
                    if (value != null && onRadioChanged != null) {
                      onRadioChanged(value);
                    }
                  },
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}