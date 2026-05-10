import 'package:flutter/material.dart';
import 'dart:math';

class ElectricPathPainter1 extends CustomPainter {
  final double progress;

  ElectricPathPainter1(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    /// DÂY
    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double startY = size.height - 10;
    double endX = size.width - 10;

    final path = Path()
      ..moveTo(0, startY)
      ..lineTo(endX, startY)
      ..lineTo(endX, 10);

    canvas.drawPath(path, linePaint);

    /// CHIỀU DÀI
    double horizontal = endX;
    double vertical = startY - 10;
    double totalLength = horizontal + vertical;

    int count = 5;
    double spacing = totalLength / count;

    for (int i = 0; i < count; i++) {
      double baseDistance = i * spacing;
      double distance = baseDistance + (progress * totalLength);
      distance %= totalLength;

      double x, y;

      if (distance < horizontal) {
        /// đoạn ngang
        x = distance;
        y = startY;
      } else {
        /// đoạn dọc
        double remain = distance - horizontal;
        x = endX;
        y = startY - remain;
      }

      /// ⚡ ZIGZAG (thay cho chấm)
      Path lightning = Path();
      lightning.moveTo(x, y);
      lightning.lineTo(x + 3, y - 2);
      lightning.lineTo(x - 3, y - 5);

      canvas.drawPath(
        lightning,
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ElectricPathPainter2 extends CustomPainter {
  final double progress;

  ElectricPathPainter2(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    /// STYLE DÂY
    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    /// VỊ TRÍ
    double startX = size.width / 2;
    double startY = size.height - 10;
    double endY = 10;

    /// VẼ DÂY
    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX, endY),
      linePaint,
    );

    /// CHIỀU DÀI
    double wireLength = (startY - endY).abs();

    /// SỐ TIA
    int count = 1;

    /// KHOẢNG CÁCH ĐỀU
    double spacing = wireLength / count;
    for (int i = 0; i < count; i++) {
      /// ⚡ vị trí gốc (cách đều)
      double base = i * spacing;

      /// ⚡ thêm animation
      double speed = 3.0; // tăng lên = chạy nhanh hơn
      double distance = base + (progress * wireLength * speed);

      /// loop lại
      distance %= wireLength;

      /// ⚡ vị trí Y (dưới → lên)
      double y = startY - distance;

      /// ⚡ TIA ĐIỆN
      Path lightning = Path();
      lightning.moveTo(startX, y);
      lightning.lineTo(startX + 2, y - 3);
      lightning.lineTo(startX - 2, y - 6);

      canvas.drawPath(
        lightning,
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ElectricPathPainter3 extends CustomPainter {
  final double progress;

  ElectricPathPainter3(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    /// STYLE DÂY
    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    /// VỊ TRÍ
    double startX = size.width / 2;
    double startY = size.height - 10;
    double endY = 10;

    /// VẼ DÂY
    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX, endY),
      linePaint,
    );

    /// CHIỀU DÀI
    double wireLength = (startY - endY).abs();

    /// 🔥 SỐ TIA
    int count = 1;

    /// 🔥 KHOẢNG CÁCH ĐỀU
    double spacing = wireLength / count;
    double speed = 4;
    for (int i = 0; i < count; i++) {
      /// vị trí gốc (cách đều)
      double base = i * spacing;

      /// thêm animation
      double speed = 4; // tăng lên = chạy nhanh hơn
      double distance = base + (progress * wireLength * speed);

      /// loop lại
      distance %= wireLength;

      /// vị trí Y (dưới → lên)
      double y = startY - distance;

      /// TIA ĐIỆN
      Path lightning = Path();
      lightning.moveTo(startX, y);
      lightning.lineTo(startX + 2, y - 3);
      lightning.lineTo(startX - 2, y - 6);

      canvas.drawPath(
        lightning,
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class ElectricPathPainter4 extends CustomPainter {
  final double progress;

  ElectricPathPainter4(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    double startX = 10;
    double endX = size.width - 10;
    double centerY = size.height / 2;

    canvas.drawLine(
      Offset(startX, centerY),
      Offset(endX, centerY),
      linePaint,
    );

    double wireLength = endX - startX;

    /// SỐ TIA
    int count = 7;

    /// KHOẢNG CÁCH ĐỀU
    double spacing = wireLength / count;

    for (int i = 0; i < count; i++) {
      /// ⚡ vị trí gốc (cách đều)
      double baseX = endX - (i * spacing);

      /// ⚡ thêm animation (dịch chuyển)
      double x = baseX - (progress * wireLength);

      /// loop lại khi ra khỏi màn
      if (x < startX) {
        x += wireLength;
      }

      double y = centerY;

      Path lightning = Path();
      lightning.moveTo(x, y);
      lightning.lineTo(x - 3, y - 2);
      lightning.lineTo(x - 6, y);

      canvas.drawPath(
        lightning,
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ElectricPathPainterCustom extends CustomPainter {
  final double progress;

  ElectricPathPainterCustom(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double centerX = size.width / 2;
    double topY = -11;
    double bottomY = size.height - 20;

    double horizontalTop = 172;
    double horizontalBottom = 10;

    /// PATH
    Path path = Path()
      ..moveTo(centerX, topY)
      ..lineTo(centerX + horizontalTop, topY)
      ..moveTo(centerX, topY)
      ..lineTo(centerX, bottomY)
      ..lineTo(centerX - horizontalBottom, bottomY);

    canvas.drawPath(path, linePaint);

    double vertical = bottomY - topY;
    double totalLength = horizontalBottom + vertical + horizontalTop;

    int count = 10;
    double spacing = totalLength / count;
    double speed = 1;

    for (int i = 0; i < count; i++) {
      double base = i * spacing;

      double distance =
          (base + progress * totalLength * speed) % totalLength;

      double x, y;

      if (distance < horizontalBottom) {
        x = centerX - horizontalBottom + distance;
        y = bottomY;

      } else if (distance < horizontalBottom + vertical) {
        double d = distance - horizontalBottom;
        x = centerX;
        y = bottomY - d;

      } else {
        double d = distance - (horizontalBottom + vertical);
        x = centerX + d;
        y = topY;
      }

      Path lightning = Path();
      lightning.moveTo(x, y);
      lightning.lineTo(x + 3, y - 2);
      lightning.lineTo(x + 6, y);

      canvas.drawPath(
        lightning,
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ElectricPathPainterCustom1 extends CustomPainter {
  final double progress;
  final double rpm;

  ElectricPathPainterCustom1(this.progress, this.rpm);

  @override
  void paint(Canvas canvas, Size size) {
    /// VẼ DÂY (GIỮ NGUYÊN)
    final linePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double centerX = size.width / 2;
    double topY = -34;
    double bottomY = size.height - 20;

    double horizontalTop = 185;
    double horizontalBottom = 0;

    Path path = Path()
      ..moveTo(centerX, topY)
      ..lineTo(centerX + horizontalTop, topY)
      ..moveTo(centerX, topY)
      ..lineTo(centerX, bottomY)
      ..lineTo(centerX - horizontalBottom, bottomY);

    canvas.drawPath(path, linePaint);

    /// TÍNH TOÁN ĐƯỜNG
    double vertical = bottomY - topY;
    double totalLength = horizontalBottom + vertical + horizontalTop;

    int count = 10;
    double spacing = totalLength / count;
    double t = ((rpm - 500) / (6000 - 500)).clamp(0, 1);
    double speed = 0.5 + t * 4; // 🔥 scale theo RPM

    /// STYLE NÉT ĐỨT
    double dash = 8;

    Paint dashPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      double base = i * spacing;

      double distance =
          (base + progress * totalLength * speed) % totalLength;

      double x, y;

      if (distance < horizontalBottom) {
        x = centerX - horizontalBottom + distance;
        y = bottomY;

        /// GIỚI HẠN KHÔNG VƯỢT endX
        double endX = (x + dash).clamp(
          centerX - horizontalBottom,
          centerX - horizontalBottom + horizontalBottom,
        );

        canvas.drawLine(
          Offset(x, y),
          Offset(endX, y),
          dashPaint,
        );

      } else if (distance < horizontalBottom + vertical) {
        /// 🔹 ĐOẠN DỌC
        double d = distance - horizontalBottom;
        x = centerX;
        y = bottomY - d;

        /// GIỚI HẠN KHÔNG VƯỢT topY
        double endY = (y - dash).clamp(topY, bottomY);

        canvas.drawLine(
          Offset(x, y),
          Offset(x, endY),
          dashPaint,
        );

      } else {
        /// 🔹 ĐOẠN NGANG TRÊN
        double d = distance - (horizontalBottom + vertical);
        x = centerX + d;
        y = topY;

        /// GIỚI HẠN KHÔNG VƯỢT cuối dây
        double endX = (x + dash).clamp(
          centerX,
          centerX + horizontalTop,
        );

        canvas.drawLine(
          Offset(x, y),
          Offset(endX, y),
          dashPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class ElectricPathPainterCustom2 extends CustomPainter {
  final double progress;
  final double rpm;

  ElectricPathPainterCustom2(this.progress, this.rpm);

  @override
  void paint(Canvas canvas, Size size) {
    /// STYLE DÂY (nền)
    final linePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double startX = 120;
    double startY = -32;

    double leftX = 0;
    double bottomY = size.height - 10;

    /// PATH chữ L
    final path = Path()
      ..moveTo(startX, startY)
      ..lineTo(leftX, startY)   // ←
      ..lineTo(leftX, bottomY); // ↓

    canvas.drawPath(path, linePaint);

    /// TÍNH ĐỘ DÀI
    double horizontal = startX - leftX;
    double vertical = bottomY - startY;
    double totalLength = horizontal + vertical;

    /// STYLE NÉT ĐỨT
    double dashLength = 10;
    double gap = 6;
    double t = ((rpm - 500) / (6000 - 500)).clamp(0, 1);
    double speed = 0.5 + t * 4; // 🔥 scale theo RPM
    final dashPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    /// OFFSET CHẠY
    double offset = (totalLength + (progress * totalLength)) % totalLength;

    /// VẼ NÉT ĐỨT CHẠY
    for (double d = 0; d < totalLength; d += dashLength + gap) {
      double distance = (d + offset) % totalLength;

      double x1, y1, x2, y2;

      if (distance < horizontal) {
        /// ← đoạn ngang
        x1 = startX - distance;
        y1 = startY;

        double next = (distance + dashLength).clamp(0, horizontal);
        x2 = startX - next;
        y2 = startY;
      } else {
        /// ↓ đoạn dọc
        double remain = distance - horizontal;

        x1 = leftX;
        y1 = startY + remain;

        double next = (remain + dashLength).clamp(0, vertical);
        x2 = leftX;
        y2 = startY + next;
      }

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class ElectricPathPainterCustom21 extends CustomPainter {
  final double progress;
  final double rpm;

  ElectricPathPainterCustom21(this.progress, this.rpm);

  @override
  void paint(Canvas canvas, Size size) {
    /// STYLE DÂY (nền)
    final linePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double startX = 0;
    double startY = -42;

    double leftX = 0;
    double bottomY = size.height - 10;

    /// PATH chữ L
    final path = Path()
      ..moveTo(startX, startY)
      ..lineTo(leftX, startY)   // ←
      ..lineTo(leftX, bottomY); // ↓

    canvas.drawPath(path, linePaint);

    /// TÍNH ĐỘ DÀI
    double horizontal = startX - leftX;
    double vertical = bottomY - startY;
    double totalLength = horizontal + vertical;

    /// STYLE NÉT ĐỨT
    double dashLength = 10;
    double gap = 6;
    double t = ((rpm - 500) / (6000 - 500)).clamp(0, 1);
    double speed = 0.5 + t * 4; // 🔥 scale theo RPM
    final dashPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    /// OFFSET CHẠY
    double offset = (totalLength + (progress * totalLength)) % totalLength;

    /// VẼ NÉT ĐỨT CHẠY
    for (double d = 0; d < totalLength; d += dashLength + gap) {
      double distance = (d + offset) % totalLength;

      double x1, y1, x2, y2;

      if (distance < horizontal) {
        /// ← đoạn ngang
        x1 = startX - distance;
        y1 = startY;

        double next = (distance + dashLength).clamp(0, horizontal);
        x2 = startX - next;
        y2 = startY;
      } else {
        /// ↓ đoạn dọc
        double remain = distance - horizontal;

        x1 = leftX;
        y1 = startY + remain;

        double next = (remain + dashLength).clamp(0, vertical);
        x2 = leftX;
        y2 = startY + next;
      }

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}