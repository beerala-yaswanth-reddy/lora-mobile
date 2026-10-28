import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../models/telemetry.dart';

/// Placeholder site for the mock indoor track. Replace with the building's
/// surveyed coordinates when this demo is connected to a real installation.
const LatLng demoBuildingLocation = LatLng(37.7749, -122.4194);

const double _mapZoom = 18.85;
const double _visualMetersPerLocalMeter = 4;
const Color _routeBlue = Color(0xFF1A73E8);
const Color _anchorCoral = Color(0xFFE56B55);

/// Converts the indoor corridor's local meter coordinates to the demo site.
LatLng _meterToLatLng(double xM, double yM) {
  final latitudeRadians = demoBuildingLocation.latitude * math.pi / 180;
  final latitude =
      demoBuildingLocation.latitude +
      (yM * _visualMetersPerLocalMeter) / 111320;
  final longitude =
      demoBuildingLocation.longitude +
      (xM * _visualMetersPerLocalMeter) / (111320 * math.cos(latitudeRadians));
  return LatLng(latitude, longitude);
}

/// Full-screen street map with an indoor route, anchor markers, and map tools.
class PositionMapCard extends StatefulWidget {
  const PositionMapCard({
    super.key,
    required this.position,
    required this.trail,
    required this.corridorLengthM,
  });

  final PositionEstimate position;
  final List<PositionEstimate> trail;
  final double corridorLengthM;

  @override
  State<PositionMapCard> createState() => PositionMapCardState();
}

class PositionMapCardState extends State<PositionMapCard> {
  final _mapController = MapController();
  bool _showIndoorTrack = true;

  void centerOnTracker() {
    _mapController.move(
      _meterToLatLng(widget.position.xM, widget.position.yM),
      _mapZoom,
    );
  }

  void centerOnAnchor(AnchorId anchor) {
    final xM = anchor == AnchorId.a ? 0.0 : widget.corridorLengthM;
    _mapController.move(_meterToLatLng(xM, 0), _mapZoom);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anchorA = _meterToLatLng(0, 0);
    final anchorB = _meterToLatLng(widget.corridorLengthM, 0);
    final trackerPoint = _meterToLatLng(widget.position.xM, widget.position.yM);
    final trailPoints = widget.trail
        .map((estimate) => _meterToLatLng(estimate.xM, estimate.yM))
        .toList(growable: false);

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: trackerPoint,
            initialZoom: _mapZoom,
            minZoom: 16,
            maxZoom: 19,
            backgroundColor: const Color(0xFFE9EEF3),
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            // Demonstration tiles; choose a production tile provider and
            // comply with its usage policy before shipping the app.
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.chetansrinivas.mobile_app',
              maxZoom: 19,
              maxNativeZoom: 19,
              keepBuffer: 3,
            ),
            if (_showIndoorTrack) ...[
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: [
                      _meterToLatLng(-1.3, -1.8),
                      _meterToLatLng(widget.corridorLengthM + 1.3, -1.8),
                      _meterToLatLng(widget.corridorLengthM + 1.3, 1.8),
                      _meterToLatLng(-1.3, 1.8),
                    ],
                    color: _routeBlue.withValues(alpha: 0.10),
                    borderColor: _routeBlue.withValues(alpha: 0.30),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: trackerPoint,
                    radius: 2.8,
                    useRadiusInMeter: true,
                    color: _routeBlue.withValues(alpha: 0.12),
                    borderColor: _routeBlue.withValues(alpha: 0.34),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [anchorA, anchorB],
                    strokeWidth: 7,
                    color: _routeBlue.withValues(alpha: 0.45),
                    borderColor: Colors.white,
                    borderStrokeWidth: 2,
                  ),
                  if (trailPoints.length > 1)
                    Polyline(
                      points: trailPoints,
                      strokeWidth: 4,
                      color: _routeBlue,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: anchorA,
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: _AnchorMarker(label: 'A', color: _anchorCoral),
                  ),
                  Marker(
                    point: anchorB,
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: _AnchorMarker(label: 'B', color: _anchorCoral),
                  ),
                  Marker(
                    point: trackerPoint,
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    child: const _TrackerMarker(),
                  ),
                ],
              ),
            ],
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              popupBorderRadius: BorderRadius.circular(16),
              popupBackgroundColor: Colors.white,
              popupInitialDisplayDuration: const Duration(seconds: 4),
              attributions: const [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 246,
          child: Column(
            children: [
              M3EIconButton(
                tooltip: _showIndoorTrack
                    ? 'Hide indoor route'
                    : 'Show indoor route',
                variant: _showIndoorTrack
                    ? M3EIconButtonVariant.filled
                    : M3EIconButtonVariant.tonal,
                icon: Icon(
                  _showIndoorTrack
                      ? Icons.layers_rounded
                      : Icons.layers_outlined,
                ),
                onPressed: () {
                  unawaited(Haptics.vibrate(HapticsType.selection));
                  setState(() => _showIndoorTrack = !_showIndoorTrack);
                },
              ),
              const SizedBox(height: 10),
              M3EIconButton(
                tooltip: 'Center on tracker',
                variant: M3EIconButtonVariant.tonal,
                icon: const Icon(Icons.my_location_rounded),
                onPressed: () {
                  unawaited(Haptics.vibrate(HapticsType.light));
                  centerOnTracker();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnchorMarker extends StatelessWidget {
  const _AnchorMarker({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TrackerMarker extends StatelessWidget {
  const _TrackerMarker();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Live tracker position',
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _routeBlue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x390B3A7A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: math.pi / 2,
          child: const Icon(
            Icons.navigation_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }
}
