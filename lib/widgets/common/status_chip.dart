import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusChip({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case 'Hadir':
      case 'Aktif':
        bg = AppColors.successLight;
        fg = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case 'Izin':
        bg = AppColors.infoLight;
        fg = AppColors.info;
        icon = Icons.info_outline;
        break;
      case 'Sakit':
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        icon = Icons.sick_outlined;
        break;
      case 'Alpha':
      case 'Nonaktif':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        icon = Icons.cancel_outlined;
        break;
      case 'Selesai':
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF475569);
        icon = Icons.task_alt_outlined;
        break;
      case 'Belum Absen':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
