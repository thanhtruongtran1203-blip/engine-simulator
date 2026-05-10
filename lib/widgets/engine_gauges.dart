import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class RpmGauge extends StatelessWidget {
  final double rpm;

  const RpmGauge({
    super.key,
    required this.rpm,
  });

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 8,
          interval: 1,
          startAngle: 140,
          endAngle: 40,
          showAxisLine: false,
          minorTicksPerInterval: 4,
          majorTickStyle: const MajorTickStyle(
            length: 6,
            thickness: 1.1,
            color: Colors.white,
          ),
          labelOffset: -5,
          minorTickStyle: const MinorTickStyle(
            length: 3,
            thickness: 1,
            color: Colors.white54,
          ),
          axisLabelStyle: const GaugeTextStyle(
            color: Colors.white,
            fontSize: 4,
          ),
          ranges: [
            GaugeRange(
              startValue: 6,
              endValue: 8,
              color: Colors.red,
              startWidth: 5,
              endWidth: 5,
            ),
          ],
          pointers: [
            NeedlePointer(
              value: rpm / 1000,
              needleColor: Colors.red,
              needleStartWidth: 0.5,
              needleEndWidth: 2,
              needleLength: 0.6,
              knobStyle: const KnobStyle(
                color: Colors.white,
                knobRadius: 0.1,
              ),
            ),
          ],
          annotations: const [
            GaugeAnnotation(
              widget: Text(
                'RPMx1000',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 4,
                ),
              ),
              angle: 90,
              positionFactor: 0.9,
            ),
          ],
        ),
      ],
    );
  }
}

class SpeedGauge extends StatelessWidget {
  final double speed;

  const SpeedGauge({
    super.key,
    required this.speed,
  });

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 200,
          startAngle: 135,
          endAngle: 45,
          showAxisLine: false,
          interval: 20,
          minorTicksPerInterval: 4,
          majorTickStyle: const MajorTickStyle(
            length: 7,
            thickness: 1.1,
            color: Colors.white,
          ),
          labelOffset: -1,
          minorTickStyle: const MinorTickStyle(
            length: 3,
            thickness: 1,
            color: Colors.white54,
          ),
          axisLabelStyle: const GaugeTextStyle(
            color: Colors.white,
            fontSize: 6,
          ),
          ranges: [
            GaugeRange(
              startValue: 160,
              endValue: 200,
              color: Colors.red,
              startWidth: 5,
              endWidth: 5,
            ),
          ],
          pointers: [
            NeedlePointer(
              value: speed * 0.98,
              needleColor: Colors.red,
              needleStartWidth: 0.5,
              needleEndWidth: 4,
              needleLength: 0.7,
              knobStyle: const KnobStyle(color: Colors.white),
            ),
          ],
          annotations: const [
            GaugeAnnotation(
              widget: Text(
                'KM/H',
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
              angle: 90,
              positionFactor: 0.9,
            ),
          ],
        ),
      ],
    );
  }
}

class FuelGauge extends StatelessWidget {
  final double value;

  const FuelGauge({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final int level = (value / 20).round();

    return SizedBox(
      width: 70,
      height: 180,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 30,
              height: 170,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: List.generate(5, (index) {
                        final bool isActive = index < level;

                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 1),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : Colors.transparent,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        );
                      }).reversed.toList(),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return Container(
                        width: 8,
                        height: 2,
                        color: Colors.white,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 40,
            top: 0,
            child: Text(
              'F',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
          const Positioned(
            left: 40,
            bottom: 12,
            child: Text(
              'E',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
          const Positioned(
            left: 40,
            bottom: 85,
            child: Icon(
              Icons.local_gas_station,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
