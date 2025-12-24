class Client {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String address;
  final String street;
  final String phone;
  final String installationLocation;
  final String holder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;

  Client({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.address,
    required this.street,
    required this.phone,
    required this.installationLocation,
    required this.holder,
    required this.createdAt,
    required this.updatedAt,
    this.needsSync = true,
  });

  String get name => '$firstName $lastName'.trim();

  Map<String, dynamic> toMap() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'address': address,
      'street': street,
      'phone': phone,
      'installation_location': installationLocation,
      'holder': holder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id']?.toString(),
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      street: map['street'] ?? '',
      phone: map['phone'] ?? '',
      installationLocation: map['installation_location'] ?? '',
      holder: map['holder'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      needsSync: (map['needs_sync'] ?? 1) == 1,
    );
  }

  Client copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? address,
    String? street,
    String? phone,
    String? installationLocation,
    String? holder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsSync,
  }) {
    return Client(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      address: address ?? this.address,
      street: street ?? this.street,
      phone: phone ?? this.phone,
      installationLocation: installationLocation ?? this.installationLocation,
      holder: holder ?? this.holder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  @override
  String toString() {
    return 'Client{id: $id, name: $name, email: $email, address: $address, phone: $phone}';
  }
}