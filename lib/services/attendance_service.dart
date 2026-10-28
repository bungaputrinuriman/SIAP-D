import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get attendance history for a specific user
  static Future<List<AttendanceModel>> getParticipantHistory(
    String userId, {
    String statusFilter = 'Semua',
  }) async {
    try {
      var query = _supabase
          .from('attendance')
          .select('*, profiles(name, university, fields(name), divisions(name), supervisors(name))')
          .eq('user_id', userId);

      if (statusFilter != 'Semua') {
        query = query.eq('status', statusFilter);
      }

      final response = await query.order('date', ascending: false);
      return response.map((e) => AttendanceModel.fromMap(e)).toList();
    } catch (e) {
      throw 'Gagal mengambil riwayat presensi: $e';
    }
  }

  /// Get all attendance records for admin
  static Future<List<AttendanceModel>> getAllAttendance({
    String? dateString,
  }) async {
    try {
      var query = _supabase
          .from('attendance')
          .select('*, profiles(name, university, field_id, division_id, supervisor_id, fields(name), divisions(name), supervisors(name))');

      if (dateString != null) {
        query = query.eq('date', dateString);
      }

      final response = await query.order('date', ascending: false);
      debugPrint('📋 getAllAttendance: ${response.length} records ditemukan');
      if (response.isNotEmpty) {
        debugPrint('📋 Sample record: ${response.first}');
      }
      return response.map((e) => AttendanceModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('❌ getAllAttendance ERROR: $e');
      throw 'Gagal mengambil seluruh presensi: $e';
    }
  }

  /// Get attendance for a specific user and date
  static Future<AttendanceModel?> getAttendanceByDate(String userId, String date) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .eq('date', date)
          .maybeSingle();

      if (response == null) return null;
      return AttendanceModel.fromMap(response);
    } catch (e) {
      throw 'Gagal mengecek presensi hari ini: $e';
    }
  }

  /// Submit check-in or specific status (Izin/Sakit)
  static Future<void> checkIn(AttendanceModel record) async {
    try {
      final currentAuthUser = _supabase.auth.currentUser;
      if (currentAuthUser == null) {
        throw 'Sesi login telah berakhir. Silakan logout dan login kembali.';
      }
      final payload = record.toMap();
      // Pastikan user_id selalu identik dengan auth.currentUser.id agar lolos policy RLS auth.uid() = user_id
      payload['user_id'] = currentAuthUser.id;

      await _supabase.from('attendance').upsert(
        payload,
        onConflict: 'user_id,date',
      );
    } catch (e) {
      debugPrint('❌ Error checkIn attendance: $e');
      throw 'Gagal submit presensi: $e';
    }
  }

  /// Submit check-out
  static Future<void> checkOut(String id, AttendanceModel updatedRecord) async {
    try {
      final currentAuthUser = _supabase.auth.currentUser;
      final payload = updatedRecord.toMap();
      if (currentAuthUser != null) {
        payload['user_id'] = currentAuthUser.id;
      }
      await _supabase
          .from('attendance')
          .update(payload)
          .eq('id', id);
    } catch (e) {
      debugPrint('❌ Error checkOut attendance: $e');
      throw 'Gagal melakukan check out: $e';
    }
  }
}
