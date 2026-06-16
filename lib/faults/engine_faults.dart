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

    required int mapFaultMode,
    required int iatFaultMode,
    required int ectFaultMode,

  }) {

    if (ckpFaultMode == 1) return 'P0335';
    if (ckpFaultMode == 2) return 'P0336';
    if (cmpFaultMode == 1) return 'P0340';
    if (appFault) return 'P2138';
    if (mapFaultMode == 1) return 'P0107';
    if (mapFaultMode == 2) return 'P0108';
    if (iatFaultMode == 1) return 'P0112';
    if (iatFaultMode == 2) return 'P0113';
    if (ectFaultMode == 1) return 'P0117';
    if (ectFaultMode == 2) return 'P0118';

    return '';
  }

  static String getSensorFaultLabel({

    required bool ckpFault,
    required bool cmpFault,

    required bool appFault,

    required int mapFaultMode,
    required int iatFaultMode,
    required int ectFaultMode,

  }) {

    if (ckpFault) {
      return 'Lỗi cảm biến vị trí trục khuỷu (CKP)';
    }

    if (cmpFault) {
      return 'Lỗi cảm biến vị trí trục cam (CMP)';
    }

    if (appFault) {
      return 'Lỗi cảm biến bàn đạp ga';
    }

    if (mapFaultMode == 1) {
      return 'Lỗi cảm biến MAP';
    }

    if (mapFaultMode == 2) {
      return 'Lỗi cảm biến MAP';
    }

    if (iatFaultMode == 1) {
      return 'Lỗi cảm biến nhiệt độ khí nạp';
    }

    if (iatFaultMode == 2) {
      return 'Lỗi cảm biến nhiệt độ khí nạp';
    }

    if (ectFaultMode == 1) {
      return 'Lỗi cảm biến nhiệt độ nước làm mát';
    }

    if (ectFaultMode == 2) {
      return 'Lỗi cảm biến nhiệt độ nước làm mát';
    }

    return '';
  }

  static String getSensorFaultDescription({
    required bool ckpFault,
    required bool cmpFault,
    required bool appFault,
    required int mapFaultMode,
    required int iatFaultMode,
    required int ectFaultMode,
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

    if (mapFaultMode == 1) {
      return 'Mạch áp suất tuyệt đối đường ống nạp thấp';
    }

    if (mapFaultMode == 2) {
      return 'Mạch áp suất tuyệt đối đường ống nạp cao';
    }

    if (iatFaultMode == 1) {
      return 'Mạch cảm biến nhiệt độ khí nạp 1 thấp';
    }

    if (iatFaultMode == 2) {
      return 'Mạch cảm biến nhiệt độ khí nạp 1 cao';
    }

    if (ectFaultMode == 1) {
      return 'Mạch cảm biến nhiệt độ nước làm mát động cơ 1 thấp';
    }

    if (ectFaultMode == 2) {
      return 'Mạch cảm biến nhiệt độ nước làm mát động cơ 1 cao';
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
    required int mapFaultMode,
    required int iatFaultMode,
    required int ectFaultMode,
  }) {

    if (ckpFaultMode == 1) {
      return 'Động cơ không khởi động hoặc chết máy';
    }

    if (ckpFaultMode == 2) {
      return 'RPM dao động, khó khởi động';
    }


    if (cmpFaultMode == 1) {
      return 'Khó khởi động, động cơ rung giật';
    }

    if (appFault) {
      return 'Động cơ giới hạn bướm ga';
    }

    if (mapFaultMode == 1 || mapFaultMode == 2) {
      return 'Động cơ giảm công suất';
    }

    if (iatFaultMode == 1) {
      return 'Động cơ hoạt động không ổn định';
    }

    if (iatFaultMode == 2) {
      return 'Động cơ hao nhiên liệu';
    }

    if (ectFaultMode == 1) {
      return 'Quạt làm mát hoạt động bất thường';
    }

    if (ectFaultMode == 2) {
      return 'Quạt làm mát hoạt động liên tục';
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
    required int mapFaultMode,
    required int iatFaultMode,
    required int ectFaultMode,
  }) {

    // CKP
    if (ckpFaultMode == 1) {
      return 'Đứt dây hoặc mất tín hiệu CKP';
    }

    if (ckpFaultMode == 2) {
      return 'Sai khoảng răng hoặc nhiễu tín hiệu CKP';
    }

    // CMP
    if (cmpFaultMode == 1) {
      return 'Mất tín hiệu CMP';
    }

    // APP
    if (appFault) {
      return 'Hai tín hiệu APP không tương quan';
    }

    // MAP
    if (mapFaultMode == 1) {
      return 'Điện áp đầu ra của mạch tín hiệu cảm biến MAP thấp hơn giá trị quy định trong thời gian quy định.';
    }

    if (mapFaultMode == 2) {
      return 'Điện áp đầu ra của mạch tín hiệu cảm biến MAP cao hơn giá trị quy định trong thời gian quy định.';
    }

// IAT
    if (iatFaultMode == 1) {
      return 'Điện áp đầu ra mạch tín hiệu cảm biến IAT thấp hơn 0,04 V trong 10 giây.';
    }

    if (iatFaultMode == 2) {
      return 'Điện áp đầu ra mạch tín hiệu cảm biến IAT cao hơn 4,9 V trong 10 giây';
    }

// ECT
    if (ectFaultMode == 1) {
      return 'Điện áp đầu ra mạch tín hiệu cảm biến ECT thấp hơn 0,02 V trong 5 giây';
    }

    if (ectFaultMode == 2) {
      return 'Điện áp đầu ra mạch tín hiệu cảm biến ECT cao hơn 4,9 V trong 5 giây';
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
        return 'Mạch sơ cấp bobin $cyl hở';
      }

      if (mode == 2) {
        return 'Mạch sơ cấp bobin $cyl thấp';
      }

      if (mode == 3) {
        return 'Mạch sơ cấp bobin $cyl cao';
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
