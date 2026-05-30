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
if (ckpFaultMode == 2) return 'P0337';
if (ckpFaultMode == 3) return 'P0338';
if (ckpFaultMode == 4) return 'P0339';
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
  return 'RPM tăng bất thường, đánh lửa sai';
}

if (ckpFaultMode == 4) {
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
// INJECTOR FAULTS
// =========================

static String getInjectorFaultCode(
Map<int, bool> injectorFaults,
) {

if (injectorFaults[1] == true) return 'P0201';
if (injectorFaults[2] == true) return 'P0202';
if (injectorFaults[3] == true) return 'P0203';
if (injectorFaults[4] == true) return 'P0204';

return '';
}

static String getInjectorFaultLabel(
Map<int, bool> injectorFaults,
) {

if (injectorFaults[1] == true) {
return 'Lỗi kim phun 1';
}

if (injectorFaults[2] == true) {
return 'Lỗi kim phun 2';
}

if (injectorFaults[3] == true) {
return 'Lỗi kim phun 3';
}

if (injectorFaults[4] == true) {
return 'Lỗi kim phun 4';
}

return '';
}

static String getInjectorFaultDescription(
Map<int, bool> injectorFaults,
) {

if (injectorFaults[1] == true) {
return 'Mạch kim phun nhiên liệu xy-lanh 1';
}

if (injectorFaults[2] == true) {
return 'Mạch kim phun nhiên liệu xy-lanh 2';
}

if (injectorFaults[3] == true) {
return 'Mạch kim phun nhiên liệu xy-lanh 3';
}

if (injectorFaults[4] == true) {
return 'Mạch kim phun nhiên liệu xy-lanh 4';
}

return '';
}
  static String getInjectorFaultSymptom(
      Map<int, bool> injectorFaults,
      ) {

    if (injectorFaults[1] == true) {
      return 'Động cơ rung, bỏ máy xy-lanh 1';
    }

    if (injectorFaults[2] == true) {
      return 'Động cơ rung, bỏ máy xy-lanh 2';
    }

    if (injectorFaults[3] == true) {
      return 'Động cơ rung, bỏ máy xy-lanh 3';
    }

    if (injectorFaults[4] == true) {
      return 'Động cơ rung, bỏ máy xy-lanh 4';
    }

    return '';
  }
// =========================
// IGNITION COIL FAULTS
// =========================

static String getCoilFaultCode(
Map<int, bool> coilFaults,
) {

if (coilFaults[1] == true) return 'P0351';
if (coilFaults[2] == true) return 'P0352';
if (coilFaults[3] == true) return 'P0353';
if (coilFaults[4] == true) return 'P0354';

return '';
}

static String getCoilFaultLabel(
Map<int, bool> coilFaults,
) {

if (coilFaults[1] == true) {
return 'Lỗi bob-bin đánh lửa 1';
}

if (coilFaults[2] == true) {
return 'Lỗi bob-bin đánh lửa 2';
}

if (coilFaults[3] == true) {
return 'Lỗi bob-bin đánh lửa 3';
}

if (coilFaults[4] == true) {
return 'Lỗi bob-bin đánh lửa 4';
}

return '';
}

static String getCoilFaultDescription(
Map<int, bool> coilFaults,
) {

if (coilFaults[1] == true) {
return 'Mạch sơ cấp cuộn bô bin 1';
}

if (coilFaults[2] == true) {
return 'Mạch sơ cấp cuộn bô bin 2';
}

if (coilFaults[3] == true) {
return 'Mạch sơ cấp cuộn bô bin 3';
}

if (coilFaults[4] == true) {
return 'Mạch sơ cấp cuộn bô bin 4';
}

return '';
}

  static String getCoilFaultSymptom(
      Map<int, bool> coilFaults,
      ) {

    if (coilFaults[1] == true) {
      return 'Động cơ rung mạnh, mất đánh lửa máy 1';
    }

    if (coilFaults[2] == true) {
      return 'Động cơ rung mạnh, mất đánh lửa máy 2';
    }

    if (coilFaults[3] == true) {
      return 'Động cơ rung mạnh, mất đánh lửa máy 3';
    }

    if (coilFaults[4] == true) {
      return 'Động cơ rung mạnh, mất đánh lửa máy 4';
    }

    return '';
  }
}
