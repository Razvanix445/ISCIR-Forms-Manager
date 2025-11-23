import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../services/sync_service.dart';

class ClientProvider with ChangeNotifier {
  List<Client> _recentClients = [];
  List<Client> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  List<Client> get recentClients => _recentClients;
  List<Client> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;

  /// Load all clients from database
  Future<void> loadClients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load only recent 10 clients
      _recentClients = await SyncService.instance.getRecentClients();
      _searchResults = []; // Clear search results
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> loadRecentClients() async {
  //   _isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     _recentClients = await SyncService.instance.getRecentClients(10);
  //     print('✅ Loaded ${_recentClients.length} recent clients');
  //   } catch (e) {
  //     print('❌ Error loading recent clients: $e');
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> searchClients(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await SyncService.instance.searchClients(query);
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new client
  Future<bool> addClient(Client client) async {
    print('DEBUG: addClient called');
    try {
      final docId = await SyncService.instance.createClient(client);
      print('DEBUG: Created client with ID: $docId');
      final newClient = client.copyWith(id: docId);
      _recentClients.add(newClient);
      _recentClients.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      print('DEBUG: Client added to list. Total clients: ${_recentClients.length}');
      return true;
    } catch (e) {
      print('DEBUG: Error adding client: $e');
      _error = 'Failed to add client: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update existing client
  Future<bool> updateClient(Client client) async {
    try {
      await SyncService.instance.updateClient(client);
      final index = _recentClients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _recentClients[index] = client;
        _recentClients.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Failed to update client: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete client
  Future<bool> deleteClient(String id) async {
    try {
      await SyncService.instance.deleteClient(id);
      _recentClients.removeWhere((client) => client.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete client: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get specific client by ID
  Client? getClientById(String id) {
    try {
      return _recentClients.firstWhere((client) => client.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }
}