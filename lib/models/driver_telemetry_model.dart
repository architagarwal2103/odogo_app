class DriverTelemetry {
  final String driverID;
  final double latitude;
  final double longitude;
  final int timestampMs;

  DriverTelemetry({
    required this.driverID,
    required this.latitude,
    required this.longitude,
    required this.timestampMs,
  });

  factory DriverTelemetry.fromJson(Map<dynamic, dynamic> json) {
    return DriverTelemetry(
      driverID: json['driverID'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestampMs: json['timestampMs'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverID': driverID,
      'latitude': latitude,
      'longitude': longitude,
      'timestampMs': timestampMs,
    };
  }
}
