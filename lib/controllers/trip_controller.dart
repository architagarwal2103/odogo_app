import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odogo_app/controllers/auth_controller.dart';
import 'package:odogo_app/models/enums.dart';
import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../repositories/trip_repository.dart';

final tripRepositoryProvider = Provider((ref) => TripRepository());

// Constantly re-evaluates the scheduled ride time windows
final timeTickerProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

// Stream for Drivers to see available rides
final pendingTripsProvider = StreamProvider<List<TripModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  // If the driver is currently busy, cut off the broadcast stream so they do not receive any more pending ride requests.
  if (currentUser?.mode == DriverMode.busy) {
    return Stream.value([]);
  }
  // Get the live ticking time
  final now = ref.watch(timeTickerProvider).value ?? DateTime.now();
  final tripsStream = ref.watch(tripRepositoryProvider).streamPendingTrips();

  return tripsStream.map((trips) {
    return trips.where((trip) {
      // Immediate rides are always visible
      if (trip.status == TripStatus.pending) return true;

      // Scheduled rides follow the broadcast rules
      if (trip.status == TripStatus.scheduled && trip.scheduledTime != null) {
        final scheduledTime = trip.scheduledTime!;
        final diff = scheduledTime.difference(now);
        final minutesLeft = diff.inMinutes;

        // "inMinutes" truncates. So if diff is 120m 59s, it stays '120' for exactly 1 minute.
        if (minutesLeft == 120) return true; // 2 hours prior
        if (minutesLeft == 60) return true; // 1 hour prior
        if (minutesLeft == 30) return true; // 30 mins prior

        // Continuous broadcast starting 15 mins prior (up until 15 mins after in case of delays)
        if (minutesLeft <= 15 && minutesLeft >= -15) return true;
      }

      // If it doesn't match the time windows, keep it hidden from the driver!
      return false;
    }).toList();
  });
});

// Stream for Commuters to watch their specific active ride
final activeTripStreamProvider = StreamProvider.family<TripModel?, String>((
  ref,
  tripID,
) {
  return ref.watch(tripRepositoryProvider).streamTrip(tripID);
});

final tripControllerProvider =
    NotifierProvider<TripController, AsyncValue<void>>(() {
      return TripController();
    });

// Fetches specific user details, like phone numbers
final userInfoProvider = FutureProvider.family<UserModel?, String>((
  ref,
  uid,
) async {
  if (uid.isEmpty) return null;
  return await ref.read(userRepositoryProvider).getUser(uid);
});

final commuterTripsProvider = StreamProvider.autoDispose<List<TripModel>>((
  ref,
) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('trips')
      .where('commuterID', isEqualTo: currentUser.userID)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => TripModel.fromJson(doc.data())).toList(),
      );
});

final driverTripsProvider = StreamProvider.autoDispose<List<TripModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('trips')
      .where('driverID', isEqualTo: currentUser.userID)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => TripModel.fromJson(doc.data())).toList(),
      );
});

