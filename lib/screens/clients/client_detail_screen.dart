import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/client_provider.dart';
import '../../providers/form_provider.dart';
import '../../models/client.dart';
import '../../models/form.dart';

class ClientDetailScreen extends StatefulWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FormProvider>().loadFormsByClient(widget.clientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<ClientProvider>(
        builder: (context, clientProvider, child) {
          final client = clientProvider.getClientById(widget.clientId);

          if (client == null) {
            return _buildClientNotFound();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClientHeader(client),
                const SizedBox(height: 16),
                _buildClientInfo(client),
                const SizedBox(height: 16),
                _buildFormsSection(client),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClientNotFound() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Client not found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildClientHeader(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Client ID: ${client.id}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Address', client.address),
            _buildInfoRow(Icons.streetview, 'Street', client.street),
            _buildInfoRow(Icons.phone, 'Phone', client.phone),
            _buildInfoRow(Icons.business, 'Holder', client.holder),
            _buildInfoRow(Icons.place, 'Installation Location', client.installationLocation),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
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
                  value.isNotEmpty ? value : 'Not specified',
                  style: TextStyle(
                    fontSize: 14,
                    color: value.isNotEmpty ? null : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormsSection(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormsHeader(client),
            const SizedBox(height: 16),
            _buildFormsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormsHeader(Client client) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Formulare ISCIR',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _createNewForm(client),
          icon: const Icon(Icons.add),
          label: const Text('Raport ISCIR Nou'),
        ),
      ],
    );
  }

  Widget _buildFormsContent() {
    return Consumer<FormProvider>(
      builder: (context, formProvider, child) {
        if (formProvider.isLoading) {
          return _buildLoadingState();
        }

        if (formProvider.error != null) {
          return _buildErrorState(formProvider);
        }

        final forms = formProvider.forms;
        if (forms.isEmpty) {
          return _buildEmptyState();
        }

        return _buildFormsList(forms);
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(FormProvider formProvider) {
    return Center(
      child: Column(
        children: [
          Text(
            'Error loading forms: ${formProvider.error}',
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              formProvider.clearError();
              formProvider.loadFormsByClient(widget.clientId);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.description_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'No forms yet',
            style: TextStyle(color: Colors.grey),
          ),
          Text(
            'Create your first ISCIR form',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFormsList(List<ISCIRForm> forms) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: forms.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => FormListTile(form: forms[index]),
    );
  }

  Future<void> _createNewForm(Client client) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creating form...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Create the form directly with auto-generated values
      final success = await context.read<FormProvider>().createForm(
        clientId: client.id!,
        formType: FormType.raportIscir,
        reportNumber: '', // Will be auto-generated in createForm method
        reportDate: DateTime.now(), // Use current date
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        if (!success) {
          final error = context.read<FormProvider>().error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to create form'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating form: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class FormListTile extends StatelessWidget {
  final ISCIRForm form;

  const FormListTile({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: _buildFormIcon(),
        title: Text(
          form.formType.code,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: _buildFormSubtitle(),
        trailing: _buildFormTrailing(),
        onTap: () => _onFormTap(context),
        onLongPress: () => _showFormOptions(context),
      ),
    );
  }

  Widget _buildFormIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getFormIconData(),
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildFormSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Report #${form.reportNumber}'),
        Text(
          '${form.reportDate.day}/${form.reportDate.month}/${form.reportDate.year}',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFormTrailing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            form.formType.code,
            style: TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 16),
      ],
    );
  }

  IconData _getFormIconData() {
    switch (form.formType) {
      // case FormType.anexa3Part1:
      //   return Icons.assignment;
      // case FormType.anexa3Part2:
      //   return Icons.assignment;
      case FormType.raportIscir:
        return Icons.assignment;
      case FormType.anexa4:
        return Icons.list_alt;
    }
  }

  void _onFormTap(BuildContext context) {
    // Navigate to form editing screen using GoRouter
    context.push('/form/${form.id}/edit').then((result) {
      // Refresh forms list if form was updated
      if (result == true) {
        context.read<FormProvider>().loadFormsByClient(form.clientId);
      }
    });
  }

  void _showFormOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionTile(
            context,
            Icons.edit,
            'Edit Form',
                () => _editForm(context),
          ),
          _buildOptionTile(
            context,
            Icons.picture_as_pdf,
            'Generate PDF',
                () => _generatePdf(context),
          ),
          _buildOptionTile(
            context,
            Icons.print,
            'Print',
                () => _printForm(context),
          ),
          _buildOptionTile(
            context,
            Icons.delete,
            'Delete Form',
                () => _deleteForm(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
      BuildContext context,
      IconData icon,
      String title,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _editForm(BuildContext context) {
    context.push('/form/${form.id}/edit').then((result) {
      if (result == true) {
        context.read<FormProvider>().loadFormsByClient(form.clientId);
      }
    });
  }

  void _generatePdf(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF generation coming soon!')),
    );
  }

  void _printForm(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printing coming soon!')),
    );
  }

  void _deleteForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Form'),
        content: Text(
          'Are you sure you want to delete "${form.formType.code} - ${form.reportNumber}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(BuildContext context) async {
    final success = await context.read<FormProvider>().deleteForm(form.id!);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Form deleted successfully' : 'Failed to delete form',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}