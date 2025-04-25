import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 0)
class NotificationModel extends HiveObject {
  @HiveField(0)
  String reminder;

  @HiveField(1)
  String time;

  @HiveField(2)
  String date;

  @HiveField(3)
  String payload;

  @HiveField(4)
  String source;

  @HiveField(5)
  String id;

  @HiveField(6)
  bool isRead;

  NotificationModel({
    required this.reminder,
    required this.time,
    required this.date,
    required this.payload,
    required this.source,
    required this.id,
    this.isRead = false,
  });
}
