class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'peserta' or 'admin'
  final String? nim;
  final String? university;
  final String? studyProgram;
  final String? fieldId;
  final String? divisionId;
  final String? supervisorId;
  final String? startDate;
  final String? endDate;
  final String status;
  final String? photoUrl;
  final DateTime createdAt;

  // Joined fields for display
  final String? fieldName;
  final String? divisionName;
  final String? supervisorName;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.nim,
    this.university,
    this.studyProgram,
    this.fieldId,
    this.divisionId,
    this.supervisorId,
    this.startDate,
    this.endDate,
    this.status = 'Aktif',
    this.photoUrl,
    DateTime? createdAt,
    this.fieldName,
    this.divisionName,
    this.supervisorName,
  }) : createdAt = createdAt ?? DateTime.now();

  // Alias getters untuk mencegah runtime/compile error di UI
  String? get instansi => university;
  String? get major => studyProgram;

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isPeserta => role.toLowerCase() == 'peserta';
  bool get isPembimbing => role.toLowerCase() == 'pembimbing';

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'peserta',
      nim: map['nim']?.toString(),
      // Mampu membaca field dari Supabase baik dalam bahasa Indonesia maupun Inggris
      university: map['university']?.toString() ?? map['instansi']?.toString(),
      studyProgram: map['study_program']?.toString() ?? map['major']?.toString(),
      fieldId: map['field_id']?.toString(),
      divisionId: map['division_id']?.toString(),
      supervisorId: map['supervisor_id']?.toString(),
      startDate: map['start_date']?.toString(),
      endDate: map['end_date']?.toString(),
      status: map['status']?.toString() ?? 'Aktif',
      photoUrl: map['photo_url']?.toString(),
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      // Safe parsing untuk JOIN data
      fieldName: map['fields'] is Map ? map['fields']['name']?.toString() : map['field_name']?.toString(),
      divisionName: map['divisions'] is Map ? map['divisions']['name']?.toString() : map['division_name']?.toString(),
      supervisorName: map['supervisors'] is Map ? map['supervisors']['name']?.toString() : map['supervisor_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      if (nim != null && nim!.isNotEmpty) 'nim': nim,
      if (university != null && university!.isNotEmpty) 'university': university,
      if (studyProgram != null && studyProgram!.isNotEmpty) 'study_program': studyProgram,
      // UUID FK columns — kirim null jika kosong agar tidak error constraint
      'field_id': (fieldId != null && fieldId!.isNotEmpty) ? fieldId : null,
      'division_id': (divisionId != null && divisionId!.isNotEmpty) ? divisionId : null,
      'supervisor_id': (supervisorId != null && supervisorId!.isNotEmpty) ? supervisorId : null,
      if (startDate != null && startDate!.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate!.isNotEmpty) 'end_date': endDate,
      'status': status,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? nim,
    String? university,
    String? studyProgram,
    String? fieldId,
    String? divisionId,
    String? supervisorId,
    String? startDate,
    String? endDate,
    String? status,
    String? photoUrl,
    DateTime? createdAt,
    String? fieldName,
    String? divisionName,
    String? supervisorName,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      nim: nim ?? this.nim,
      university: university ?? this.university,
      studyProgram: studyProgram ?? this.studyProgram,
      fieldId: fieldId ?? this.fieldId,
      divisionId: divisionId ?? this.divisionId,
      supervisorId: supervisorId ?? this.supervisorId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      fieldName: fieldName ?? this.fieldName,
      divisionName: divisionName ?? this.divisionName,
      supervisorName: supervisorName ?? this.supervisorName,
    );
  }
}