import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odogo_app/models/trip_model.dart';
import 'package:odogo_app/models/enums.dart';

class TripRepository {
  final FirebaseFirestore _firestore;
  TripRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  CollectionReference get _trips => _firestore.collection('trips');

  // Commuter: Requests a new ride.
  Future<void> createTrip(TripModel trip) async {
    try {
      await _trips.doc(trip.tripID).set(trip.toJson());
    } catch (e) {
      throw Exception('Failed to request ride: $e');
    }
  }

  // Driver: Streams all trips currently sitting in the 'pending' state.
  Stream<List<TripModel>> streamPendingTrips() {
    return _trips
        .where('status', whereIn: ['pending', 'scheduled'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TripModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // Both: Streams a specific trip to watch for real-time status updates
  // (e.g., waiting for a driver to accept, or tracking the active ride).
  Stream<TripModel?> streamTrip(String tripID) {
    return _trips.doc(tripID).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return TripModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Fetches a specific trip's data as a Map.
  /// This allows the Controller to get trip details without calling Firestore directly.
  Future<Map<String, dynamic>?> getTripData(String tripID) async {
    try {
      final doc = await _trips.doc(tripID).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to fetch trip data: $e');
    }
  }

  /// Driver: Accepts a trip or updates its status (e.g., pending -> ongoing -> completed).
  /// Universal: Updates any specific fields on a trip document.
  /// Verifies that updating one field (like status) doesn't corrupt others (like ridePIN).
  Future<void> updateTripData(String tripID, Map<String, dynamic> data) async {
    try {
      await _trips.doc(tripID).update(data);
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }

  // Completely removes a trip from the database to save space.
  Future<void> deleteTrip(String tripID) async {
    try {
      await _trips.doc(tripID).delete();
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }

  // Cleans up old trips to save database space.
  // Keeps a maximum of 100 trips, AND deletes anything older than 30 days.
  Future<void> cleanupOldTrips(String userID, String roleField) async {
    try {
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _trips
          .where(roleField, isEqualTo: userID)
          .where('status', whereIn: ['completed', 'cancelled'])
          .get();

      final docs = snapshot.docs;

      // Sort locally using the actual bookingTime field!
      docs.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        final timeA =
            (dataA['bookingTime'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final timeB =
            (dataB['bookingTime'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA); // Descending (newest first)
      });

      for (int i = 0; i < docs.length; i++) {
        final data = docs[i].data() as Map<String, dynamic>;
        final tripDate =
            (data['bookingTime'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final isTooOld = tripDate.isBefore(oneMonthAgo);
        final isBeyond100 = i >= 100;

        if (isTooOld || isBeyond100) {
          await _trips.doc(docs[i].id).delete();
        }
      }
    } catch (e) {
      print(
        "Failed to cleanup old trips: $e"
            .replaceFirst('Exception: ', '')
            .trim(),
      );
    }
  }

  /// Fetches a single trip's raw data as a Map. Useful for validation before actions.
  Future<Map<String, dynamic>?> getTripRawData(String tripID) async {
    final doc = await _trips.doc(tripID).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  /// Runs the atomic transaction to safely assign a driver to a trip
  Future<void> runAcceptRideTransaction({
    required String tripID,
    required String driverID,
    required String driverName,
    required bool isScheduled,
  }) async {
    final docRef = _trips.doc(tripID);

    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) throw Exception('Trip not found');

      final data = snapshot.data() as Map<String, dynamic>;
      final currentStatus = data['status'] as String?;
      final existingDriver = data['driverID'];

      if (existingDriver == null &&
          (currentStatus == TripStatus.pending.name ||
              currentStatus == TripStatus.scheduled.name)) {
        tx.update(docRef, {
          'status': isScheduled
              ? TripStatus.scheduled.name
              : TripStatus.confirmed.name,
          'driverName': driverName,
          'driverID': driverID,
        });
      } else {
        throw Exception('Trip already accepted by another driver or not available.');
      }
    });
  }
}
