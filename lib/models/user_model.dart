import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odogo_app/models/enums.dart';

class UserModel {
  final String userID;
  final String emailID;
  final String phoneNo;
  final String gender;
  final Timestamp dob;
  final UserRole role;

  // Commuter-specific fields
  final List<String>? savedLocations;
  final String? roomNo;
  final int? numCancels;

  // Driver-specific fields
  final bool? verificationStatus;
  final Map<String, String>? docPaths;
  final DriverMode? mode;
  final double? avgRating;
  final int? ratingCount;

  UserModel({
    required this.userID,
    required this.emailID,
    required this.phoneNo,
    required this.gender,
    required this.dob,
    required this.role,
    this.savedLocations,
    this.roomNo,
    this.numCancels,
    this.verificationStatus,
    this.docPaths,
    this.mode,
    this.avgRating,
    this.ratingCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var locationsList = json['savedLocations'] as List?;
    List<String>? parsedLocations = locationsList?.cast<String>();

    return UserModel(
      userID: json['userID'] ?? '',
      emailID: json['emailID'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] as Timestamp,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.commuter,
      ),
      savedLocations: parsedLocations,
      roomNo: json['roomNo'],
      numCancels: json['numCancels'],
      verificationStatus: json['verificationStatus'],
      docPaths: json['docPaths'] != null
          ? Map<String, String>.from(json['docPaths'])
          : null,
      mode: json['mode'] != null
          ? DriverMode.values.firstWhere((e) => e.name == json['mode'])
          : null,
      avgRating: (json['avgRating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'emailID': emailID,
      'phoneNo': phoneNo,
      'gender': gender,
      'dob': dob,
      'role': role.name,
      if (savedLocations != null) 'savedLocations': savedLocations,
      if (roomNo != null) 'roomNo': roomNo,
      if (numCancels != null) 'numCancels': numCancels,
      if (verificationStatus != null) 'verificationStatus': verificationStatus,
      if (docPaths != null) 'docPaths': docPaths,
      if (mode != null) 'mode': mode!.name,
      if (avgRating != null) 'avgRating': avgRating,
      if (ratingCount != null) 'ratingCount': ratingCount,
    };
  }
}
