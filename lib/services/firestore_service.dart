import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/client.dart';
import '../models/form.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _clientsCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('clients');
  }

  CollectionReference<Map<String, dynamic>> get _formsCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('forms');
  }

  /// CLIENT OPERATIONS

  Future<String> createClient(Client client) async {
    final docRef = await _clientsCollection.add(client.toMap());
    return docRef.id;
  }

  Future<List<Client>> getAllClients() async {
    final snapshot = await _clientsCollection.get();

    final clients = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Client.fromMap(data);
    }).toList();

    clients.sort((a, b) => a.firstName.compareTo(b.firstName));

    return clients;
  }

  Future<List<Client>> getRecentClients({int limit = 10}) async {
    final snapshot = await _clientsCollection
        .orderBy('updated_at', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Client.fromMap(data);
    }).toList();
  }

  Future<List<Client>> searchClients(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _clientsCollection.get();
    final lowerQuery = query.toLowerCase();

    final matchingClients = snapshot.docs.where((doc) {
      final data = doc.data();
      final firstName = (data['first_name'] ?? '').toString().toLowerCase();
      final lastName = (data['last_name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final phone = (data['phone'] ?? '').toString().toLowerCase();

      return firstName.contains(lowerQuery) ||
          lastName.contains(lowerQuery) ||
          email.contains(lowerQuery) ||
          phone.contains(lowerQuery);
    }).map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Client.fromMap(data);
    }).toList();

    matchingClients.sort((a, b) => a.firstName.compareTo(b.firstName));
    return matchingClients;
  }

  Future<Client?> getClient(String clientId) async {
    final doc = await _clientsCollection.doc(clientId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    return Client.fromMap(data);
  }

  Future<void> updateClient(Client client) async {
    if (client.id == null) throw Exception('Client ID is required');
    await _clientsCollection.doc(client.id.toString()).update(client.toMap());
  }

  Future<void> deleteClient(String clientId) async {
    final formsSnapshot = await _formsCollection
        .where('clientId', isEqualTo: clientId)
        .get();

    for (var doc in formsSnapshot.docs) {
      await doc.reference.delete();
    }

    await _clientsCollection.doc(clientId).delete();
  }

  /// FORM OPERATIONS

  Future<String> createForm(ISCIRForm form) async {
    final docRef = await _formsCollection.add(form.toFirestoreMap());
    return docRef.id;
  }

  Future<List<ISCIRForm>> getFormsByClient(String clientId) async {
    final snapshot = await _formsCollection
        .where('clientId', isEqualTo: clientId)
        .get();

    final forms = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ISCIRForm.fromMap(data);
    }).toList();

    forms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return forms;
  }

  Future<ISCIRForm?> getForm(String formId) async {
    final doc = await _formsCollection.doc(formId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    return ISCIRForm.fromMap(data);
  }

  Future<void> updateForm(ISCIRForm form) async {
    if (form.id == null) throw Exception('Form ID is required');
    await _formsCollection.doc(form.id.toString()).update(form.toFirestoreMap());
  }

  Future<void> deleteForm(String formId) async {
    await _formsCollection.doc(formId).delete();
  }

  Future<List<ISCIRForm>> getAllForms() async {
    final snapshot = await _formsCollection.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ISCIRForm.fromMap(data);
    }).toList();
  }

  Future<int> getTotalFormsCount() async {
    final snapshot = await _formsCollection.get();
    return snapshot.docs.length;
  }

  /// FORM DATA OPERATIONS

  Future<void> saveFormField(String formId, String fieldName, dynamic fieldValue) async {
    await _formsCollection.doc(formId).update({
      'formData.$fieldName': fieldValue,
    });
  }

  Future<void> saveFormData(String formId, Map<String, dynamic> formData) async {
    await _formsCollection.doc(formId).set({
      'formData': formData,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getFormData(String formId) async {
    final doc = await _formsCollection.doc(formId).get();
    if (!doc.exists) return {};

    final data = doc.data();
    return data?['formData'] as Map<String, dynamic>? ?? {};
  }

  Stream<List<Client>> clientsStream() {
    return _clientsCollection.orderBy('firstName').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Client.fromMap(data);
      }).toList(),
    );
  }

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