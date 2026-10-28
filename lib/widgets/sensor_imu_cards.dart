import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../models/telemetry.dart';

/// Accelerometer / gyroscope readout, mirroring the web dashboard's
/// SensorCards. Accelerometer values include gravity, as the MPU6050
/// reports it raw.
class SensorImuCards extends StatelessWidget {
  const SensorImuCards({super.key, required this.imu});

  final ImuReading imu;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);

    return M3ECard(
      variant: M3ECardVariant.outlined,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IMU (MPU6050)', style: theme.typography.emphasized.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Accelerometer includes gravity (~9.81 m/s² at rest)',
              style: theme.typography.baseline.bodySmall,
            ),
            const SizedBox(height: 12),
            _AxisRow(label: 'Accel', unit: 'm/s²', x: imu.accelX, y: imu.accelY, z: imu.accelZ),
            const SizedBox(height: 8),
            _AxisRow(label: 'Gyro', unit: 'rad/s', x: imu.gyroX, y: imu.gyroY, z: imu.gyroZ),
          ],
        ),
      ),
    );
  }
}

class _AxisRow extends StatelessWidget {
  const _AxisRow({
    required this.label,
    required this.unit,
    required this.x,
    required this.y,
    required this.z,
  });

  final String label;
  final String unit;
  final double x;
  final double y;
  final double z;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(label, style: theme.typography.baseline.labelLarge),
        ),
        Expanded(child: _AxisValue(name: 'X', value: x, unit: unit)),
        Expanded(child: _AxisValue(name: 'Y', value: y, unit: unit)),
        Expanded(child: _AxisValue(name: 'Z', value: z, unit: unit)),
      ],
    );
  }
}

class _AxisValue extends StatelessWidget {
  const _AxisValue({required this.name, required this.value, required this.unit});

  final String name;
  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: theme.typography.baseline.labelSmall),
        Text(
          value.toStringAsFixed(2),
          style: theme.typography.emphasized.bodyMedium,
        ),
      ],
    );
  }
}
