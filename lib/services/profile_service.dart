import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart'; // Gunakan IMPORT, BUKAN EXPORT!

class ProfileService {
  static final _supabase = Supabase.instance.client;

  static Future<ProfileModel?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return getProfileById(user.id);
  }

  static Future<ProfileModel?> getProfileById(String id) async {
    final response = await _supabase
        .from('profiles')
        .select('''
          *,
          fields(name),
          divisions(name),
          supervisors(name)
        ''')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;

    final profileMap = Map<String, dynamic>.from(response);

    // Jika role adalah pembimbing dan field_id/fieldName belum terisi, otomatis ambil dari tabel supervisors
    if (profileMap['role'] == 'pembimbing') {
      try {
        Map<String, dynamic>? supervisorRow;
        if (profileMap['supervisor_id'] != null && profileMap['supervisor_id'].toString().isNotEmpty) {
          final supResp = await _supabase
              .from('supervisors')
              .select('id, name, field_id, email, phone')
              .eq('id', profileMap['supervisor_id'])
              .maybeSingle();
          if (supResp != null) supervisorRow = supResp;
        }

        if (supervisorRow == null && profileMap['email'] != null && profileMap['email'].toString().isNotEmpty) {
          final supResp = await _supabase
              .from('supervisors')
              .select('id, name, field_id, email, phone')
              .eq('email', profileMap['email'])
              .maybeSingle();
          if (supResp != null) supervisorRow = supResp;
        }

        if (supervisorRow != null) {
          final supFieldId = supervisorRow['field_id']?.toString();
          final supId = supervisorRow['id']?.toString();

          if (profileMap['supervisor_id'] == null && supId != null) {
            profileMap['supervisor_id'] = supId;
          }

          if (supFieldId != null && supFieldId.isNotEmpty) {
            profileMap['field_id'] = supFieldId;
            final fieldResp = await _supabase
                .from('fields')
                .select('name')
                .eq('id', supFieldId)
                .maybeSingle();
            if (fieldResp != null) {
              profileMap['fields'] = {'name': fieldResp['name']};
              profileMap['field_name'] = fieldResp['name'];
            }

            // Simpan pembaruan ke tabel profiles agar tersimpan permanen
            await _supabase.from('profiles').update({
              'field_id': supFieldId,
              if (supId != null) 'supervisor_id': supId,
            }).eq('id', id);
          }
        }
      } catch (e) {
        debugPrint('Auto-sync pembimbing field error: $e');
      }
    }

    return ProfileModel.fromMap(profileMap);
  }

  static Future<List<ProfileModel>> getAllParticipants() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('''
            *,
            fields(name),
            divisions(name),
            supervisors(name)
          ''')
          .eq('role', 'peserta')
          .order('name');
      return (response as List).map((data) => ProfileModel.fromMap(data)).toList();
    } catch (e) {
      debugPrint('❌ getAllParticipants ERROR: $e');
      rethrow;
    }
  }

  static Future<void> updateProfile(ProfileModel profile) async {
    await _supabase.from('profiles').upsert(profile.toMap());
  }

  static Future<void> deleteParticipant(String userId, {String? participantName}) async {
    // Hapus notifikasi yang berkaitan dengan peserta ini
    if (participantName != null && participantName.trim().isNotEmpty) {
      try {
        await _supabase.from('notifications').delete().ilike('title', '%${participantName.trim()}%');
        await _supabase.from('notifications').delete().ilike('body', '%${participantName.trim()}%');
      } catch (e) {
        debugPrint('Error deleting notifications for participant $participantName: $e');
      }
    }

    try {
      await _supabase.from('notifications').delete().eq('user_id', userId);
    } catch (_) {}

    // Hapus data absensi peserta TERLEBIH DAHULU (mencegah foreign key constraint error)
    await _supabase.from('attendance').delete().eq('user_id', userId);

    // Hapus data profil dari tabel profiles
    await _supabase.from('profiles').delete().eq('id', userId);
  }
}