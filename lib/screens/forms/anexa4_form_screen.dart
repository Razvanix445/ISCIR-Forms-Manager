import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/form.dart';
import '../../models/client.dart';
import '../../providers/form_provider.dart';

class Anexa4FormScreen extends StatefulWidget {
  final ISCIRForm form;
  final Client client;

  const Anexa4FormScreen({
    super.key,
    required this.form,
    required this.client,
  });

  @override
  State<Anexa4FormScreen> createState() => _Anexa4FormScreenState();
}

class _Anexa4FormScreenState extends State<Anexa4FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _radioSelections = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingData();
  }

  void _initializeControllers() {
    // Initialize controllers for Anexa 4 registry fields
    final fields = [
      'nr_inregistrare',
      'denumire_utilizator',
      'localitate_judet',
      'strada_nr',
      'bl_sc_et_ap',
      'tip_aparat',
      'parametri_principali',
      'nr_fabricatie_an',
      'producator_furnizor',
      'raport_verificare_nr_data',
      'livret_aparat_nr_data',
      'scadenta_urmatoare_verificare',
      'observatii',
    ];

    for (String field in fields) {
      _controllers[field] = TextEditingController();
    }

    // Initialize radio selections
    _radioSelections.addAll({
      'operatia_efectuata': 'admitere', // admitere/vtp/reparare
    });
  }

  void _loadExistingData() {
    final formData = widget.form.formData;

    _controllers.forEach((key, controller) {
      if (formData.containsKey(key)) {
        controller.text = formData[key]?.toString() ?? '';
      }
    });

    _radioSelections.forEach((key, defaultValue) {
      if (formData.containsKey(key)) {
        _radioSelections[key] = formData[key]?.toString() ?? defaultValue;
      }
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.form.formType.code} - ${widget.form.reportNumber}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _saveForm,
            icon: const Icon(Icons.save),
            tooltip: 'Save Registry',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 16),
              _buildRegistryFormSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 16),
              _buildNotesSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ANEXA 4',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registrul de evidență a aparatelor aflate în supraveghere',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    widget.client.name.isNotEmpty ? widget.client.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Registry Entry for Equipment Under Supervision',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistryFormSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'REGISTRY ENTRY DETAILS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),

            // Column 1: Nr. înregistrare
            _buildTextField(
              'nr_inregistrare',
              '1. Nr. înregistrare',
              icon: Icons.numbers,
            ),
            const SizedBox(height: 12),

            // Column 2: Deținător/Utilizator (pre-filled from client)
            _buildInfoDisplay('2. Deținător/Utilizator', widget.client.name),
            const SizedBox(height: 12),

            // Column 3: Locul funcționării aparatului
            Text(
              '3. Locul funcționării aparatului',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              'localitate_judet',
              'Localitatea/Județul',
              icon: Icons.location_city,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              'strada_nr',
              'Strada, Nr.',
              icon: Icons.streetview,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              'bl_sc_et_ap',
              'Bl., sc., et., ap.',
              icon: Icons.apartment,
            ),
            const SizedBox(height: 16),

            // Column 4: Operația efectuată
            _buildRadioSection(
              '4. Operația efectuată',
              'operatia_efectuata',
              ['admitere', 'vtp', 'reparare'],
              ['Admiterea funcționării', 'VTP', 'Reparare'],
            ),
            const SizedBox(height: 16),

            // Column 5: Caracteristicile aparatului
            Text(
              '5. Caracteristicile aparatului',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              'tip_aparat',
              'Tip',
              icon: Icons.category,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              'parametri_principali',
              'Parametri principali',
              icon: Icons.settings,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Column 6: Nr. de fabricație/an de fabricație
            _buildTextField(
              'nr_fabricatie_an',
              '6. Nr. de fabricație/an de fabricație',
              icon: Icons.precision_manufacturing,
            ),
            const SizedBox(height: 12),

            // Column 7: Producător/Furnizor
            _buildTextField(
              'producator_furnizor',
              '7. Producător/Furnizor',
              icon: Icons.factory,
            ),
            const SizedBox(height: 12),

            // Column 8: Raport de verificare Nr./dată
            _buildTextField(
              'raport_verificare_nr_data',
              '8. Raport de verificare Nr./dată',
              icon: Icons.assignment,
            ),
            const SizedBox(height: 12),

            // Column 9: Livret aparat Nr. înregistrare/data
            _buildTextField(
              'livret_aparat_nr_data',
              '9. Livret aparat Nr. înregistrare/data',
              icon: Icons.book,
            ),
            const SizedBox(height: 12),

            // Column 10: Scadența următoarei verificări
            _buildTextField(
              'scadenta_urmatoare_verificare',
              '10. Scadența următoarei verificări',
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 12),

            // Column 11: Observații
            _buildTextField(
              'observatii',
              '11. Observații',
              icon: Icons.note,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NOTĂ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                'Acest registru de evidență se completează obligatoriu de către persoanele juridice autorizate iar datele înregistrate se transmit trimestrial la ISCIR în format electronic - Microsoft Excel.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoDisplay(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Nu este specificat',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String key,
      String label, {
        IconData? icon,
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: _controllers[key],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (value) => _autoSave(),
    );
  }

  Widget _buildRadioSection(
      String title,
      String key,
      List<String> values,
      List<String> labels,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          children: values.asMap().entries.map((entry) {
            int index = entry.key;
            String value = entry.value;
            return SizedBox(
              width: 200,
              child: RadioListTile<String>(
                title: Text(labels[index]),
                value: value,
                groupValue: _radioSelections[key],
                onChanged: (selectedValue) {
                  setState(() {
                    _radioSelections[key] = selectedValue!;
                  });
                  _autoSave();
                },
                dense: true,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveForm,
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.save),
        label: Text(_isLoading ? 'Saving...' : 'Save Registry'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  void _autoSave() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _saveFormData(showSnackbar: false);
      }
    });
  }

  Future<void> _saveForm() async {
    await _saveFormData(showSnackbar: true);
  }

  Future<void> _saveFormData({bool showSnackbar = true}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> formData = {};

      _controllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          formData[key] = controller.text;
        }
      });

      _radioSelections.forEach((key, value) {
        formData[key] = value;
      });

      final success = await context.read<FormProvider>().saveFormData(
        widget.form.id!,
        formData,
      );

      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Registry saved successfully' : 'Failed to save registry'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving registry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}