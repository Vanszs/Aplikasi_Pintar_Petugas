import 'package:intl/intl.dart';

class TimezoneHelper {
  /// Get current DateTime in Jakarta timezone (UTC+7)
  static DateTime getNowJakarta() {
    // Get current UTC time and add 7 hours for Jakarta timezone
    return DateTime.now().toUtc().add(const Duration(hours: 7));
  }
  
  /// Convert any DateTime to Jakarta timezone (UTC+7)
  static DateTime toJakarta(DateTime dateTime) {
    if (dateTime.isUtc) {
      return dateTime.add(const Duration(hours: 7));
    }
    return dateTime;
  }
  
  /// Format DateTime to ISO string with Jakarta timezone
  static String toISOStringJakarta(DateTime dateTime) {
    final jakartaTime = toJakarta(dateTime);
    return jakartaTime.toIso8601String();
  }
  
  /// Format DateTime for display in Indonesian format
  static String formatIndonesian(DateTime dateTime) {
    final jakartaTime = toJakarta(dateTime);
    final formatter = DateFormat('dd MMMM yyyy HH:mm:ss WIB', 'id_ID');
    return formatter.format(jakartaTime);
  }
  
  /// Format DateTime for API payload
  static String formatForAPI(DateTime dateTime) {
    final jakartaTime = toJakarta(dateTime);
    // Format: 2025-07-11T10:30:45+07:00
    return '${jakartaTime.toIso8601String().substring(0, 19)}+07:00';
  }
  
  /// Get timestamp for notification/report creation
  static Map<String, dynamic> getTimestampData() {
    final now = getNowJakarta();
    return {
      'created_at': formatForAPI(now),
      'timestamp': now.millisecondsSinceEpoch,
      'timezone': 'Asia/Jakarta',
      'utc_offset': '+07:00'
    };
  }
  
  /// Check if a timestamp is too old (for notification filtering)
  static bool isTimestampTooOld(String timestampString, Duration maxAge) {
    try {
      final timestamp = DateTime.parse(timestampString);
      final now = getNowJakarta();
      return now.difference(timestamp) > maxAge;
    } catch (e) {
      return false; // If parsing fails, allow the notification
    }
  }
}
