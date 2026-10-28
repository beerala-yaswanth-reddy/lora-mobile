import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../models/telemetry.dart';

/// Anchor A / Anchor B RSSI readout, mirroring the web dashboard's
/// AnchorPanel. A reading of exactly -127 dBm is the documented "missing"
/// sentinel and is shown as such rather than as a real signal value.
class AnchorRssiPanel extends StatelessWidget {
  const AnchorRssiPanel({super.key, required this.anchors});

  final List<AnchorReading> anchors;

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
            Text('Anchors', style: theme.typography.emphasized.titleMedium),
            const SizedBox(height: 8),
            M3ECardList(
              variant: M3ECardVariant.outlined,
              itemCount: anchors.length,
              itemBuilder: (context, index) {
                final anchor = anchors[index];
                return M3EListItem(
                  headline: anchor.label,
                  supportingText: anchor.isMissingSentinel
                      ? 'No signal (sentinel -127 dBm)'
                      : '${anchor.rssiDbm} dBm · ${anchor.distanceM.toStringAsFixed(1)} m',
                  leading: Icon(
                    _iconFor(anchor),
                    color: _colorFor(anchor, theme.colorScheme),
                  ),
                  trailing: M3EChip(
                    label: anchor.valid ? 'Valid' : 'Invalid',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AnchorReading anchor) {
    if (!anchor.valid) return Icons.wifi_off;
    if (anchor.rssiDbm > -60) return Icons.wifi;
    if (anchor.rssiDbm > -80) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }

  Color _colorFor(AnchorReading anchor, M3EColorScheme scheme) {
    return anchor.valid ? scheme.primary : scheme.error;
  }
}
