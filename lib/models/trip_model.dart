import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odogo_app/models/enums.dart';

class TripModel {
  final String tripID;
  final TripStatus status;
  final String commuterName;
  final String commuterID;
  final String? driverName; // Nullable until a driver accepts
  final String? driverID; // Nullable until a driver accepts
  final String startLocName;
  final String endLocName;
  final Timestamp? eta;
  final String ridePIN;
  final bool driverEnd;
  final bool commuterEnd;
  final Timestamp? scheduledTime; // Null for immediate rides

  TripModel({
    required this.tripID,
    required this.status,
    required this.commuterName,
    required this.commuterID,
    this.driverName,
    this.driverID,
    required this.startLocName,
    required this.endLocName,
    this.eta,
    required this.ridePIN,
    required this.driverEnd,
    required this.commuterEnd,
    this.scheduledTime,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      tripID: json['tripID'] ?? '',
      status: TripStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TripStatus.pending,
      ),
      commuterName: json['commuterName'] ?? '',
      commuterID: json['commuterID'] ?? '',
      driverName: json['driverName'],
      driverID: json['driverID'],
      startLocName: json['startLoc'] ?? '',
      endLocName: json['endLoc'] ?? '',
      eta: json['eta'] as Timestamp?,
      ridePIN: json['ridePIN'] ?? '',
      driverEnd: json['driverEnd'] ?? false,
      commuterEnd: json['commuterEnd'] ?? false,
      scheduledTime: json['scheduledTime'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripID': tripID,
      'status': status.name,
      'commuterName': commuterName,
      'commuterID': commuterID,
      if (driverName != null) 'driverName': driverName,
      if (driverID != null) 'driverID': driverID,
      'startLoc': startLocName,
      'endLoc': endLocName,
      if (eta != null) 'eta': eta,
      'ridePIN': ridePIN,
      'driverEnd': driverEnd,
      'commuterEnd': commuterEnd,
      if (scheduledTime != null) 'scheduledTime': scheduledTime,
    };
  }
}
