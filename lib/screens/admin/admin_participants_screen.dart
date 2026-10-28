import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/status_chip.dart';

class AdminParticipantsScreen extends StatefulWidget {
  const AdminParticipantsScreen({super.key});

  @override
  State<AdminParticipantsScreen> createState() => _AdminParticipantsScreenState();
}

class _AdminParticipantsScreenState extends State<AdminParticipantsScreen> {
  final _searchController = TextEditingController();
  int _selectedTab = 0; // 0: Aktif, 1: Arsip Selesai, 2: Semua

  @override
  void initState() {
    super.initState();
    // Reload data setiap kali screen ini dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loadAdminData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final allParticipants = provider.filteredParticipants;

    final activeCount = provider.participantsList.where((p) => p.status == 'Aktif').length;
    final finishedCount = provider.participantsList.where((p) => p.status == 'Selesai').length;
    final totalCount = provider.participantsList.length;

    // Filter berdasarkan tab yang dipilih agar tidak menumpuk
    final displayedParticipants = allParticipants.where((p) {
      if (_selectedTab == 0) return p.status == 'Aktif';
      if (_selectedTab == 1) return p.status == 'Selesai';
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Add Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => provider.setAdminSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, NIM, universitas...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              provider.setAdminSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _showAddEditParticipantDialog(context, provider),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),

        // Tab Filter: Aktif / Arsip Selesai / Semua
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              _buildTabButton(
                index: 0,
                title: 'Aktif',
                count: activeCount,
                icon: Icons.check_circle_outline,
                activeColor: AppColors.success,
              ),
              const SizedBox(width: 8),
              _buildTabButton(
                index: 1,
                title: 'Arsip Selesai',
                count: finishedCount,
                icon: Icons.archive_outlined,
                activeColor: const Color(0xFF475569),
              ),
              const SizedBox(width: 8),
              _buildTabButton(
                index: 2,
                title: 'Semua',
                count: totalCount,
                icon: Icons.people_outline,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),

        // Participant List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await provider.loadAdminData();
            },
            child: displayedParticipants.isEmpty
                ? provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.45,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _selectedTab == 1 ? Icons.inventory_2_outlined : Icons.people_outline,
                                    size: 64,
                                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedTab == 0
                                        ? 'Tidak Ada Peserta Aktif'
                                        : (_selectedTab == 1
                                            ? 'Belum Ada Arsip Peserta Selesai'
                                            : 'Tidak Ada Data Peserta'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedTab == 1
                                        ? 'Peserta yang telah menyelesaikan PKL akan diarsipkan di sini.'
                                        : 'Tarik ke bawah atau tekan tombol untuk muat ulang.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => provider.loadAdminData(),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Muat Ulang Data'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedParticipants.length,
                    itemBuilder: (context, index) {
                      final p = displayedParticipants[index];
                      return _buildParticipantCard(context, p, provider);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required int count,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? activeColor : AppColors.textSecondary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '$title ($count)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? activeColor : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantCard(BuildContext context, ProfileModel p, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        radius: 22,
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.university} (${p.nim})',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: p.status),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bidang: ${p.fieldName?.isNotEmpty == true ? p.fieldName : '-'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Divisi: ${p.divisionName?.isNotEmpty == true ? p.divisionName : '-'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pembimbing: ${p.supervisorName?.isNotEmpty == true ? p.supervisorName : '-'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (p.startDate != null || p.endDate != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Periode: ${p.startDate ?? '-'} s/d ${p.endDate ?? '-'}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                 PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _showAddEditParticipantDialog(context, provider, participant: p);
                    } else if (value == 'status_selesai') {
                      _confirmChangeStatus(context, provider, p, 'Selesai');
                    } else if (value == 'status_aktif') {
                      _confirmChangeStatus(context, provider, p, 'Aktif');
                    } else if (value == 'reset_password') {
                      _showResetPasswordDialog(context, provider, p);
                    } else if (value == 'delete') {
                      _confirmAndDeleteParticipant(context, provider, p);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Data'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: p.status == 'Aktif' ? 'status_selesai' : 'status_aktif',
                      child: Row(
                        children: [
                          Icon(
                            p.status == 'Aktif' ? Icons.archive_outlined : Icons.unarchive_outlined,
                            size: 18,
                            color: p.status == 'Aktif' ? Colors.orange : AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(p.status == 'Aktif' ? 'Selesaikan & Arsipkan' : 'Aktifkan Kembali'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'reset_password',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset_outlined, size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Reset Password', style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever_outlined, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus Peserta', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditParticipantDialog(BuildContext context, AppProvider provider, {ProfileModel? participant}) {
    final isEdit = participant != null;
    final nameCtrl = TextEditingController(text: participant?.name ?? '');
    final emailCtrl = TextEditingController(text: participant?.email ?? '');
    final passCtrl = TextEditingController();
    final nimCtrl = TextEditingController(text: participant?.nim ?? '');
    final univCtrl = TextEditingController(text: participant?.university ?? '');
    final studyCtrl = TextEditingController(text: participant?.studyProgram ?? '');
    final startDateCtrl = TextEditingController(text: participant?.startDate ?? '');
    final endDateCtrl = TextEditingController(text: participant?.endDate ?? '');

    String selectedFieldId = participant?.fieldId ?? (provider.fieldsList.isNotEmpty ? provider.fieldsList.first.id : '');
    String selectedFieldName = participant?.fieldName ?? (provider.fieldsList.isNotEmpty ? provider.fieldsList.first.name : '');
    String selectedDivisionId = participant?.divisionId ?? '';
    String selectedDivisionName = participant?.divisionName ?? '';
    String selectedSupervisorId = participant?.supervisorId ?? '';
    String selectedSupervisorName = participant?.supervisorName ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final divisionsForField = provider.getDivisionsByField(selectedFieldId);
            // Auto-select first division if current selection is invalid
            if (divisionsForField.isNotEmpty &&
                (selectedDivisionId.isEmpty || !divisionsForField.any((d) => d.id == selectedDivisionId))) {
              selectedDivisionId = divisionsForField.first.id;
              selectedDivisionName = divisionsForField.first.name;
            } else if (divisionsForField.isEmpty) {
              selectedDivisionId = '';
              selectedDivisionName = '';
            }

            final supervisorsForSelection = provider.supervisorsList.where((s) {
              final matchField = selectedFieldId.isEmpty ||
                  s.fieldId == selectedFieldId ||
                  (selectedFieldName.isNotEmpty && s.fieldId == selectedFieldName);
              if (!matchField) return false;

              if (divisionsForField.isNotEmpty && selectedDivisionId.isNotEmpty) {
                return s.divisionId == selectedDivisionId ||
                    (selectedDivisionName.isNotEmpty && s.divisionId == selectedDivisionName);
              }
              return true;
            }).toList();

            if (selectedSupervisorId.isNotEmpty && !supervisorsForSelection.any((s) => s.id == selectedSupervisorId)) {
              selectedSupervisorId = supervisorsForSelection.isNotEmpty ? supervisorsForSelection.first.id : '';
              selectedSupervisorName = supervisorsForSelection.isNotEmpty ? supervisorsForSelection.first.name : '';
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? 'Edit Data Peserta' : 'Tambah Peserta PKL Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(controller: nameCtrl, labelText: 'Nama Lengkap'),
                    const SizedBox(height: 12),
                    CustomTextField(controller: emailCtrl, labelText: 'Email'),
                    const SizedBox(height: 12),
                    if (!isEdit) ...[
                      CustomTextField(controller: passCtrl, labelText: 'Password (untuk Login)', obscureText: true),
                      const SizedBox(height: 12),
                    ],
                    CustomTextField(controller: nimCtrl, labelText: 'NIM / NISN'),
                    const SizedBox(height: 12),
                    CustomTextField(controller: univCtrl, labelText: 'Universitas / Sekolah'),
                    const SizedBox(height: 12),
                    CustomTextField(controller: studyCtrl, labelText: 'Program Studi'),
                    const SizedBox(height: 16),

                    // Bidang Dropdown
                    const Text('Bidang', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.inputBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedFieldId.isNotEmpty && provider.fieldsList.any((f) => f.id == selectedFieldId) ? selectedFieldId : null,
                          hint: const Text('Pilih Bidang', style: TextStyle(fontSize: 13)),
                          items: provider.fieldsList.map((f) {
                            return DropdownMenuItem<String>(
                              value: f.id,
                              child: Text(f.name, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            final field = provider.fieldsList.firstWhere((f) => f.id == val);
                            setDialogState(() {
                              selectedFieldId = field.id;
                              selectedFieldName = field.name;
                              final newDivisions = provider.getDivisionsByField(field.id);
                              selectedDivisionId = newDivisions.isNotEmpty ? newDivisions.first.id : '';
                              selectedDivisionName = newDivisions.isNotEmpty ? newDivisions.first.name : '';

                              final newSups = provider.supervisorsList.where((s) {
                                final matchField = s.fieldId == selectedFieldId || s.fieldId == selectedFieldName;
                                if (!matchField) return false;
                                if (newDivisions.isNotEmpty && selectedDivisionId.isNotEmpty) {
                                  return s.divisionId == selectedDivisionId || s.divisionId == selectedDivisionName;
                                }
                                return true;
                              }).toList();
                              if (newSups.any((s) => s.id == selectedSupervisorId)) {
                                // keep existing
                              } else if (newSups.isNotEmpty) {
                                selectedSupervisorId = newSups.first.id;
                                selectedSupervisorName = newSups.first.name;
                              } else {
                                selectedSupervisorId = '';
                                selectedSupervisorName = '';
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Divisi Dropdown (filtered by Bidang)
                    const Text('Divisi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.inputBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedDivisionId.isNotEmpty && divisionsForField.any((d) => d.id == selectedDivisionId) ? selectedDivisionId : null,
                          hint: const Text('Pilih Divisi', style: TextStyle(fontSize: 13)),
                          items: divisionsForField.map((d) {
                            return DropdownMenuItem<String>(
                              value: d.id,
                              child: Text(d.name, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            final div = divisionsForField.firstWhere((d) => d.id == val);
                            setDialogState(() {
                              selectedDivisionId = div.id;
                              selectedDivisionName = div.name;

                              final newSups = provider.supervisorsList.where((s) {
                                final matchField = selectedFieldId.isEmpty || s.fieldId == selectedFieldId || s.fieldId == selectedFieldName;
                                if (!matchField) return false;
                                return s.divisionId == selectedDivisionId || s.divisionId == selectedDivisionName;
                              }).toList();
                              if (newSups.any((s) => s.id == selectedSupervisorId)) {
                                // keep existing
                              } else if (newSups.isNotEmpty) {
                                selectedSupervisorId = newSups.first.id;
                                selectedSupervisorName = newSups.first.name;
                              } else {
                                selectedSupervisorId = '';
                                selectedSupervisorName = '';
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pembimbing Dropdown
                    const Text('Pembimbing Lapangan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.inputBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedSupervisorId.isNotEmpty && supervisorsForSelection.any((s) => s.id == selectedSupervisorId) ? selectedSupervisorId : null,
                          hint: Text(
                            supervisorsForSelection.isEmpty
                                ? (divisionsForField.isEmpty ? 'Belum ada pembimbing di bidang ini' : 'Belum ada pembimbing di divisi ini')
                                : 'Pilih Pembimbing',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          items: supervisorsForSelection.map((s) {
                            final field = provider.fieldsList.where((f) => f.id == s.fieldId).firstOrNull;
                            final division = (s.divisionId != null && s.divisionId!.isNotEmpty)
                                ? provider.divisionsList.where((d) => d.id == s.divisionId).firstOrNull
                                : null;
                            final detail = [
                              if (field != null) field.name,
                              if (division != null) division.name,
                            ].join(' • ');

                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(
                                detail.isNotEmpty ? '${s.name} ($detail)' : s.name,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: supervisorsForSelection.isEmpty ? null : (val) {
                            if (val == null) return;
                            final sup = supervisorsForSelection.firstWhere((s) => s.id == val);
                            setDialogState(() {
                              selectedSupervisorId = sup.id;
                              selectedSupervisorName = sup.name;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Periode PKL
                    const Text('Periode PKL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(startDateCtrl.text) ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  startDateCtrl.text = picked.toIso8601String().substring(0, 10);
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: CustomTextField(
                                controller: startDateCtrl,
                                labelText: 'Mulai (YYYY-MM-DD)',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(endDateCtrl.text) ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  endDateCtrl.text = picked.toIso8601String().substring(0, 10);
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: CustomTextField(
                                controller: endDateCtrl,
                                labelText: 'Selesai (YYYY-MM-DD)',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                    if (!isEdit && passCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak boleh kosong')));
                      return;
                    }

                    final newParticipant = ProfileModel(
                      id: isEdit ? participant.id : '', // id will be generated by registerUser if not isEdit
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      role: 'peserta',
                      nim: nimCtrl.text.trim(),
                      university: univCtrl.text.trim(),
                      studyProgram: studyCtrl.text.trim(),
                      fieldId: selectedFieldId,
                      fieldName: selectedFieldName,
                      divisionId: selectedDivisionId,
                      divisionName: selectedDivisionName,
                      supervisorId: selectedSupervisorId,
                      supervisorName: selectedSupervisorName,
                      status: isEdit ? participant.status : 'Aktif',
                      startDate: startDateCtrl.text.trim().isNotEmpty ? startDateCtrl.text.trim() : null,
                      endDate: endDateCtrl.text.trim().isNotEmpty ? endDateCtrl.text.trim() : null,
                    );

                    bool success;
                    if (isEdit) {
                      success = await provider.saveParticipant(newParticipant);
                    } else {
                      success = await provider.registerAndSaveParticipant(newParticipant, passCtrl.text.trim());
                    }

                    if (success && context.mounted) {
                      Navigator.pop(context);
                    } else if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Terjadi kesalahan')));
                    }
                  },
                  child: Text(isEdit ? 'Simpan' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmChangeStatus(BuildContext context, AppProvider provider, ProfileModel p, String newStatus) async {
    final isEnding = newStatus == 'Selesai';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isEnding ? Icons.archive_outlined : Icons.unarchive_outlined,
              color: isEnding ? Colors.orange : AppColors.success,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEnding ? 'Selesaikan & Arsipkan PKL' : 'Aktifkan Kembali Peserta',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.4),
            children: [
              TextSpan(
                text: isEnding
                    ? 'Tandai masa PKL untuk peserta '
                    : 'Aktifkan kembali status magang untuk ',
              ),
              TextSpan(
                text: p.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: isEnding
                    ? ' telah selesai?\n\n'
                      '📁 Peserta akan dipindahkan ke tab Arsip Selesai agar daftar peserta aktif tidak menumpuk.\n\n'
                      '⏰ Peserta tidak lagi dihitung dalam absensi harian.\n\n'
                      '📊 Seluruh data profil dan riwayat presensi tetap aman tersimpan sebagai arsip dan dapat diekspor kapan saja.'
                    : '?\n\nPeserta akan kembali muncul di daftar peserta aktif dan dapat mengisi presensi harian.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnding ? Colors.orange : AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEnding ? 'Selesaikan & Arsipkan' : 'Aktifkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.updateParticipantStatus(p.id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (isEnding
                      ? 'Peserta "${p.name}" berhasil diarsipkan ke status Selesai.'
                      : 'Peserta "${p.name}" telah diaktifkan kembali.')
                  : 'Gagal memperbarui status: ${provider.errorMessage}',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmAndDeleteParticipant(BuildContext context, AppProvider provider, ProfileModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Peserta'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            children: [
              const TextSpan(text: 'Hapus peserta '),
              TextSpan(
                text: p.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' dari sistem?\n\n'),
              const TextSpan(
                text: '⚠ Seluruh data absensi peserta ini juga akan dihapus.\nTindakan ini tidak dapat dibatalkan.',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteParticipant(p.id, participantName: p.name);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Peserta "${p.name}" berhasil dihapus.'
                        : 'Gagal menghapus: ${provider.errorMessage}'),
                    backgroundColor: success ? null : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, AppProvider provider, ProfileModel p) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_outlined, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text('Reset Password\n${p.name}', style: const TextStyle(fontSize: 15))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan password baru untuk peserta ini.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: passCtrl,
              labelText: 'Password Baru',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              if (passCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final success = await provider.resetParticipantPassword(p.id, passCtrl.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Password "${p.name}" berhasil direset.'
                        : 'Gagal reset password: ${provider.errorMessage}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }
}
