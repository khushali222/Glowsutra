import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class NotificationHelper {
  static const String _storageKey = 'unreadNotifications';
  static final Uuid _uuid = Uuid();

  /// Save a notification with message and scheduled time
  // static Future<void> saveScheduledNotification(
  //     String message, DateTime time) async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   String? stored = prefs.getString(_storageKey);
  //   List<Map<String, dynamic>> currentList = [];
  //
  //   if (stored != null) {
  //     final List<dynamic> decoded = jsonDecode(stored);
  //     currentList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  //   }
  //   final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Safe for 32-bit
  //
  //   final notificationData = {
  //     'id':id, // Unique ID
  //     'message': message,
  //     'scheduledTime': time.toIso8601String(),
  //   };
  //
  //   currentList.add(notificationData);
  //
  //   await prefs.setString(_storageKey, jsonEncode(currentList));
  // }
  static Future<void> saveScheduledNotification(
    String message,
    DateTime time,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // String? stored = prefs.getString(_storageKey);
    // List<Map<String, dynamic>> currentList = [];//schedle 10
    //
    // print("[saveScheduledNotification] Raw stored data: $stored");
    //
    // if (stored != null) {
    //   final List<dynamic> decoded = jsonDecode(stored);
    //   currentList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    //   print(
    //     "[saveScheduledNotification] Decoded existing notifications: $currentList",
    //   );
    // }
    //
    final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final notificationData = {
      'id': id,
      'message': message,
      'scheduledTime': time.toIso8601String(),
    };

    print(
      "[saveScheduledNotification] New notification to add: $notificationData",
    );

    // currentList.add(notificationData); // 5+1 +1
    //
    // final String finalJson = jsonEncode(currentList);
    // print("[saveScheduledNotification] Final JSON to store: $finalJson");
    //
    // await prefs.setString(_storageKey, finalJson);
    // print("[saveScheduledNotification] Notification saved successfully.");
  }

  static Future<void> markNotificationAsDelivered(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_storageKey);

    if (jsonStr == null) return;

    List<dynamic> decoded = jsonDecode(jsonStr);
    List<Map<String, dynamic>> updatedList =
        decoded.map((e) => Map<String, dynamic>.from(e)).toList();

    for (var notif in updatedList) {
      if (notif['id'] == id) {
        notif['delivered'] = true; // optional flag
      }
    }

    await prefs.setString(_storageKey, jsonEncode(updatedList));
  }

  /// Get only delivered notifications (past scheduled time)
  static Future<List<Map<String, dynamic>>> getDeliveredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final String? jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null) return [];

    List<dynamic> decoded = jsonDecode(jsonStr);
    List<Map<String, dynamic>> delivered = [];

    for (var item in decoded) {
      final Map<String, dynamic> notif = Map<String, dynamic>.from(item);
      final DateTime scheduledTime = DateTime.parse(notif['scheduledTime']);

      if (_isPast(scheduledTime, now)) {
        notif['formattedDisplay'] =
            "${notif['message']} - ${_formatTime(scheduledTime)} - ${_formatDate(scheduledTime)}";
        delivered.add(notif);
      }
    }

    return delivered;
  }

  /// Remove delivered notification by its ID
  static Future<void> removeDeliveredNotificationById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_storageKey);

    if (jsonStr == null) return;

    List<dynamic> decoded = jsonDecode(jsonStr);
    List<Map<String, dynamic>> currentList =
        decoded.map((e) => Map<String, dynamic>.from(e)).toList();

    currentList.removeWhere((notif) => notif['id'] == id);

    await prefs.setString(_storageKey, jsonEncode(currentList));
  }

  /// Clear all notifications
  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Helper: Format time to hh:mm AM/PM
  static String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $suffix";
  }

  /// Helper: Format date to yyyy-mm-dd
  static String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Helper: Check if time is in the past
  static bool _isPast(DateTime scheduled, DateTime now) {
    return scheduled.isBefore(now.subtract(Duration(seconds: 1)));
  }
}
