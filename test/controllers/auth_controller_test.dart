import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:odogo_app/controllers/auth_controller.dart';
import 'package:odogo_app/repositories/user_repository.dart';
import 'package:odogo_app/services/email_link_auth_service.dart';
import 'package:odogo_app/models/user_model.dart';
import 'package:odogo_app/models/enums.dart';

// ---------------------------------------------------------
// 1. CREATE THE MOCKS
// ---------------------------------------------------------
class MockEmailAuthService extends Mock implements EmailOtpAuthService {}
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  // FIX 1: Initializes the Flutter testing environment for SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockEmailAuthService mockAuthService;
  late MockUserRepository mockUserRepo;
  late ProviderContainer container;

  setUp(() {
    // FIX 2: Clear the fake hard drive before EVERY test so they don't corrupt each other
    SharedPreferences.setMockInitialValues({});

    mockAuthService = MockEmailAuthService();
    mockUserRepo = MockUserRepository();

    // FIX 3: Give the fake database a default answer so it doesn't crash when _checkSavedSession runs
    when(() => mockUserRepo.getUserByEmail(any())).thenAnswer((_) async => null);

    container = ProviderContainer(
      overrides: [
        emailAuthServiceProvider.overrideWithValue(mockAuthService),
        userRepositoryProvider.overrideWithValue(mockUserRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // A helper function to let the background _checkSavedSession finish before we act
  Future<void> waitForBoot(AuthController controller) async {
    await Future.delayed(Duration.zero);
  }

  // ------------------------------------------------------------------
  // BASELINE: Testing OTP Sending
  // ------------------------------------------------------------------
  test('sendOtp success changes state to AuthOtpSent', () async {
    const testEmail = 'test@example.com';
    when(() => mockAuthService.sendOtp(email: any(named: 'email'))).thenAnswer((_) async {});

    final controller = container.read(authControllerProvider.notifier);
    await waitForBoot(controller); // Wait for boot!

    await controller.sendOtp(testEmail);

    verify(() => mockAuthService.sendOtp(email: testEmail)).called(1);
    final finalState = container.read(authControllerProvider);
    expect(finalState, isA<AuthOtpSent>());
    expect((finalState as AuthOtpSent).email, testEmail);
  });

  test('sendOtp failure catches exception and changes state to AuthError', () async {
    const testEmail = 'test@example.com';
    const errorMessage = 'Network timeout';
    when(() => mockAuthService.sendOtp(email: any(named: 'email'))).thenThrow(Exception(errorMessage));

    final controller = container.read(authControllerProvider.notifier);
    await waitForBoot(controller); // Wait for boot!

    await controller.sendOtp(testEmail);

    final finalState = container.read(authControllerProvider);
    expect(finalState, isA<AuthError>());
    expect((finalState as AuthError).message, contains(errorMessage)); 
  });

  // ------------------------------------------------------------------
  // FEATURE 16: Switch Account
  // ------------------------------------------------------------------
  test('switchAccount successfully changes the active email and fetches new user', () async {
    const oldEmail = 'old@test.com';
    const newEmail = 'new@test.com';
    
    SharedPreferences.setMockInitialValues({'odogo_user_email': oldEmail});

    final fakeNewUser = UserModel(
      userID: 'user_2',
      emailID: newEmail,
      name: 'Second Account',
      phoneNo: '0000000000',
      gender: 'Male',
      dob: Timestamp.now(),
      role: UserRole.commuter,
    );

    // Teach the fake database about BOTH users
    when(() => mockUserRepo.getUserByEmail(oldEmail)).thenAnswer((_) async => null);
    when(() => mockUserRepo.getUserByEmail(newEmail)).thenAnswer((_) async => fakeNewUser);

    final controller = container.read(authControllerProvider.notifier);
    await waitForBoot(controller);

    await controller.switchAccount(newEmail);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('odogo_user_email'), newEmail);

    final finalState = container.read(authControllerProvider);
    expect(finalState, isA<AuthAuthenticated>());
    expect((finalState as AuthAuthenticated).user.emailID, newEmail);
  });

  // ------------------------------------------------------------------
  // FEATURE 17: Delete Account OTP Match (Happy Path)
  // ------------------------------------------------------------------
  test('deleteAccount with correct OTP wipes data and falls back to remaining account', () async {
    const emailToDelete = 'delete_me@test.com';
    const remainingEmail = 'keep_me@test.com';

    SharedPreferences.setMockInitialValues({
      'odogo_user_email': emailToDelete,
      'odogo_linked_accounts': [remainingEmail, emailToDelete],
    });

    when(() => mockAuthService.verifyOtp(email: emailToDelete, otp: '1234')).thenReturn(true);
    when(() => mockUserRepo.deleteUser(emailToDelete)).thenAnswer((_) async {});

    final fallbackUser = UserModel(
      userID: 'user_keep',
      emailID: remainingEmail,
      name: 'Survivor',
      phoneNo: '111',
      gender: 'Male',
      dob: Timestamp.now(),
      role: UserRole.commuter,
    );
    
    // Teach the database how to respond during boot and during the fallback
    when(() => mockUserRepo.getUserByEmail(emailToDelete)).thenAnswer((_) async => null);
    when(() => mockUserRepo.getUserByEmail(remainingEmail)).thenAnswer((_) async => fallbackUser);

    final controller = container.read(authControllerProvider.notifier);
    await waitForBoot(controller);

    await controller.deleteAccount(emailToDelete, '1234');

    final prefs = await SharedPreferences.getInstance();
    final linked = prefs.getStringList('odogo_linked_accounts');
    expect(linked?.contains(emailToDelete), false);
    expect(linked?.contains(remainingEmail), true);
    expect(prefs.getString('odogo_user_email'), remainingEmail);
    
    final finalState = container.read(authControllerProvider);
    expect(finalState, isA<AuthAuthenticated>());
    expect((finalState as AuthAuthenticated).user.emailID, remainingEmail);
  });

  // ------------------------------------------------------------------
  // FEATURE 17: Delete Account OTP Match (Sad Path)
  // ------------------------------------------------------------------
  test('deleteAccount with WRONG OTP stops immediately and shows error', () async {
    const email = 'test@test.com';
    
    SharedPreferences.setMockInitialValues({
      'odogo_user_email': email,
      'odogo_linked_accounts': [email],
    });

    when(() => mockUserRepo.getUserByEmail(email)).thenAnswer((_) async => null);
    when(() => mockAuthService.verifyOtp(email: email, otp: '9999')).thenReturn(false);

    final controller = container.read(authControllerProvider.notifier);
    await waitForBoot(controller);

    await controller.deleteAccount(email, '9999');

    verifyNever(() => mockUserRepo.deleteUser(email));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('odogo_linked_accounts')?.contains(email), true);

    final finalState = container.read(authControllerProvider);
    expect(finalState, isA<AuthError>());
    expect((finalState as AuthError).message, contains("Invalid or expired OTP"));
  });
}