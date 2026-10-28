import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common/status_chip.dart';

class AdminRekapPresensiScreen extends StatefulWidget {
  const AdminRekapPresensiScreen({super.key});

  @override
  State<AdminRekapPresensiScreen> createState() => _AdminRekapPresensiScreenState();
}

class _AdminRekapPresensiScreenState extends State<AdminRekapPresensiScreen> {
  // Default to today's date when opening the screen
  DateTime? _selectedDate = DateTime.now();
  String _selectedDivisionId = 'all';

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    // Reload data setiap kali tab rekap dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadAdminData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final divisions = provider.divisionsList;
    final now = DateTime.now();
    final isSelectedToday = _selectedDate != null && _isSameDay(_selectedDate!, now);
    
    // Filter attendance based on selected date (or all dates) and division
    final filteredAttendance = provider.allAttendanceList.where((a) {
      // 1. Division filter
      final isSameDivision = _selectedDivisionId == 'all' || a.divisionId == _selectedDivisionId;
      if (!isSameDivision) return false;

      // 2. Date filter: null means "Semua Tanggal"
      if (_selectedDate == null) {
        return true;
      }

      final targetKey = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      if (a.date == targetKey || a.dateKey == targetKey) {
        return true;
      }

      final aDate = DateTime.tryParse(a.dateKey) ?? DateTime.tryParse(a.date);
      if (aDate != null) {
        return _isSameDay(aDate, _selectedDate!);
      }
      return false;
    }).toList();

    // Sort by date descending
    filteredAttendance.sort((a, b) {
      final aDate = DateTime.tryParse(a.dateKey) ?? DateTime.now();
      final bDate = DateTime.tryParse(b.dateKey) ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    return Column(
      children: [
        // Filter Header & Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Date display button & Division dropdown
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectDate(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Icon(
                                _selectedDate == null
                                    ? Icons.all_inclusive_rounded
                                    : Icons.calendar_today_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? 'Semua Tanggal'
                                      : (isSelectedToday
                                          ? 'Hari Ini (${DateFormat('d MMM', 'id_ID').format(_selectedDate!)})'
                                          : DateFormat('d MMM yyyy', 'id_ID').format(_selectedDate!)),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_selectedDate != null)
                                Tooltip(
                                  message: 'Tampilkan Semua Tanggal',
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDate = null;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedDivisionId,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('Semua Divisi')),
                            ...divisions.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedDivisionId = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Row 2: Quick Filter Chips (Hari Ini | Pilih Tanggal | Semua Tanggal)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Hari Ini',
                      icon: Icons.today_rounded,
                      isSelected: isSelectedToday,
                      onTap: () {
                        setState(() {
                          _selectedDate = DateTime.now();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: (_selectedDate != null && !isSelectedToday)
                          ? DateFormat('d MMM yyyy', 'id_ID').format(_selectedDate!)
                          : 'Pilih Tanggal',
                      icon: Icons.calendar_month_rounded,
                      isSelected: _selectedDate != null && !isSelectedToday,
                      onTap: () => _selectDate(context),
                      onClear: (_selectedDate != null && !isSelectedToday)
                          ? () => setState(() => _selectedDate = null)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Semua Tanggal',
                      icon: Icons.all_inclusive_rounded,
                      isSelected: _selectedDate == null,
                      onTap: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Row 3: Summary counter chips
              Row(
                children: [
                  _buildSummaryBadge('Total', '${filteredAttendance.length}', AppColors.primary),
                  const SizedBox(width: 8),
                  _buildSummaryBadge('Hadir', '${filteredAttendance.where((a) => a.status == 'Hadir').length}', AppColors.success),
                  const SizedBox(width: 8),
                  _buildSummaryBadge('Izin', '${filteredAttendance.where((a) => a.status == 'Izin').length}', AppColors.info),
                  const SizedBox(width: 8),
                  _buildSummaryBadge('Sakit', '${filteredAttendance.where((a) => a.status == 'Sakit').length}', AppColors.warning),
                ],
              ),
              const SizedBox(height: 12),
              
              // Row 4: Export to Excel Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mengekspor data ke Excel...')),
                    );
                    final success = await provider.exportRekapToExcel(customList: filteredAttendance);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      if (success != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Berhasil mengunduh absensi_diskominfo.xlsx!'), backgroundColor: AppColors.success),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gagal mengekspor data.'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Export Laporan (.xlsx)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),

        // Data List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await provider.loadAdminData();
            },
            child: filteredAttendance.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.insert_chart_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tidak Ada Data',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedDate != null
                                      ? 'Belum ada data presensi pada ${isSelectedToday ? "hari ini" : DateFormat("d MMMM yyyy", "id_ID").format(_selectedDate!)}.'
                                      : 'Belum ada data presensi yang tercatat.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => provider.loadAdminData(),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Muat Ulang'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredAttendance.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final att = filteredAttendance[index];
                      final parsedDate = DateTime.tryParse(att.dateKey) ?? DateTime.tryParse(att.date) ?? DateTime.now();
                      final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(parsedDate);
                      
                      return Container(
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
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      att.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                att.divisionName ?? '-',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.login, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        att.checkInTime != null ? DateFormat('HH:mm').format(att.checkInTime!) : '--:--',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(width: 14),
                                      const Icon(Icons.logout, size: 16, color: AppColors.accent),
                                      const SizedBox(width: 4),
                                      Text(
                                        att.checkOutTime != null ? DateFormat('HH:mm').format(att.checkOutTime!) : '--:--',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                  StatusChip(status: att.status),
                                ],
                              ),
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

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              if (onClear != null && isSelected) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Pilih Tanggal Presensi',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
