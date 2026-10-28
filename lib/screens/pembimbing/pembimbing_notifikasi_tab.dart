import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/app_provider.dart';

class PembimbingNotifikasiTab extends StatelessWidget {
  const PembimbingNotifikasiTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final notifications = provider.notifications;

    return RefreshIndicator(
      onRefresh: () async => provider.loadPembimbingData(),
      child: Column(
        children: [
          // Header action bar
          if (notifications.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    notifications.any((n) => !n.isRead)
                        ? '${provider.unreadNotificationCount} belum dibaca'
                        : '${notifications.length} notifikasi',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      if (notifications.any((n) => !n.isRead))
                        TextButton(
                          onPressed: () => provider.markAllNotificationsRead(),
                          child: const Text('Tandai dibaca', style: TextStyle(fontSize: 13, color: AppColors.accent)),
                        ),
                      TextButton.icon(
                        onPressed: () => _confirmClearAll(context, provider),
                        icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppColors.error),
                        label: const Text('Hapus Semua', style: TextStyle(fontSize: 13, color: AppColors.error)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const Divider(height: 1, color: AppColors.border),

          Expanded(
            child: notifications.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none, size: 72, color: AppColors.textMuted),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada notifikasi',
                              style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Notifikasi izin & sakit anak bimbingan\nakan muncul di sini',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border, indent: 72),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return Dismissible(
                        key: Key(notif.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: AppColors.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          provider.deleteNotification(notif.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notifikasi dihapus'), duration: Duration(seconds: 2)),
                          );
                        },
                        child: _notifTile(context, notif, provider),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _notifTile(BuildContext context, NotificationModel notif, AppProvider provider) {
    final isIzin = notif.title.toLowerCase().contains('izin');
    final isSakit = notif.title.toLowerCase().contains('sakit');

    Color iconBg;
    Color iconColor;
    IconData icon;

    if (isSakit) {
      iconBg = AppColors.sakitBg;
      iconColor = AppColors.sakitText;
      icon = Icons.sick_outlined;
    } else if (isIzin) {
      iconBg = AppColors.izinBg;
      iconColor = AppColors.izinText;
      icon = Icons.event_busy_outlined;
    } else {
      iconBg = AppColors.accentLight;
      iconColor = AppColors.accent;
      icon = Icons.notifications_outlined;
    }

    return InkWell(
      onTap: () {
        if (!notif.isRead) provider.markNotificationRead(notif.id);
        _showNotifDetail(context, notif, provider);
      },
      child: Container(
        color: notif.isRead ? Colors.transparent : AppColors.accentLight.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(notif.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
              tooltip: 'Hapus notifikasi',
              onPressed: () async {
                await provider.deleteNotification(notif.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifikasi dihapus'), duration: Duration(seconds: 2)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
  }

  void _showNotifDetail(BuildContext context, NotificationModel notif, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.body, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Text(
              DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(notif.createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteNotification(notif.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifikasi dihapus'), duration: Duration(seconds: 2)),
                );
              }
            },
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
            label: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Semua Notifikasi'),
        content: const Text('Apakah Anda yakin ingin menghapus seluruh riwayat notifikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.clearAllNotifications();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua notifikasi berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}
