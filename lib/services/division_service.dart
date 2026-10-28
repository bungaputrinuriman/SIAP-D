import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/division_model.dart';

class DivisionService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<DivisionModel>> getDivisions() async {
    try {
      final response = await _supabase
          .from('divisions')
          .select()
          .eq('status', 'Aktif')
          .order('name');
          
      return response.map((e) => DivisionModel.fromMap(e)).toList();
    } catch (e) {
      throw 'Gagal memuat data divisi: $e';
    }
  }

  static Future<void> addDivision(DivisionModel division) async {
    try {
      await _supabase.from('divisions').insert({
        'id': division.id,
        'field_id': division.fieldId,
        'name': division.name,
        'description': division.description,
        'status': division.status,
      });
    } catch (e) {
      throw 'Gagal menambahkan divisi: $e';
    }
  }

  static Future<void> updateDivision(DivisionModel division) async {
    try {
      await _supabase
          .from('divisions')
          .update({
            'field_id': division.fieldId,
            'name': division.name,
            'description': division.description,
            'status': division.status,
          })
          .eq('id', division.id);
    } catch (e) {
      throw 'Gagal memperbarui divisi: $e';
    }
  }

  static Future<void> deleteDivision(String id) async {
    try {
      await _supabase.from('divisions').delete().eq('id', id);
    } catch (e) {
      throw 'Gagal menghapus divisi: $e';
    }
  }
}
