import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odogo_app/controllers/auth_controller.dart';
import '../services/notification_permission_service.dart';

class CommuteAlertsScreen extends ConsumerStatefulWidget {
  const CommuteAlertsScreen({super.key});

  @override
  ConsumerState<CommuteAlertsScreen> createState() =>
      _CommuteAlertsScreenState();
}

class _CommuteAlertsScreenState extends ConsumerState<CommuteAlertsScreen> {
  // Toggle state for daily route updates
  bool _notificationsEnabled = false;
  bool _isLoading = true;
  bool _isPermanentlyDenied = false;

  final NotificationPermissionService _permissionService =
      NotificationPermissionService();

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final isGranted = await _permissionService
          .isNotificationPermissionGranted();
      final savedPreference = await _permissionService
          .getNotificationPreference();
      final isPermanentlyDenied = await _permissionService
          .isPermissionPermanentlyDenied();

      setState(() {
        // Use actual permission status if granted, otherwise use saved preference
        _notificationsEnabled = isGranted && savedPreference;
        _isPermanentlyDenied = isPermanentlyDenied;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print(
        'Error loading notification settings: $e'
            .replaceFirst('Exception: ', '')
            .trim(),
      );
    }
  }

  Future<void> _handleNotificationToggle(bool value) async {
    if (value) {
      // If user is turning on notifications, request permission.
      if (!_isPermanentlyDenied) {
        final granted = await _permissionService
            .requestNotificationPermission();
        setState(() {
          _notificationsEnabled = granted;
          if (granted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Notifications enabled! You\'ll receive commute alerts.',
                ),
                backgroundColor: Color(0xFF66D2A3),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Notification permission denied. Please enable it in settings.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      } else {
        // Permission permanently denied - open app settings
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enable notifications in app settings'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                _permissionService.openSettings();
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      // User is turning off notifications
      await _permissionService.disableNotifications();
      setState(() => _notificationsEnabled = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications disabled'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // Back Button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          user?.name ?? 'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF66D2A3),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.notification_important,
                    size: 36,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Commute Alerts',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Notification Toggle
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          _notificationsEnabled
                              ? 'Daily route updates enabled'
                              : 'Daily route updates disabled',
                        ),
                        value: _notificationsEnabled,
                        activeThumbColor: const Color(0xFF66D2A3),
                        activeTrackColor: const Color(
                          0xFF66D2A3,
                        ).withOpacity(0.3),
                        onChanged: _handleNotificationToggle,
                      ),
                    ),

              const SizedBox(height: 16),

              // Info box
              if (!_notificationsEnabled)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You won\'t receive commute alerts. Turn on to get notified about your daily routes.',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isPermanentlyDenied)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Permission Permanently Blocked',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _permissionService.openSettings(),
                              child: const Text(
                                'Open Settings to enable notifications',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Close button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
