import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Adjust this import to match your project structure
import 'package:odogo_app/services/contact_launcher_service.dart';

// --- MOCKS ---
// We have to mock the platform interface so the test doesn't actually try to open a real phone app
class MockUrlLauncher extends Mock with MockPlatformInterfaceMixin implements UrlLauncherPlatform {}
class FakeLaunchOptions extends Fake implements LaunchOptions {}

void main() {
  late MockUrlLauncher mockLauncher;

  setUpAll(() {
    registerFallbackValue(FakeLaunchOptions());
  });

  setUp(() {
    mockLauncher = MockUrlLauncher();
    // Force the app to use our fake launcher instead of the real Android/iOS launcher
    UrlLauncherPlatform.instance = mockLauncher;
  });

  // Helper function to build a fake UI screen so we can get a valid 'BuildContext'
  Widget createTestApp(Future<void> Function(BuildContext) action) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => action(context),
              child: const Text('Trigger Action'),
            );
          },
        ),
      ),
    );
  }

  group('ContactLauncherService Tests (Task 19)', () {
    testWidgets('callNumber sanitizes phone string and launches tel: URI', (WidgetTester tester) async {
      // Arrange: Program the fake launcher to pretend it successfully opened the phone app
      when(() => mockLauncher.launchUrl(any(), any())).thenAnswer((_) async => true);

      // We pass a messy phone number with spaces and dashes to test the _sanitizePhone logic
      await tester.pumpWidget(createTestApp((context) => ContactLauncherService.callNumber(context, '+91 98765-43210')));
      
      // Act: Tap the button
      await tester.tap(find.text('Trigger Action'));
      await tester.pumpAndSettle();

      // Assert: Did it strip the spaces/dashes and format the 'tel:' link correctly?
      verify(() => mockLauncher.launchUrl('tel:+919876543210', any())).called(1);
    });

    testWidgets('smsNumber sanitizes phone string and launches sms: URI', (WidgetTester tester) async {
      when(() => mockLauncher.launchUrl(any(), any())).thenAnswer((_) async => true);

      await tester.pumpWidget(createTestApp((context) => ContactLauncherService.smsNumber(context, '(123) 456 7890')));
      
      await tester.tap(find.text('Trigger Action'));
      await tester.pumpAndSettle();

      // Assert: Did it format the 'sms:' link correctly?
      verify(() => mockLauncher.launchUrl('sms:1234567890', any())).called(1);
    });

    testWidgets('shows SnackBar if phone number is empty', (WidgetTester tester) async {
      // Act: Pass a null phone number
      await tester.pumpWidget(createTestApp((context) => ContactLauncherService.callNumber(context, null)));
      await tester.tap(find.text('Trigger Action'));
      await tester.pump(); // Pump once to trigger the SnackBar

      // Assert: Did the orange SnackBar appear on screen?
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Phone number not available.'), findsOneWidget);
      
      // Verify it NEVER tried to open the phone app
      verifyNever(() => mockLauncher.launchUrl(any(), any()));
    });
  });
}