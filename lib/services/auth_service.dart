import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'profile_service.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get currently logged in user profile
  static Future<ProfileModel?> getCurrentUser() async {
    return await ProfileService.getCurrentProfile();
  }

  /// Register new user (Supabase Edge Function or Admin API approach recommended in production).
  /// For this MVP, we use the regular signUp, but beware it will log in the new user 
  /// and replace the current session in Supabase Auth. To prevent Admin session loss, 
  /// this ideally requires a backend endpoint. If backend isn't set up, we just use standard signUp.
  static Future<String> registerUser({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Simpan ID admin yang sedang aktif sebelum signUp
    final adminId = _supabase.auth.currentUser?.id;
    final adminRefreshToken = _supabase.auth.currentSession?.refreshToken;

    try {
      final response = await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
      );

      // Jika signUp berhasil tapi sesi berubah ke akun baru,
      // kembalikan sesi admin
      final newUserId = response.user?.id;
      if (newUserId == null) {
        throw 'Gagal mendapatkan data user setelah registrasi';
      }

      // Sesi sekarang adalah peserta baru — restore admin
      if (newUserId != adminId) {
        await _supabase.auth.signOut();
        if (adminRefreshToken != null && adminRefreshToken.isNotEmpty) {
          try {
            await _supabase.auth.setSession(adminRefreshToken);
          } catch (_) {}
        }
      }

      return newUserId;
    } on AuthException catch (e) {
      // signUp gagal → sesi admin TIDAK berubah, jangan logout!
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('already exists')) {
        throw 'Email "$cleanEmail" sudah terdaftar. Gunakan email lain.';
      }
      throw e.message;
    } catch (e) {
      // Jika bukan AuthException, sesi mungkin tidak berubah
      throw '$e';
    }
  }

  /// Login with email and password
  static Future<ProfileModel> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      if (response.user != null) {
        final profile = await ProfileService.getProfileById(response.user!.id);
        if (profile != null) return profile;
        
        await _supabase.auth.signOut();
        throw 'Data profil peserta belum ditemukan. Silakan hubungi admin.';
      }
      throw 'Sesi login gagal didapatkan.';
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw 'Email atau password salah.';
      }
      throw e.message;
    } catch (e) {
      throw 'Gagal melakukan login: $e';
    }
  }

  /// Check if user is currently logged in
  static bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  /// Update password user yang sedang login saat ini (Pembimbing / Peserta / Admin)
  static Future<void> updateCurrentUserPassword(String newPassword) async {
    final cleanPass = newPassword.trim();
    if (cleanPass.length < 6) {
      throw 'Password minimal 6 karakter.';
    }
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: cleanPass),
      );
      if (response.user == null) {
        throw 'Gagal memperbarui password. Silakan coba lagi.';
      }
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Gagal memperbarui password: $e';
    }
  }

  /// Reset password peserta atau pembimbing (oleh admin) menggunakan Supabase Admin API
  static Future<void> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      // Gunakan Supabase Admin API untuk update password user lain
      // tanpa perlu logout dari sesi admin
      final res = await _supabase.functions.invoke(
        'reset-user-password',
        body: {'user_id': userId, 'new_password': newPassword},
      );

      if (res.status != 200) {
        final err = (res.data is Map && res.data['error'] != null)
            ? res.data['error'].toString()
            : res.data?.toString();
        throw err ?? 'Gagal memproses permintaan (Status: ${res.status})';
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('FunctionException') || errStr.contains('404')) {
        throw 'Gagal reset password: $e\n\nPastikan Edge Function "reset-user-password" sudah aktif di Supabase.';
      }
      throw 'Gagal reset password: $e';
    }
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw 'Gagal keluar dari akun: $e';
    }
  }
}
