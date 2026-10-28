import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DateFormatter {
  static bool _initialized = false;

  static void _ensureInitialized() {
    if (!_initialized) {
      try {
        initializeDateFormatting('id_ID', null);
      } catch (_) {}
      _initialized = true;
    }
  }

  /// Formats date to "15 September 2026"
  static String formatFullDate(DateTime date) {
    _ensureInitialized();
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('d MMMM yyyy').format(date);
    }
  }

  /// Formats time to "08:15 WIB"
  static String formatTime(DateTime date) {
    _ensureInitialized();
    try {
      final formatted = DateFormat('HH:mm', 'id_ID').format(date);
      return '$formatted WIB';
    } catch (_) {
      final formatted = DateFormat('HH:mm').format(date);
      return '$formatted WIB';
    }
  }

  /// Returns today's date in standard string key "YYYY-MM-DD"
  static String getTodayKey() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  /// Formats DateTime to readable string for history view
  static String formatDateTime(DateTime date) {
    return '${formatFullDate(date)} - ${formatTime(date)}';
  }
}
