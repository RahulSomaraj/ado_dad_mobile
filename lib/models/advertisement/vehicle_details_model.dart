class VehicleDetails {
  final String name;
  final String modelName;
  final String modelType;
  final String wheelerType;
  final String color;
  final VehicleSubDetails details;
  final String vendor;
  final VehicleModel vehicleModel;

  VehicleDetails({
    required this.name,
    required this.modelName,
    required this.modelType,
    required this.wheelerType,
    required this.color,
    required this.details,
    required this.vendor,
    required this.vehicleModel,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      name: json["name"] ?? "",
      modelName: json["modelName"] ?? "",
      modelType: json["modelType"] ?? "",
      wheelerType: json["wheelerType"] ?? "",
      color: json["color"] ?? "",
      details: VehicleSubDetails.fromJson(json["details"]),
      vendor: json["vendor"] ?? "",
      vehicleModel: VehicleModel.fromJson(json["vehicleModel"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "modelName": modelName,
      "modelType": modelType,
      "wheelerType": wheelerType,
      "color": color,
      "details": details.toJson(),
      "vendor": vendor,
      "vehicleModel": vehicleModel.toJson(),
    };
  }
}

class VehicleSubDetails {
  final int modelYear;
  final String month;

  VehicleSubDetails({
    required this.modelYear,
    required this.month,
  });

  factory VehicleSubDetails.fromJson(Map<String, dynamic> json) {
    return VehicleSubDetails(
      modelYear: json["modelYear"] ?? 0,
      month: json["month"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "modelYear": modelYear,
      "month": month,
    };
  }
}

class VehicleModel {
  final String name;
  final String modelName;
  final String modelDetails;
  final String fuelType;
  final String transmissionType;
  final int mileage;
  final int engineCapacity;
  final int fuelCapacity;
  final int maxPower;
  final AdditionalInfo additionalInfo;

  VehicleModel({
    required this.name,
    required this.modelName,
    required this.modelDetails,
    required this.fuelType,
    required this.transmissionType,
    required this.mileage,
    required this.engineCapacity,
    required this.fuelCapacity,
    required this.maxPower,
    required this.additionalInfo,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      name: json["name"] ?? "",
      modelName: json["modelName"] ?? "",
      modelDetails: json["modelDetails"] ?? "",
      fuelType: json["fuelType"] ?? "",
      transmissionType: json["transmissionType"] ?? "",
      mileage: json["mileage"] ?? 0,
      engineCapacity: json["engineCapacity"] ?? 0,
      fuelCapacity: json["fuelCapacity"] ?? 0,
      maxPower: json["maxPower"] ?? 0,
      additionalInfo: AdditionalInfo.fromJson(json["additionalInfo"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "modelName": modelName,
      "modelDetails": modelDetails,
      "fuelType": fuelType,
      "transmissionType": transmissionType,
      "mileage": mileage,
      "engineCapacity": engineCapacity,
      "fuelCapacity": fuelCapacity,
      "maxPower": maxPower,
      "additionalInfo": additionalInfo.toJson(),
    };
  }
}

class AdditionalInfo {
  final bool abs;
  final bool airConditioning;
  final int numberOfAirbags;
  final bool cruiseControl;
  final bool navigationSystem;
  final bool parkingSensors;
  final bool sunroof;
  final bool usbCompatibility;

  AdditionalInfo({
    required this.abs,
    required this.airConditioning,
    required this.numberOfAirbags,
    required this.cruiseControl,
    required this.navigationSystem,
    required this.parkingSensors,
    required this.sunroof,
    required this.usbCompatibility,
  });

  factory AdditionalInfo.fromJson(Map<String, dynamic> json) {
    return AdditionalInfo(
      abs: json["abs"] ?? false,
      airConditioning: json["airConditioning"] ?? false,
      numberOfAirbags: json["numberOfAirbags"] ?? 0,
      cruiseControl: json["cruiseControl"] ?? false,
      navigationSystem: json["navigationSystem"] ?? false,
      parkingSensors: json["parkingSensors"] ?? false,
      sunroof: json["sunroof"] ?? false,
      usbCompatibility: json["usbCompatibility"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "abs": abs,
      "airConditioning": airConditioning,
      "numberOfAirbags": numberOfAirbags,
      "cruiseControl": cruiseControl,
      "navigationSystem": navigationSystem,
      "parkingSensors": parkingSensors,
      "sunroof": sunroof,
      "usbCompatibility": usbCompatibility,
    };
  }
}
