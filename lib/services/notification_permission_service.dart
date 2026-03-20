import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationPermissionService {
  static const String _notificationEnabledKey = 'notification_enabled';

  /// Check if notification permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request notification permission (opens system permission dialog)
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      await _saveNotificationPreference(true);
      return true;
    } else if (status.isDenied) {
      // Permission was denied
      await _saveNotificationPreference(false);
      return false;
    } else if (status.isPermanentlyDenied) {
      // Permission is permanently denied, app can't request it again
      // User must go to settings manually
      openAppSettings();
      return false;
    }

    return false;
  }

  /// Revoke/disable notifications
  /// Note: On Android 12+, we cannot truly revoke permissions programmatically.
  /// Instead, we just save the preference and the app won't send notifications.
  Future<void> disableNotifications() async {
    await _saveNotificationPreference(false);
  }

  /// Enable notifications (request permission if not already granted)
  Future<bool> enableNotifications() async {
    final isGranted = await isNotificationPermissionGranted();
    if (!isGranted) {
      return await requestNotificationPermission();
    }
    await _saveNotificationPreference(true);
    return true;
  }

  /// Get saved notification preference
  Future<bool> getNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true if not set yet
    return prefs.getBool(_notificationEnabledKey) ?? true;
  }

  /// Save notification preference locally
  Future<void> _saveNotificationPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);
  }

  /// Check if permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied() async {
    final status = await Permission.notification.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings for user to manually enable notification
  Future<void> openSettings() async {
    openAppSettings();
  }
}

class NotificationService {
  // Singleton pattern so we only initialize it once
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Uses your app's default launcher icon for Android notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // FIX 1: Add the "settings:" named parameter
    await _notificationsPlugin.initialize(settings: initSettings);
  }

  /// The function you are trying to call in your controllers/home screens!
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'odogo_alerts',
          'OdoGo Ride Alerts',
          channelDescription: 'Notifications for upcoming rides',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFF66D2A3),
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // FIX: Remove the named parameters and pass them directly in order!
    await _notificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}
