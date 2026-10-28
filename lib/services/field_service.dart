import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/field_model.dart';

class FieldService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all active fields
  static Future<List<FieldModel>> getFields() async {
    try {
      final response = await _supabase
          .from('fields')
          .select()
          .eq('status', 'Aktif')
          .order('name');
          
      return response.map((e) => FieldModel.fromMap(e)).toList();
    } catch (e) {
      throw 'Gagal memuat data bidang: $e';
    }
  }

  static Future<void> addField(FieldModel field) async {
    try {
      await _supabase.from('fields').insert({
        'id': field.id,
        'name': field.name,
        'description': field.description,
        'status': field.status,
      });
    } catch (e) {
      throw 'Gagal menambahkan bidang: $e';
    }
  }

  static Future<void> updateField(FieldModel field) async {
    try {
      await _supabase
          .from('fields')
          .update({
            'name': field.name,
            'description': field.description,
            'status': field.status,
          })
          .eq('id', field.id);
    } catch (e) {
      throw 'Gagal memperbarui bidang: $e';
    }
  }

  static Future<void> deleteField(String id) async {
    try {
      await _supabase.from('fields').delete().eq('id', id);
    } catch (e) {
      throw 'Gagal menghapus bidang: $e';
    }
  }
}
