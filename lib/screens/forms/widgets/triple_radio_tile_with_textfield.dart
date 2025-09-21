import 'package:flutter/material.dart';

class TripleRadioTileWithTextfield extends StatelessWidget {
  final String fieldKey;
  final String title;
  final TextEditingController? textController;
  final String? radioSelection;
  final ValueChanged<String?> onTextChanged;
  final ValueChanged<String?> onRadioChanged;
  final String hintText;

  const TripleRadioTileWithTextfield({
    super.key,
    required this.fieldKey,
    required this.title,
    this.textController,
    this.radioSelection,
    required this.onTextChanged,
    required this.onRadioChanged,
    this.hintText = 'Introduceți valoarea măsurată',
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
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true, // Makes the field more compact
                  ),
                  onChanged: onTextChanged,
                ),
              ),

              const SizedBox(width: 150),

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