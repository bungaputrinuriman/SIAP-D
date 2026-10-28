import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/attendance_model.dart';
import '../../models/profile_model.dart';
import '../../providers/app_provider.dart';

class PembimbingKehadiranTab extends StatefulWidget {
  const PembimbingKehadiranTab({super.key});

  @override
  State<PembimbingKehadiranTab> createState() => _PembimbingKehadiranTabState();
}

class _PembimbingKehadiranTabState extends State<PembimbingKehadiranTab> {
  int _activeTabIndex = 0; // 0: Peserta Aktif, 1: Arsip Selesai
  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'Semua'; // 'Semua', 'Hadir', 'Izin', 'Sakit', 'Belum Absen'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final participants = provider.myParticipants;
    final allAttendances = provider.myParticipantsAttendances;

    // Pisahkan peserta aktif dan yang sudah selesai/arsip
    final activePesertaList = participants.where((p) => p.status != 'Selesai').toList();
    final selesaiPesertaList = participants.where((p) => p.status == 'Selesai').toList();

    final dateKey = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final isToday = DateFormatter.getTodayKey() == dateKey;

    // Filter attendance for the selected date
    final Map<String, AttendanceModel> attMap = {};
    for (final att in allAttendances) {
      if (att.date == dateKey) {
        attMap[att.userId] = att;
      }
    }

    // Build participant attendance status list HANYA untuk peserta aktif
    final List<Map<String, dynamic>> participantStatusList = activePesertaList.map((peserta) {
      final att = attMap[peserta.id];
      final status = att != null ? att.status : 'Belum Absen';
      return {
        'peserta': peserta,
        'attendance': att,
        'status': status,
      };
    }).toList();

    // Counts (hanya berdasarkan peserta aktif agar tidak menumpuk)
    final int hadirCount = participantStatusList.where((item) => (item['status'] as String).toLowerCase() == 'hadir').length;
    final int izinCount = participantStatusList.where((item) => (item['status'] as String).toLowerCase() == 'izin').length;
    final int sakitCount = participantStatusList.where((item) => (item['status'] as String).toLowerCase() == 'sakit').length;
    final int belumCount = participantStatusList.where((item) => (item['status'] as String).toLowerCase() == 'belum absen').length;

