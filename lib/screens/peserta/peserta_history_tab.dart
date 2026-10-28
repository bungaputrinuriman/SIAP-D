import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common/status_chip.dart';

class PesertaHistoryTab extends StatelessWidget {
  const PesertaHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final history = provider.userAttendanceHistory;

    final totalHadir = history.where((h) => h.status.toLowerCase() == 'hadir').length;
    final totalIzinSakit = history.where((h) => h.status.toLowerCase() == 'izin' || h.status.toLowerCase() == 'sakit').length;


    return Column(
      children: [
        // Summary Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Presensi Anda',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalHadir Hadir',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalIzinSakit Izin/Sakit',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await provider.loadUserData();
            },
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum Ada Riwayat',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Data presensi Anda akan muncul di sini.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final att = history[index];
                      final parsedDate = DateTime.tryParse(att.dateKey) ?? DateTime.now();
                      final dateStr = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(parsedDate);
                      
                      final isHadir = att.status.toLowerCase() == 'hadir';


                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateStr,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                  StatusChip(status: att.status),
                                ],
                              ),
                              const Divider(height: 20),
                              if (isHadir) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Absen Masuk', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(Icons.login, size: 16, color: AppColors.primary),
                                              const SizedBox(width: 6),
                                              Text(
                                                att.checkInTime != null ? DateFormat('HH:mm').format(att.checkInTime!) : '--:--',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(height: 30, width: 1, color: AppColors.border),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Absen Pulang', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(Icons.logout, size: 16, color: AppColors.accent),
                                              const SizedBox(width: 6),
                                              Text(
                                                att.checkOutTime != null ? DateFormat('HH:mm').format(att.checkOutTime!) : '--:--',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // Jika izin / sakit
                                Row(
                                  children: [
                                    Icon(
                                      att.status.toLowerCase() == 'sakit' ? Icons.sick_outlined : Icons.info_outline,
                                      size: 18,
                                      color: att.status.toLowerCase() == 'sakit' ? AppColors.warning : AppColors.info,

                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        att.reason?.isNotEmpty == true ? att.reason! : (att.note.isNotEmpty ? att.note : 'Tidak ada keterangan tambahan.'),
                                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
