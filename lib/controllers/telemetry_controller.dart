import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_telemetry_model.dart';
import '../repositories/telemetry_repository.dart';

final telemetryRepositoryProvider = Provider((ref) => TelemetryRepository());

// Commuters use this to see the driver move on the map
final driverLocationProvider = StreamProvider.family<DriverTelemetry?, String>((
  ref,
  driverID,
) {
  return ref.read(telemetryRepositoryProvider).streamDriverLocation(driverID);
});

final telemetryControllerProvider = Provider((ref) {
  return TelemetryController(ref.read(telemetryRepositoryProvider));
});

class TelemetryController {
  final TelemetryRepository _repository;

  TelemetryController(this._repository);

  Future<void> broadcastLocation(DriverTelemetry telemetry) async {
    await _repository.updateDriverLocation(telemetry);
  }

  Future<void> stopBroadcasting(String driverID) async {
    await _repository.removeDriverLocation(driverID);
  }
}
