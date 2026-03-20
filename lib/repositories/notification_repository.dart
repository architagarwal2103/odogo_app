import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odogo_app/models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _notifications =>
      _firestore.collection('notifications');

  /// Streams a user's unread notifications ordered by newest first.
  Stream<List<NotificationModel>> streamUserNotifications(String userID) {
    return _notifications
        .where('recipientID', isEqualTo: userID)
        .where('isRead', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => NotificationModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  /// Marks a specific notification as read so it disappears from the badge count.
  Future<void> markAsRead(String notificationID) async {
    await _notifications.doc(notificationID).update({'isRead': true});
  }
}
