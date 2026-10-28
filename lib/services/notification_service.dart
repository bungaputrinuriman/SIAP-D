import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Mengirim notifikasi ke pembimbing lapangan.
  /// [supervisorRowId] adalah UUID dari tabel 'supervisors' milik peserta.
  /// Fungsi ini akan mencari profil pembimbing yang punya role 'pembimbing'
  /// dan supervisor_id yang sama, lalu menyimpan notifikasi ke tabel 'notifications'
  /// agar dapat ditampilkan saat pembimbing login.
  /// Mengirim notifikasi ke pembimbing lapangan.
  /// [supervisorRowId] adalah UUID dari tabel 'supervisors' milik peserta.
  /// [fieldId] adalah UUID bidang peserta jika supervisorRowId belum diisi.
  static Future<void> sendNotificationToSupervisor({
    required String? supervisorRowId,
    String? fieldId,
    required String title,
    required String message,
  }) async {
    try {
      final Set<String> targetUserIds = {};

      // 1. Cari pembimbing berdasarkan supervisorRowId jika ada
      if (supervisorRowId != null && supervisorRowId.isNotEmpty) {
        final respBySupId = await _supabase
            .from('profiles')
            .select('id')
            .eq('role', 'pembimbing')
            .eq('supervisor_id', supervisorRowId);
        for (final r in (respBySupId as List)) {
          if (r['id'] != null) targetUserIds.add(r['id'].toString());
        }

        // Cari juga via email dari tabel supervisors
        final supRow = await _supabase
            .from('supervisors')
            .select('email, field_id')
            .eq('id', supervisorRowId)
            .maybeSingle();
        if (supRow != null) {
          final supEmail = supRow['email']?.toString();
          if (supEmail != null && supEmail.isNotEmpty) {
            final respByEmail = await _supabase
                .from('profiles')
                .select('id')
                .eq('role', 'pembimbing')
                .eq('email', supEmail);
            for (final r in (respByEmail as List)) {
              if (r['id'] != null) targetUserIds.add(r['id'].toString());
            }
          }
          if (fieldId == null || fieldId.isEmpty) {
            fieldId = supRow['field_id']?.toString();
          }
        }
      }

      // 2. Jika belum ditemukan dan ada fieldId, cari pembimbing di bidang tersebut
      if (targetUserIds.isEmpty && fieldId != null && fieldId.isNotEmpty) {
        // Cari pembimbing dengan field_id yang sama di profiles
        final respByField = await _supabase
            .from('profiles')
            .select('id')
            .eq('role', 'pembimbing')
            .eq('field_id', fieldId);
        for (final r in (respByField as List)) {
          if (r['id'] != null) targetUserIds.add(r['id'].toString());
        }

        // Cari juga pembimbing dari tabel supervisors dengan field_id yang sama
        final supsInField = await _supabase
            .from('supervisors')
            .select('email')
            .eq('field_id', fieldId);
        for (final s in (supsInField as List)) {
          final semail = s['email']?.toString();
          if (semail != null && semail.isNotEmpty) {
            final respEmail = await _supabase
                .from('profiles')
                .select('id')
                .eq('role', 'pembimbing')
                .eq('email', semail);
            for (final r in (respEmail as List)) {
              if (r['id'] != null) targetUserIds.add(r['id'].toString());
            }
          }
        }
      }

      if (targetUserIds.isEmpty) {
        // Fallback: kirim ke semua akun pembimbing agar notifikasi pengajuan izin/sakit tidak terlewat
        final allPembimbing = await _supabase.from('profiles').select('id').eq('role', 'pembimbing');
        for (final r in (allPembimbing as List)) {
          if (r['id'] != null) targetUserIds.add(r['id'].toString());
        }
      }

      if (targetUserIds.isEmpty) {
        debugPrint('[Notif] Tidak ditemukan akun pembimbing untuk peserta (supervisorRowId=$supervisorRowId, fieldId=$fieldId)');
        return;
      }

      for (final pembimbingUserId in targetUserIds) {
        await _supabase.from('notifications').insert({
          'user_id': pembimbingUserId,
          'title': title,
          'body': message,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('[Notif] ✅ Notifikasi terkirim ke pembimbing $pembimbingUserId');
      }
    } catch (e) {
      debugPrint('[Notif] ⚠️ Gagal mengirim notifikasi: $e');
    }
  }
}
