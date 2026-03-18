import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odogo_app/models/trip_model.dart';

class TripRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
        .where('status', isEqualTo: 'pending')
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

  /// Driver: Accepts a trip or updates its status (e.g., pending -> ongoing -> completed).
  /// Universal: Updates any specific fields on a trip document.
  Future<void> updateTripData(String tripID, Map<String, dynamic> data) async {
    try {
      await _trips.doc(tripID).update(data);
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }
}
