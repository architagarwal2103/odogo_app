import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:odogo_app/controllers/trip_controller.dart';
import 'package:odogo_app/repositories/trip_repository.dart';
import 'package:odogo_app/repositories/user_repository.dart';
import 'package:odogo_app/controllers/auth_controller.dart';
import 'package:odogo_app/models/user_model.dart';
import 'package:odogo_app/models/enums.dart';

class MockTripRepository extends Mock implements TripRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthController extends Mock implements AuthController {}

void main() {
  // CRITICAL FIX: Initialize the binding for the whole file
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTripRepository mockTripRepo;
  late MockUserRepository mockUserRepo;
  late ProviderContainer container;

  const tTripId = 'trip_abc';

  UserModel createTestUser({
    UserRole role = UserRole.driver,
    List<Timestamp>? history,
  }) {
    return UserModel(
      userID: 'user_123',
      emailID: 'test@test.com',
      name: 'Test User',
      phoneNo: '1234567890',
      gender: 'Male',
      dob: Timestamp.now(),
      role: role,
      mode: DriverMode.online,
      cancelHistory: history ?? [],
    );
  }

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockUserRepo = MockUserRepository();

    container = ProviderContainer(
      overrides: [
        tripRepositoryProvider.overrideWithValue(mockTripRepo),
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        currentUserProvider.overrideWithValue(createTestUser()),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('TripController - Final Refactored Tests', () {
    test('completeRide updates status when both parties finished', () async {
      when(() => mockTripRepo.getTripData(tTripId)).thenAnswer(
        (_) async => {
          'driverID': 'user_123',
          'driverEnd': true,
          'commuterEnd': true,
        },
      );

      when(
        () => mockTripRepo.updateTripData(any(), any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockUserRepo.updateUser(any(), any()),
      ).thenAnswer((_) async => {});

      final controller = container.read(tripControllerProvider.notifier);
      await controller.completeRide(tripID: tTripId, isDriver: true);

      verify(
        () => mockTripRepo.updateTripData(
          tTripId,
          any(that: containsValue(TripStatus.completed.name)),
        ),
      ).called(1);
    });

    test('cancelRide throws exception on 3rd cancel in 15 mins', () async {
      final now = DateTime.now();
      final busyUser = createTestUser(
        history: [
          Timestamp.fromDate(now.subtract(const Duration(minutes: 2))),
          Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
        ],
      );

      container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(busyUser),
          tripRepositoryProvider.overrideWithValue(mockTripRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      );

      when(() => mockTripRepo.getTripData(tTripId)).thenAnswer(
        (_) async => {'driverID': 'user_123', 'status': 'confirmed'},
      );

      final controller = container.read(tripControllerProvider.notifier);

      expect(
        () => controller.cancelRide(tTripId),
        throwsA(predicate((e) => e.toString().contains('maximum of 2 rides'))),
      );
    });

    test('Controller state is loading while startRide is in progress', () {
      // Use startRide because it explicitly sets the loading state in your controller
      when(
        () => mockTripRepo.updateTripData(any(), any()),
      ).thenAnswer((_) async => Future.delayed(const Duration(seconds: 1)));

      final controller = container.read(tripControllerProvider.notifier);

      // Trigger but don't await to catch it while it's "Working"
      controller.startRide(tTripId);

      expect(container.read(tripControllerProvider), isA<AsyncLoading>());
    });
  });
}
