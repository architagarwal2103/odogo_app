import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odogo_app/controllers/user_controller.dart';
import 'package:odogo_app/controllers/auth_controller.dart';
import 'package:odogo_app/repositories/user_repository.dart';
import 'package:odogo_app/models/user_model.dart';
import 'package:odogo_app/models/enums.dart';

class MockUserRepository extends Mock implements UserRepository {}
class MockAuthController extends Notifier<AuthState> with Mock implements AuthController {
  @override
  AuthState build() => AuthInitial();
}

void main() {
  late MockUserRepository mockUserRepo;
  late MockAuthController mockAuthController;
  late ProviderContainer container;

  final fakeUser = UserModel(
    userID: 'test@test.com',
    emailID: 'test@test.com',
    name: 'Old Name',
    phoneNo: '1234567890',
    gender: 'Male',
    dob: Timestamp.now(),
    role: UserRole.commuter,
    savedLocations: ['Hall 1'],
  );

  setUp(() {
    mockUserRepo = MockUserRepository();
    mockAuthController = MockAuthController();

    container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        currentUserProvider.overrideWithValue(fakeUser),
        authControllerProvider.overrideWith(() => mockAuthController),
      ],
    );

    when(() => mockAuthController.refreshUser()).thenAnswer((_) async {});
  });

  tearDown(() {
    container.dispose();
  });

  test('updateName successfully calls repository and refreshes user', () async {
    const newName = 'New Super Cool Name';
    when(() => mockUserRepo.updateUser('test@test.com', {'name': newName}))
        .thenAnswer((_) async {});

    final controller = container.read(userControllerProvider.notifier);
    await controller.updateName(newName);

    verify(() => mockUserRepo.updateUser('test@test.com', {'name': newName})).called(1);
    verify(() => mockAuthController.refreshUser()).called(1);
    expect(container.read(userControllerProvider), const AsyncValue<void>.data(null));
  });

  test('updateWorkAddress replaces the first index of savedLocations', () async {
    const newWorkAddress = 'Main Gate'; 
    
    final expectedMap = {
      'savedLocations': [newWorkAddress]
    };

    when(() => mockUserRepo.updateUser('test@test.com', expectedMap))
        .thenAnswer((_) async {});

    final controller = container.read(userControllerProvider.notifier);
    await controller.updateWorkAddress(newWorkAddress);

    verify(() => mockUserRepo.updateUser('test@test.com', expectedMap)).called(1);
    expect(container.read(userControllerProvider), const AsyncValue<void>.data(null));
  });

  test('updateUserPhone successfully calls repository and refreshes user', () async {
    const newPhone = '9998887776';
    when(() => mockUserRepo.updateUser('test@test.com', {'phoneNo': newPhone}))
        .thenAnswer((_) async {});

    final controller = container.read(userControllerProvider.notifier);
    await controller.updateUserPhone(newPhone);

    verify(() => mockUserRepo.updateUser('test@test.com', {'phoneNo': newPhone})).called(1);
    verify(() => mockAuthController.refreshUser()).called(1);
    expect(container.read(userControllerProvider), const AsyncValue<void>.data(null));
  });

  test('updateHome successfully calls repository and refreshes user', () async {
    const newHome = 'Hall 13'; // Strict match
    when(() => mockUserRepo.updateUser('test@test.com', {'home': newHome}))
        .thenAnswer((_) async {});

    final controller = container.read(userControllerProvider.notifier);
    await controller.updateHome(newHome);

    verify(() => mockUserRepo.updateUser('test@test.com', {'home': newHome})).called(1);
    verify(() => mockAuthController.refreshUser()).called(1);
    expect(container.read(userControllerProvider), const AsyncValue<void>.data(null));
  });

  test('updateGender catches database error and emits AsyncError', () async {
    const newGender = 'Female';
    final dbError = Exception('Firebase is down!');
    when(() => mockUserRepo.updateUser('test@test.com', {'gender': newGender}))
        .thenThrow(dbError);

    final controller = container.read(userControllerProvider.notifier);
    await controller.updateGender(newGender);

    final state = container.read(userControllerProvider);
    expect(state is AsyncError, true);
    expect(state.error, dbError);
    verifyNever(() => mockAuthController.refreshUser());
  });

  test('updateDriverMode successfully calls repository and refreshes user', () async {
    const targetMode = DriverMode.online;
    when(() => mockUserRepo.updateUser('test@test.com', {'mode': targetMode.name}))
        .thenAnswer((_) async {});

    final controller = container.read(userControllerProvider.notifier);
    await controller.updateDriverMode(targetMode);

    verify(() => mockUserRepo.updateUser('test@test.com', {'mode': targetMode.name})).called(1);
    verify(() => mockAuthController.refreshUser()).called(1);
    expect(container.read(userControllerProvider), const AsyncValue<void>.data(null));
  });
}