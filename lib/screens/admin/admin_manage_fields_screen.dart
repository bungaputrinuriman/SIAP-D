import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/field_model.dart';
import '../../models/division_model.dart';
import '../../models/supervisor_model.dart';
import '../../providers/app_provider.dart';
import '../../services/supervisor_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_text_field.dart';
import 'admin_division_detail_screen.dart';

class AdminManageFieldsScreen extends StatefulWidget {
  const AdminManageFieldsScreen({super.key});

  @override
  State<AdminManageFieldsScreen> createState() => _AdminManageFieldsScreenState();
}

class _AdminManageFieldsScreenState extends State<AdminManageFieldsScreen> {
  @override
  void initState() {
    super.initState();
    // Data di-load oleh provider saat initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loadAdminData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final fields = provider.fieldsList;
    final divisions = provider.divisionsList;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: const Text(
                  'Daftar Bidang & Divisi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddFieldDialog(context, provider),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Bidang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Fields with Divisions
          if (fields.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('Belum ada bidang terdaftar.')),
              ),
            )
          else
            ...fields.map((f) {
              final fieldDivisions = divisions.where((d) => d.fieldId == f.id).toList();
              return _buildFieldSection(context, provider, f, fieldDivisions);
            }),
          const SizedBox(height: 24),

