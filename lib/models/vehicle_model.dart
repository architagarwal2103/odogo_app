class VehicleModel {
  final String registrationNum;
  final String rcDoc;
  final String pucDoc;
  final String insuranceDoc;

  VehicleModel({
    required this.registrationNum,
    required this.rcDoc,
    required this.pucDoc,
    required this.insuranceDoc,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      registrationNum: json['registrationNum'] ?? '',
      rcDoc: json['rcDoc'] ?? '',
      pucDoc: json['pucDoc'] ?? '',
      insuranceDoc: json['insuranceDoc'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registrationNum': registrationNum,
      'rcDoc': rcDoc,
      'pucDoc': pucDoc,
      'insuranceDoc': insuranceDoc,
    };
  }
}