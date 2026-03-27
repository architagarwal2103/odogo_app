import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:odogo_app/controllers/trip_controller.dart';
import 'package:odogo_app/repositories/trip_repository.dart';
import 'package:odogo_app/repositories/user_repository.dart';
import 'package:odogo_app/controllers/auth_controller.dart';
import 'package:odogo_app/models/trip_model.dart';
import 'package:odogo_app/models/user_model.dart';
import 'package:odogo_app/models/enums.dart';

class MockTripRepository extends Mock implements TripRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockAuthController extends Notifier<AuthState> with Mock implements AuthController {
  @override
  AuthState build() => AuthInitial();
}
class FakeTripModel extends Fake implements TripModel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTripRepository mockTripRepo;
  late MockUserRepository mockUserRepo;
  late MockAuthController mockAuthController;
  late ProviderContainer container;

  const tTripId = 'trip_abc';

  UserModel createTestUser({
    UserRole role = UserRole.driver,
    List<Timestamp>? history,
  }) {
    return UserModel(
      userID: 'test@test.com',
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

  final scheduledTrip = TripModel(
    tripID: 'trip_123',
    status: TripStatus.scheduled,
    commuterName: 'Aditya',
    commuterID: 'commuter@test.com', 
    startLocName: 'Hall 1', // Strict match
    endLocName: 'Main Gate', // Strict match
    startTime: DateTime.now().add(const Duration(hours: 2)),
    ridePIN: '1234',
    driverEnd: false,
    commuterEnd: false,
    scheduledTime: DateTime.now().add(const Duration(hours: 2)),
    bookingTime: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(FakeTripModel());
    registerFallbackValue(scheduledTrip);
  });

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockUserRepo = MockUserRepository();
    mockAuthController = MockAuthController();

    container = ProviderContainer(
      overrides: [
        tripRepositoryProvider.overrideWithValue(mockTripRepo),
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        authControllerProvider.overrideWith(() => mockAuthController),
        currentUserProvider.overrideWithValue(createTestUser()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TripController - Final Refactored Tests', () {
    test('completeRide updates status when both parties finished', () async {
      when(() => mockTripRepo.getTripRawData(tTripId)).thenAnswer(
        (_) async => {
          'driverID': 'test@test.com', 
          'driverEnd': true,
          'commuterEnd': true,
        },
      );

      when(() => mockTripRepo.updateTripData(any(), any())).thenAnswer((_) async {});
      when(() => mockUserRepo.updateUser(any(), any())).thenAnswer((_) async {});
      when(() => mockAuthController.refreshUser()).thenAnswer((_) async {});

      final controller = container.read(tripControllerProvider.notifier);
      await controller.completeRide(tripID: tTripId, isDriver: true);

      verify(() => mockTripRepo.updateTripData(tTripId, any(that: containsValue(TripStatus.completed.name)))).called(1);
    });

    test('cancelRide throws exception on 2nd cancel in 15 mins', () async {
      final now = DateTime.now();
      final busyUser = createTestUser(
        history: [
          Timestamp.fromDate(now.subtract(const Duration(minutes: 2))),
          Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
        ],
      );

      final localContainer = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(busyUser),
          tripRepositoryProvider.overrideWithValue(mockTripRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      );

      when(() => mockTripRepo.getTripRawData(tTripId)).thenAnswer(
        (_) async => {'driverID': 'test@test.com', 'status': 'confirmed'}, 
      );

      final controller = localContainer.read(tripControllerProvider.notifier);

      expect(
        () => controller.cancelRide(tTripId),
        throwsA(predicate((e) => e.toString().contains('maximum of 2 rides'))),
      );
    });

    test('Controller state is loading while startRide is in progress', () {
      when(() => mockTripRepo.updateTripData(any(), any()))
          .thenAnswer((_) => Future.delayed(const Duration(seconds: 1)));

      final controller = container.read(tripControllerProvider.notifier);
      
      controller.startRide(tTripId);
      expect(container.read(tripControllerProvider).isLoading, true);
    });
  });

  group('TripController - Point 4: Confirm Booking (requestRide)', () {
    test('requestRide successfully calls repository to create a trip', () async {
      when(() => mockTripRepo.createTrip(any())).thenAnswer((_) async {});

      final controller = container.read(tripControllerProvider.notifier);
      final dummyTrip = FakeTripModel();

      await controller.requestRide(dummyTrip);

      verify(() => mockTripRepo.createTrip(any())).called(1);
      final state = container.read(tripControllerProvider);
      expect(state.isLoading, false);
      expect(state.hasError, false);
    });

    test('requestRide sets state to AsyncError when database throws an exception', () async {
      final dbError = Exception('No Internet Connection or Database Timeout');
      when(() => mockTripRepo.createTrip(any())).thenThrow(dbError);

      final controller = container.read(tripControllerProvider.notifier);
      final dummyTrip = FakeTripModel();

      await controller.requestRide(dummyTrip);

      final state = container.read(tripControllerProvider);
      expect(state.isLoading, false);
      expect(state.hasError, true);
      expect(state.error, dbError);
    });
  });

  group('TripController - Scheduled Rides & Timeouts', () {
    test('scheduleRide successfully creates a trip in the database', () async {
      when(() => mockTripRepo.createTrip(any())).thenAnswer((_) async {});
      final controller = container.read(tripControllerProvider.notifier);

      await controller.scheduleRide(scheduledTrip);

      verify(() => mockTripRepo.createTrip(scheduledTrip)).called(1);
      expect(container.read(tripControllerProvider), const AsyncValue<void>.data(null));
    });

    test('acceptRide successfully claims a scheduled ride and updates driver mode', () async {
      const tripID = 'trip_123';
      const driverID = 'driver@test.com'; 
      const driverName = 'John Doe';

      when(() => mockTripRepo.runAcceptRideTransaction(
        tripID: tripID,
        driverID: driverID,
        driverName: driverName,
        isScheduled: true,
      )).thenAnswer((_) async {});

      when(() => mockUserRepo.updateUser(driverID, {'mode': DriverMode.busy.name}))
          .thenAnswer((_) async {});

      when(() => mockAuthController.refreshUser()).thenAnswer((_) async {});

      final controller = container.read(tripControllerProvider.notifier);

      await controller.acceptRide(tripID, driverName, driverID, isScheduled: true);

      verify(() => mockTripRepo.runAcceptRideTransaction(
        tripID: tripID,
        driverID: driverID,
        driverName: driverName,
        isScheduled: true,
      )).called(1);
      
      verify(() => mockUserRepo.updateUser(driverID, {'mode': DriverMode.busy.name})).called(1);
      verify(() => mockAuthController.refreshUser()).called(1);
    });

    test('cancelScheduledRideByCommuter marks trip as cancelled', () async {
      when(() => mockTripRepo.updateTripData('trip_123', {'status': TripStatus.cancelled.name}))
          .thenAnswer((_) async {});

      final controller = container.read(tripControllerProvider.notifier);

      await controller.cancelScheduledRideByCommuter(scheduledTrip);

      verify(() => mockTripRepo.updateTripData('trip_123', {'status': TripStatus.cancelled.name})).called(1);
    });

    test('cancelScheduledRideByDriver removes driver but keeps trip scheduled', () async {
      when(() => mockTripRepo.updateTripData('trip_123', {
        'driverID': null,
        'driverName': null,
      })).thenAnswer((_) async {});

      final controller = container.read(tripControllerProvider.notifier);

      await controller.cancelScheduledRideByDriver(scheduledTrip);

      verify(() => mockTripRepo.updateTripData('trip_123', {
        'driverID': null,
        'driverName': null,
      })).called(1);
    });

    test('autoCancelExpiredRide successfully marks trip as cancelled in database', () async {
      const testTripID = 'trip_999';

      when(() => mockTripRepo.updateTripData(testTripID, {'status': TripStatus.cancelled.name}))
          .thenAnswer((_) async {});

      final controller = container.read(tripControllerProvider.notifier);
      await controller.autoCancelExpiredRide(testTripID);

      verify(() => mockTripRepo.updateTripData(testTripID, {'status': TripStatus.cancelled.name})).called(1);
    });
  });
}