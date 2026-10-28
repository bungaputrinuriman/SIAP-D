class FieldModel {
  final String id;
  final String name;
  final String? description;
  final String status;
  final DateTime createdAt;

  FieldModel({
    required this.id,
    required this.name,
    this.description,
    this.status = 'Aktif',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory FieldModel.fromMap(Map<String, dynamic> map) {
    return FieldModel(
      id: map['id']?.toString() ?? '',
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
      'name': name,
      'description': description,
      'status': status,
    };
  }
}
