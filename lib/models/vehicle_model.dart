class VehicleModel {
  final String registrationNum;
  final String model;
  final String driverID;

  VehicleModel({
    required this.registrationNum,
    required this.model,
    required this.driverID,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      registrationNum: json['registrationNum'] ?? '',
      model: json['model'] ?? '',
      driverID: json['driverID'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registrationNum': registrationNum,
      'model': model,
      'driverID': driverID,
    };
  }
}