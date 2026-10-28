class AttendanceModel {
  final String id;
  final String userId;
  final String date; 
  final String status; // 'Hadir', 'Izin', 'Sakit'
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? reason;
  final String? checkInPhotoUrl;
  final String? checkInSignatureUrl;
  final String? checkOutPhotoUrl;
  final String? checkOutSignatureUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields from profiles
  final String? userName;
  final String? university;
  final String? fieldName;
  final String? divisionName;
  final String? supervisorName;
  final String? divisionId;
  final String? fieldId;
  final String? supervisorId;

  // Backward compatibility for UI
  String get dateKey => date;
  String get displayDate => date;
  String get note => '';
  String get locationAddress => '';
  bool get isLocationValid => true;
  String get name => userName ?? '';

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.date,
    this.status = 'Hadir',
    this.checkInTime,
    this.checkOutTime,
    this.reason,
    this.checkInPhotoUrl,
    this.checkInSignatureUrl,
    this.checkOutPhotoUrl,
    this.checkOutSignatureUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.userName,
    this.university,
    this.fieldName,
    this.divisionName,
    this.supervisorName, this.divisionId, this.fieldId, this.supervisorId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    final profileData = map['profiles'];
    return AttendanceModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status'] ?? 'Hadir',
      checkInTime: map['check_in_time'] != null ? DateTime.tryParse(map['check_in_time'].toString()) : null,
      checkOutTime: map['check_out_time'] != null ? DateTime.tryParse(map['check_out_time'].toString()) : null,
      reason: map['reason'],
      checkInPhotoUrl: map['check_in_photo_url'],
      checkInSignatureUrl: map['check_in_signature_url'],
      checkOutPhotoUrl: map['check_out_photo_url'],
      checkOutSignatureUrl: map['check_out_signature_url'],
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
      
      // Handle JOIN data from profiles
      userName: profileData is Map ? profileData['name']?.toString() : null,
      university: profileData is Map ? profileData['university']?.toString() : null,
      fieldName: profileData is Map && profileData['fields'] is Map ? profileData['fields']['name']?.toString() : null,
      divisionName: profileData is Map && profileData['divisions'] is Map ? profileData['divisions']['name']?.toString() : null,
      supervisorName: profileData is Map && profileData['supervisors'] is Map ? profileData['supervisors']['name']?.toString() : null,
      // field_id, division_id, supervisor_id tersedia karena kita tambahkan ke SELECT
      fieldId: profileData is Map ? profileData['field_id']?.toString() : null,
      divisionId: profileData is Map ? profileData['division_id']?.toString() : null,
      supervisorId: profileData is Map ? profileData['supervisor_id']?.toString() : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'date': date,
      'status': status,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'reason': reason,
      'check_in_photo_url': checkInPhotoUrl,
      'check_in_signature_url': checkInSignatureUrl,
      'check_out_photo_url': checkOutPhotoUrl,
      'check_out_signature_url': checkOutSignatureUrl,
    };
    
    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? date,
    String? status,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? reason,
    String? checkInPhotoUrl,
    String? checkInSignatureUrl,
    String? checkOutPhotoUrl,
    String? checkOutSignatureUrl,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      reason: reason ?? this.reason,
      checkInPhotoUrl: checkInPhotoUrl ?? this.checkInPhotoUrl,
      checkInSignatureUrl: checkInSignatureUrl ?? this.checkInSignatureUrl,
      checkOutPhotoUrl: checkOutPhotoUrl ?? this.checkOutPhotoUrl,
      checkOutSignatureUrl: checkOutSignatureUrl ?? this.checkOutSignatureUrl,
      userName: userName,
      university: university,
      fieldName: fieldName,
      divisionName: divisionName,
      supervisorName: supervisorName,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
