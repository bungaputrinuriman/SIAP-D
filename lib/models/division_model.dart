class DivisionModel {
  final String id;
  final String fieldId;
  final String name;
  final String? description;
  final String status;
  final DateTime createdAt;

  DivisionModel({
    required this.id,
    required this.fieldId,
    required this.name,
    this.description,
    this.status = 'Aktif',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DivisionModel.fromMap(Map<String, dynamic> map) {
    return DivisionModel(
      id: map['id']?.toString() ?? '',
      fieldId: map['field_id']?.toString() ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      status: map['status'] ?? 'Aktif',
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'field_id': fieldId,
      'name': name,
      'description': description,
      'status': status,
    };
  }
}
