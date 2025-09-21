import 'package:flutter/material.dart';

class RadioGroupWidget extends StatelessWidget {
  final String title;
  final String groupKey;
  final List<String> values;
  final List<String> labels;
  final String? selectedValue;
  final ValueChanged<String>? onChanged;
  final bool horizontal;

  const RadioGroupWidget({
    super.key,
    required this.title,
    required this.groupKey,
    required this.values,
    required this.labels,
    this.selectedValue,
    this.onChanged,
    this.horizontal = true,
  }) : assert(values.length == labels.length, 'Values and labels must have the same length');

  @override
  Widget build(BuildContext context) {
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
            groupValue: selectedValue,
            onChanged: (selectedValue) {
              if (selectedValue != null && onChanged != null) {
                onChanged!(selectedValue);
              }
            },
            dense: true,
          );
        }).toList(),
      ]
    );
  }
}