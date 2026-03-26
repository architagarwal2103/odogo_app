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

void main() {
  late MockTripRepository mockTripRepo;
  late MockUserRepository mockUserRepo;
  late MockAuthController mockAuthController;
  late ProviderContainer container;

  // A fake scheduled trip for our tests
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

    // Register fallback values for complex mocktail arguments
    registerFallbackValue(scheduledTrip);
  });

  tearDown(() {
    container.dispose();
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