import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/attendance_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class PesertaAttendanceScreen extends StatefulWidget {
  final String initialStatus;
  const PesertaAttendanceScreen({super.key, this.initialStatus = 'Hadir'});

  @override
  State<PesertaAttendanceScreen> createState() => _PesertaAttendanceScreenState();
}

class _PesertaAttendanceScreenState extends State<PesertaAttendanceScreen> {
  late String _selectedStatus; // 'Hadir', 'Izin', 'Sakit'
  final _reasonController = TextEditingController();
  final _noteController = TextEditingController();
  final SignatureController _sigController = SignatureController(
    penStrokeWidth: 3,
    penColor: AppColors.primary,
    exportBackgroundColor: Colors.white,
  );

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();


  XFile? _capturedImage;
  Uint8List? _imageBytes;
  bool _isPhotoSimulated = false;

  bool _isLoadingLocation = true;
  bool _isInRadius = false;
  String _locationMessage = 'Sedang memeriksa lokasi...';
  
  // Koordinat asli Dinas Komunikasi dan Informatika Kabupaten Bogor
  static const double _officeLat = -6.485383;
  static const double _officeLng = 106.838560;
  static const double _maxRadius = 100.0; // Jarak toleransi maksimal dalam meter

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationMessage = 'Memeriksa akses lokasi...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _isInRadius = false;
            _locationMessage = 'Layanan lokasi dinonaktifkan di perangkat.';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _isInRadius = false;
              _locationMessage = 'Izin lokasi ditolak.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _isInRadius = false;
            _locationMessage = 'Izin lokasi ditolak permanen.';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _locationMessage = 'Mendapatkan lokasi saat ini...';
        });
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distanceInMeters = Geolocator.distanceBetween(
        _officeLat,
        _officeLng,
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          // Kita beri toleransi radius agak lebih besar jika GPS kurang akurat,
          // tapi tetap sesuai _maxRadius jika memungkinkan.
          if (distanceInMeters <= _maxRadius) {
            _isInRadius = true;
            _locationMessage = 'Dalam jangkauan Kantor (Jarak: ${distanceInMeters.toStringAsFixed(0)} meter)';
          } else {
            _isInRadius = false;
            _locationMessage = 'Di luar jangkauan (Jarak: ${distanceInMeters.toStringAsFixed(0)} meter)';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _isInRadius = false;
          _locationMessage = 'Gagal mengambil lokasi: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _noteController.dispose();
    _sigController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto({ImageSource source = ImageSource.camera}) async {
    if (_selectedStatus == 'Hadir' && !_isInRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak bisa mengambil foto karena di luar jangkauan lokasi kantor.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedImage = photo;
          _imageBytes = bytes;
          _isPhotoSimulated = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPhotoSimulated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto tidak dapat diambil ($e). Mode simulasi diaktifkan.'),
            backgroundColor: AppColors.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPhotoOptions() {
    if (_selectedStatus == 'Sakit') {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Lampirkan Foto Surat Sakit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text('Ambil Foto dengan Kamera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(source: ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(source: ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      _pickPhoto(source: ImageSource.camera);
    }
  }

  void _handleSubmit() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final user = provider.currentUser;
    if (user == null) return;

    final todayAtt = provider.todayAttendance;
    final now = DateTime.now();
    final isCheckOut = todayAtt != null && todayAtt.checkInTime != null && todayAtt.checkOutTime == null && todayAtt.status == 'Hadir';

    // Validation checks
    if (_selectedStatus == 'Hadir' && !_isInRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus berada di dalam jangkauan kantor untuk melakukan presensi hadir/pulang!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedStatus == 'Izin') {
      if (_reasonController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alasan izin wajib diisi!'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else if (_selectedStatus == 'Sakit') {
      if (_reasonController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keterangan sakit wajib diisi!'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (_imageBytes == null && !_isPhotoSimulated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto surat sakit wajib dilampirkan!'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else if (_selectedStatus == 'Hadir') {
      if (_noteController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan kegiatan wajib diisi!'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (_imageBytes == null && !_isPhotoSimulated && (!isCheckOut || _capturedImage == null && todayAtt.checkInPhotoUrl == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto kehadiran wajib diambil dari kamera!'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    bool success = false;

    if (isCheckOut) {
      // Perform Check-Out for Hadir
      final newRecord = todayAtt.copyWith(
        checkOutTime: now,
        checkOutPhotoUrl: _capturedImage != null ? _capturedImage!.path : todayAtt.checkInPhotoUrl,
        checkOutSignatureUrl: 'data:image/png;base64,sig_checkout',
        reason: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : todayAtt.reason,
      );
      success = await provider.submitAttendanceRecord(newRecord);
    } else if (_selectedStatus == 'Hadir') {
      final newRecord = AttendanceModel(
        id: '', // Will be generated by Supabase
        userId: user.id,
        date: DateFormatter.getTodayKey(),
        checkInTime: now,
        checkOutTime: null,
        status: _selectedStatus,
        reason: _noteController.text.trim(),
        checkInPhotoUrl: (_capturedImage != null ? _capturedImage!.path : 'https://via.placeholder.com/150'),
        checkInSignatureUrl: 'data:image/png;base64,sig_checkin',
        createdAt: now,
        updatedAt: now,
      );
      success = await provider.submitAttendanceRecord(newRecord);
    } else if (_selectedStatus == 'Izin') {
      final reason = _reasonController.text.trim();
      final newRecord = AttendanceModel(
        id: '',
        userId: user.id,
        date: DateFormatter.getTodayKey(),
        checkInTime: null,
        checkOutTime: null,
        status: _selectedStatus,
        reason: reason,
        checkInPhotoUrl: '',
        checkInSignatureUrl: '',
        createdAt: now,
        updatedAt: now,
      );
      success = await provider.submitAttendanceRecord(
        newRecord,
        customNotificationMessage: reason.isNotEmpty ? 'Alasan: $reason' : null,
      );
    } else if (_selectedStatus == 'Sakit') {
      // Date range for Sakit
      final startClean = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endClean = DateTime(_endDate.year, _endDate.month, _endDate.day);
      final int days = endClean.difference(startClean).inDays + 1;
      final startFormatted = "${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}";
      final endFormatted = "${_endDate.day.toString().padLeft(2, '0')}/${_endDate.month.toString().padLeft(2, '0')}/${_endDate.year}";
      final rangeInfo = "Rentang $startFormatted s/d $endFormatted ($days hari)";
      final rawReason = _reasonController.text.trim();
      final fullReason = rawReason.isNotEmpty ? "$rawReason - $rangeInfo" : rangeInfo;

      bool allSuccess = true;
      for (int i = 0; i < days; i++) {
        final currentDate = startClean.add(Duration(days: i));
        final formattedDate = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
        
        final newRecord = AttendanceModel(
          id: '',
          userId: user.id,
          date: formattedDate,
          checkInTime: null,
          checkOutTime: null,
          status: 'Sakit',
          reason: fullReason,
          checkInPhotoUrl: (_capturedImage != null ? _capturedImage!.path : 'https://via.placeholder.com/150'),
          checkInSignatureUrl: '',
          createdAt: now,
          updatedAt: now,
        );
        final res = await provider.submitAttendanceRecord(
          newRecord,
          sendNotification: (i == 0), // Kirim notifikasi hanya sekali untuk rentang hari
          customNotificationMessage: 'Alasan: $fullReason',
        );
        if (!res) allSuccess = false;
      }
      success = allSuccess;
    }


    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedStatus == 'Hadir' 
              ? (todayAtt != null ? 'Absen Pulang berhasil disimpan!' : 'Absen Masuk berhasil disimpan!')
              : 'Pengajuan $_selectedStatus berhasil disimpan!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate, // End date cannot be before start date
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final todayAtt = provider.todayAttendance;
    final isCheckOut = todayAtt != null && todayAtt.checkInTime != null && todayAtt.checkOutTime == null && todayAtt.status == 'Hadir';

    final String formTitle;
    if (isCheckOut) {
      formTitle = 'Form Absen Pulang';
    } else if (_selectedStatus == 'Hadir') {
      formTitle = 'Form Presensi PKL';
    } else if (_selectedStatus == 'Izin') {
      formTitle = 'Form Pengajuan Izin';
    } else {
      formTitle = 'Form Pengajuan Sakit';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(formTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Badge Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isLoadingLocation 
                    ? AppColors.infoLight 
                    : (_isInRadius ? AppColors.successLight : AppColors.errorLight),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isLoadingLocation
                      ? AppColors.info.withValues(alpha: 0.3)
                      : (_isInRadius ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                children: [
                  if (_isLoadingLocation)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _isInRadius ? Icons.gavel : Icons.location_off,
                      color: _isInRadius ? AppColors.success : AppColors.error,
                      size: 24,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoadingLocation
                              ? 'Memeriksa Lokasi'
                              : (_isInRadius ? 'Lokasi Terverifikasi' : 'Lokasi Tidak Sesuai'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isLoadingLocation
                                ? AppColors.infoText
                                : (_isInRadius ? AppColors.success : AppColors.error),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _locationMessage,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  if (!_isLoadingLocation)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _checkLocation,
                      tooltip: 'Muat ulang lokasi',
                    )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status Selector (if not check out)
            if (!isCheckOut) ...[
              const Text(
                'Status Kehadiran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStatusChipChoice('Hadir', Icons.check_circle_outline, AppColors.success),
                  const SizedBox(width: 10),
                  _buildStatusChipChoice('Izin', Icons.info_outline, AppColors.info),
                  const SizedBox(width: 10),
                  _buildStatusChipChoice('Sakit', Icons.sick_outlined, AppColors.warning),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Date Picker for Sakit
            if (_selectedStatus == 'Sakit') ...[
              const Text(
                'Tanggal Pengajuan Sakit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dari Tanggal',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormatter.formatFullDate(_startDate),
                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sampai Tanggal',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormatter.formatFullDate(_endDate),
                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.sakitBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      'Durasi pengajuan: ${DateTime(_endDate.year, _endDate.month, _endDate.day).difference(DateTime(_startDate.year, _startDate.month, _startDate.day)).inDays + 1} hari',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.sakitText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // BEHAVIOR FOR HADIR
            if (_selectedStatus == 'Hadir') ...[
              // Photo Capture Box
              const Text(
                'Foto Kehadiran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _pickPhoto(source: ImageSource.camera),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_imageBytes != null || _isPhotoSimulated) ? AppColors.success : AppColors.border,
                      width: (_imageBytes != null || _isPhotoSimulated) ? 2 : 1,
                    ),
                  ),
                  child: _imageBytes != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _imageBytes!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Foto Ulang',
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Foto Berhasil Diambil',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (_isPhotoSimulated ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPhotoSimulated ? Icons.check_circle : Icons.camera_alt_outlined,
                                size: 32,
                                color: _isPhotoSimulated ? AppColors.success : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isPhotoSimulated ? 'Foto Berhasil Diambil' : 'Ketuk untuk Ambil Foto Langsung',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isPhotoSimulated ? AppColors.success : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isPhotoSimulated ? 'Ketuk untuk membuka kamera kembali' : 'Membuka kamera',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Activity Note
              CustomTextField(
                controller: _noteController,
                labelText: isCheckOut ? 'Ringkasan Laporan Kegiatan Hari Ini *' : 'Catatan Kegiatan *',
                hintText: isCheckOut
                    ? 'Contoh: Menyelesaikan pemeliharaan server database...'
                    : 'Contoh: Mengerjakan modul laporan harian...',
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Signature Pad
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tanda Tangan Digital',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _sigController.clear(),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Hapus', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Signature(
                    controller: _sigController,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // BEHAVIOR FOR IZIN
            if (_selectedStatus == 'Izin') ...[
              CustomTextField(
                controller: _reasonController,
                labelText: 'Keterangan Izin',
                hintText: 'Contoh: Saya izin tidak hadir karena ada keperluan keluarga.',
                maxLines: 4,
              ),
              const SizedBox(height: 24),
            ],

            // BEHAVIOR FOR SAKIT
            if (_selectedStatus == 'Sakit') ...[
              CustomTextField(
                controller: _reasonController,
                labelText: 'Keterangan Sakit',
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              const Text(
                'Foto Surat Sakit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showPhotoOptions,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_imageBytes != null || _isPhotoSimulated) ? AppColors.success : AppColors.border,
                      width: (_imageBytes != null || _isPhotoSimulated) ? 2 : 1,
                    ),
                  ),
                  child: _imageBytes != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _imageBytes!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Foto Ulang',
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Foto Berhasil Diambil',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (_isPhotoSimulated ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPhotoSimulated ? Icons.check_circle : Icons.camera_alt_outlined,
                                size: 32,
                                color: _isPhotoSimulated ? AppColors.success : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isPhotoSimulated ? 'Foto Berhasil Diambil' : 'Ketuk untuk Ambil Foto Surat Sakit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isPhotoSimulated ? AppColors.success : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Submit Button
            CustomButton(
              text: isCheckOut
                  ? 'Simpan Absen Pulang'
                  : (_selectedStatus == 'Hadir' ? 'Kirim Absen Masuk' : 'Kirim Pengajuan $_selectedStatus'),
              onPressed: _handleSubmit,
              isLoading: provider.isLoading,
              icon: isCheckOut ? Icons.logout : Icons.send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChipChoice(String label, IconData icon, Color color) {
    final isSelected = _selectedStatus == label;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatus = label;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
