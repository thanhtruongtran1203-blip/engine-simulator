    import 'dart:math';
    
    import 'package:flutter/material.dart';
    
    import '../faults/engine_faults.dart';
  
    class FaultItem {
      final String code;
      final String label;
      final String description;
      final String cause;
      final String symptom;
  
      FaultItem({
        required this.code,
        required this.label,
        required this.description,
        required this.cause,
        required this.symptom,
      });
    }
    
    class FaultController {
    
      final Random _rand = Random();
    
      int ckpFaultMode = 0;
      int cmpFaultMode = 0;
    
      bool appFault = false;
      int mapFaultMode = 0;
      int iatFaultMode = 0;
      int ectFaultMode = 0;

      bool get mapFault => mapFaultMode != 0;

      bool get iatFault => iatFaultMode != 0;

      bool get ectFault => ectFaultMode != 0;
    
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
    
        if (ckpFaultMode > 2) {
          ckpFaultMode = 0;
        }
      }
    
      void toggleCMPFault() {
        cmpFaultMode++;
    
        if (cmpFaultMode > 1) {
          cmpFaultMode = 0;
        }
      }
    
      void toggleAPPFault() {
        appFault = !appFault;
      }

      void toggleMAPFault() {

        mapFaultMode++;

        if (mapFaultMode > 2) {

          mapFaultMode = 0;

        }

      }

      void toggleIATFault() {

        iatFaultMode++;

        if (iatFaultMode > 2) {

          iatFaultMode = 0;

        }

      }

      void toggleECTFault() {

        ectFaultMode++;

        if (ectFaultMode > 2) {

          ectFaultMode = 0;

        }

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

            mapFaultMode: mapFaultMode,
            iatFaultMode: iatFaultMode,
            ectFaultMode: ectFaultMode,

          );

      String get currentSensorFaultLabel =>
          EngineFaults.getSensorFaultLabel(
            ckpFault: ckpFault,
            cmpFault: cmpFault,
            appFault: appFault,

            mapFaultMode: mapFaultMode,
            iatFaultMode: iatFaultMode,
            ectFaultMode: ectFaultMode,
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

            mapFaultMode: mapFaultMode,
            iatFaultMode: iatFaultMode,
            ectFaultMode: ectFaultMode,
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

            mapFaultMode: mapFaultMode,
            iatFaultMode: iatFaultMode,
            ectFaultMode: ectFaultMode,
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

            mapFaultMode: mapFaultMode,
            iatFaultMode: iatFaultMode,
            ectFaultMode: ectFaultMode,
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
  
      List<FaultItem> get allFaults {
  
        final faults = <FaultItem>[];

        if (ckpFaultMode != 0) {

          faults.add(
            FaultItem(

              code: currentSensorFaultCode,

              label: currentSensorFaultLabel,

              description:
              EngineFaults.getSensorFaultDescription(

                ckpFault: true,

                cmpFault: false,

                appFault: false,

                mapFaultMode: 0,

                iatFaultMode: 0,

                ectFaultMode: 0,
              ),

              cause:
              EngineFaults.getFaultCause(

                ckpFaultMode: ckpFaultMode,

                cmpFaultMode: 0,

                appFault: false,

                mapFaultMode: 0,

                iatFaultMode: 0,

                ectFaultMode: 0,
              ),

              symptom:
              EngineFaults.getFaultSymptom(

                ckpFaultMode: ckpFaultMode,

                ckpFault: true,

                cmpFaultMode: 0,

                cmpFault: false,

                appFault: false,

                mapFaultMode: 0,

                iatFaultMode: 0,

                ectFaultMode: 0,
              ),
            ),
          );
        }

        if (cmpFaultMode != 0) {

          faults.add(
            FaultItem(
              code: EngineFaults.getSensorFaultCode(
                ckpFaultMode: 0,
                cmpFaultMode: cmpFaultMode,
                ckpFault: false,
                cmpFault: true,
                appFault: false,
                mapFaultMode: 0,
                iatFaultMode: 0,
                ectFaultMode: 0,
              ),

              label:

              EngineFaults.getSensorFaultLabel(

                ckpFault: false,

                cmpFault: true,

                appFault: false,

                mapFaultMode: 0,

                iatFaultMode: 0,

                ectFaultMode: 0,
              ),

              description:

              EngineFaults.getSensorFaultDescription(

                ckpFault: false,

                cmpFault: true,

                appFault: false,

                mapFaultMode: 0,

                iatFaultMode: 0,

                ectFaultMode: 0,
              ),
  
              cause: EngineFaults.getFaultCause(
                ckpFaultMode: 0,
                cmpFaultMode: cmpFaultMode,
                appFault: false,
                mapFaultMode: mapFaultMode,
                iatFaultMode: 0,
                ectFaultMode: 0,
              ),
  
              symptom: EngineFaults.getFaultSymptom(
                ckpFaultMode: 0,
                ckpFault: false,
                cmpFaultMode: cmpFaultMode,
                cmpFault: true,
                appFault: false,
                mapFaultMode: mapFaultMode,
                iatFaultMode: 0,
                ectFaultMode: 0,
              ),
            ),
          );
        }
        if (appFault) {
  
          faults.add(
            FaultItem(
              code: 'P2138',
              label: 'Lỗi cảm biến bàn đạp ga',
              description:
              'Tương quan điện áp cổng các cảm biến vị trí bàn đạp/bướm ga "D"/"E"',
              cause: EngineFaults.getFaultCause(
                ckpFaultMode: 0,
                cmpFaultMode: 0,
                appFault: true,
                mapFaultMode: mapFaultMode,
                iatFaultMode: 0,
                ectFaultMode: 0,
              ),
              symptom: EngineFaults.getFaultSymptom(
                ckpFaultMode: 0,
                ckpFault: false,
                cmpFaultMode: 0,
                cmpFault: false,
                appFault: true,
                mapFaultMode: mapFaultMode,
                iatFaultMode: 0,
                ectFaultMode: 0,
              ),
            ),
          );
        }
        if (mapFault) {

          faults.add(

            FaultItem(

              code:
              EngineFaults.getSensorFaultCode(

                ckpFaultMode: 0,
                cmpFaultMode: 0,

                ckpFault: false,
                cmpFault: false,

                appFault: false,

                mapFaultMode: mapFaultMode,
                iatFaultMode: 0,
                ectFaultMode: 0,
              ),

              label:
              'Lỗi cảm biến áp suất đường ống nạp (MAP)',

              description:
              EngineFaults.getSensorFaultDescription(

                ckpFault: false,
                cmpFault: false,

                appFault: false,

                mapFaultMode: mapFaultMode,
                iatFaultMode: 0,
                ectFaultMode: 0,
              ),

              cause:
              EngineFaults.getFaultCause(

                ckpFaultMode: 0,

                cmpFaultMode: 0,

                appFault: false,

                mapFaultMode: mapFaultMode,

                iatFaultMode: 0,

                ectFaultMode: 0,
              ),

              symptom:
              EngineFaults.getFaultSymptom(

                ckpFaultMode: 0,

                ckpFault: false,

                cmpFaultMode: 0,

                cmpFault: false,

                appFault: false,

                mapFaultMode: mapFaultMode,

                iatFaultMode: 0,

                ectFaultMode: 0,
              ),
            ),
          );
        }
        if (iatFault) {

          faults.add(

            FaultItem(

              code:
              EngineFaults.getSensorFaultCode(

                ckpFaultMode: 0,
                cmpFaultMode: 0,

                ckpFault: false,
                cmpFault: false,

                appFault: false,

                mapFaultMode: 0,
                iatFaultMode: iatFaultMode,
                ectFaultMode: 0,
              ),

              label:
              'Lỗi cảm biến nhiệt độ khí nạp',

              description:
              EngineFaults.getSensorFaultDescription(

                ckpFault: false,
                cmpFault: false,

                appFault: false,

                mapFaultMode: 0,
                iatFaultMode: iatFaultMode,
                ectFaultMode: 0,
              ),

              cause:
              EngineFaults.getFaultCause(

                ckpFaultMode: 0,

                cmpFaultMode: 0,

                appFault: false,

                mapFaultMode: 0,

                iatFaultMode: iatFaultMode,

                ectFaultMode: 0,
              ),

              symptom:
              EngineFaults.getFaultSymptom(

                ckpFaultMode: 0,

                ckpFault: false,

                cmpFaultMode: 0,

                cmpFault: false,

                appFault: false,

                mapFaultMode: 0,

                iatFaultMode: iatFaultMode,

                ectFaultMode: 0,
              ),
            ),
          );
        }
        if (ectFault) {

          faults.add(

            FaultItem(

              code:
              EngineFaults.getSensorFaultCode(

                ckpFaultMode: 0,
                cmpFaultMode: 0,

                ckpFault: false,
                cmpFault: false,

                appFault: false,

                mapFaultMode: 0,
                iatFaultMode: 0,
                ectFaultMode: ectFaultMode,
              ),

              label:
              'Lỗi cảm biến nhiệt độ nước làm mát',

              description:
              EngineFaults.getSensorFaultDescription(

                ckpFault: false,

                cmpFault: false,

                appFault: false,

                mapFaultMode: 0,

                iatFaultMode: 0,

                ectFaultMode: ectFaultMode,
              ),

              cause:

              EngineFaults.getFaultCause(

                ckpFaultMode: 0,

                cmpFaultMode: 0,

                appFault: false,

                mapFaultMode: 0,

                iatFaultMode: 0,

                ectFaultMode: ectFaultMode,
              ),

              symptom:

              EngineFaults.getFaultSymptom(

                ckpFaultMode: 0,

                ckpFault: false,

                cmpFaultMode: 0,

                cmpFault: false,

                appFault: false,

                mapFaultMode: 0,

                iatFaultMode: 0,

                ectFaultMode: ectFaultMode,
              ),
            ),
          );
        }
  
        for (final cyl in [1,2,3,4]) {
  
          final mode =
              injectorFaultModes[cyl] ?? 0;
  
          if (mode == 0) continue;
  
          final temp = {
            1:0,
            2:0,
            3:0,
            4:0,
          };
  
          temp[cyl] = mode;
  
          faults.add(
            FaultItem(
              code:
              EngineFaults.getInjectorFaultCode(temp),
  
              label:
              EngineFaults.getInjectorFaultLabel(temp),
  
              description:
              EngineFaults.getInjectorFaultDescription(temp),
  
              cause:
              EngineFaults.getInjectorFaultCause(temp),
  
              symptom:
              EngineFaults.getInjectorFaultSymptom(temp),
            ),
          );
        }
        for (final cyl in [1,2,3,4]) {
  
          final mode =
              coilFaultModes[cyl] ?? 0;
  
          if (mode == 0) continue;
  
          final temp = {
            1:0,
            2:0,
            3:0,
            4:0,
          };
  
          temp[cyl] = mode;
  
          faults.add(
            FaultItem(
              code:
              EngineFaults.getCoilFaultCode(temp),
  
              label:
              EngineFaults.getCoilFaultLabel(temp),
  
              description:
              EngineFaults.getCoilFaultDescription(temp),
  
              cause:
              EngineFaults.getCoilFaultCause(temp),
  
              symptom:
              EngineFaults.getCoilFaultSymptom(temp),
            ),
          );
        }
        return faults;
      }
    
      bool get hasAnyFault {
        return ckpFault ||
            cmpFault ||
            appFault ||
            iatFault ||
            mapFault ||
            ectFault ||
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