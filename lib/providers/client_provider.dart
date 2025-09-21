import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../services/database_service.dart';

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
      final result = await DatabaseService.instance.getAllClients();
      _clients = result ?? []; // Handle null result
      print('Loaded ${_clients.length} clients'); // Debug log
    } catch (e) {
      print('Error loading clients: $e'); // Debug log
      _error = 'Failed to load clients: $e';
      _clients = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new client
  Future<bool> addClient(Client client) async {
    try {
      final id = await DatabaseService.instance.createClient(client);
      final newClient = client.copyWith(id: id);
      _clients.add(newClient);
      _clients.sort((a, b) => a.name.compareTo(b.name)); // Keep sorted
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add client: $e';
      notifyListeners();
      return false;
    }
  }

  // Update existing client
  Future<bool> updateClient(Client client) async {
    try {
      await DatabaseService.instance.updateClient(client);
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
  Future<bool> deleteClient(int id) async {
    try {
      await DatabaseService.instance.deleteClient(id);
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
  Client? getClientById(int id) {
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