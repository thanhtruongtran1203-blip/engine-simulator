import 'models.dart';

class EngineConfig {
  final String name;
  final String type;
  final int cylinders;
  final List<int> firingOrder;
  final int rpmMax;

  EngineConfig({
    required this.name,
    required this.type,
    required this.cylinders,
    required this.firingOrder,
    required this.rpmMax,
  });
}

// ================== BRANDS ==================
final brands = [
  Brand(name: "Suzuki", logo: "assets/suzuki.png"),
  Brand(name: "Toyota", logo: "assets/toyota.png"),
  Brand(name: "Honda", logo: "assets/honda.png"),
  Brand(name: "Hyundai", logo: "assets/hyundai.png"),
  Brand(name: "Kia", logo: "assets/kia.png"),
  Brand(name: "Mazda", logo: "assets/mazda.png"),
  Brand(name: "BMW", logo: "assets/bmw.png"),
  Brand(name: "Ford", logo: "assets/ford.png"),
  Brand(name: "Mercedes", logo: "assets/mercedes.png"),
  Brand(name: "VinFast", logo: "assets/vinfast.png"),
  Brand(name: "Mitsubishi", logo: "assets/Mitsubishi.png"),
  Brand(name: "Peugeot", logo: "assets/Peugeot.png"),
];

// ================== ENGINE DATA ==================

