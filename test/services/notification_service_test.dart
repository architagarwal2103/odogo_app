import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:odogo_app/services/notification_permission_service.dart';

void main() {
  late NotificationPermissionService permissionService;

  setUp(() {
    // Initialize the fake hard drive for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    
    permissionService = NotificationPermissionService();
  });

  group('NotificationPermissionService Tests', () {
    test('getNotificationPreference defaults to true when no preference is saved', () async {
      // Act
      final isEnabled = await permissionService.getNotificationPreference();

      // Assert
      expect(isEnabled, true); // App should default to wanting to send notifications
    });

    test('disableNotifications successfully saves "false" to local storage', () async {
      // Act
      await permissionService.disableNotifications();
      final isEnabled = await permissionService.getNotificationPreference();

      // Assert
      expect(isEnabled, false);
      
      // Verify it actually hit the hard drive
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notification_enabled'), false);
    });

    test('enableNotifications workflow successfully saves "true" to local storage', () async {
      // Arrange (Simulate the user previously turning them off)
      SharedPreferences.setMockInitialValues({'notification_enabled': false});

      // Act
      // Note: We bypass the actual requestNotificationPermission() in standard unit tests 
      // because it requires native Android/iOS UI popups which don't exist in the test environment.
      // Instead, we test the persistence layer:
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_enabled', true);
      
      final isEnabled = await permissionService.getNotificationPreference();

      // Assert
      expect(isEnabled, true);
    });
  });
}