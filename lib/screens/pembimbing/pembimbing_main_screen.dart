import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common/top_notification_banner.dart';
import 'pembimbing_home_tab.dart';
import 'pembimbing_kehadiran_tab.dart';
import 'pembimbing_notifikasi_tab.dart';
import 'pembimbing_profile_tab.dart';

class PembimbingMainScreen extends StatefulWidget {
  const PembimbingMainScreen({super.key});

  @override
  State<PembimbingMainScreen> createState() => _PembimbingMainScreenState();
}

class _PembimbingMainScreenState extends State<PembimbingMainScreen> {
  int _currentIndex = 0;
  RealtimeChannel? _notifChannel;
  Timer? _pollingTimer;
  final Set<String> _shownNotificationIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      provider.loadPembimbingData().then((_) {
        if (!mounted) return;
        _setupRealtimeNotifications(provider);
        // Beri sedikit jeda 400ms setelah UI dashboard ter-render agar animasi banner meluncur mulus seperti WhatsApp
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _checkAndShowNewNotifications(provider);
          }
        });
      });

      // Polling setiap 4 detik agar notifikasi selalu fresh
      _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (!mounted) return;
        final prov = context.read<AppProvider>();
        await prov.loadPembimbingData();
        _checkAndShowNewNotifications(prov);
      });
    });
  }

  Future<void> _checkAndShowNewNotifications(AppProvider prov) async {
    if (!mounted) return;
    final user = prov.currentUser;
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'popped_notifs_${user.id}';
      final savedList = prefs.getStringList(key) ?? [];
      final Set<String> persistedShownIds = savedList.toSet()..addAll(_shownNotificationIds);

      for (final n in prov.notifications) {
        if (!n.isRead && !persistedShownIds.contains(n.id)) {
          _shownNotificationIds.add(n.id);
          persistedShownIds.add(n.id);

          // Simpan ID notifikasi yang sudah muncul pop-up-nya ke SharedPreferences
          // agar setelah logout dan login kembali tidak pernah muncul pop-up lagi
          final updatedList = persistedShownIds.toList();
          if (updatedList.length > 200) {
            updatedList.removeRange(0, updatedList.length - 200);
          }
          await prefs.setStringList(key, updatedList);

          _showTopBanner(n.id, n.title, n.body, prov);
          break; // Tampilkan satu notifikasi teratas
        }
      }
    } catch (e) {
      debugPrint('Error in _checkAndShowNewNotifications: $e');
    }
  }

  void _showTopBanner(String notifId, String title, String body, AppProvider prov) {
    if (!mounted) return;
    TopNotificationBanner.show(
      context,
      title: title,
      body: body,
      timeAgo: 'Baru saja',
      onTap: () {
        // Tandai notifikasi sebagai dibaca di database
        prov.markNotificationRead(notifId);
        // Langsung arahkan ke halaman Kehadiran saat banner disentuh
        setState(() => _currentIndex = 1);
      },
    );
  }

  void _setupRealtimeNotifications(AppProvider provider) {
    final user = provider.currentUser;
    if (user == null) return;

    try {
      _notifChannel = Supabase.instance.client
          .channel('pembimbing_notifs_${user.id}')
          .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              callback: (payload) async {
                final newRecord = payload.newRecord;
                final notifUserId = newRecord['user_id']?.toString();
                final notifId = newRecord['id']?.toString();
                if (notifUserId == null || notifUserId == user.id) {
                  if (mounted && notifId != null) {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final key = 'popped_notifs_${user.id}';
                      final savedList = prefs.getStringList(key) ?? [];
                      if (!savedList.contains(notifId) && !_shownNotificationIds.contains(notifId)) {
                        _shownNotificationIds.add(notifId);
                        savedList.add(notifId);
                        await prefs.setStringList(key, savedList);

                        final title = newRecord['title']?.toString() ?? 'Pemberitahuan Baru';
                        final body = newRecord['body']?.toString() ?? '';
                        // Tampilkan floating push notification banner dari atas
                        _showTopBanner(notifId, title, body, provider);
                      }
                    } catch (e) {
                      debugPrint('Realtime notif error: $e');
                    }
                    // Reload data
                    provider.loadPembimbingData();
                  }
                }
              })
          .subscribe();
    } catch (e) {
      debugPrint('Realtime notification error: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _notifChannel?.unsubscribe();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = [
      'Dashboard Pembimbing',
      'Kehadiran Peserta',
      'Profil Saya',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[_currentIndex],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'DISKOMINFO • Pembimbing Lapangan',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (context, prov, child) {
              final unread = prov.unreadNotificationCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    tooltip: 'Riwayat Notifikasi',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: const Text(
                                'Notifikasi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              iconTheme: const IconThemeData(color: Colors.white),
                              leading: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            body: const PembimbingNotifikasiTab(),
                          ),
                        ),
                      );
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          PembimbingHomeTab(),
          PembimbingKehadiranTab(),
          PembimbingProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fact_check_outlined),
              activeIcon: Icon(Icons.fact_check),
              label: 'Kehadiran',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