final Map<String, List<EngineConfig>> engineData = {

  // ================= SUZUKI =================
  "Suzuki": [
    EngineConfig(name: "K15B", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "G10A", type: "I3", cylinders: 3, firingOrder: [1,3,2], rpmMax: 6500),
    EngineConfig(name: "G13B", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 7000),
    EngineConfig(name: "G16B", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "K10B", type: "I3", cylinders: 3, firingOrder: [1,3,2], rpmMax: 6500),
    EngineConfig(name: "K10C", type: "I3 Turbo", cylinders: 3, firingOrder: [1,3,2], rpmMax: 6000),
    EngineConfig(name: "K12M", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "K14B", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "K14C", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "J20A", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
  ],

  // ================= TOYOTA =================
  "Toyota": [
    EngineConfig(name: "1NZ-FE", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "2NZ-FE", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "1ZR-FE", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "2ZR-FE", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "2ZR-FAE", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "1NR-FE", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "2NR-FE", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "2GR-FE", type: "V6", cylinders: 6, firingOrder: [1,2,3,4,5,6], rpmMax: 6500),
    EngineConfig(name: "A25A-FKS", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "M20A-FKS", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
  ],

  // ================= HONDA =================
  "Honda": [
    EngineConfig(name: "L12B", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "L13A", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "L15B", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "R18A", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "R20A", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "K20A", type: "I4 VTEC", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 8000),
    EngineConfig(name: "K24W", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 7000),
    EngineConfig(name: "B16A", type: "I4 VTEC", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 8200),
    EngineConfig(name: "D15B", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 7000),
    EngineConfig(name: "J35", type: "V6", cylinders: 6, firingOrder: [1,2,3,4,5,6], rpmMax: 6500),
  ],

  // ================= HYUNDAI =================
  "Hyundai": [
    EngineConfig(name: "Kappa 1.0", type: "I3 Turbo", cylinders: 3, firingOrder: [1,3,2], rpmMax: 6000),
    EngineConfig(name: "Kappa 1.2", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "Gamma 1.4", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "Gamma 1.6", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "Gamma 1.6T", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "Nu 2.0", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "Theta II 2.4", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "Lambda II 3.3", type: "V6", cylinders: 6, firingOrder: [1,2,3,4,5,6], rpmMax: 6500),
    EngineConfig(name: "Smartstream 1.6T", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "Smartstream 2.5", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
  ],

  // ================= KIA =================
  "Kia": [
    EngineConfig(name: "Kappa 1.0", type: "I3 Turbo", cylinders: 3, firingOrder: [1,3,2], rpmMax: 6000),
    EngineConfig(name: "Kappa 1.2", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "Gamma 1.4", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "Gamma 1.6", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "Gamma 1.6T", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "Nu 2.0", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "Theta II 2.4", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "Lambda II 3.3", type: "V6", cylinders: 6, firingOrder: [1,2,3,4,5,6], rpmMax: 6500),
    EngineConfig(name: "Smartstream 1.6T", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "Smartstream 2.5", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
  ],

  // ================= MAZDA =================
  "Mazda": [
    EngineConfig(name: "Skyactiv-G 1.5", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "Skyactiv-G 2.0", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "Skyactiv-G 2.5", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "Skyactiv-X 2.0", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "MZR 1.6", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "MZR 2.0", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "MZR 2.5", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "BP-ZE", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 7000),
    EngineConfig(name: "13B Rotary", type: "Rotary", cylinders: 2, firingOrder: [1,2], rpmMax: 9000),
    EngineConfig(name: "20B Rotary", type: "Rotary", cylinders: 3, firingOrder: [1,2,3], rpmMax: 9000),
  ],

  "BMW": [
    EngineConfig(name: "N20", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 7000),
    EngineConfig(name: "B48", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 7000),
    EngineConfig(name: "B58", type: "I6 Turbo", cylinders: 6, firingOrder: [1,5,3,6,2,4], rpmMax: 7000),
    EngineConfig(name: "N52", type: "I6", cylinders: 6, firingOrder: [1,5,3,6,2,4], rpmMax: 6500),
    EngineConfig(name: "S58", type: "I6 TwinTurbo", cylinders: 6, firingOrder: [1,5,3,6,2,4], rpmMax: 7200),
  ],

  "Ford": [
    EngineConfig(name: "EcoBoost 1.5", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "EcoBoost 2.0", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "EcoBoost 2.3", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6800),
    EngineConfig(name: "EcoBoost 3.5", type: "V6 TwinTurbo", cylinders: 6, firingOrder: [1,4,2,5,3,6], rpmMax: 6000),
    EngineConfig(name: "PowerStroke 3.2", type: "I5 Diesel", cylinders: 5, firingOrder: [1,2,4,5,3], rpmMax: 4500),
  ],

  "Mercedes": [
    EngineConfig(name: "M274", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "M282", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "M276", type: "V6", cylinders: 6, firingOrder: [1,4,2,5,3,6], rpmMax: 6500),
    EngineConfig(name: "M139", type: "I4 AMG", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 7200),
    EngineConfig(name: "OM654", type: "I4 Diesel", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 5000),
  ],

  "Mitsubishi": [
    EngineConfig(name: "4G63", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 7000),
    EngineConfig(name: "4B11", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 7000),
    EngineConfig(name: "4A91", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6000),
    EngineConfig(name: "6G72", type: "V6", cylinders: 6, firingOrder: [1,4,2,5,3,6], rpmMax: 6000),
    EngineConfig(name: "4N15", type: "I4 Diesel", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 4500),
  ],

  "Peugeot": [
    EngineConfig(name: "TU5", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "EP6", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "DV6", type: "I4 Diesel", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 4500),
    EngineConfig(name: "DW10", type: "I4 Diesel", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 4500),
    EngineConfig(name: "EB2", type: "I3", cylinders: 3, firingOrder: [1,2,3], rpmMax: 6000),
  ],

  "VinFast": [
    EngineConfig(name: "N20", type: "I4 Turbo", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 7000),
    EngineConfig(name: "Fadil 1.4", type: "I4", cylinders: 4, firingOrder: [1,3,4,2], rpmMax: 6500),
    EngineConfig(name: "VF e34 Motor", type: "Electric", cylinders: 0, firingOrder: [], rpmMax: 12000),
    EngineConfig(name: "VF5 Motor", type: "Electric", cylinders: 0, firingOrder: [], rpmMax: 12000),
    EngineConfig(name: "VF8 Motor", type: "Electric", cylinders: 0, firingOrder: [], rpmMax: 13000),
  ],
};