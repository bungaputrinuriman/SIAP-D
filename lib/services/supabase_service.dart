import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://rpbajlrqmlyoyujqelew.supabase.co',
      publishableKey: 'sb_publishable_PX4iTFRNhnTQt6ZR7nnR2A__77cdMnb',
    );
  }
}
