import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/client.dart';
import '../models/form.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Reference to user's clients collection
  CollectionReference<Map<String, dynamic>> get _clientsCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('clients');
  }

  // Reference to user's forms collection
  CollectionReference<Map<String, dynamic>> get _formsCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('forms');
  }

  // CLIENT OPERATIONS

  // Create a new client
  Future<String> createClient(Client client) async {
    final docRef = await _clientsCollection.add(client.toMap());
    return docRef.id;
  }

  // Get all clients for current user
  Future<List<Client>> getAllClients() async {
    final snapshot = await _clientsCollection.get(); // Removed orderBy

    final clients = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Client.fromMap(data);
    }).toList();

    // Sort in memory instead
    clients.sort((a, b) => a.firstName.compareTo(b.firstName));

    return clients;
  }

  // Get a single client by ID
  Future<Client?> getClient(String clientId) async {
    final doc = await _clientsCollection.doc(clientId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    return Client.fromMap(data);
  }

  // Update a client
  Future<void> updateClient(Client client) async {
    if (client.id == null) throw Exception('Client ID is required');
    await _clientsCollection.doc(client.id.toString()).update(client.toMap());
  }

  // Delete a client
  Future<void> deleteClient(String clientId) async {
    // Delete all forms associated with this client
    final formsSnapshot = await _formsCollection
        .where('clientId', isEqualTo: clientId)
        .get();

    for (var doc in formsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete the client
    await _clientsCollection.doc(clientId).delete();
  }

  // FORM OPERATIONS

  // Create a new form
  Future<String> createForm(ISCIRForm form) async {
    final docRef = await _formsCollection.add(form.toFirestoreMap());
    return docRef.id;
  }

  // Get all forms for a specific client
  Future<List<ISCIRForm>> getFormsByClient(String clientId) async {
    final snapshot = await _formsCollection
        .where('clientId', isEqualTo: clientId)
        .get(); // Removed orderBy

    final forms = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ISCIRForm.fromMap(data);
    }).toList();

    // Sort in memory
    forms.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first

    return forms;
  }

  // Get a single form by ID
  Future<ISCIRForm?> getForm(String formId) async {
    final doc = await _formsCollection.doc(formId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    return ISCIRForm.fromMap(data);
  }

  // Update a form
  Future<void> updateForm(ISCIRForm form) async {
    if (form.id == null) throw Exception('Form ID is required');
    await _formsCollection.doc(form.id.toString()).update(form.toFirestoreMap());
  }

  // Delete a form
  Future<void> deleteForm(String formId) async {
    await _formsCollection.doc(formId).delete();
  }

  // Get all forms (for reports/statistics)
  Future<List<ISCIRForm>> getAllForms() async {
    final snapshot = await _formsCollection.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ISCIRForm.fromMap(data);
    }).toList();
  }

  // Get total forms count
  Future<int> getTotalFormsCount() async {
    final snapshot = await _formsCollection.get();
    return snapshot.docs.length;
  }

  // FORM DATA OPERATIONS

  // Save form field data
  Future<void> saveFormField(String formId, String fieldName, dynamic fieldValue) async {
    await _formsCollection.doc(formId).update({
      'formData.$fieldName': fieldValue,
    });
  }

  // Save all form data at once
  Future<void> saveFormData(String formId, Map<String, dynamic> formData) async {
    // Use merge: true to merge with existing data instead of replacing
    await _formsCollection.doc(formId).set({
      'formData': formData,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true)); // ← CRITICAL: merge: true!
  }

  // Get form data
  Future<Map<String, dynamic>> getFormData(String formId) async {
    final doc = await _formsCollection.doc(formId).get();
    if (!doc.exists) return {};

    final data = doc.data();
    return data?['formData'] as Map<String, dynamic>? ?? {};
  }

  // Stream methods for real-time updates (optional but useful)

  // Stream of all clients
  Stream<List<Client>> clientsStream() {
    return _clientsCollection.orderBy('firstName').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Client.fromMap(data);
      }).toList(),
    );
  }

  // Stream of forms for a client
  Stream<List<ISCIRForm>> formsStreamByClient(String clientId) {
    return _formsCollection
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ISCIRForm.fromMap(data);
      }).toList(),
    );
  }
}