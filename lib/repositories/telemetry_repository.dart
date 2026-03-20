import 'package:firebase_database/firebase_database.dart';
import 'package:odogo_app/models/driver_telemetry_model.dart';
// import '../models/driver_telemetry_model.dart';

class TelemetryRepository {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  /// Driver: Pushes their live location to the RTDB.
  Future<void> updateDriverLocation(DriverTelemetry telemetry) async {
    try {
      await _rtdb
          .ref('drivers_locations/${telemetry.driverID}')
          .set(telemetry.toJson());
    } catch (e) {
      throw Exception('Failed to update telemetry: $e');
    }
  }

  /// Driver: Removes their location from the map when they go offline.
  Future<void> removeDriverLocation(String driverID) async {
    await _rtdb.ref('drivers_locations/$driverID').remove();
  }

  /// Commuter: Listens to a specific driver's location as they approach.
  Stream<DriverTelemetry?> streamDriverLocation(String driverID) {
    return _rtdb.ref('drivers_locations/$driverID').onValue.map((event) {
      if (event.snapshot.exists) {
        return DriverTelemetry.fromJson(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
      }
      return null;
    });
  }
}
