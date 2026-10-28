import 'dart:async';
import 'dart:math' as math;

import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mock_telemetry_service.dart';
import '../models/telemetry.dart';
import '../widgets/anchor_rssi_panel.dart';
import '../widgets/ekf_performance_panel.dart';
import '../widgets/mode_status_bar.dart';
import '../widgets/position_map_card.dart';
import '../widgets/sensor_imu_cards.dart';

/// The map-first companion for the indoor positioning demo.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _corridorLengthM = 10;

  final _service = MockTelemetryService();
  final _mapKey = GlobalKey<PositionMapCardState>();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  StreamSubscription<TelemetrySnapshot>? _telemetrySubscription;
  TelemetrySnapshot? _snapshot;
  bool _paused = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _telemetrySubscription = _service.stream.listen((snapshot) {
      if (mounted) setState(() => _snapshot = snapshot);
    });
    _service.start();
  }

  @override
  void dispose() {
    unawaited(_telemetrySubscription?.cancel());
    _service.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _setPaused(bool paused) async {
    if (_paused == paused) return;
    await Haptics.vibrate(HapticsType.selection);
    if (!mounted) return;
    setState(() => _paused = paused);
    paused ? _service.pause() : _service.resume();
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    unawaited(Haptics.vibrate(HapticsType.selection));
    setState(() => _selectedTab = index);
  }

  void _searchMap(String query) {
    final term = query.trim().toLowerCase();
    final map = _mapKey.currentState;
    if (term.isEmpty || map == null) return;

    unawaited(Haptics.vibrate(HapticsType.light));
    if (term.contains('anchor a')) {
      map.centerOnAnchor(AnchorId.a);
    } else if (term.contains('anchor b')) {
      map.centerOnAnchor(AnchorId.b);
    } else if (term.contains('tracker') || term.contains('device')) {
      map.centerOnTracker();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search for tracker, Anchor A, or Anchor B.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  Future<void> _openDirections() async {
    await Haptics.vibrate(HapticsType.light);
    try {
      await MapLauncher.directions(
        LocationCoords(
          demoBuildingLocation.latitude,
          demoBuildingLocation.longitude,
          title: 'Indoor tracker demo site',
        ),
        mode: TravelMode.walking,
      ).show();
    } on MapLaunchException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open a maps app: ${error.reason.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          PositionMapCard(
            key: _mapKey,
            position: snapshot.position,
            trail: snapshot.trail,
            corridorLengthM: _corridorLengthM,
          ),
          _buildMapHeader(context),
          DraggableScrollableSheet(
            initialChildSize: 0.27,
            minChildSize: 0.25,
            maxChildSize: 0.76,
            snap: true,
            snapSizes: const [0.27, 0.56, 0.76],
            builder: (context, scrollController) =>
                _buildTrackingSheet(context, snapshot, scrollController),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildMapHeader(BuildContext context) {
    final theme = M3ETheme.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.white,
                elevation: 5,
                shadowColor: const Color(0x330A2440),
                borderRadius: BorderRadius.circular(24),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _searchMap,
                  decoration: InputDecoration(
                    hintText: 'Search tracker or anchor',
                    hintStyle: const TextStyle(color: Color(0xFF738096)),
                    prefixIconColor: const Color(0xFF627084),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5EEFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.radar_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.white.withValues(alpha: 0.96),
                elevation: 1,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF19A675),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _paused ? 'Updates paused' : 'Live · 1 device',
                        style: theme.typography.emphasized.labelLarge.copyWith(
                          color: const Color(0xFF17263A),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          height: 16,
                          child: VerticalDivider(width: 1),
                        ),
                      ),
                      Text(
                        'Market Street',
                        style: theme.typography.baseline.labelLarge.copyWith(
                          color: const Color(0xFF506075),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingSheet(
    BuildContext context,
    TelemetrySnapshot snapshot,
    ScrollController scrollController,
  ) {
    final theme = M3ETheme.of(context);
    final distanceToAnchorB = (_corridorLengthM - snapshot.position.xM).abs();
    final estimatedSeconds =
        (distanceToAnchorB / math.max(snapshot.position.speedMps, 0.6)).round();

    return Material(
      color: const Color(0xFF102033),
      elevation: 14,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF8EA0B8),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedTab == 0
                          ? 'Anchor B ahead'
                          : _selectedTab == 1
                          ? 'Signal health'
                          : 'Motion sensors',
                      style: theme.typography.emphasized.titleLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _paused
                          ? 'Resume to receive new positions'
                          : 'Position updated just now',
                      style: theme.typography.baseline.bodyMedium.copyWith(
                        color: const Color(0xFFBFCBDA),
                      ),
                    ),
                  ],
                ),
              ),
              _LiveBadge(paused: _paused),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Metric(
                value: '${distanceToAnchorB.toStringAsFixed(1)} m',
                label: 'remaining',
              ),
              const SizedBox(width: 28),
              _Metric(
                value: _formatDuration(estimatedSeconds),
                label: 'estimated',
              ),
              const Spacer(),
              Material(
                color: const Color(0xFF243C5D),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: _paused ? 'Resume updates' : 'Pause updates',
                  color: Colors.white,
                  icon: Icon(
                    _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  ),
                  onPressed: () => _setPaused(!_paused),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _openDirections,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3478F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.directions_rounded, size: 20),
              label: const Text('Route to demo site'),
            ),
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFF2A3B50)),
          const SizedBox(height: 18),
          if (_selectedTab == 0) ...[
            _buildAnchorPreview(context, snapshot),
            const SizedBox(height: 14),
            ModeStatusBar(
              lastUpdate: snapshot.timestamp,
              isPaused: _paused,
              onPausedChanged: _setPaused,
            ),
            const SizedBox(height: 14),
            AnchorRssiPanel(anchors: snapshot.anchors),
            const SizedBox(height: 14),
            SensorImuCards(imu: snapshot.imu),
            const SizedBox(height: 14),
            EkfPerformancePanel(ekf: snapshot.ekf, position: snapshot.position),
          ] else if (_selectedTab == 1) ...[
            AnchorRssiPanel(anchors: snapshot.anchors),
            const SizedBox(height: 14),
            ModeStatusBar(
              lastUpdate: snapshot.timestamp,
              isPaused: _paused,
              onPausedChanged: _setPaused,
            ),
          ] else ...[
            SensorImuCards(imu: snapshot.imu),
            const SizedBox(height: 14),
            EkfPerformancePanel(ekf: snapshot.ekf, position: snapshot.position),
          ],
          const SizedBox(height: 18),
          const Text(
            'Map data © OpenStreetMap contributors',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8EA0B8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAnchorPreview(BuildContext context, TelemetrySnapshot snapshot) {
    final theme = M3ETheme.of(context);
    return Row(
      children: [
        for (final anchor in snapshot.anchors) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF182C45),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF304764)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: anchor.valid
                          ? const Color(0xFFFEDED8)
                          : const Color(0xFFFFDAD6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.router_rounded,
                      size: 17,
                      color: anchor.valid
                          ? const Color(0xFFE56B55)
                          : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anchor.label,
                          style: theme.typography.emphasized.labelLarge
                              .copyWith(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          anchor.valid ? '${anchor.rssiDbm} dBm' : 'No signal',
                          style: theme.typography.baseline.labelSmall.copyWith(
                            color: const Color(0xFFBFCBDA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (anchor != snapshot.anchors.last) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE4EAF2))),
          ),
          child: Row(
            children: [
              _BottomNavItem(
                label: 'Map',
                icon: Icons.map_outlined,
                selectedIcon: Icons.map_rounded,
                selected: _selectedTab == 0,
                onTap: () => _selectTab(0),
              ),
              _BottomNavItem(
                label: 'Signals',
                icon: Icons.router_outlined,
                selectedIcon: Icons.router_rounded,
                selected: _selectedTab == 1,
                onTap: () => _selectTab(1),
              ),
              _BottomNavItem(
                label: 'Sensors',
                icon: Icons.sensors_outlined,
                selectedIcon: Icons.sensors_rounded,
                selected: _selectedTab == 2,
                onTap: () => _selectTab(2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) =>
      seconds < 60 ? '$seconds sec' : '${(seconds / 60).ceil()} min';
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: M3ETheme.of(
          context,
        ).typography.emphasized.headlineSmall.copyWith(color: Colors.white),
      ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Color(0xFFBFCBDA))),
    ],
  );
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.paused});

  final bool paused;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFF182C45),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0xFF304764)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: paused ? const Color(0xFFBFCBDA) : const Color(0xFF27C28A),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          paused ? 'Paused' : 'Live',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE5EEFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 21,
                  color: selected
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF627084),
                ),
                if (selected) ...[
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF1A73E8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
