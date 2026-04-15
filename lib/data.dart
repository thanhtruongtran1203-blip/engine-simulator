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
};