import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHelper {
  static const String _storageKey = 'unreadNotifications';

  /// Save a notification with message and scheduled time
  static Future<void> saveScheduledNotification(
    String message,
    DateTime time,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> currentList = prefs.getStringList(_storageKey) ?? [];

    final notificationData = jsonEncode({
      'message': message,
      'scheduledTime': time.toIso8601String(),
    });

    currentList.add(notificationData);
    await prefs.setStringList(_storageKey, currentList);
  }

  //Get only delivered notifications (past scheduled time)
  static Future<List<String>> getDeliveredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    List<String> delivered = [];

    final List<String> scheduled = prefs.getStringList(_storageKey) ?? [];

    for (String jsonStr in scheduled) {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      final DateTime scheduledTime = DateTime.parse(decoded['scheduledTime']);
      final String message = decoded['message'];

      if (scheduledTime.isBefore(now)) {
        delivered.add(
          "$message - ${_formatTime(scheduledTime)} - ${_formatDate(scheduledTime)}",
        );
      }
    }

    return delivered;
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $suffix";
  }

  static String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  static Future<void> removeDeliveredNotification(String displayText) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    List<String> currentList = prefs.getStringList(_storageKey) ?? [];

    currentList.removeWhere((jsonStr) {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      final DateTime scheduledTime = DateTime.parse(decoded['scheduledTime']);
      final String message = decoded['message'];

      if (scheduledTime.isBefore(now)) {
        final formatted = "$message - ${_formatTime(scheduledTime)} - ${_formatDate(scheduledTime)}";
        return formatted == displayText;
      }
      return false;
    });

    await prefs.setStringList(_storageKey, currentList);
  }

}
