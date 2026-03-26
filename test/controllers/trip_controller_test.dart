import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:odogo_app/controllers/trip_controller.dart';
import 'package:odogo_app/repositories/trip_repository.dart';
import 'package:odogo_app/repositories/user_repository.dart';
import 'package:odogo_app/controllers/auth_controller.dart';
import 'package:odogo_app/models/trip_model.dart';
import 'package:odogo_app/models/enums.dart';

// --- MOCKS ---
class MockTripRepository extends Mock implements TripRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockAuthController extends Notifier<AuthState> with Mock implements AuthController {
  @override
  AuthState build() => AuthInitial();
}

// Fake model for the original requestRide tests
class FakeTripModel extends Fake implements TripModel {}

void main() {
  late MockTripRepository mockTripRepo;
  late MockUserRepository mockUserRepo;
  late MockAuthController mockAuthController;
  late ProviderContainer container;

  // A fake scheduled trip for the new scheduled tests
  final scheduledTrip = TripModel(
    tripID: 'trip_123',
    status: TripStatus.scheduled,
    commuterName: 'Aditya',
    commuterID: 'commuter_99',
    startLocName: 'IITK Gate',
    endLocName: 'Kanpur Central',
    startTime: DateTime.now().add(const Duration(hours: 2)),
    ridePIN: '1234',
    driverEnd: false,
    commuterEnd: false,
    scheduledTime: DateTime.now().add(const Duration(hours: 2)),
  );

  setUpAll(() {
    // Register fallbacks for BOTH sets of tests so nothing crashes!
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
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TripController - Point 4: Confirm Booking (requestRide)', () {
    test('requestRide successfully calls repository to create a trip', () async {
      // --- ARRANGE ---
      // Tell the mock database to just return a successful empty future when asked to create a trip
      when(() => mockTripRepo.createTrip(any())).thenAnswer((_) async {});

      final controller = container.read(tripControllerProvider.notifier);
      final dummyTrip = FakeTripModel();

      // --- ACT ---
      // Call the exact method from your trip_controller.dart
      await controller.requestRide(dummyTrip);

      // --- ASSERT ---
      // 1. Verify the controller successfully passed the trip to the repository
      verify(() => mockTripRepo.createTrip(any())).called(1);
      
      // 2. Verify the controller state went back to Data (not loading/error) after finishing
      final state = container.read(tripControllerProvider);
      expect(state.isLoading, false);
      expect(state.hasError, false);
    });
    // ------------------------------------------------------------------
    // POINT 4 EDGE CASE: Booking Fails (No Internet / DB Error)
    // ------------------------------------------------------------------
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
  // ------------------------------------------------------------------
  // TASK 9: Schedule for later
  // ------------------------------------------------------------------
  test('scheduleRide successfully creates a trip in the database', () async {
    // Arrange
    when(() => mockTripRepo.createTrip(any())).thenAnswer((_) async {});
    final controller = container.read(tripControllerProvider.notifier);

    // Act
    await controller.scheduleRide(scheduledTrip);

    // Assert
    verify(() => mockTripRepo.createTrip(scheduledTrip)).called(1);
    expect(container.read(tripControllerProvider), const AsyncValue<void>.data(null));
  });

  // ------------------------------------------------------------------
  // TASK 10: Accepting scheduled booking
  // ------------------------------------------------------------------
  test('acceptRide successfully claims a scheduled ride and updates driver mode', () async {
    // Arrange
    const tripID = 'trip_123';
    const driverID = 'driver_456';
    const driverName = 'John Doe';

    // Mock the atomic transaction
    when(() => mockTripRepo.runAcceptRideTransaction(
      tripID: tripID,
      driverID: driverID,
      driverName: driverName,
      isScheduled: true,
    )).thenAnswer((_) async {});

    // Mock the user mode update
    when(() => mockUserRepo.updateUser(driverID, {'mode': DriverMode.busy.name}))
        .thenAnswer((_) async {});

    // Mock the auth refresh
    when(() => mockAuthController.refreshUser()).thenAnswer((_) async {});

    final controller = container.read(tripControllerProvider.notifier);

    // Act
    await controller.acceptRide(tripID, driverName, driverID, isScheduled: true);

    // Assert
    verify(() => mockTripRepo.runAcceptRideTransaction(
      tripID: tripID,
      driverID: driverID,
      driverName: driverName,
      isScheduled: true,
    )).called(1);
    
    verify(() => mockUserRepo.updateUser(driverID, {'mode': DriverMode.busy.name})).called(1);
    verify(() => mockAuthController.refreshUser()).called(1);
  });

  // ------------------------------------------------------------------
  // TASK 6 & 7 (Scheduled Variation): Cancelling Scheduled Rides
  // ------------------------------------------------------------------
  test('cancelScheduledRideByCommuter marks trip as cancelled', () async {
    // Arrange
    when(() => mockTripRepo.updateTripData('trip_123', {'status': TripStatus.cancelled.name}))
        .thenAnswer((_) async {});

    final controller = container.read(tripControllerProvider.notifier);

    // Act
    await controller.cancelScheduledRideByCommuter(scheduledTrip);

    // Assert
    verify(() => mockTripRepo.updateTripData('trip_123', {'status': TripStatus.cancelled.name})).called(1);
  });

  test('cancelScheduledRideByDriver removes driver but keeps trip scheduled', () async {
    // Arrange
    when(() => mockTripRepo.updateTripData('trip_123', {
      'driverID': null,
      'driverName': null,
    })).thenAnswer((_) async {});

    final controller = container.read(tripControllerProvider.notifier);

    // Act
    await controller.cancelScheduledRideByDriver(scheduledTrip);

    // Assert
    verify(() => mockTripRepo.updateTripData('trip_123', {
      'driverID': null,
      'driverName': null,
    })).called(1);
  });
}