class TripController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  // Getter to access the repository using internal 'ref'
  TripRepository get _repository => ref.read(tripRepositoryProvider);

  Future<void> requestRide(TripModel trip) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createTrip(trip);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Driver: Accepts a pending ride
  Future<void> acceptRide(String tripID, String driverName, String driverID, {bool isScheduled = false}) async {
    state = const AsyncValue.loading();
    try {
      // 1. Delegate the complex transaction to the repository
      await _repository.runAcceptRideTransaction(
        tripID: tripID,
        driverID: driverID,
        driverName: driverName,
        isScheduled: isScheduled,
      );

      // 2. Set driver mode to busy
      await ref.read(userRepositoryProvider).updateUser(driverID, {
        'mode': DriverMode.busy.name,
      });

      // 3. Refresh user state
      await ref.read(authControllerProvider.notifier).refreshUser();
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      print(
        'DEBUG: acceptRide error: $e'.replaceFirst('Exception: ', '').trim(),
      );
      print('DEBUG: Stack trace: $st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> confirmScheduledRide(String tripID) async {
    try {
      await _repository.updateTripData(tripID, {
        'status': TripStatus.confirmed.name,
      });
    } catch (e) {
      print(e);
    }
  }

  /// Driver: Marks the ride as picked up / in progress
  Future<void> startRide(String tripID) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTripData(tripID, {
        'status': TripStatus.ongoing.name,
        'startTime': DateTime.now(),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Commuter/Driver: Cancelling ride logic
  Future<void> cancelRide(String tripID) async {
    state = const AsyncValue.loading();
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) throw Exception("User not authenticated.");

      // 1. Use the repository to fetch the data instead of Firebase direct
      final tripData = await _repository.getTripRawData(tripID);
      if (tripData == null) throw Exception("Trip not found");

      // ... (Keep all your existing boolean logic and strike constraint rules here exactly as they are) ...
      final bool isDriverCancelling = currentUser.role == UserRole.driver;
      final bool isCommuterCancelling = currentUser.role == UserRole.commuter;
      final bool hasDriverAccepted = tripData['driverID'] != null;

      bool applyConstraint = true;
      if (isCommuterCancelling && !hasDriverAccepted) applyConstraint = false;

      final now = DateTime.now();
      List<Timestamp> recentCancels = [];

      // Enforce the 15-minute constraint if applicable
      if (applyConstraint) {
        final fifteenMinsAgo = now.subtract(const Duration(minutes: 15));
        recentCancels = currentUser.cancelHistory?.where((timestamp) {
          return timestamp.toDate().isAfter(fifteenMinsAgo);
        }).toList() ?? [];

        if (recentCancels.length >= 2) throw Exception("You can cancel a maximum of 2 rides in 15 minutes.");
      }

      if (isDriverCancelling) {
        await _repository.updateTripData(tripID, {
          'status': TripStatus.pending.name,
          'driverID': null, // Use null instead of FieldValue.delete() for mocks to work smoothly
          'driverName': null, 
        });
        await ref.read(userRepositoryProvider).updateUser(currentUser.userID, {'mode': DriverMode.online.name});
      } else if (isCommuterCancelling) {
        await _repository.updateTripData(tripID, {'status': TripStatus.cancelled.name}); // If commuter cancels, the trip is dead

        // If a driver was already attached to this trip, they should be made free
        if (hasDriverAccepted) {
          await ref.read(userRepositoryProvider).updateUser(tripData['driverID'], {'mode': DriverMode.online.name});
        }
      }

      // Counts towards penalty only if the constraint is applied
      if (applyConstraint) {
        recentCancels.add(Timestamp.fromDate(now));
        await ref.read(userRepositoryProvider).updateUser(currentUser.userID, {'cancelHistory': recentCancels});
      }

      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // Ensure the UI catches the strike rule errors!
    }
  }

  /// User: Marks their side of the ride as complete
  Future<void> completeRide({required String tripID, required bool isDriver}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTripData(tripID, {
        isDriver ? 'driverEnd' : 'commuterEnd': true,
      });
      
      // Use the repository to check the status
      final tripData = await _repository.getTripRawData(tripID);
      if (tripData == null) throw Exception("Trip not found");

      final driverEnd = tripData['driverEnd'] ?? false;
      final commuterEnd = tripData['commuterEnd'] ?? false;

      if (driverEnd && commuterEnd) {
        await _repository.updateTripData(tripID, {'status': TripStatus.completed.name});
        final assignedDriverID = tripData['driverID'];
        if (assignedDriverID != null) {
          await ref.read(userRepositoryProvider).updateUser(assignedDriverID, {'mode': DriverMode.online.name});
        }
      }

      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  //ScheduleRide Function
  Future<void> scheduleRide(TripModel trip) async {
    state = const AsyncValue.loading();
    try {
      // Saves the trip to Firestore exactly like a normal ride, but with the 'scheduled' status
      await _repository.createTrip(trip);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancelScheduledRideByCommuter(TripModel trip) async {
    try {
      await _repository.updateTripData(trip.tripID, {
        'status': TripStatus.cancelled.name,
      });
      // Free the driver if one was assigned
      if (trip.driverID != null) {
        await ref.read(userRepositoryProvider).updateUser(trip.driverID!, {
          'mode': DriverMode.online.name,
        });
      }
    } catch (e) {
      print('Error cancelling by commuter: $e');
    }
  }

  Future<void> cancelScheduledRideByDriver(TripModel trip) async {
    try {
      // Unassign the driver, but leave the status as 'scheduled' so it goes back to the pool
      await _repository.updateTripData(trip.tripID, {
        'driverID': null,
        'driverName': null,
      });
      // Free the driver who just cancelled
      if (trip.driverID != null) {
        await ref.read(userRepositoryProvider).updateUser(trip.driverID!, {
          'mode': DriverMode.online.name,
        });
      }
    } catch (e) {
      print('Error cancelling by driver: $e');
    }
  }

  // Auto-cancels an immediate ride if no driver accepts within 15 minutes
  Future<void> autoCancelExpiredRide(String tripID) async {
    try {
      await _repository.updateTripData(tripID, {
        'status': TripStatus.cancelled.name,
      });
    } catch (e) {
      print('Error auto-cancelling ride: $e');
    }
  }
}
