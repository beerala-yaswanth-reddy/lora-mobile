import 'dart:async';
import 'dart:math';

import '../models/telemetry.dart';

/// Simulated telemetry source standing in for the physical ESP32 tracker.
///
/// This app is UI-only: there is no serial/COM backend here. The service
/// generates plausible RSSI, IMU, and EKF-style readings for a tracker
/// walking the corridor between the two configured anchors, so the dashboard
/// widgets have something real to render and animate. The anchor layout
/// (A at 0m, B at 10m) matches the `config.json` anchor coordinates used by
/// the existing ES-project web dashboard.
class MockTelemetryService {
  MockTelemetryService({
    this.corridorLengthM = 10.0,
    this.tickInterval = const Duration(milliseconds: 500),
  });

  final double corridorLengthM;
  final Duration tickInterval;

  static const double _pathLossExponent = 2.5;
  static const double _txPowerDbm = -40;
  static const int _missingRssiSentinel = -127;

  final _random = Random();
  final _controller = StreamController<TelemetrySnapshot>.broadcast();
  final List<PositionEstimate> _trail = [];

  Timer? _timer;
  double _t = 0;
  bool _paused = false;

  Stream<TelemetrySnapshot> get stream => _controller.stream;
  bool get isPaused => _paused;

  void start() {
    _timer ??= Timer.periodic(tickInterval, (_) => _tick());
  }

  void pause() => _paused = true;

  void resume() => _paused = false;

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _controller.close();
  }

  void _tick() {
    if (_paused) return;
    _t += tickInterval.inMilliseconds / 1000.0;

    // Walk back and forth along the corridor with a gentle lateral wobble.
    final cyclePosition = (sin(_t * 0.25) + 1) / 2; // 0..1
    final x = cyclePosition * corridorLengthM;
    final y = sin(_t * 1.3) * 0.3;
    final dx = cos(_t * 0.25) * 0.25 * corridorLengthM * 0.25;
    final speed = dx.abs();

    final anchorA = _simulateAnchor(
      id: AnchorId.a,
      label: 'Anchor A',
      distance: sqrt(x * x + y * y),
    );
    final anchorB = _simulateAnchor(
      id: AnchorId.b,
      label: 'Anchor B',
      distance: sqrt(pow(x - corridorLengthM, 2) + y * y),
    );

    final anyAnchorValid = anchorA.valid || anchorB.valid;
    final position = PositionEstimate(
      xM: x,
      yM: y,
      valid: anyAnchorValid,
      speedMps: speed,
    );

    if (position.valid) {
      _trail.add(position);
      if (_trail.length > 60) _trail.removeAt(0);
    }

    final imu = ImuReading(
      accelX: _noise(0.15),
      accelY: _noise(0.15),
      accelZ: 9.81 + _noise(0.1),
      gyroX: _noise(0.05),
      gyroY: _noise(0.05),
      gyroZ: _noise(0.05),
    );

    final ekf = EkfStats(
      converged: _t > 2,
      updateRateHz: 1000 / tickInterval.inMilliseconds,
      positionUncertaintyM: anyAnchorValid ? 0.3 + _random.nextDouble() * 0.4 : 1.5 + _random.nextDouble(),
    );

    _controller.add(
      TelemetrySnapshot(
        deviceId: 'tracker-sim-01',
        timestamp: DateTime.now(),
        position: position,
        anchors: [anchorA, anchorB],
        imu: imu,
        ekf: ekf,
        trail: List.unmodifiable(_trail),
      ),
    );
  }

  AnchorReading _simulateAnchor({
    required AnchorId id,
    required String label,
    required double distance,
  }) {
    // Occasionally drop a reading to exercise the -127 "missing" sentinel,
    // matching the firmware/protocol convention from the ESP32 tracker.
    final dropped = _random.nextDouble() < 0.05;
    if (dropped) {
      return AnchorReading(
        id: id,
        label: label,
        rssiDbm: _missingRssiSentinel,
        distanceM: distance,
        valid: false,
      );
    }

    final rssi = (_txPowerDbm - 10 * _pathLossExponent * log(distance + 0.1) / ln10 + _noise(2)).round();
    return AnchorReading(
      id: id,
      label: label,
      rssiDbm: rssi,
      distanceM: distance,
      valid: rssi != _missingRssiSentinel,
    );
  }

  double _noise(double magnitude) => (_random.nextDouble() * 2 - 1) * magnitude;
}