    // Apply Filter & Search untuk Peserta Aktif
    final filteredActiveList = participantStatusList.where((item) {
      final ProfileModel p = item['peserta'];
      final String s = item['status'];

      // Status Filter
      if (_statusFilter != 'Semua' && s.toLowerCase() != _statusFilter.toLowerCase()) {
        return false;
      }

      // Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = p.name.toLowerCase().contains(query);
        final univMatch = (p.university ?? '').toLowerCase().contains(query);
        final nimMatch = (p.nim ?? '').toLowerCase().contains(query);
        if (!nameMatch && !univMatch && !nimMatch) return false;
      }

      return true;
    }).toList();

    // Apply Search untuk Peserta Arsip Selesai
    final filteredSelesaiList = selesaiPesertaList.where((p) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = p.name.toLowerCase().contains(query);
        final univMatch = (p.university ?? '').toLowerCase().contains(query);
        final nimMatch = (p.nim ?? '').toLowerCase().contains(query);
        if (!nameMatch && !univMatch && !nimMatch) return false;
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async => provider.loadPembimbingData(),
      child: Column(
        children: [
          // Segmented Tab Selector: Aktif vs Arsip Selesai
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeTabIndex = 0;
                          _statusFilter = 'Semua';
                        });
                      },
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: _activeTabIndex == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Peserta Aktif (${activePesertaList.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _activeTabIndex == 0 ? FontWeight.bold : FontWeight.w500,
                                color: _activeTabIndex == 0 ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeTabIndex = 1;
                        });
                      },
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: _activeTabIndex == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.archive_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Arsip Selesai (${selesaiPesertaList.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _activeTabIndex == 1 ? FontWeight.bold : FontWeight.w500,
                                color: _activeTabIndex == 1 ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter Top Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_activeTabIndex == 0) ...[
                  // Date picker row (hanya di tab aktif)
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isToday
                                        ? 'Hari Ini (${DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate)})'
                                        : DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isToday) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedDate = DateTime.now());
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Hari Ini', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _activeTabIndex == 0
                        ? 'Cari nama atau institusi peserta aktif...'
                        : 'Cari arsip nama atau institusi peserta selesai...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),

                if (_activeTabIndex == 0) ...[
                  const SizedBox(height: 12),
                  // Status Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua', activePesertaList.length, AppColors.primary),
                        const SizedBox(width: 8),
                        _buildFilterChip('Hadir', hadirCount, AppColors.success),
                        const SizedBox(width: 8),
                        _buildFilterChip('Izin', izinCount, AppColors.info),
                        const SizedBox(width: 8),
                        _buildFilterChip('Sakit', sakitCount, AppColors.warning),
                        const SizedBox(width: 8),
                        _buildFilterChip('Belum Absen', belumCount, AppColors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // List Data Peserta (Aktif atau Arsip Selesai)
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _activeTabIndex == 0
                    ? (filteredActiveList.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.person_search_outlined, size: 64, color: AppColors.textMuted),
                                    const SizedBox(height: 14),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Tidak ada peserta dengan kata kunci "$_searchQuery"'
                                          : 'Tidak ada data peserta aktif untuk filter ini',
                                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Coba ubah tanggal atau status filter',
                                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            itemCount: filteredActiveList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = filteredActiveList[index];
                              final ProfileModel peserta = item['peserta'];
                              final AttendanceModel? att = item['attendance'];
                              final String status = item['status'];
                              return _buildParticipantCard(context, peserta, att, status);
                            },
                          ))
                    : (filteredSelesaiList.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.archive_outlined, size: 64, color: AppColors.textMuted),
                                    const SizedBox(height: 14),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Tidak ditemukan arsip peserta "$_searchQuery"'
                                          : 'Belum ada arsip peserta PKL yang selesai bimbingan',
                                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Peserta yang telah ditandai Selesai oleh Admin akan tersimpan di sini',
                                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            itemCount: filteredSelesaiList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final peserta = filteredSelesaiList[index];
                              final userAttendances = allAttendances.where((a) => a.userId == peserta.id).toList();
                              return _buildCompletedParticipantCard(context, peserta, userAttendances);
                            },
                          )),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, Color color) {
    final isSelected = _statusFilter.toLowerCase() == label.toLowerCase();
    return InkWell(
      onTap: () => setState(() => _statusFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(BuildContext context, ProfileModel peserta, AttendanceModel? att, String status) {
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'hadir':
        statusColor = AppColors.hadirText;
        statusBg = AppColors.hadirBg;
        statusIcon = Icons.check_circle;
        break;
      case 'izin':
        statusColor = AppColors.izinText;
        statusBg = AppColors.izinBg;
        statusIcon = Icons.event_busy;
        break;
      case 'sakit':
        statusColor = AppColors.sakitText;
        statusBg = AppColors.sakitBg;
        statusIcon = Icons.sick;
        break;
      default:
        statusColor = AppColors.belumAbsenText;
        statusBg = AppColors.belumAbsenBg;
        statusIcon = Icons.access_time;
    }

    String checkInTimeStr = '-';
    String checkOutTimeStr = '-';
    if (att != null) {
      if (att.checkInTime != null) {
        checkInTimeStr = "${att.checkInTime!.hour.toString().padLeft(2, '0')}:${att.checkInTime!.minute.toString().padLeft(2, '0')}";
      }
      if (att.checkOutTime != null) {
        checkOutTimeStr = "${att.checkOutTime!.hour.toString().padLeft(2, '0')}:${att.checkOutTime!.minute.toString().padLeft(2, '0')}";
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailDialog(context, peserta, att, status),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar, Name & Status
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        peserta.name.isNotEmpty ? peserta.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peserta.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${peserta.university ?? '-'} • ${peserta.nim ?? '-'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Detail row if attended or leave
                if (status.toLowerCase() == 'hadir') ...[
                  const Divider(height: 20, color: AppColors.border),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.login, size: 14, color: AppColors.success),
                            const SizedBox(width: 6),
                            Text(
                              'Masuk: $checkInTimeStr',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.logout, size: 14, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Text(
                              'Pulang: $checkOutTimeStr',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (att?.reason != null && att!.reason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Catatan: ${att.reason}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ] else if (att?.reason != null && att!.reason!.isNotEmpty) ...[
                  const Divider(height: 20, color: AppColors.border),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        status.toLowerCase() == 'sakit' ? Icons.sick_outlined : Icons.info_outline,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Keterangan: ${att.reason}',
                          style: TextStyle(fontSize: 12, color: statusColor, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, ProfileModel peserta, AttendanceModel? att, String status) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Presensi Peserta',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      peserta.name.isNotEmpty ? peserta.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          peserta.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${peserta.university ?? '-'} • ${peserta.nim ?? '-'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _detailRow('Tanggal', DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate)),
                    _detailRow('Status Kehadiran', status),
                    if (att != null) ...[
                      if (att.checkInTime != null)
                        _detailRow('Jam Masuk', DateFormat('HH:mm WIB').format(att.checkInTime!)),
                      if (att.checkOutTime != null)
                        _detailRow('Jam Pulang', DateFormat('HH:mm WIB').format(att.checkOutTime!)),
                      if (att.reason != null && att.reason!.isNotEmpty)
                        _detailRow(status == 'Hadir' ? 'Catatan Kegiatan' : 'Alasan / Keterangan', att.reason!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          const Text(': ', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedParticipantCard(BuildContext context, ProfileModel peserta, List<AttendanceModel> userAttendances) {
    final int totalHadir = userAttendances.where((a) => a.status.toLowerCase() == 'hadir').length;
    final int totalIzin = userAttendances.where((a) => a.status.toLowerCase() == 'izin').length;
    final int totalSakit = userAttendances.where((a) => a.status.toLowerCase() == 'sakit').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showArsipPresensiDialog(context, peserta, userAttendances),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      child: Text(
                        peserta.name.isNotEmpty ? peserta.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  peserta.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Selesai',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${peserta.university ?? '-'} • ${peserta.nim ?? '-'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildArsipStatItem('Total Hadir', '$totalHadir', AppColors.success),
                      Container(height: 20, width: 1, color: AppColors.border),
                      _buildArsipStatItem('Total Izin', '$totalIzin', AppColors.info),
                      Container(height: 20, width: 1, color: AppColors.border),
                      _buildArsipStatItem('Total Sakit', '$totalSakit', AppColors.warning),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArsipStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  void _showArsipPresensiDialog(BuildContext context, ProfileModel peserta, List<AttendanceModel> userAttendances) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Arsip Presensi Peserta',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Selesai PKL',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      peserta.name.isNotEmpty ? peserta.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(peserta.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${peserta.university ?? '-'} • ${peserta.nim ?? '-'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Total Rekam Kehadiran: ${userAttendances.length} Hari',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: userAttendances.isEmpty
                    ? const Center(
                        child: Text('Tidak ada riwayat presensi yang tersimpan',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      )
                    : ListView.separated(
                        itemCount: userAttendances.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final att = userAttendances[index];
                          Color chipColor = att.status == 'Hadir'
                              ? AppColors.success
                              : (att.status == 'Izin' ? AppColors.info : AppColors.warning);
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        att.displayDate,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        att.status == 'Hadir'
                                            ? 'Masuk: ${att.checkInTime != null ? DateFormat('HH:mm').format(att.checkInTime!) : '--:--'} • Pulang: ${att.checkOutTime != null ? DateFormat('HH:mm').format(att.checkOutTime!) : '--:--'}'
                                            : (att.reason?.isNotEmpty == true ? att.reason! : '-'),
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: chipColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: chipColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    att.status,
                                    style: TextStyle(color: chipColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup Arsip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
