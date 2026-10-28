import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Top status strip: always-visible SIMULATION badge (this build never talks
/// to real hardware), a relative "last update" timestamp, and a play/pause
/// control for the mock telemetry feed.
class ModeStatusBar extends StatelessWidget {
  const ModeStatusBar({
    super.key,
    required this.lastUpdate,
    required this.isPaused,
    required this.onPausedChanged,
  });

  final DateTime? lastUpdate;
  final bool isPaused;
  final ValueChanged<bool> onPausedChanged;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final statusText = isPaused
        ? 'Simulation paused'
        : lastUpdate == null
            ? 'Waiting for telemetry…'
            : 'Updated ${DateTime.now().difference(lastUpdate!).inSeconds}s ago';

    return M3ECard(
      variant: M3ECardVariant.filled,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            M3EChip(
              label: 'SIMULATION',
              leading: const Icon(Icons.auto_awesome, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                statusText,
                style: theme.typography.baseline.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              isPaused ? 'Resume' : 'Pause',
              style: theme.typography.baseline.labelMedium,
            ),
            const SizedBox(width: 4),
            M3ESwitch(
              value: !isPaused,
              onChanged: (running) => onPausedChanged(!running),
            ),
          ],
        ),
      ),
    );
  }
}
