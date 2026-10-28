import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/attendance_model.dart';
import '../models/profile_model.dart';

class ExcelExportService {
  static Future<String?> exportRekapToExcel(
    List<AttendanceModel> attendances,
    List<ProfileModel> participants,
  ) async {
    try {
      var excel = Excel.createExcel();
      const fileName = 'absensi_diskominfo.xlsx';
      Sheet sheetObject = excel['Absensi Diskominfo'];
      excel.setDefaultSheet('Absensi Diskominfo');

      // Create Header Row
      List<String> headers = [
        'No',
        'Nama',
        'Universitas',
        'Bidang',
        'Divisi',
        'Pembimbing Lapangan',
        'Tanggal',
        'Absen Masuk',
        'Absen Pulang',
        'Status',
        'Alasan / Catatan'
      ];

      sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Create participant map for quick lookup
      final Map<String, ProfileModel> pMap = {
        for (var p in participants) p.id: p
      };

      int rowNo = 1;
      for (var att in attendances) {
        final p = pMap[att.userId];
        final bidang = (att.fieldName?.isNotEmpty == true)
            ? att.fieldName!
            : (p?.fieldName?.isNotEmpty == true ? p!.fieldName! : '-');
        final divisi = (att.divisionName?.isNotEmpty == true)
            ? att.divisionName!
            : (p?.divisionName?.isNotEmpty == true ? p!.divisionName! : '-');
        final supervisor = (att.supervisorName?.isNotEmpty == true)
            ? att.supervisorName!
            : (p?.supervisorName?.isNotEmpty == true ? p!.supervisorName! : '-');

        String checkIn = att.checkInTime != null ? "${att.checkInTime!.hour.toString().padLeft(2, '0')}:${att.checkInTime!.minute.toString().padLeft(2, '0')}" : '-';
        String checkOut = att.checkOutTime != null ? "${att.checkOutTime!.hour.toString().padLeft(2, '0')}:${att.checkOutTime!.minute.toString().padLeft(2, '0')}" : '-';
        if (att.status == 'Izin' || att.status == 'Sakit') {
          checkIn = '-';
          checkOut = '-';
        }

        String alasan = (att.reason?.isNotEmpty == true) ? att.reason! : '-';

        List<CellValue> row = [
          IntCellValue(rowNo++),
          TextCellValue(att.name),
          TextCellValue(att.university ?? '-'),
          TextCellValue(bidang),
          TextCellValue(divisi),
          TextCellValue(supervisor),
          TextCellValue(att.date),
          TextCellValue(checkIn),
          TextCellValue(checkOut),
          TextCellValue(att.status),
          TextCellValue(alasan),
        ];

        sheetObject.appendRow(row);
      }

      final fileBytes = excel.save(fileName: fileName);
      if (fileBytes == null) return null;

      if (kIsWeb) {
        return '$fileName (Berhasil Diunduh)';
      } else {
        Directory directory;
        try {
          directory = await getApplicationDocumentsDirectory();
        } catch (_) {
          directory = Directory.systemTemp;
        }
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return filePath;
      }
    } catch (e) {
      debugPrint('Error exporting Excel: $e');
      rethrow;
    }
  }
}
