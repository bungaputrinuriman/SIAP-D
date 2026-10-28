import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supervisor_model.dart';

class SupervisorService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<SupervisorModel>> getSupervisors() async {
    try {
      final response = await _supabase
          .from('supervisors')
          .select()
          .eq('status', 'Aktif')
          .order('name');
          
      return response.map((e) => SupervisorModel.fromMap(e)).toList();
    } catch (e) {
      throw 'Gagal memuat data pembimbing: $e';
    }
  }

  static Future<void> addSupervisorWithProfile(SupervisorModel supervisor, String authUserId) async {
    try {
      final supervisorData = <String, dynamic>{
        'name': supervisor.name,
        if (supervisor.email != null) 'email': supervisor.email,
        if (supervisor.phone != null) 'phone': supervisor.phone,
        if (supervisor.fieldId != null) 'field_id': supervisor.fieldId,
        'status': supervisor.status,
      };

      if (supervisor.divisionId != null && supervisor.divisionId!.isNotEmpty) {
        supervisorData['division_id'] = supervisor.divisionId;
      }

      Map<String, dynamic> resp;
      try {
        resp = await _supabase.from('supervisors').insert(supervisorData).select('id').single();
      } catch (e) {
        // Fallback jika tabel supervisors belum memiliki kolom division_id
        if (e.toString().contains('division_id')) {
          supervisorData.remove('division_id');
          resp = await _supabase.from('supervisors').insert(supervisorData).select('id').single();
        } else {
          rethrow;
        }
      }

      final supervisorId = resp['id'];

      // Di tabel profiles kolom division_id sudah ada
      await _supabase.from('profiles').insert({
        'id': authUserId,
        'name': supervisor.name,
        'email': supervisor.email,
        'role': 'pembimbing',
        'supervisor_id': supervisorId,
        if (supervisor.fieldId != null) 'field_id': supervisor.fieldId,
        if (supervisor.divisionId != null && supervisor.divisionId!.isNotEmpty) 'division_id': supervisor.divisionId,
      });
    } catch (e) {
      throw 'Gagal menambahkan pembimbing: $e';
    }
  }

  static Future<void> addSupervisor(SupervisorModel supervisor) async {
    try {
      final data = <String, dynamic>{
        'name': supervisor.name,
        if (supervisor.email != null) 'email': supervisor.email,
        if (supervisor.phone != null) 'phone': supervisor.phone,
        if (supervisor.fieldId != null) 'field_id': supervisor.fieldId,
        if (supervisor.divisionId != null && supervisor.divisionId!.isNotEmpty) 'division_id': supervisor.divisionId,
        'status': supervisor.status,
      };
      try {
        await _supabase.from('supervisors').insert(data);
      } catch (e) {
        if (e.toString().contains('division_id')) {
          data.remove('division_id');
          await _supabase.from('supervisors').insert(data);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      throw 'Gagal menambahkan pembimbing: $e';
    }
  }

  static Future<void> updateSupervisor(SupervisorModel supervisor) async {
    try {
      final updateData = <String, dynamic>{
        'name': supervisor.name,
        'email': supervisor.email,
        'phone': supervisor.phone,
        'field_id': supervisor.fieldId,
        'status': supervisor.status,
      };

      if (supervisor.divisionId != null && supervisor.divisionId!.isNotEmpty) {
        updateData['division_id'] = supervisor.divisionId;
      } else {
        updateData['division_id'] = null;
      }

      try {
        await _supabase.from('supervisors').update(updateData).eq('id', supervisor.id);
      } catch (e) {
        if (e.toString().contains('division_id')) {
          updateData.remove('division_id');
          await _supabase.from('supervisors').update(updateData).eq('id', supervisor.id);
        } else {
          rethrow;
        }
      }

      // Sinkronkan juga ke tabel profiles untuk akun pembimbing yang terhubung
      final profileUpdates = <String, dynamic>{
        'name': supervisor.name,
        'field_id': supervisor.fieldId,
        'division_id': (supervisor.divisionId != null && supervisor.divisionId!.isNotEmpty) ? supervisor.divisionId : null,
      };

      await _supabase
          .from('profiles')
          .update(profileUpdates)
          .eq('supervisor_id', supervisor.id)
          .eq('role', 'pembimbing');

      if (supervisor.email != null && supervisor.email!.isNotEmpty) {
        await _supabase
            .from('profiles')
            .update(profileUpdates)
            .eq('email', supervisor.email!)
            .eq('role', 'pembimbing');
      }
    } catch (e) {
      throw 'Gagal memperbarui pembimbing: $e';
    }
  }

  static Future<void> deleteSupervisor(String id) async {
    try {
      // 1. Lepaskan relasi supervisor_id pada peserta yang dibimbing oleh pembimbing ini
      try {
        await _supabase.from('profiles').update({'supervisor_id': null}).eq('supervisor_id', id);
      } catch (e) {
        debugPrint('Catatan: update supervisor_id peserta ke null: $e');
      }

      // 2. Hapus profile akun login yang terhubung ke pembimbing ini terlebih dahulu
      await _supabase.from('profiles').delete().eq('supervisor_id', id).eq('role', 'pembimbing');
      
      // 3. Setelah itu, baru hapus data pembimbing dari tabel supervisors
      await _supabase.from('supervisors').delete().eq('id', id);
    } catch (e) {
      throw 'Gagal menghapus pembimbing: $e';
    }
  }
}
