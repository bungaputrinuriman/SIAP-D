import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload photo/signature to Supabase Storage
  static Future<String?> uploadFile(
    String userId, 
    String folder, 
    File file
  ) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final filePath = '$userId/$folder/$fileName';
      
      await _supabase.storage
          .from('attendance_files')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final String publicUrl = _supabase.storage
          .from('attendance_files')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }
}