          // Supervisors Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: const Text(
                  'Daftar Pembimbing Lapangan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddSupervisorDialog(context, provider),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Tambah Pembimbing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (provider.supervisorsList.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('Belum ada pembimbing terdaftar.')),
              ),
            )
          else
            ...provider.supervisorsList.map((s) {
              final field = provider.fieldsList.where((f) => f.id == s.fieldId).firstOrNull;
              final division = (s.divisionId != null && s.divisionId!.isNotEmpty)
                  ? provider.divisionsList.where((d) => d.id == s.divisionId).firstOrNull
                  : null;
              final divisionText = division != null ? 'Divisi: ${division.name}' : (field != null ? 'Divisi belum ditentukan' : '-');
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                    child: const Icon(Icons.person_outline, color: AppColors.secondary),
                  ),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    '${field != null ? "${field.name} • " : ""}$divisionText • ${s.phone ?? "-"}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.lock_reset_outlined, color: Colors.orange, size: 20),
                        tooltip: 'Reset Password Pembimbing',
                        onPressed: () => _showResetSupervisorPasswordDialog(context, provider, s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                        tooltip: 'Edit Pembimbing',
                        onPressed: () => _showEditSupervisorDialog(context, provider, s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        tooltip: 'Hapus Pembimbing',
                        onPressed: () => _deleteSupervisor(context, provider, s.id, s.name),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFieldSection(BuildContext context, AppProvider provider, FieldModel field, List<DivisionModel> fieldDivisions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field Header Card
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.business_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        (field.description ?? ''),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  tooltip: 'Tambah Divisi',
                  onPressed: () => _showAddDivisionDialog(context, provider, field),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  tooltip: 'Hapus Bidang',
                  onPressed: () => _deleteField(context, provider, field.id, field.name),
                ),
              ],
            ),
          ),
        ),

        // Division Cards (Clickable)
        if (fieldDivisions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 16),
            child: Text(
              'Belum ada divisi di bidang ini.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Column(
              children: fieldDivisions.map((div) {
                final memberCount = provider.getDivisionMemberCount(div.id, div.name);
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminDivisionDetailScreen(division: div),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_tree_outlined, color: AppColors.accent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  div.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$memberCount Anggota',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            tooltip: 'Hapus Divisi',
                            onPressed: () => _deleteDivision(context, provider, div.id, div.name),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _showAddFieldDialog(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Bidang Diskominfo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(controller: nameCtrl, labelText: 'Nama Bidang *'),
                const SizedBox(height: 12),
                CustomTextField(controller: descCtrl, labelText: 'Deskripsi / Tugas Utama'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading ? null : () async {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama bidang tidak boleh kosong.')),
                  );
                  return;
                }
                setStateDialog(() => isLoading = true);
                final newField = FieldModel(
                  id: '', // UUID di-generate Supabase
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                );
                final ok = await provider.addField(newField);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Bidang "${nameCtrl.text.trim()}" berhasil ditambahkan.'
                          : 'Gagal: ${provider.errorMessage}'),
                      backgroundColor: ok ? null : Colors.red,
                    ),
                  );
                }
              },
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDivisionDialog(BuildContext context, AppProvider provider, FieldModel field) {
    final nameCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Tambah Divisi di ${field.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: nameCtrl, labelText: 'Nama Divisi *'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading ? null : () async {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama divisi tidak boleh kosong.')),
                  );
                  return;
                }
                setStateDialog(() => isLoading = true);
                final newDiv = DivisionModel(
                  id: '', // UUID di-generate Supabase
                  fieldId: field.id,
                  name: nameCtrl.text.trim(),
                );
                final ok = await provider.addDivision(newDiv);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Divisi "${nameCtrl.text.trim()}" berhasil ditambahkan.'
                          : 'Gagal: ${provider.errorMessage}'),
                      backgroundColor: ok ? null : Colors.red,
                    ),
                  );
                }
              },
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tambah Pembimbing ──────────────────────────────────────────────────────
  void _showAddSupervisorDialog(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? selectedFieldId;
    String? selectedDivisionId;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_add_outlined, color: AppColors.secondary),
              SizedBox(width: 8),
              Expanded(child: Text('Tambah Pembimbing Lapangan')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan: Seluruh data wajib diisi lengkap.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: nameCtrl,
                  labelText: 'Nama Lengkap *',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Pilih Bidang yang Ditempati *',
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  hint: const Text('Pilih Bidang yang Ditempati *'),
                  value: selectedFieldId,
                  items: provider.fieldsList.map((f) {
                    return DropdownMenuItem(value: f.id, child: Text(f.name));
                  }).toList(),
                  onChanged: (val) => setStateDialog(() {
                    selectedFieldId = val;
                    final divs = val != null ? provider.getDivisionsByField(val) : <DivisionModel>[];
                    selectedDivisionId = divs.isNotEmpty ? divs.first.id : null;
                  }),
                ),
                if (selectedFieldId != null && selectedFieldId!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Builder(
                    builder: (ctx) {
                      final fieldDivisions = provider.getDivisionsByField(selectedFieldId!);
                      final isValidVal = selectedDivisionId != null && fieldDivisions.any((d) => d.id == selectedDivisionId);
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Pilih Divisi yang Ditempati *',
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          helperText: fieldDivisions.isEmpty
                              ? 'Belum ada divisi di bidang ini.'
                              : null,
                        ),
                        hint: const Text('Pilih Divisi yang Ditempati *'),
                        value: isValidVal ? selectedDivisionId : (fieldDivisions.isNotEmpty ? fieldDivisions.first.id : null),
                        items: fieldDivisions.map((d) {
                          return DropdownMenuItem(value: d.id, child: Text('📁 ${d.name}'));
                        }).toList(),
                        onChanged: fieldDivisions.isEmpty
                            ? null
                            : (val) => setStateDialog(() => selectedDivisionId = val),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
                CustomTextField(
                  controller: phoneCtrl,
                  labelText: 'No. HP / WhatsApp *',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const Text('Informasi Akun Login (Wajib)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: emailCtrl,
                  labelText: 'Email Akun *',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: passwordCtrl,
                  labelText: 'Password Akun * (Min. 6 Karakter)',
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final password = passwordCtrl.text.trim();

                      // Validasi menyeluruh: Semua field wajib diisi!
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama lengkap pembimbing wajib diisi!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (selectedFieldId == null || selectedFieldId!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bidang yang ditempati pembimbing wajib dipilih!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      final fieldDivisions = provider.getDivisionsByField(selectedFieldId!);
                      if (fieldDivisions.isNotEmpty && (selectedDivisionId == null || selectedDivisionId!.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Divisi yang ditempati pembimbing wajib dipilih!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nomor HP / WhatsApp pembimbing wajib diisi!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email akun pembimbing wajib diisi!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (!email.contains('@') || !email.contains('.')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Format email tidak valid!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password akun login wajib diisi!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (password.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password minimal 6 karakter!'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      setStateDialog(() => isLoading = true);
                      try {
                        // 1. Buat akun Auth
                        final newUserId = await AuthService.registerUser(
                          email: email,
                          password: password,
                        );

                        // 2. Buat Supervisor & Profile
                        final newSupervisor = SupervisorModel(
                          id: '',
                          name: name,
                          email: email,
                          phone: phone,
                          fieldId: selectedFieldId,
                          divisionId: (selectedDivisionId != null && selectedDivisionId!.isNotEmpty) ? selectedDivisionId : null,
                        );
                        await SupervisorService.addSupervisorWithProfile(newSupervisor, newUserId);
                        
                        // Refresh PROVIDER agar data pembimbing dan dropdown peserta ikut update
                        await provider.loadAdminData();
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pembimbing "$name" (Bidang: ${provider.fieldsList.firstWhere((f) => f.id == selectedFieldId, orElse: () => FieldModel(id: '', name: '-')).name}) berhasil ditambahkan.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setStateDialog(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reset Password Pembimbing ───────────────────────────────────────────────
  void _showResetSupervisorPasswordDialog(BuildContext context, AppProvider provider, SupervisorModel supervisor) {
    final passCtrl = TextEditingController();
    bool isLoading = false;
    bool obscurePass = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset_outlined, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Reset Password\n${supervisor.name}', style: const TextStyle(fontSize: 15)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan password baru untuk akun pembimbing ini (minimal 6 karakter).',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: obscurePass,
                decoration: InputDecoration(
                  labelText: 'Password Baru *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setStateDialog(() => obscurePass = !obscurePass),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              onPressed: isLoading
                  ? null
                  : () async {
                      final newPass = passCtrl.text.trim();
                      if (newPass.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password minimal 6 karakter.')),
                        );
                        return;
                      }

                      setStateDialog(() => isLoading = true);
                      final success = await provider.resetSupervisorPassword(supervisor, newPass);
                      setStateDialog(() => isLoading = false);

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Password pembimbing "${supervisor.name}" berhasil direset.'
                                : 'Gagal reset password: ${provider.errorMessage}'),
                            backgroundColor: success ? AppColors.success : AppColors.error,
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Pembimbing ────────────────────────────────────────────────────────
  void _showEditSupervisorDialog(BuildContext context, AppProvider provider, SupervisorModel supervisor) {
    final nameCtrl = TextEditingController(text: supervisor.name);
    final emailCtrl = TextEditingController(text: supervisor.email ?? '');
    final phoneCtrl = TextEditingController(text: supervisor.phone ?? '');
    String? selectedFieldId = supervisor.fieldId;
    String? selectedDivisionId = supervisor.divisionId;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(child: Text('Edit Pembimbing Lapangan')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameCtrl,
                  labelText: 'Nama Lengkap *',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Pilih Bidang yang Ditempati *',
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: provider.fieldsList.any((f) => f.id == selectedFieldId) ? selectedFieldId : null,
                  hint: const Text('Pilih Bidang yang Ditempati *'),
                  items: provider.fieldsList.map((f) {
                    return DropdownMenuItem(value: f.id, child: Text(f.name));
                  }).toList(),
                  onChanged: (val) => setStateDialog(() {
                    selectedFieldId = val;
                    final divs = val != null ? provider.getDivisionsByField(val) : <DivisionModel>[];
                    selectedDivisionId = divs.isNotEmpty ? divs.first.id : null;
                  }),
                ),
                if (selectedFieldId != null && selectedFieldId!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Builder(
                    builder: (ctx) {
                      final fieldDivisions = provider.getDivisionsByField(selectedFieldId!);
                      final isValidVal = selectedDivisionId != null && fieldDivisions.any((d) => d.id == selectedDivisionId);
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Pilih Divisi yang Ditempati *',
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          helperText: fieldDivisions.isEmpty
                              ? 'Belum ada divisi di bidang ini.'
                              : null,
                        ),
                        hint: const Text('Pilih Divisi yang Ditempati *'),
                        value: isValidVal ? selectedDivisionId : (fieldDivisions.isNotEmpty ? fieldDivisions.first.id : null),
                        items: fieldDivisions.map((d) {
                          return DropdownMenuItem(value: d.id, child: Text(d.name));
                        }).toList(),
                        onChanged: fieldDivisions.isEmpty
                            ? null
                            : (val) => setStateDialog(() => selectedDivisionId = val),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
                CustomTextField(
                  controller: phoneCtrl,
                  labelText: 'No. HP / WhatsApp',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: emailCtrl,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama lengkap tidak boleh kosong.'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (selectedFieldId == null || selectedFieldId!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bidang yang ditempati pembimbing wajib dipilih!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      final fieldDivisions = provider.getDivisionsByField(selectedFieldId!);
                      if (fieldDivisions.isNotEmpty && (selectedDivisionId == null || selectedDivisionId!.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Divisi yang ditempati pembimbing wajib dipilih!'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      setStateDialog(() => isLoading = true);
                      try {
                        final updatedSupervisor = SupervisorModel(
                          id: supervisor.id,
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : supervisor.email,
                          phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                          fieldId: selectedFieldId,
                          divisionId: (selectedDivisionId != null && selectedDivisionId!.isNotEmpty) ? selectedDivisionId : null,
                          status: supervisor.status,
                        );

                        final ok = await provider.updateSupervisor(updatedSupervisor);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'Data pembimbing "${nameCtrl.text.trim()}" berhasil diperbarui.'
                                  : 'Gagal: ${provider.errorMessage}'),
                              backgroundColor: ok ? AppColors.success : Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        setStateDialog(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hapus Pembimbing ───────────────────────────────────────────────────────
  Future<void> _deleteSupervisor(BuildContext context, AppProvider provider, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Hapus Pembimbing')),
          ],
        ),
        content: Text('Hapus pembimbing "$name"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await provider.deleteSupervisor(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Pembimbing "$name" berhasil dihapus.' : 'Gagal: ${provider.errorMessage}'),
          backgroundColor: ok ? null : Colors.red,
        ),
      );
    }
  }

  // ── Hapus Bidang ────────────────────────────────────────────────────────────
  Future<void> _deleteField(BuildContext context, AppProvider provider, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Hapus Bidang')),
          ],
        ),
        content: Text(
          'Hapus bidang "$name"?\n\nSemua divisi di bawah bidang ini juga akan ikut terhapus. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await provider.deleteField(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Bidang "$name" berhasil dihapus.' : 'Gagal: ${provider.errorMessage}'),
          backgroundColor: ok ? null : Colors.red,
        ),
      );
    }
  }

  // ── Hapus Divisi ────────────────────────────────────────────────────────────
  Future<void> _deleteDivision(BuildContext context, AppProvider provider, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Hapus Divisi')),
          ],
        ),
        content: Text('Hapus divisi "$name"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await provider.deleteDivision(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Divisi "$name" berhasil dihapus.' : 'Gagal: ${provider.errorMessage}'),
          backgroundColor: ok ? null : Colors.red,
        ),
      );
    }
  }
}
