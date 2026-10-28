class SupervisorModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? fieldId;
  final String? divisionId;
  final String status;
  final DateTime createdAt;

  SupervisorModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.fieldId,
    this.divisionId,
    this.status = 'Aktif',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SupervisorModel.fromMap(Map<String, dynamic> map) {
    return SupervisorModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      email: map['email'],
      phone: map['phone'],
      fieldId: map['field_id']?.toString(),
      divisionId: map['division_id']?.toString(),
      status: map['status'] ?? 'Aktif',
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'field_id': fieldId,
      if (divisionId != null) 'division_id': divisionId,
      'status': status,
    };
  }
}
