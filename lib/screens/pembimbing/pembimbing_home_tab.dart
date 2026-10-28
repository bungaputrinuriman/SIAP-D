import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/attendance_model.dart';
import '../../providers/app_provider.dart';

class PembimbingHomeTab extends StatelessWidget {
  const PembimbingHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final allParticipants = provider.myParticipants;
    final activeParticipants = allParticipants.where((p) => p.status == 'Aktif').toList();
    final completedCount = allParticipants.where((p) => p.status == 'Selesai').length;
    final allAttendances = provider.myParticipantsAttendances;
    final todayKey = DateFormatter.getTodayKey();

    // Today's attendance map: userId -> AttendanceModel
    final Map<String, AttendanceModel> todayAttMap = {};
    for (final att in allAttendances) {
      if (att.date == todayKey) {
        todayAttMap[att.userId] = att;
      }
    }

    final hadirCount = todayAttMap.values.where((a) => a.status.toLowerCase() == 'hadir').length;
    final izinCount = todayAttMap.values.where((a) => a.status.toLowerCase() == 'izin').length;
    final sakitCount = todayAttMap.values.where((a) => a.status.toLowerCase() == 'sakit').length;
    final activeAttendedCount = todayAttMap.keys.where((uid) => activeParticipants.any((p) => p.id == uid)).length;
    final belumCount = activeParticipants.length - activeAttendedCount > 0 ? activeParticipants.length - activeAttendedCount : 0;

    return RefreshIndicator(
      onRefresh: () async => provider.loadPembimbingData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.supervisor_account, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${user?.name ?? 'Pembimbing'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.fieldName?.isNotEmpty == true
                                  ? (user!.fieldName!)
                                  : 'Pembimbing Lapangan PKL',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rekap Hari Ini
            const Text(
              'Ringkasan Kehadiran Hari Ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _statCard('Bimbingan Aktif', '${activeParticipants.length}', Icons.people, AppColors.primary, AppColors.accentLight),
                _statCard('Hadir', '$hadirCount', Icons.check_circle_outline, AppColors.success, AppColors.hadirBg),
                _statCard('Izin', '$izinCount', Icons.event_busy_outlined, AppColors.info, AppColors.izinBg),
                _statCard('Sakit', '$sakitCount', Icons.sick_outlined, AppColors.warning, AppColors.sakitBg),
              ],
            ),
            if (belumCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.belumAbsenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$belumCount peserta aktif belum mengisi absensi hari ini',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (completedCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.archive_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$completedCount anak bimbingan telah menyelesaikan masa PKL (Arsip).',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color iconColor, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: iconColor),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
