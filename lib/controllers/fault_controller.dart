import 'dart:math';

import 'package:flutter/material.dart';

import '../faults/engine_faults.dart';

class FaultController {

  final Random _rand = Random();

  int ckpFaultMode = 0;
  int cmpFaultMode = 0;

  bool appFault = false;
  bool mapFault = false;
  bool iatFault = false;
  bool ectFault = false;
  bool oilTempFault = false;
  bool fuelPumpFault = false;

  final Map<int, int> injectorFaultModes = {
    1: 0,
    2: 0,
    3: 0,
    4: 0,
  };

  final Map<int, int> coilFaultModes = {
    1: 0,
    2: 0,
    3: 0,
    4: 0,
  };

  bool get ckpFault => ckpFaultMode != 0;

  bool get cmpFault => cmpFaultMode != 0;

  bool hasInjectorFault(int cyl) =>
      (injectorFaultModes[cyl] ?? 0) != 0;

  bool hasCoilFault(int cyl) =>
      (coilFaultModes[cyl] ?? 0) != 0;

  void toggleCKPFault() {
    ckpFaultMode++;

    if (ckpFaultMode > 5) {
      ckpFaultMode = 0;
    }
  }

  void toggleCMPFault() {
    cmpFaultMode++;

    if (cmpFaultMode > 4) {
      cmpFaultMode = 0;
    }
  }

  void toggleAPPFault() {
    appFault = !appFault;
  }

  void toggleMAPFault() {
    mapFault = !mapFault;
  }

  void toggleIATFault() {
    iatFault = !iatFault;
  }

  void toggleECTFault() {
    ectFault = !ectFault;
  }

  void toggleOilTempFault() {
    oilTempFault = !oilTempFault;
  }

  void toggleFuelPumpFault() {
    fuelPumpFault = !fuelPumpFault;
  }

  void toggleInjectorFault(int cyl) {
    injectorFaultModes[cyl] =
        (injectorFaultModes[cyl] ?? 0) + 1;

    if ((injectorFaultModes[cyl] ?? 0) > 3) {
      injectorFaultModes[cyl] = 0;
    }
  }

  void toggleCoilFault(int cyl) {
    coilFaultModes[cyl] =
        (coilFaultModes[cyl] ?? 0) + 1;

    if ((coilFaultModes[cyl] ?? 0) > 3) {
      coilFaultModes[cyl] = 0;
    }
  }

  String get currentSensorFaultCode =>
      EngineFaults.getSensorFaultCode(
        ckpFaultMode: ckpFaultMode,
        cmpFaultMode: cmpFaultMode,
        ckpFault: ckpFault,
        cmpFault: cmpFault,
        appFault: appFault,
        mapFault: mapFault,
        iatFault: iatFault,
        ectFault: ectFault,
        oilTempFault: oilTempFault,
        fuelPumpFault: fuelPumpFault,
      );

  String get currentSensorFaultLabel =>
      EngineFaults.getSensorFaultLabel(
        ckpFault: ckpFault,
        cmpFault: cmpFault,
        appFault: appFault,
        mapFault: mapFault,
        iatFault: iatFault,
        ectFault: ectFault,
        oilTempFault: oilTempFault,
        fuelPumpFault: fuelPumpFault,
      );

  String get currentInjectorFaultCode =>
      EngineFaults.getInjectorFaultCode(
        injectorFaultModes,
      );

  String get currentInjectorFaultLabel =>
      EngineFaults.getInjectorFaultLabel(
        injectorFaultModes,
      );

  String get currentInjectorFaultDescription =>
      EngineFaults.getInjectorFaultDescription(
        injectorFaultModes,
      );

  String get currentCoilFaultCode =>
      EngineFaults.getCoilFaultCode(
        coilFaultModes,
      );

  String get currentCoilFaultLabel =>
      EngineFaults.getCoilFaultLabel(
        coilFaultModes,
      );

  String get currentCoilFaultDescription =>
      EngineFaults.getCoilFaultDescription(
        coilFaultModes,
      );


  String get currentFaultCode {
    if (currentSensorFaultCode.isNotEmpty) return currentSensorFaultCode;
    if (currentInjectorFaultCode.isNotEmpty) return currentInjectorFaultCode;
    if (currentCoilFaultCode.isNotEmpty) return currentCoilFaultCode;
    return '';
  }

  String get currentFaultLabel {
    if (currentSensorFaultLabel.isNotEmpty) return currentSensorFaultLabel;
    if (currentInjectorFaultLabel.isNotEmpty) return currentInjectorFaultLabel;
    if (currentCoilFaultLabel.isNotEmpty) return currentCoilFaultLabel;
    return '';
  }

