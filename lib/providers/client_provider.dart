import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../services/firestore_service.dart';
import '../services/sync_service.dart';

class ClientProvider with ChangeNotifier {
  List<Client> _clients = [];
  bool _isLoading = false;
  String? _error;

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all clients from database
  Future<void> loadClients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _clients = await SyncService.instance.loadClients(); // Changed
      print('Loaded ${_clients.length} clients');
    } catch (e) {
      print('Error loading clients: $e');
      _error = 'Failed to load clients: $e';
      _clients = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new client
  Future<bool> addClient(Client client) async {
    print('DEBUG: addClient called'); // Add this
    try {
      final docId = await SyncService.instance.createClient(client);
      print('DEBUG: Created client with ID: $docId'); // Add this
      final newClient = client.copyWith(id: docId);
      _clients.add(newClient);
      _clients.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      print('DEBUG: Client added to list. Total clients: ${_clients.length}'); // Add this
      return true;
    } catch (e) {
      print('DEBUG: Error adding client: $e'); // Add this
      _error = 'Failed to add client: $e';
      notifyListeners();
      return false;
    }
  }

  // Update existing client
  Future<bool> updateClient(Client client) async {
    try {
      await SyncService.instance.updateClient(client);
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;
        _clients.sort((a, b) => a.name.compareTo(b.name)); // Keep sorted
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Failed to update client: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete client
  Future<bool> deleteClient(String id) async {
    try {
      await SyncService.instance.deleteClient(id);
      _clients.removeWhere((client) => client.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete client: $e';
      notifyListeners();
      return false;
    }
  }

  // Get specific client by ID
  Client? getClientById(String id) {
    try {
      return _clients.firstWhere((client) => client.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }
}