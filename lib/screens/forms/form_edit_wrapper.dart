import 'package:flutter/material.dart';

import '../../models/client.dart';
import '../../models/form.dart';
import '../../services/database_service.dart';
import 'raport_iscir_form_screen.dart';

class FormEditWrapper extends StatelessWidget {
  final String formId;

  const FormEditWrapper({super.key, required this.formId});

  @override
  Widget build(BuildContext context) {
    // Parse the local form ID
    final localFormId = int.tryParse(formId);

    if (localFormId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Invalid form ID: $formId',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<ISCIRForm?>(
      future: DatabaseService.instance.getForm(localFormId), // ← Load from LOCAL database!
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.hasError
                        ? 'Error: ${snapshot.error}'
                        : 'Form not found or error loading form',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Form ID: $formId',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final form = snapshot.data!;

        // Parse the client ID from the form
        final localClientId = int.tryParse(form.clientId);

        if (localClientId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Invalid client ID in form: ${form.clientId}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return FutureBuilder<Client?>(
          future: DatabaseService.instance.getClient(localClientId), // ← Load client from LOCAL database!
          builder: (context, clientSnapshot) {
            if (clientSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (clientSnapshot.hasError || !clientSnapshot.hasData) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        clientSnapshot.hasError
                            ? 'Error: ${clientSnapshot.error}'
                            : 'Client not found or error loading client',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Client ID: ${form.clientId}',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            final client = clientSnapshot.data!;

            return RaportIscirFormScreen(
              form: form,
              client: client,
            );
          },
        );
      },
    );
  }
}