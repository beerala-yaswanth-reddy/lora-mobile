import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../models/telemetry.dart';

/// Filter convergence + performance diagnostics, mirroring the web
/// dashboard's EKFPanel / PerformancePanel.
class EkfPerformancePanel extends StatelessWidget {
  const EkfPerformancePanel({super.key, required this.ekf, required this.position});

  final EkfStats ekf;
  final PositionEstimate position;

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
            Row(
              children: [
                Text('Estimator', style: theme.typography.emphasized.titleMedium),
                const Spacer(),
                M3EChip(
                  label: ekf.converged ? 'Converged' : 'Initializing',
                  leading: Icon(
                    ekf.converged ? Icons.check_circle : Icons.hourglass_top,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Stat(label: 'Position', value: position.valid
                ? '${position.xM.toStringAsFixed(2)} m, ${position.yM.toStringAsFixed(2)} m'
                : 'Unavailable (geometry underdetermined)'),
            _Stat(label: 'Uncertainty', value: '±${ekf.positionUncertaintyM.toStringAsFixed(2)} m'),
            _Stat(label: 'Update rate', value: '${ekf.updateRateHz.toStringAsFixed(1)} Hz'),
            _Stat(label: 'Speed', value: '${position.speedMps.toStringAsFixed(2)} m/s'),
            if (!position.valid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Two RSSI anchors cannot uniquely fix 2D position; the corridor '
                  'constraint is reporting no valid estimate for this sample.',
                  style: theme.typography.baseline.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.typography.baseline.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: theme.typography.emphasized.bodyMedium),
          ),
        ],
      ),
    );
  }
}
