import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common/status_chip.dart';
import 'peserta_attendance_screen.dart';

class PesertaHomeTab extends StatelessWidget {
  final Function(int) onNavigateTab;

  const PesertaHomeTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final todayAtt = provider.todayAttendance;
    final hasCheckedIn = provider.hasCheckedInToday;
    final hasCheckedOut = provider.hasCheckedOutToday;
    final isIzinOrSakit = todayAtt != null && (todayAtt.status.toLowerCase() == 'izin' || todayAtt.status.toLowerCase() == 'sakit');
    final isSelesai = user?.status.toLowerCase() == 'selesai';


    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadParticipantData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22.0),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${user?.name ?? 'Peserta PKL'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user?.university} • ${user?.nim}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelesai ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelesai) ...[
                              const Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              isSelesai ? 'Selesai PKL' : (user?.status ?? 'Aktif'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user?.fieldName?.isNotEmpty == true
                                    ? (user!.fieldName ?? '-')
                                    : 'Bidang Teknologi Informasi',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (user?.divisionName?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.account_tree_outlined, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  user!.divisionName ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date & Today Status Header / Selesai Banner
            if (isSelesai) ...[
              Card(
                elevation: 0,
                color: const Color(0xFFF0FDF4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF86EFAC)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified, color: Color(0xFF16A34A), size: 36),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Masa Magang / PKL Telah Selesai',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selamat dan terima kasih atas dedikasi Anda selama masa magang di Diskominfo. Akun Anda kini berstatus arsip alumni. Seluruh data presensi dan riwayat kegiatan Anda tetap tersimpan dengan aman.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF15803D),
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => onNavigateTab(1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.folder_shared_outlined, size: 18),
                          label: const Text(
                            'Buka Riwayat & Arsip Presensi',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Presensi Hari Ini',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.formatFullDate(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  StatusChip(
                    status: todayAtt != null ? todayAtt.status : 'Belum Absen',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Today's Attendance Card Detail
              if (isIzinOrSakit)
                Card(
                  elevation: 0,
                  color: (todayAtt.status == 'Izin' ? AppColors.infoLight : AppColors.warningLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: (todayAtt.status == 'Izin' ? AppColors.info : AppColors.warning).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              todayAtt.status == 'Izin' ? Icons.info_outline : Icons.sick_outlined,
                              color: todayAtt.status == 'Izin' ? AppColors.info : AppColors.warning,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                todayAtt.status == 'Sakit'
                                    ? 'Status Kehadiran: Sakit (Masa Pengajuan Sakit)'
                                    : 'Status Kehadiran: ${todayAtt.status}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: todayAtt.status == 'Izin' ? AppColors.infoText : AppColors.sakitText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          todayAtt.status == 'Sakit'
                              ? 'Keterangan Sakit Selama Rentang Tanggal Pengajuan:'
                              : 'Alasan Pengajuan:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: todayAtt.status == 'Izin' ? AppColors.infoText : AppColors.sakitText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (todayAtt.status == 'Izin' ? AppColors.info : AppColors.warning).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            (todayAtt.reason?.isNotEmpty == true)
                                ? todayAtt.reason!
                                : (todayAtt.note.isNotEmpty ? todayAtt.note : '-'),
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeBox(
                                title: 'Absen Masuk',
                                time: hasCheckedIn && todayAtt!.checkInTime != null ? "${todayAtt.checkInTime!.hour.toString().padLeft(2, '0')}:${todayAtt.checkInTime!.minute.toString().padLeft(2, '0')}" : 'Belum Absen',
                                isDone: hasCheckedIn,
                                icon: Icons.login,
                                color: AppColors.success,
                              ),
                            ),
                            Container(
                              height: 44,
                              width: 1,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _buildTimeBox(
                                title: 'Absen Pulang',
                                time: hasCheckedOut && todayAtt!.checkOutTime != null ? "${todayAtt.checkOutTime!.hour.toString().padLeft(2, '0')}:${todayAtt.checkOutTime!.minute.toString().padLeft(2, '0')}" : 'Belum Absen',
                                isDone: hasCheckedOut,
                                icon: Icons.logout,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        if (todayAtt?.note.isNotEmpty == true) ...[
                          const Divider(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notes, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Catatan: ${todayAtt!.note}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (hasCheckedIn && hasCheckedOut) || isIzinOrSakit
                        ? AppColors.surfaceVariant
                        : AppColors.primary,
                    foregroundColor: (hasCheckedIn && hasCheckedOut) || isIzinOrSakit
                        ? AppColors.textSecondary
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: (hasCheckedIn && hasCheckedOut) || isIzinOrSakit ? 0 : 2,
                  ),
                  onPressed: (hasCheckedIn && hasCheckedOut) || isIzinOrSakit
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PesertaAttendanceScreen(),
                            ),
                          );
                        },
                  icon: Icon(
                    isIzinOrSakit || (hasCheckedIn && hasCheckedOut)
                        ? Icons.check_circle
                        : (hasCheckedIn ? Icons.logout : Icons.how_to_reg),
                  ),
                  label: Text(
                    isIzinOrSakit
                        ? 'Pengajuan ${todayAtt.status} Aktif'
                        : (!hasCheckedIn
                            ? 'Absen Masuk'
                            : (!hasCheckedOut
                                ? 'Absen Pulang'
                                : 'Absensi Hari Ini Lengkap')),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: (hasCheckedIn && hasCheckedOut) || isIzinOrSakit
                          ? AppColors.textMuted
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Recent History Snippet Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Terakhir',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigateTab(1), // Jump to history tab (index 1)
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Recent History List
            if (provider.participantHistory.isEmpty)
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'Belum ada data presensi tersimpan.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
              )
            else
              ...provider.participantHistory.take(3).map((item) {
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      item.displayDate,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      item.status == 'Hadir'
                          ? 'Masuk: ${item.checkInTime != null ? DateFormat('HH:mm').format(item.checkInTime!) : '--:--'} • Keluar: ${item.checkOutTime != null ? DateFormat('HH:mm').format(item.checkOutTime!) : '--:--'}'
                          : 'Alasan: ${(item.reason?.isNotEmpty == true) ? item.reason! : (item.note.isNotEmpty ? item.note : '-')}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: StatusChip(status: item.status),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBox({
    required String title,
    required String time,
    required bool isDone,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isDone ? color : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDone ? color : AppColors.textMuted,
              ),
            ),
            if (isDone) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 16, color: color),
            ],
          ],
        ),
      ],
    );
  }
}
