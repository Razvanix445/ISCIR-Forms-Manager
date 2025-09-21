import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/client_provider.dart';
import '../../models/client.dart';
import '../../services/database_service.dart';
import 'add_edit_client_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  @override
  void initState() {
    super.initState();
    // Load clients when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ISCIR Forms - Clients'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Database'),
                  content: const Text('This will delete ALL data and recreate the database. Continue?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        try {
                          await DatabaseService.instance.resetDatabase();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Database reset successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Reload clients
                          context.read<ClientProvider>().loadClients();

                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Reset failed: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('RESET'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Database',
          ),
        ],
      ),
      body: Consumer<ClientProvider>(
        builder: (context, clientProvider, child) {
          if (clientProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (clientProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${clientProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      clientProvider.clearError();
                      clientProvider.loadClients();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final clients = clientProvider.clients;

          if (clients.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No clients yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first client using the + button',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return ClientListTile(client: client);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewClient,
        tooltip: 'Add Client',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNewClient() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddEditClientScreen(),
      ),
    );

    // If client was added successfully, refresh the list
    if (result == true && mounted) {
      context.read<ClientProvider>().loadClients();
    }
  }
}

class ClientListTile extends StatelessWidget {
  final Client client;

  const ClientListTile({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          client.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 ${client.address}'),
            if (client.phone.isNotEmpty) Text('📞 ${client.phone}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navigate to client detail screen
          context.push('/client/${client.id}');
        },
        onLongPress: () {
          _showClientOptions(context, client);
        },
      ),
    );
  }

  void _showClientOptions(BuildContext context, Client client) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Client'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => AddEditClientScreen(client: client),
                ),
              );
              if (result == true && context.mounted) {
                context.read<ClientProvider>().loadClients();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Client', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, client);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete "${client.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ClientProvider>().deleteClient(client.id!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success
                      ? 'Client deleted successfully'
                      : 'Failed to delete client')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
