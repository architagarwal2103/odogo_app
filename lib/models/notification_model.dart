import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odogo_app/models/enums.dart';

class NotificationModel {
  final String notificationID;
  final String recipientID;
  final String content;
  final NotificationType type;
  final Timestamp timestamp;
  final bool isRead;

  NotificationModel({
    required this.notificationID,
    required this.recipientID,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationID: json['notificationID'] ?? '',
      recipientID: json['recipientID'] ?? '',
      content: json['content'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      timestamp: json['timestamp'] as Timestamp,
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationID': notificationID,
      'recipientID': recipientID,
      'content': content,
      'type': type.name,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}