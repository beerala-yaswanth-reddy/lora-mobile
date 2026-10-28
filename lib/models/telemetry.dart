/// Data models for the indoor-positioning telemetry shown on the dashboard.
///
/// These mirror the fields produced by the existing ES-project web dashboard
/// (anchors A/B RSSI, IMU accel/gyro, EKF-derived position + uncertainty) so
/// swapping the mock source for a real backend later only touches
/// [MockTelemetryService].
library;

enum AnchorId { a, b }

class AnchorReading {
  const AnchorReading({
    required this.id,
    required this.label,
    required this.rssiDbm,
    required this.distanceM,
    required this.valid,
  });

  final AnchorId id;
  final String label;

  /// Received signal strength in dBm. `-127` is the documented "missing
  /// reading" sentinel and is never treated as a real measurement.
  final int rssiDbm;
  final double distanceM;
  final bool valid;

  bool get isMissingSentinel => rssiDbm == -127;
}

class ImuReading {
  const ImuReading({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
  });

  /// Accelerometer axes in m/s^2. These include gravity (~9.81 on the
  /// vertical axis at rest), matching the raw MPU6050 output.
  final double accelX;
  final double accelY;
  final double accelZ;

  /// Gyroscope axes in rad/s.
  final double gyroX;
  final double gyroY;
  final double gyroZ;
}

class EkfStats {
  const EkfStats({
    required this.converged,
    required this.updateRateHz,
    required this.positionUncertaintyM,
  });

  final bool converged;
  final double updateRateHz;
  final double positionUncertaintyM;
}

class PositionEstimate {
  const PositionEstimate({
    required this.xM,
    required this.yM,
    required this.valid,
    required this.speedMps,
  });

  final double xM;
  final double yM;
  final bool valid;
  final double speedMps;
}

class TelemetrySnapshot {
  const TelemetrySnapshot({
    required this.deviceId,
    required this.timestamp,
    required this.position,
    required this.anchors,
    required this.imu,
    required this.ekf,
    required this.trail,
  });

  final String deviceId;
  final DateTime timestamp;
  final PositionEstimate position;
  final List<AnchorReading> anchors;
  final ImuReading imu;
  final EkfStats ekf;

  /// Recent breadcrumb of valid positions, oldest first.
  final List<PositionEstimate> trail;
}
