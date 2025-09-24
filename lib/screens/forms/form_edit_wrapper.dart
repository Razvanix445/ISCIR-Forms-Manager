import 'package:flutter/material.dart';

import '../../models/client.dart';
import '../../models/form.dart';
import '../../services/database_service.dart';
import 'raport_iscir_form_screen.dart';
import 'anexa4_form_screen.dart';

class FormEditWrapper extends StatelessWidget {
  final int formId;

  const FormEditWrapper({super.key, required this.formId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ISCIRForm?>(
      future: DatabaseService.instance.getForm(formId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text('Form not found or error loading form'),
            ),
          );
        }

        final form = snapshot.data!;

        return FutureBuilder<Client?>(
          future: DatabaseService.instance.getClient(form.clientId),
          builder: (context, clientSnapshot) {
            if (clientSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (clientSnapshot.hasError || !clientSnapshot.hasData) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text('Client not found or error loading client'),
                ),
              );
            }

            final client = clientSnapshot.data!;

            switch (form.formType) {
              case FormType.raportIscir:
                return RaportIscirFormScreen(form: form, client: client);
              case FormType.anexa4:
                return Anexa4FormScreen(form: form, client: client);
            }
          },
        );
      },
    );
  }
}