  String get currentFaultDescription {
    if (currentSensorFaultCode.isNotEmpty) {
      return EngineFaults.getSensorFaultDescription(
        ckpFault: ckpFault,
        cmpFault: cmpFault,
        appFault: appFault,
        mapFault: mapFault,
        iatFault: iatFault,
        ectFault: ectFault,
        oilTempFault: oilTempFault,
        fuelPumpFault: fuelPumpFault,
      );
    }

    if (currentInjectorFaultCode.isNotEmpty) {
      return EngineFaults.getInjectorFaultDescription(
        injectorFaultModes,
      );
    }

    if (currentCoilFaultCode.isNotEmpty) {
      return EngineFaults.getCoilFaultDescription(
        coilFaultModes,
      );
    }

    return '';
  }

  String get currentFaultCause {
    // INJECTOR
    if (currentInjectorFaultCode.isNotEmpty) {
      return EngineFaults.getInjectorFaultCause(
        injectorFaultModes,
      );
    }

    if (currentCoilFaultCode.isNotEmpty) {
      return EngineFaults.getCoilFaultCause(
        coilFaultModes,
      );
    }

    if (currentSensorFaultCode.isNotEmpty) {
      return EngineFaults.getFaultCause(
        ckpFaultMode: ckpFaultMode,
        cmpFaultMode: cmpFaultMode,
        appFault: appFault,
        mapFault: mapFault,
        iatFault: iatFault,
        ectFault: ectFault,
        oilTempFault: oilTempFault,
        fuelPumpFault: fuelPumpFault,
      );
    }

    return '';
  }

  String get currentFaultSymptom {
    if (currentSensorFaultCode.isNotEmpty) {
      return EngineFaults.getFaultSymptom(
        ckpFaultMode: ckpFaultMode,
        ckpFault: ckpFault,
        cmpFaultMode: cmpFaultMode,
        cmpFault: cmpFault,
        appFault: appFault,
        mapFault: mapFault,
        iatFault: iatFault,
        ectFault: ectFault,
        oilTempFault: oilTempFault,
        fuelPumpFault: fuelPumpFault,
      );
    }

    if (currentInjectorFaultCode.isNotEmpty) {
      return EngineFaults.getInjectorFaultSymptom(
        injectorFaultModes,
      );
    }

    if (currentCoilFaultCode.isNotEmpty) {
      return EngineFaults.getCoilFaultSymptom(
        coilFaultModes,
      );
    }

    return '';
  }

  bool get hasAnyFault {
    return ckpFault ||
        cmpFault ||
        appFault ||
        iatFault ||
        mapFault ||
        ectFault ||
        oilTempFault ||
        fuelPumpFault ||
        injectorFaultModes.values.any((v) => v != 0) ||
        coilFaultModes.values.any((v) => v != 0);
  }

  bool cmpGlitchActive(bool isRunning) {

    if (!cmpFault || !isRunning) {
      return false;
    }

    final t =
        DateTime.now().millisecondsSinceEpoch ~/ 180;

    return t % 5 == 0;
  }

  Offset faultShakeOffset(bool isRunning) {

    if (!isRunning) {
      return Offset.zero;
    }

    final t =
        DateTime.now().millisecondsSinceEpoch / 1000.0;

    // P0336
    if (ckpFaultMode == 2) {
      return Offset(
        sin(t * 45) * 2.5,
        cos(t * 38) * 1.8,
      );
    }

    // P0337
    if (ckpFaultMode == 3) {
      return Offset(
        sin(t * 55) * 3.2,
        cos(t * 42) * 2.0,
      );
    }

    // P0338
    if (ckpFaultMode == 4) {
      return Offset(
        sin(t * 60) * 4.0,
        cos(t * 50) * 2.5,
      );
    }

    // P0339
    if (ckpFaultMode == 5) {
      return Offset(
        sin(t * 70) * 5.0,
        cos(t * 65) * 3.0,
      );
    }

    if (cmpFault) {
      return Offset(
        sin(t * 38) * 1.8,
        cos(t * 29) * 1.1,
      );
    }

    if (injectorFaultModes.values.any((v) => v != 0) ||
        coilFaultModes.values.any((v) => v != 0)) {

      return Offset(
        sin(t * 42) * 2.2,
        cos(t * 31) * 1.4,
      );
    }

    return Offset.zero;
  }
}