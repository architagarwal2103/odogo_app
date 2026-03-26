import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Adjust these imports to match your project structure
import 'package:odogo_app/controllers/user_controller.dart';
import 'package:odogo_app/controllers/auth_controller.dart';
import 'package:odogo_app/repositories/user_repository.dart';
import 'package:odogo_app/models/user_model.dart';
import 'package:odogo_app/models/enums.dart';

// 1. CREATE THE MOCKS
class MockUserRepository extends Mock implements UserRepository {}

// We have to mock the AuthController because your UserController 
// calls refreshUser() on it after a successful save.
class MockAuthController extends Notifier<AuthState> with Mock implements AuthController {
  @override
  AuthState build() => AuthInitial();
}

void main() {
  late MockUserRepository mockUserRepo;
  late MockAuthController mockAuthController;
  late ProviderContainer container;

  // We need a fake user in the system so `_getUid()` doesn't crash
  final fakeUser = UserModel(
    userID: 'test_uid_123',
    emailID: 'test@test.com',
    name: 'Old Name',
    phoneNo: '1234567890',
    gender: 'Male',
    dob: Timestamp.now(),
    role: UserRole.commuter,
    // Note: We give them an old work address to test the replacement logic
    savedLocations: ['Old Work Address'], 
  );

  setUp(() {
    mockUserRepo = MockUserRepository();
    mockAuthController = MockAuthController();

    // Set up the fake environment
    container = ProviderContainer(
      overrides: [
        // 1. Force the app to use our fake repository
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        
        // 2. Force the app to think "fakeUser" is currently logged in
        currentUserProvider.overrideWithValue(fakeUser),
        
        // 3. Force the app to use our fake AuthController
        // NEW (Correct)
        authControllerProvider.overrideWith(() => mockAuthController),
      ],
    );

    // Whenever UserController calls refreshUser(), just do nothing successfully.
    when(() => mockAuthController.refreshUser()).thenAnswer((_) async {});
  });

  tearDown(() {
    container.dispose();
  });

  // ------------------------------------------------------------------
  // TEST 1: Updating a simple field (Name)
  // ------------------------------------------------------------------
  test('updateName successfully calls repository and refreshes user', () async {
    // --- ARRANGE ---
    const newName = 'New Super Cool Name';
    
    // Program the fake database to succeed when asked to update the name
    when(() => mockUserRepo.updateUser('test_uid_123', {'name': newName}))
        .thenAnswer((_) async {});

    final controller = container.read(userControllerProvider.notifier);

    // --- ACT ---
    await controller.updateName(newName);

    // --- ASSERT ---
    // 1. Verify the database was told to save the exact right map
    verify(() => mockUserRepo.updateUser('test_uid_123', {'name': newName})).called(1);
    
    // 2. Verify the controller asked the auth system to fetch fresh data
    verify(() => mockAuthController.refreshUser()).called(1);
    
    // 3. Verify the loading spinner stopped and state is Data(null)
    expect(container.read(userControllerProvider), const AsyncValue<void>.data(null));
  });

  // ------------------------------------------------------------------
  // TEST 2: Updating a complex field (Work Address List Logic)
  // ------------------------------------------------------------------
  test('updateWorkAddress replaces the first index of savedLocations', () async {
    // --- ARRANGE ---
    const newWorkAddress = '123 New Tech Park';
    
    // We expect the array to replace 'Old Work Address' with '123 New Tech Park'
    final expectedMap = {
      'savedLocations': [newWorkAddress]
    };

    when(() => mockUserRepo.updateUser('test_uid_123', expectedMap))
        .thenAnswer((_) async {});

    final controller = container.read(userControllerProvider.notifier);

    // --- ACT ---
    await controller.updateWorkAddress(newWorkAddress);

    // --- ASSERT ---
    // Verify our array manipulation logic in the controller actually works!
    verify(() => mockUserRepo.updateUser('test_uid_123', expectedMap)).called(1);
    expect(container.read(userControllerProvider), const AsyncValue<void>.data(null));
  });

  // ------------------------------------------------------------------
  // TEST: Feature 15a - Update Phone Number
  // ------------------------------------------------------------------
  test('updateUserPhone successfully calls repository and refreshes user', () async {
    const newPhone = '9998887776';
    
    when(() => mockUserRepo.updateUser('test_uid_123', {'phoneNo': newPhone}))
        .thenAnswer((_) async {});

    final controller = container.read(userControllerProvider.notifier);

    await controller.updateUserPhone(newPhone);

    verify(() => mockUserRepo.updateUser('test_uid_123', {'phoneNo': newPhone})).called(1);
    verify(() => mockAuthController.refreshUser()).called(1);
    expect(container.read(userControllerProvider), const AsyncValue<void>.data(null));
  });

  // ------------------------------------------------------------------
  // TEST: Feature 15e - Update Home Address
  // ------------------------------------------------------------------
  test('updateHome successfully calls repository and refreshes user', () async {
    const newHome = '123 Test Boulevard';
    
    when(() => mockUserRepo.updateUser('test_uid_123', {'home': newHome}))
        .thenAnswer((_) async {});

    final controller = container.read(userControllerProvider.notifier);

    await controller.updateHome(newHome);

    verify(() => mockUserRepo.updateUser('test_uid_123', {'home': newHome})).called(1);
    verify(() => mockAuthController.refreshUser()).called(1);
    expect(container.read(userControllerProvider), const AsyncValue<void>.data(null));
  });

  // ------------------------------------------------------------------
  // TEST 3: Handling Errors (Sad Path)
  // ------------------------------------------------------------------
  test('updateGender catches database error and emits AsyncError', () async {
    // --- ARRANGE ---
    const newGender = 'Female';
    final dbError = Exception('Firebase is down!');
    
    // Program the database to CRASH
    when(() => mockUserRepo.updateUser('test_uid_123', {'gender': newGender}))
        .thenThrow(dbError);

    final controller = container.read(userControllerProvider.notifier);

    // --- ACT ---
    await controller.updateGender(newGender);

    // --- ASSERT ---
    // Read the final state of the controller
    final state = container.read(userControllerProvider);
    
    // It should be an Error state, not a Data state
    expect(state is AsyncError, true);
    expect(state.error, dbError);
    
    // Make sure refreshUser was NEVER called because the save failed
    verifyNever(() => mockAuthController.refreshUser());
  });
}