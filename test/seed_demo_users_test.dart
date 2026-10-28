import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

void main() {
  test('Seed demo users', () async {
    final client = SupabaseClient(
      'https://rpbajlrqmlyoyujqelew.supabase.co',
      'sb_publishable_PX4iTFRNhnTQt6ZR7nnR2A__77cdMnb',
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );

    try {
      // 1. Create Admin
      final adminRes = await client.auth.signUp(
        email: 'admin@diskominfo.com',
        password: 'Admin123',
      );
      debugPrint('Admin Auth User ID: ${adminRes.user?.id}');

      if (adminRes.user != null) {
        await client.from('profiles').upsert({
          'id': adminRes.user!.id,
          'name': 'Administrator',
          'email': 'admin@diskominfo.com',
          'role': 'admin',
          'status': 'Aktif',
        });
        debugPrint('Admin profile created.');
      }
    } catch (e) {
      debugPrint('Failed to create Admin: $e');
    }

    try {
      // 2. Create Peserta
      final pesertaRes = await client.auth.signUp(
        email: 'peserta@diskominfo.com',
        password: 'Peserta123',
      );
      debugPrint('Peserta Auth User ID: ${pesertaRes.user?.id}');

      if (pesertaRes.user != null) {
        await client.from('profiles').upsert({
          'id': pesertaRes.user!.id,
          'name': 'Peserta Demo',
          'email': 'peserta@diskominfo.com',
          'role': 'peserta',
          'status': 'Aktif',
        });
        debugPrint('Peserta profile created.');
      }
    } catch (e) {
      debugPrint('Failed to create Peserta: $e');
    }
  });
}
