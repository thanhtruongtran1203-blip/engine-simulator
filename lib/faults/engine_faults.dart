class EngineFaults {

// =========================
// SENSOR FAULTS
// =========================

  static String getSensorFaultCode({
    required int ckpFaultMode,
    required int cmpFaultMode,
    required bool ckpFault,
    required bool cmpFault,
    required bool appFault,
    required bool mapFault,
    required bool iatFault,
    required bool ectFault,
    required bool oilTempFault,
    required bool fuelPumpFault,
  }) {

    if (ckpFaultMode == 1) return 'P0335';
    if (ckpFaultMode == 2) return 'P0336';
    if (ckpFaultMode == 3) return 'P0337';
    if (ckpFaultMode == 4) return 'P0338';
    if (ckpFaultMode == 5) return 'P0339';
    if (cmpFaultMode == 1) return 'P0340';
    if (cmpFaultMode == 2) return 'P0341';
    if (cmpFaultMode == 3) return 'P0342';
    if (cmpFaultMode == 4) return 'P0344';
    if (appFault) return 'P2138';
    if (mapFault) return 'P0097';
    if (iatFault) return 'P0113';
    if (ectFault) return 'P0118';
    if (oilTempFault) return 'P0195';
    if (fuelPumpFault) return 'P0230';

    return '';
  }

  static String getSensorFaultLabel({
    required bool ckpFault,
    required bool cmpFault,
    required bool appFault,
    required bool mapFault,
    required bool iatFault,
    required bool ectFault,
    required bool oilTempFault,
    required bool fuelPumpFault,
  }) {

    if (ckpFault) {
      return 'Lỗi cảm biến CKP';
    }

    if (cmpFault) {
      return 'Lỗi cảm biến CMP';
    }

    if (appFault) {
      return 'Lỗi cảm biến bàn đạp ga';
    }

    if (mapFault) {
      return 'Lỗi cảm biến MAP';
    }

    if (iatFault) {
      return 'Lỗi cảm biến nhiệt độ khí nạp';
    }

    if (ectFault) {
      return 'Lỗi cảm biến nhiệt độ nước làm mát';
    }

    if (oilTempFault) {
      return 'Lỗi cảm biến nhiệt độ dầu';
    }

    if (fuelPumpFault) {
      return 'Lỗi bơm nhiên liệu';
    }

    return '';
  }

  static String getSensorFaultDescription({
    required bool ckpFault,
    required bool cmpFault,
    required bool appFault,
    required bool mapFault,
    required bool iatFault,
    required bool ectFault,
    required bool oilTempFault,
    required bool fuelPumpFault,
  }) {

    if (ckpFault) {
      return 'Mạch cảm biến vị trí trục khuỷu';
    }

    if (cmpFault) {
      return 'Mạch cảm biến vị trí trục cam';
    }

    if (appFault) {
      return 'Tương quan cảm biến vị trí bàn đạp ga';
    }

    if (mapFault) {
      return 'Tín hiệu cảm biến áp suất đường ống nạp thấp';
    }

    if (iatFault) {
      return 'Tín hiệu cảm biến nhiệt độ khí nạp cao';
    }

    if (ectFault) {
      return 'Tín hiệu cảm biến nhiệt độ nước làm mát cao';
    }

    if (oilTempFault) {
      return 'Mạch cảm biến nhiệt độ dầu động cơ';
    }

    if (fuelPumpFault) {
      return 'Mạch điều khiển sơ cấp bơm nhiên liệu';
    }

    return '';
  }

// =========================
// SENSOR SYMPTOMS
// =========================

  static String getFaultSymptom({
    required int ckpFaultMode,
    required bool ckpFault,
    required int cmpFaultMode,
    required bool cmpFault,
    required bool appFault,
    required bool mapFault,
    required bool iatFault,
    required bool ectFault,
    required bool oilTempFault,
    required bool fuelPumpFault,
  }) {

    if (ckpFaultMode == 1) {
      return 'Động cơ chết máy, mất tín hiệu CKP';
    }

    if (ckpFaultMode == 2) {
      return 'RPM dao động, khó khởi động';
    }

    if (ckpFaultMode == 3) {
      return 'Tín hiệu CKP yếu, khó nổ';
    }

    if (ckpFaultMode == 4) {
      return 'RPM tăng bất thường, đánh lửa sai';
    }

    if (ckpFaultMode == 5) {
      return 'Động cơ rung giật ngẫu nhiên';
    }


    if (cmpFaultMode == 1) {
      return 'Động cơ rung nhẹ, sai đồng bộ CMP';
    }

    if (cmpFaultMode == 2) {
      return 'Đánh lửa sai thời điểm nhẹ';
    }

    if (cmpFaultMode == 3) {
      return 'Tín hiệu CMP yếu, hụt ga';
    }

    if (cmpFaultMode == 4) {
      return 'Động cơ rung giật ngẫu nhiên';
    }

    if (appFault) {
      return 'Động cơ giới hạn bướm ga';
    }

    if (mapFault) {
      return 'Động cơ giảm công suất';
    }

    if (iatFault) {
      return 'Động cơ hao nhiên liệu';
    }

    if (ectFault) {
      return 'Quạt làm mát hoạt động liên tục';
    }

    if (oilTempFault) {
      return 'Hiển thị nhiệt độ dầu bất thường';
    }

    if (fuelPumpFault) {
      return 'Động cơ hụt ga hoặc chết máy';
    }

    return '';
  }

  // =========================
// SENSOR CAUSES
// =========================

  static String getFaultCause({
    required int ckpFaultMode,
    required int cmpFaultMode,
    required bool appFault,
    required bool mapFault,
    required bool iatFault,
    required bool ectFault,
    required bool oilTempFault,
    required bool fuelPumpFault,
  }) {

    // CKP
    if (ckpFaultMode == 1) {
      return 'Đứt dây hoặc mất tín hiệu CKP';
    }

    if (ckpFaultMode == 2) {
      return 'Sai khoảng răng hoặc nhiễu tín hiệu CKP';
    }

    if (ckpFaultMode == 3) {
      return 'Điện áp CKP thấp';
    }

    if (ckpFaultMode == 4) {
      return 'Điện áp CKP cao';
    }

    if (ckpFaultMode == 5) {
      return 'Tín hiệu CKP chập chờn';
    }

    // CMP
    if (cmpFaultMode == 1) {
      return 'Mất tín hiệu CMP';
    }

    if (cmpFaultMode == 2) {
      return 'Sai đồng bộ CMP';
    }

    if (cmpFaultMode == 3) {
      return 'Điện áp CMP thấp';
    }

    if (cmpFaultMode == 4) {
      return 'Tín hiệu CMP không ổn định';
    }

    // APP
    if (appFault) {
      return 'Hai tín hiệu APP không tương quan';
    }

    // MAP
    if (mapFault) {
      return 'Điện áp MAP thấp';
    }

    // IAT
    if (iatFault) {
      return 'Điện áp cảm biến IAT cao';
    }

    // ECT
    if (ectFault) {
      return 'Điện áp ECT cao';
    }

    // Oil temp
    if (oilTempFault) {
      return 'Lỗi mạch cảm biến nhiệt độ dầu';
    }

    // Fuel pump
    if (fuelPumpFault) {
      return 'Mất điều khiển bơm nhiên liệu';
    }

    return '';
  }

// =========================
// INJECTOR FAULTS
// =========================

  static String getInjectorFaultCode(
      Map<int, int> injectorFaultModes,
      ) {

    for (final cyl in [1,2,3,4]) {

      final mode =
          injectorFaultModes[cyl] ?? 0;

      // OPEN
      if (mode == 1) {
        return 'P020$cyl';
      }

      // LOW
      if (mode == 2) {

        const lowCodes = {
          1: 'P0261',
          2: 'P0264',
          3: 'P0267',
          4: 'P0270',
        };

        return lowCodes[cyl]!;
      }

      // HIGH
      if (mode == 3) {

        const highCodes = {
          1: 'P0262',
          2: 'P0265',
          3: 'P0268',
          4: 'P0271',
        };

        return highCodes[cyl]!;
      }
    }

    return '';
  }

  static String getInjectorFaultLabel(
      Map<int, int> injectorFaultModes,
      ) {

    for (final cyl in [1,2,3,4]) {

      final mode =
          injectorFaultModes[cyl] ?? 0;

      if (mode == 1) {
        return 'Hở mạch kim phun $cyl';
      }

      if (mode == 2) {
        return 'Kim phun $cyl tín hiệu thấp';
      }

      if (mode == 3) {
        return 'Kim phun $cyl tín hiệu cao';
      }
    }

    return '';
  }

  static String getInjectorFaultDescription(
      Map<int, int> injectorFaultModes,
      ) {

    for (final cyl in [1,2,3,4]) {

      final mode =
          injectorFaultModes[cyl] ?? 0;

      if (mode == 1) {
        return 'Mạch kim phun xy-lanh $cyl hở';
      }

      if (mode == 2) {
        return 'Điều khiển kim phun $cyl thấp';
      }

      if (mode == 3) {
        return 'Điều khiển kim phun $cyl cao';
      }
    }

    return '';
  }

  static String getInjectorFaultSymptom(
      Map<int, int> injectorFaultModes,
      ) {

    for (final cyl in [1,2,3,4]) {

      final mode =
          injectorFaultModes[cyl] ?? 0;

      if (mode == 1) {
        return 'Động cơ rung mạnh, bỏ máy';
      }

      if (mode == 2) {
        return 'Động cơ rung nhẹ, thiếu nhiên liệu';
      }

      if (mode == 3) {
        return 'Động cơ hao nhiên liệu, xăng đậm';
      }
    }

    return '';
  }

  static String getInjectorFaultCause(
      Map<int, int> injectorFaultModes,
      ) {

    for (final cyl in [1,2,3,4]) {

      final mode =
          injectorFaultModes[cyl] ?? 0;

      if (mode == 1) {
        return 'Đứt dây hoặc hở mạch kim phun $cyl';
      }

      if (mode == 2) {
        return 'Kim phun $cyl chạm mass';
      }

      if (mode == 3) {
        return 'Kim phun $cyl chạm nguồn';
      }
    }

    return '';
  }
// =========================
// IGNITION COIL FAULTS
// =========================

  static String getCoilFaultCode(
      Map<int, int> coilFaultModes,
      ) {

    for (final cyl in [1,2,3,4]) {

      final mode =
          coilFaultModes[cyl] ?? 0;

      // P035x
      if (mode == 1) {
        return 'P035$cyl';
      }

      // LOW
      if (mode == 2) {

        const lowCodes = {
          1: 'P2300',
          2: 'P2303',
          3: 'P2306',
          4: 'P2309',
        };

        return lowCodes[cyl]!;
      }

      // HIGH
      if (mode == 3) {

        const highCodes = {
          1: 'P2301',
          2: 'P2304',
          3: 'P2307',
          4: 'P2310',
        };

        return highCodes[cyl]!;
      }
    }

    return '';
  }

  static String getCoilFaultLabel(
      Map<int, int> coilFaultModes,
      ) {

    for (final cyl in [1,2,3,4]) {

      final mode =
          coilFaultModes[cyl] ?? 0;

      if (mode == 1) {
        return 'Hở mạch bobin $cyl';
      }

      if (mode == 2) {
        return 'Bobin $cyl tín hiệu thấp';
      }

      if (mode == 3) {
        return 'Bobin $cyl tín hiệu cao';
      }
    }

    return '';
  }

  static String getCoilFaultDescription(
      Map<int, int> coilFaultModes,
      ) {

    for (final cyl in [1,2,3,4]) {

      final mode =
          coilFaultModes[cyl] ?? 0;

      if (mode == 1) {
        return 'Mạch sơ cấp bobin $cyl hở';
      }

      if (mode == 2) {
        return 'Điều khiển bobin $cyl thấp';
      }

      if (mode == 3) {
        return 'Điều khiển bobin $cyl cao';
      }
    }

    return '';
  }

  static String getCoilFaultSymptom(
      Map<int, int> coilFaultModes,
      ) {

    for (final cyl in [1,2,3,4]) {

      final mode =
          coilFaultModes[cyl] ?? 0;

      if (mode == 1) {
        return 'Mất đánh lửa máy $cyl';
      }

      if (mode == 2) {
        return 'Động cơ rung nhẹ, đánh lửa yếu';
      }

      if (mode == 3) {
        return 'Động cơ giật nhẹ, RPM dao động';
      }
    }

    return '';
  }
  static String getCoilFaultCause(
      Map<int, int> coilFaultModes,
      ) {

    for (final cyl in [1,2,3,4]) {

      final mode =
          coilFaultModes[cyl] ?? 0;

      // P035x
      if (mode == 1) {
        return 'Đứt dây hoặc hở mạch bobin $cyl';
      }

      // P230x LOW
      if (mode == 2) {
        return 'Bobin $cyl chạm mass hoặc tín hiệu yếu';
      }

      // P230x HIGH
      if (mode == 3) {
        return 'Bobin $cyl chạm nguồn hoặc nhiễu điện';
      }
    }

    return '';
  }
}
