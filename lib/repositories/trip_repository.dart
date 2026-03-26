import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odogo_app/models/trip_model.dart';

class TripRepository {
  final FirebaseFirestore _firestore;
  TripRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  CollectionReference get _trips => _firestore.collection('trips');

  /// Commuter: Requests a new ride.
  Future<void> createTrip(TripModel trip) async {
    try {
      await _trips.doc(trip.tripID).set(trip.toJson());
    } catch (e) {
      throw Exception('Failed to request ride: $e');
    }
  }

  /// Driver: Streams all trips currently sitting in the 'pending' state.
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

  /// Both: Streams a specific trip to watch for real-time status updates
  /// (e.g., waiting for a driver to accept, or tracking the active ride).
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
  Future<void> updateTripData(String tripID, Map<String, dynamic> data) async {
    try {
      await _trips.doc(tripID).update(data);
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }

  // Cleans up old trips to save database space.
  // Keeps a maximum of 100 trips, AND deletes anything older than 30 days.
  Future<void> cleanupOldTrips(String userID, String roleField) async {
    try {
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));

      // Fetch all finished trips for this user
      final snapshot = await _trips
          .where(roleField, isEqualTo: userID)
          .where('status', whereIn: ['completed', 'cancelled'])
          .get();

      final docs = snapshot.docs;

      // Sort locally by tripID (which is a timestamp epoch in your app)
      docs.sort((a, b) {
        final timeA = int.tryParse(a.id) ?? 0;
        final timeB = int.tryParse(b.id) ?? 0;
        return timeB.compareTo(timeA); // Descending (newest first)
      });

      // Loop through and delete based on constraints
      for (int i = 0; i < docs.length; i++) {
        final tripEpoch = int.tryParse(docs[i].id) ?? 0;
        final tripDate = DateTime.fromMillisecondsSinceEpoch(tripEpoch);

        final isTooOld = tripDate.isBefore(oneMonthAgo);
        final isBeyond100 = i >= 100;

        // If it violates either constraint (minm of 1 month or 100 rides)
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
}
