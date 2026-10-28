import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/attendance_model.dart';
import '../models/field_model.dart';
import '../models/division_model.dart';
import '../models/supervisor_model.dart';
import '../models/notification_model.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/attendance_service.dart';
import '../services/supervisor_service.dart';
import '../services/excel_export_service.dart';
import '../services/notification_service.dart';
import '../core/utils/date_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';


final _supabase = Supabase.instance.client;

class AppProvider extends ChangeNotifier {
  ProfileModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppProvider() {
    checkCurrentUserSession();
  }

  Future<void> checkCurrentUserSession() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) {
      _currentUser = null;
      return;
    }

    try {
      final profile = await ProfileService.getProfileById(authUser.id);
      if (profile == null) {
        // Akun di auth ada, tetapi baris data di database (tabel profiles) sudah dihapus!
        debugPrint('⚠️ Auth session aktif tapi akun telah dihapus dari database. Membersihkan sesi login...');
        await _supabase.auth.signOut();
        _currentUser = null;
        notifyListeners();
        return;
      }

      _currentUser = profile;
      if (profile.isPeserta) {
        await loadParticipantData();
      } else if (profile.isPembimbing) {
        await loadPembimbingData();
      } else {
        await loadAdminData();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error saat verifikasi sesi database: $e');
    }
  }

  // Participant specific state
  AttendanceModel? _todayAttendance;
  List<AttendanceModel> _participantHistory = [];
  String _historyFilter = 'Semua';

  // Admin specific state
  List<ProfileModel> _participantsList = [];
  List<AttendanceModel> _allAttendances = [];
  List<FieldModel> _fieldsList = [];
  List<DivisionModel> _divisionsList = [];
  List<SupervisorModel> _supervisorsList = [];

  // Admin Filters
  String _adminFilterDateKey = '';
  String _adminFilterUniversity = 'Semua';
  String _adminFilterField = 'Semua';
  String _adminFilterStatus = 'Semua';
  String _adminSearchQuery = '';

  // Pembimbing specific state
  List<ProfileModel> _myParticipants = [];
  List<AttendanceModel> _myParticipantsAttendances = [];
  List<NotificationModel> _notifications = [];


  // Getters
  ProfileModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isPeserta => _currentUser?.isPeserta ?? false;
  bool get isPembimbing => _currentUser?.isPembimbing ?? false;

  // Pembimbing getters
  List<ProfileModel> get myParticipants => _myParticipants;
  List<AttendanceModel> get myParticipantsAttendances => _myParticipantsAttendances;
  List<NotificationModel> get notifications => _notifications;
  int get unreadNotificationCount => _notifications.where((n) => !n.isRead).length;

  AttendanceModel? get todayAttendance => _todayAttendance;
  bool get hasAttendedToday => _todayAttendance != null;
  bool get hasCheckedInToday => _todayAttendance != null && _todayAttendance!.checkInTime != null;
  bool get hasCheckedOutToday => _todayAttendance != null && _todayAttendance!.checkOutTime != null;
  
  List<AttendanceModel> get participantHistory => _participantHistory;
  List<AttendanceModel> get userAttendanceHistory => _participantHistory;
  String get historyFilter => _historyFilter;

  List<ProfileModel> get participantsList => _participantsList;
  List<AttendanceModel> get allAttendances => _allAttendances;
  List<AttendanceModel> get allAttendanceList => _allAttendances;
  List<FieldModel> get fieldsList => _fieldsList;
  List<DivisionModel> get divisionsList => _divisionsList;
  List<SupervisorModel> get supervisorsList => _supervisorsList;

  String get adminFilterDateKey => _adminFilterDateKey;
  String get adminFilterUniversity => _adminFilterUniversity;
  String get adminFilterField => _adminFilterField;
  String get adminFilterStatus => _adminFilterStatus;
  String get adminSearchQuery => _adminSearchQuery;

  // Get Divisions for a specific Field ID or Field Name
  List<DivisionModel> getDivisionsByField(String fieldIdOrName) {
    return _divisionsList.where((d) => d.fieldId == fieldIdOrName).toList();
  }

  // Dynamically calculate division member count
  int getDivisionMemberCount(String divisionId, String divisionName) {
    return _participantsList.where((p) {
      return p.status == 'Aktif' && (
        (divisionId.isNotEmpty && p.divisionId == divisionId) ||
        (divisionName.isNotEmpty && p.divisionName == divisionName)
      );
    }).length;
  }

  // Filtered Participants for Admin
  List<ProfileModel> get filteredParticipants {
    if (_adminSearchQuery.trim().isEmpty) return _participantsList;
    final q = _adminSearchQuery.trim().toLowerCase();
    return _participantsList.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.university?.toLowerCase().contains(q) ?? false) ||
          (p.nim?.toLowerCase().contains(q) ?? false) ||
          (p.fieldName?.toLowerCase().contains(q) ?? false) ||
          (p.divisionName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // Filtered Attendances for Admin
  List<AttendanceModel> get filteredAttendances {
    return _allAttendances.where((att) {
      if (_adminFilterDateKey.isNotEmpty && att.date != _adminFilterDateKey) {
        return false;
      }
      if (_adminFilterUniversity != 'Semua' && att.university != _adminFilterUniversity) {
        return false;
      }
      if (_adminFilterField != 'Semua' && att.fieldName != _adminFilterField) {
        return false;
      }
      if (_adminFilterStatus != 'Semua' && att.status != _adminFilterStatus) {
        return false;
      }
      return true;
    }).toList();
  }

  // Admin Stats Calculation for target date (default today)
  String get targetDateKey => _adminFilterDateKey.isNotEmpty ? _adminFilterDateKey : DateFormatter.getTodayKey();

  int get totalParticipants => _participantsList.where((p) => p.status == 'Aktif').length;

  int get todayHadirCount {
    return _allAttendances.where((att) => att.date == targetDateKey && att.status == 'Hadir').length;
  }

  int get todayIzinCount {
    return _allAttendances.where((att) => att.date == targetDateKey && att.status == 'Izin').length;
  }

  int get todaySakitCount {
    return _allAttendances.where((att) => att.date == targetDateKey && att.status == 'Sakit').length;
  }

  int get todayBelumAbsenCount {
    final attendedUserIds = _allAttendances
        .where((att) => att.date == targetDateKey)
        .map((att) => att.userId)
        .toSet();
    return _participantsList
        .where((p) => p.status == 'Aktif' && !attendedUserIds.contains(p.id))
        .length;
  }

  // Actions
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.login(email: email, password: password);
      _currentUser = user;
      _isLoading = false;
      
      if (user.isPeserta) {
        await loadParticipantData();
      } else if (user.isPembimbing) {
        await loadPembimbingData();
      } else {
        await loadAdminData();
      }
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    _todayAttendance = null;
    _participantHistory = [];
    _participantsList = [];
    _allAttendances = [];
    _divisionsList = [];
    _myParticipants = [];
    _myParticipantsAttendances = [];
    _notifications = [];
    notifyListeners();
  }

  Future<void> loadParticipantData() async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Verifikasi apakah akun peserta masih terdaftar di database
      final verifiedProfile = await ProfileService.getProfileById(_currentUser!.id);
      if (verifiedProfile == null) {
        debugPrint('⚠️ Akun peserta (${_currentUser!.id}) sudah dihapus dari database. Logout otomatis.');
        await logout();
        _errorMessage = 'Akun Anda tidak ditemukan atau telah dihapus dari sistem.';
        return;
      }
      _currentUser = verifiedProfile;

      _todayAttendance = await AttendanceService.getAttendanceByDate(_currentUser!.id, DateFormatter.getTodayKey());
      _participantHistory = await AttendanceService.getParticipantHistory(
        _currentUser!.id,
        statusFilter: _historyFilter,
      );
    } catch (e) {
      debugPrint('Error loading participant data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserData() async => loadParticipantData();

  Future<void> loadPembimbingData() async {
    if (_currentUser == null || !_currentUser!.isPembimbing) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Verifikasi apakah akun pembimbing masih terdaftar di database
      final verifiedProfile = await ProfileService.getProfileById(_currentUser!.id);
      if (verifiedProfile == null) {
        debugPrint('⚠️ Akun pembimbing (${_currentUser!.id}) sudah dihapus dari database. Logout otomatis.');
        await logout();
        _errorMessage = 'Akun pembimbing Anda tidak ditemukan atau telah dihapus dari sistem.';
        return;
      }
      _currentUser = verifiedProfile;

      String? supervisorId = _currentUser!.supervisorId;
      String? supervisorFieldId = _currentUser!.fieldId;
      Map<String, dynamic>? supRow;

      // Cek ke tabel supervisors untuk verifikasi data pembimbing & bidang
      try {
        if (supervisorId != null && supervisorId.isNotEmpty) {
          final res = await _supabase
              .from('supervisors')
              .select('id, name, field_id, email')
              .eq('id', supervisorId)
              .maybeSingle();
          if (res != null) supRow = res;
        }

        if (supRow == null && _currentUser!.email.isNotEmpty) {
          final res = await _supabase
              .from('supervisors')
              .select('id, name, field_id, email')
              .eq('email', _currentUser!.email)
              .maybeSingle();
          if (res != null) supRow = res;
        }

        if (supRow != null) {
          supervisorId = supRow['id']?.toString() ?? supervisorId;
          supervisorFieldId = supRow['field_id']?.toString() ?? supervisorFieldId;

          // Ambil nama bidang jika belum ada
          String? resolvedFieldName = _currentUser!.fieldName;
          if (supervisorFieldId != null && supervisorFieldId.isNotEmpty) {
            final fRes = await _supabase.from('fields').select('name').eq('id', supervisorFieldId).maybeSingle();
            if (fRes != null) {
              resolvedFieldName = fRes['name']?.toString();
            }
          }

          _currentUser = _currentUser!.copyWith(
            supervisorId: supervisorId,
            fieldId: supervisorFieldId,
            fieldName: resolvedFieldName,
          );
        }
      } catch (e) {
        debugPrint('Pembimbing supervisors lookup error: $e');
      }

      // Ambil seluruh peserta
      final allParticipantsResp = await _supabase
          .from('profiles')
          .select('*, fields(name), divisions(name), supervisors(name)')
          .eq('role', 'peserta');

      final allPeserta = (allParticipantsResp as List).map((e) => ProfileModel.fromMap(e)).toList();

      // Filter peserta yang berada di bawah bimbingan pembimbing ini SECARA SPESIFIK:
      // Hanya peserta yang memang ditugaskan kepada pembimbing ini (berdasarkan supervisor_id atau nama pembimbing)
      final effectiveSupId = supervisorId ?? _currentUser!.supervisorId;
      final effectiveSupName = (supRow != null && supRow['name'] != null)
          ? supRow['name'].toString().trim().toLowerCase()
          : _currentUser!.name.trim().toLowerCase();

      _myParticipants = allPeserta.where((p) {
        // 1. Cek apakah supervisor_id peserta sama dengan ID pembimbing di tabel supervisors
        final matchSupervisorId = effectiveSupId != null &&
            effectiveSupId.isNotEmpty &&
            p.supervisorId != null &&
            p.supervisorId == effectiveSupId;

        // 2. Cek apakah supervisor_id peserta sama dengan ID auth akun pembimbing
        final matchAuthId = p.supervisorId != null &&
            p.supervisorId!.isNotEmpty &&
            p.supervisorId == _currentUser!.id;

        // 3. Cek apakah supervisorName pada peserta cocok dengan nama pembimbing ini
        final matchName = effectiveSupName.isNotEmpty &&
            p.supervisorName != null &&
            p.supervisorName!.trim().toLowerCase() == effectiveSupName;

        return matchSupervisorId || matchAuthId || matchName;
      }).toList();

      // Load attendances for all these participants
      final userIds = _myParticipants.map((p) => p.id).toList();
      if (userIds.isNotEmpty) {
        final attendancesResp = await _supabase
            .from('attendance')
            .select('*, profiles(name, university, fields(name), divisions(name), supervisors(name))')
            .inFilter('user_id', userIds)
            .order('date', ascending: false);
        _myParticipantsAttendances = (attendancesResp as List).map((e) => AttendanceModel.fromMap(e)).toList();
      } else {
        _myParticipantsAttendances = [];
      }

      // Load notifications for this pembimbing (hanya dari peserta bimbingan yang aktif)
      await _loadNotifications(activeParticipants: _myParticipants);

      debugPrint('✅ loadPembimbingData: ${_myParticipants.length} peserta bimbingan, ${_myParticipantsAttendances.length} absensi');
    } catch (e) {
      _errorMessage = 'Gagal memuat data pembimbing: $e';
      debugPrint('❌ loadPembimbingData ERROR: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Set<String>> _getDeletedNotificationIds() async {
    if (_currentUser == null) return {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'deleted_notifs_${_currentUser!.id}';
      return (prefs.getStringList(key) ?? []).toSet();
    } catch (e) {
      debugPrint('Error getting deleted notification ids: $e');
      return {};
    }
  }

  Future<void> _saveDeletedNotificationIds(Set<String> ids) async {
    if (_currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'deleted_notifs_${_currentUser!.id}';
      final list = ids.toList();
      if (list.length > 1000) {
        list.removeRange(0, list.length - 1000);
      }
      await prefs.setStringList(key, list);
    } catch (e) {
      debugPrint('Error saving deleted notification ids: $e');
    }
  }

  Future<void> _loadNotifications({List<ProfileModel>? activeParticipants}) async {
    if (_currentUser == null) return;
    try {
      final resp = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', _currentUser!.id)
          .order('created_at', ascending: false)
          .limit(50);
      final rawList = (resp as List).map((e) => NotificationModel.fromMap(e)).toList();

      // Filter notifikasi yang sudah pernah dihapus oleh user secara lokal
      final deletedIds = await _getDeletedNotificationIds();
      final unDeletedList = rawList.where((n) => !deletedIds.contains(n.id)).toList();

      // Bersihkan notifikasi yang sudah dihapus dari server secara background jika masih ada di Supabase
      final stillInDb = rawList.where((n) => deletedIds.contains(n.id)).map((n) => n.id).toList();
      if (stillInDb.isNotEmpty) {
        for (final ghostId in stillInDb) {
          try {
            await _supabase.from('notifications').delete().eq('id', ghostId);
          } catch (_) {}
        }
      }

      if (activeParticipants != null) {
        final validNames = activeParticipants.map((p) => p.name.trim().toLowerCase()).where((n) => n.isNotEmpty).toList();
        final List<NotificationModel> filtered = [];
        final List<String> orphanIds = [];

        for (final notif in unDeletedList) {
          final titleLower = notif.title.toLowerCase();
          final bodyLower = notif.body.toLowerCase();

          // Notifikasi hanya valid jika terkait dengan peserta bimbingan yang masih aktif
          final belongsToStudent = validNames.any((name) =>
              titleLower.contains(name) || bodyLower.contains(name));

          if (belongsToStudent) {
            filtered.add(notif);
          } else {
            orphanIds.add(notif.id);
          }
        }

        _notifications = filtered;

        // Bersihkan notifikasi peserta yang sudah dihapus secara permanen dari tabel notifications
        if (orphanIds.isNotEmpty) {
          deletedIds.addAll(orphanIds);
          await _saveDeletedNotificationIds(deletedIds);
          for (final oId in orphanIds) {
            try {
              await _supabase.from('notifications').delete().eq('id', oId);
            } catch (_) {}
          }
        }
      } else {
        _notifications = unDeletedList;
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      _notifications = [];
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', notificationId);
      _notifications = _notifications.map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (_currentUser == null) return;
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('user_id', _currentUser!.id).eq('is_read', false);
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    // 1. Segera hapus dari list in-memory dan beritahu UI agar responsif seketika
    _notifications = _notifications.where((n) => n.id != notificationId).toList();
    notifyListeners();

    // 2. Simpan ID ke SharedPreferences agar tidak akan pernah muncul lagi saat navigasi kembali / buka ulang
    try {
      final deletedIds = await _getDeletedNotificationIds();
      deletedIds.add(notificationId);
      await _saveDeletedNotificationIds(deletedIds);
    } catch (e) {
      debugPrint('Error saving deleted notification to SharedPreferences: $e');
    }

    // 3. Hapus juga dari database Supabase
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      debugPrint('Error deleting notification from Supabase: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    if (_currentUser == null) return;
    
    // 1. Simpan semua ID yang sedang tampil ke blacklist terhapus
    final idsToDelete = _notifications.map((n) => n.id).toList();
    _notifications = [];
    notifyListeners();

    // 2. Simpan ke SharedPreferences
    try {
      final deletedIds = await _getDeletedNotificationIds();
      deletedIds.addAll(idsToDelete);
      await _saveDeletedNotificationIds(deletedIds);
    } catch (e) {
      debugPrint('Error saving cleared notifications to SharedPreferences: $e');
    }

    // 3. Hapus juga dari Supabase
    try {
      await _supabase.from('notifications').delete().eq('user_id', _currentUser!.id);
    } catch (e) {
      debugPrint('Error clearing all notifications from Supabase: $e');
    }
  }

  void setHistoryFilter(String filter) {
    _historyFilter = filter;
    loadParticipantData();
  }

  Future<void> loadAdminData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _participantsList = await ProfileService.getAllParticipants();
      _allAttendances = await AttendanceService.getAllAttendance();

      // Load fields
      final fieldsResp = await _supabase.from('fields').select().eq('status', 'Aktif').order('name');
      _fieldsList = (fieldsResp as List).map((e) => FieldModel.fromMap(e)).toList();

      // Load divisions
      final divisionsResp = await _supabase.from('divisions').select().eq('status', 'Aktif').order('name');
      _divisionsList = (divisionsResp as List).map((e) => DivisionModel.fromMap(e)).toList();

      // Load supervisors
      final supervisorsResp = await _supabase.from('supervisors').select().eq('status', 'Aktif').order('name');
      _supervisorsList = (supervisorsResp as List).map((e) => SupervisorModel.fromMap(e)).toList();

      debugPrint('✅ loadAdminData: ${_participantsList.length} peserta, ${_fieldsList.length} bidang, ${_supervisorsList.length} pembimbing');
    } catch (e) {
      _errorMessage = 'Gagal memuat data: $e';
      debugPrint('❌ loadAdminData ERROR: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setAdminFilterDate(String dateKey) {
    _adminFilterDateKey = dateKey;
    notifyListeners();
  }

  void setAdminFilterUniversity(String university) {
    _adminFilterUniversity = university;
    notifyListeners();
  }

  void setAdminFilterField(String field) {
    _adminFilterField = field;
    notifyListeners();
  }

  void setAdminFilterStatus(String status) {
    _adminFilterStatus = status;
    notifyListeners();
  }

  void setAdminSearchQuery(String query) {
    _adminSearchQuery = query;
    notifyListeners();
  }

  void resetAdminFilters() {
    _adminFilterDateKey = '';
    _adminFilterUniversity = 'Semua';
    _adminFilterField = 'Semua';
    _adminFilterStatus = 'Semua';
    _adminSearchQuery = '';
    notifyListeners();
  }

  Future<bool> submitAttendanceRecord(
    AttendanceModel record, {
    bool sendNotification = true,
    String? customNotificationMessage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (record.checkInTime != null && record.checkOutTime == null) {
         await AttendanceService.checkIn(record);
      } else if (record.checkOutTime != null) {
         await AttendanceService.checkOut(record.id, record);
      } else {
         // This is Izin or Sakit
         await AttendanceService.checkIn(record);
         // Trigger notification to supervisor (pembimbing)
         if (_currentUser != null && sendNotification) {
           final statusName = record.status;
           final reasonText = customNotificationMessage ??
               (record.reason != null && record.reason!.isNotEmpty
                   ? 'Alasan: ${record.reason}'
                   : 'Peserta ${_currentUser!.name} mengajukan $statusName pada tanggal ${record.date}.');

           await NotificationService.sendNotificationToSupervisor(
             supervisorRowId: _currentUser!.supervisorId,
             fieldId: _currentUser!.fieldId,
             title: 'Pengajuan $statusName - ${_currentUser!.name}',
             message: reasonText,
           );
         }
      }
      
      _todayAttendance = await AttendanceService.getAttendanceByDate(record.userId, record.date);
      await loadParticipantData();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveParticipant(ProfileModel participant) async {
    try {
      await ProfileService.updateProfile(participant);
      await loadAdminData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerAndSaveParticipant(ProfileModel participant, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uid = await AuthService.registerUser(email: participant.email, password: password);
      final newParticipant = participant.copyWith(id: uid);
      await ProfileService.updateProfile(newParticipant);
      
      await loadAdminData();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateParticipantStatus(String id, String status) async {
    try {
      final profile = _participantsList.firstWhere((p) => p.id == id);
      await ProfileService.updateProfile(profile.copyWith(status: status));
      await loadAdminData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteParticipant(String id, {String? participantName}) async {
    try {
      String resolvedName = participantName ?? '';
      if (resolvedName.isEmpty) {
        final existing = _participantsList.where((p) => p.id == id);
        if (existing.isNotEmpty) {
          resolvedName = existing.first.name;
        }
      }

      await ProfileService.deleteParticipant(id, participantName: resolvedName);
      _participantsList.removeWhere((p) => p.id == id);

      if (resolvedName.isNotEmpty) {
        _notifications.removeWhere((n) =>
          n.title.toLowerCase().contains(resolvedName.toLowerCase()) ||
          n.body.toLowerCase().contains(resolvedName.toLowerCase())
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetParticipantPassword(String userId, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await AuthService.resetUserPassword(userId: userId, newPassword: newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update password akun yang sedang login saat ini (Pembimbing / Peserta)
  Future<bool> updateCurrentUserPassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await AuthService.updateCurrentUserPassword(newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reset password pembimbing oleh admin
  Future<bool> resetSupervisorPassword(SupervisorModel supervisor, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Cari ID auth akun login pembimbing dari tabel profiles
      Map<String, dynamic>? prof;

      // 1. Cari berdasarkan supervisor_id dan role 'pembimbing'
      if (supervisor.id.isNotEmpty) {
        final res = await _supabase
            .from('profiles')
            .select('id')
            .eq('supervisor_id', supervisor.id)
            .eq('role', 'pembimbing')
            .limit(1);
        if (res.isNotEmpty) {
          prof = res.first;
        }
      }

      // 2. Cari berdasarkan email dan role 'pembimbing'
      if (prof == null && supervisor.email != null && supervisor.email!.trim().isNotEmpty) {
        final res = await _supabase
            .from('profiles')
            .select('id')
            .ilike('email', supervisor.email!.trim())
            .eq('role', 'pembimbing')
            .limit(1);
        if (res.isNotEmpty) {
          prof = res.first;
        }
      }

      // 3. Fallback: Cari berdasarkan email tanpa filter role (jika role belum diset pembimbing)
      if (prof == null && supervisor.email != null && supervisor.email!.trim().isNotEmpty) {
        final res = await _supabase
            .from('profiles')
            .select('id')
            .ilike('email', supervisor.email!.trim())
            .limit(1);
        if (res.isNotEmpty) {
          prof = res.first;
        }
      }

      // 4. Fallback: jika id di tabel supervisors merupakan ID auth akun profiles
      if (prof == null && supervisor.id.isNotEmpty) {
        final res = await _supabase
            .from('profiles')
            .select('id')
            .eq('id', supervisor.id)
            .limit(1);
        if (res.isNotEmpty) {
          prof = res.first;
        }
      }

      final userId = prof?['id']?.toString();
      if (userId == null) {
        throw 'Akun login pembimbing "${supervisor.name}" belum terdaftar di tabel profiles.';
      }

      await AuthService.resetUserPassword(userId: userId, newPassword: newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addField(FieldModel field) async {
    try {
      await _supabase.from('fields').insert({
        'name': field.name,
        if (field.description != null && field.description!.isNotEmpty)
          'description': field.description,
        'status': field.status,
      });
      await loadAdminData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addDivision(DivisionModel division) async {
    try {
      await _supabase.from('divisions').insert({
        'field_id': division.fieldId,
        'name': division.name,
        if (division.description != null && division.description!.isNotEmpty)
          'description': division.description,
        'status': division.status,
      });
      await loadAdminData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteField(String id) async {
    try {
      await _supabase.from('fields').delete().eq('id', id);
      _fieldsList = _fieldsList.where((f) => f.id != id).toList();
      _divisionsList = _divisionsList.where((d) => d.fieldId != id).toList();
      notifyListeners();
      await loadAdminData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDivision(String id) async {
    try {
      await _supabase.from('divisions').delete().eq('id', id);
      _divisionsList = _divisionsList.where((d) => d.id != id).toList();
      notifyListeners();
      await loadAdminData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSupervisor(String id) async {
    try {
      await SupervisorService.deleteSupervisor(id);
      // Hapus langsung dari local list untuk update UI segera
      _supervisorsList = _supervisorsList.where((s) => s.id != id).toList();
      notifyListeners();
      // Reload dari server untuk sinkronisasi
      await loadAdminData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSupervisor(SupervisorModel supervisor) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupervisorService.updateSupervisor(supervisor);
      await loadAdminData();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> exportRekapToExcel({List<AttendanceModel>? customList}) async {
    return await ExcelExportService.exportRekapToExcel(
      customList ?? filteredAttendances,
      _participantsList,
    );
  }
}