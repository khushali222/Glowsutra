import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  FlutterLocalNotificationsPlugin get notificationsPlugin =>
      _notificationsPlugin;

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? actionId = response.actionId;
        print("data ${response.data}");
        print("payload ${response.payload}");
        print("responsetype ${response.notificationResponseType}");
        print("input ${response.input}");
        if (response.notificationResponseType ==
            NotificationResponseType.selectedNotification) {
          print("input ${response.notificationResponseType}");
          onTapNotification(response.payload!);
        }
        if (actionId == 'ok_action') {
          print("✅ User acknowledged water reminder.");
        } else if (actionId == 'cancel_action') {
          print("❌ User dismissed water reminder.");
        } else {
          print("📩 Notification tapped (not a button).");
        }
      },
    );
  }

  void onTapNotification(String payload) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> notificationsJson =
        prefs.getStringList('unreadNotifications') ?? [];

    List<Map<String, dynamic>> notifications =
        notificationsJson
            .map((item) => jsonDecode(item) as Map<String, dynamic>)
            .toList();

    DateTime payloadTime = DateTime.parse(payload);
    print("update notific before $notifications");
    // Remove the notification with the corresponding payload time
    notifications.removeWhere((notification) {
      String? storedPayload = notification['payload'];
      if (storedPayload == null) return false;
      DateTime storedTime = DateTime.parse(storedPayload);
      return storedTime.isAtSameMomentAs(payloadTime);
    });
    print("update notific $notifications");
    // Save the updated notifications list back to SharedPreferences
    List<String> updatedJson =
        notifications.map((notification) => jsonEncode(notification)).toList();

    await prefs.setStringList('unreadNotifications', updatedJson);

    // Only update the state if the widget is still mounted

    print("Removed notification with payload time: $payload");
  }
}
