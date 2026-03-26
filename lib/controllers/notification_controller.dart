import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import 'auth_controller.dart';

final notificationRepositoryProvider = Provider(
  (ref) => NotificationRepository(),
);

// Streams only the unread notifications for the currently logged-in user
final userNotificationsProvider = StreamProvider<List<NotificationModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);

  // If no one is logged in, return an empty list
  if (user == null) {
    return Stream.value([]);
  }

  return ref
      .read(notificationRepositoryProvider)
      .streamUserNotifications(user.userID);
});

final notificationControllerProvider = Provider((ref) {
  return NotificationController(ref.read(notificationRepositoryProvider));
});

class NotificationController {
  final NotificationRepository _repository;

  NotificationController(this._repository);

  Future<void> dismissNotification(String notificationID) async {
    await _repository.markAsRead(notificationID);
  }
}
