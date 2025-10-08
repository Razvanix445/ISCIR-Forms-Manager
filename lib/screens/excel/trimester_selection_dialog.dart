import 'package:flutter/material.dart';

class TrimesterSelectionDialog extends StatefulWidget {
  const TrimesterSelectionDialog({super.key});

  @override
  State<TrimesterSelectionDialog> createState() => _TrimesterSelectionDialogState();
}

class _TrimesterSelectionDialogState extends State<TrimesterSelectionDialog> {
  int _selectedYear = DateTime.now().year;
  int _selectedTrimester = _getCurrentTrimester();

  static int _getCurrentTrimester() {
    final month = DateTime.now().month;
    if (month >= 10) return 4; // Oct-Dec
    if (month >= 7) return 3;  // Jul-Sep
    if (month >= 4) return 2;  // Apr-Jun
    return 1;                  // Jan-Mar
  }

  String _getTrimesterLabel(int trimester) {
    switch (trimester) {
      case 1: return 'Trimestrul 1 (Ianuarie - Martie)';
      case 2: return 'Trimestrul 2 (Aprilie - Iunie)';
      case 3: return 'Trimestrul 3 (Iulie - Septembrie)';
      case 4: return 'Trimestrul 4 (Octombrie - Decembrie)';
      default: return '';
    }
  }

  List<int> _getAvailableYears() {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.date_range,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selectează perioada',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Alege anul și trimestrul pentru raport',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            /// Year selection
            const Text(
              'Anul',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<int>(
                value: _selectedYear,
                isExpanded: true,
                underline: const SizedBox(),
                items: _getAvailableYears().map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(
                      year.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedYear = value);
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            /// Trimester selection
            const Text(
              'Trimestrul',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(4, (index) {
              final trimester = index + 1;
              final isSelected = _selectedTrimester == trimester;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedTrimester = trimester),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.05),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.green
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getTrimesterLabel(trimester),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.green.shade700
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            /// Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Anulează',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'year': _selectedYear,
                      'trimester': _selectedTrimester,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Generează',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}