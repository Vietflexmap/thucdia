import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:flutter_map_pmtiles/flutter_map_pmtiles.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/map_config.dart';
import '../../data/app_state.dart';
import '../../data/enums.dart';
import '../../services/measurement_service.dart';
import '../waypoint/waypoint_list_screen.dart';
import 'track_list_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final MeasurementService _measurement = MeasurementService();
  final List<LatLng> _measurementPoints = [];
  MeasurementMode _measurementMode = MeasurementMode.none;
  LatLng? _lastFollowPoint;
  TileProvider? _offlineProvider;
  String? _offlinePath;
  bool _loadingOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().startGpsWatch();
    });
  }

  @override
  void dispose() {
    final provider = _offlineProvider;
    if (provider is MbTilesTileProvider) provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        _scheduleOfflineProvider(state);
        final position = state.currentPosition;
        final current = position == null ? null : LatLng(position.latitude, position.longitude);
        if (current != null && state.autoFollowGps && current != _lastFollowPoint) {
          _lastFollowPoint = current;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _mapController.move(current, _mapController.camera.zoom < 15 ? 17 : _mapController.camera.zoom);
          });
        }

        final trackPoints = state.activeTrack?.points
                .map((e) => LatLng(e.latitude, e.longitude))
                .toList() ??
            const <LatLng>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Vietflex Thực địa'),
            actions: [
              IconButton(
                tooltip: 'Waypoint',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WaypointListScreen()),
                ),
                icon: const Icon(Icons.place_outlined),
              ),
              IconButton(
                tooltip: 'Track đã lưu',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrackListScreen()),
                ),
                icon: const Icon(Icons.route_outlined),
              ),
              IconButton(
                tooltip: state.offlineBasemap == null ? 'Mở MBTiles/PMTiles' : 'Đổi MBTiles/PMTiles',
                onPressed: () async {
                  try {
                    final layer = await state.importOfflineBasemap();
                    if (layer != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã nạp offline: ${layer.name}')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) _showError(context, 'Không mở được bản đồ offline: $e');
                  }
                },
                icon: Icon(state.offlineBasemap == null ? Icons.offline_pin_outlined : Icons.offline_pin),
              ),
              PopupMenuButton<BasemapType>(
                tooltip: 'Bản đồ nền online',
                initialValue: state.basemap,
                onSelected: state.setBasemap,
                itemBuilder: (_) => BasemapType.values
                    .map((value) => PopupMenuItem(value: value, child: Text(_basemapLabel(value))))
                    .toList(),
                icon: const Icon(Icons.layers_outlined),
              ),
              IconButton(
                tooltip: state.autoFollowGps ? 'Tắt bám GPS' : 'Bám GPS',
                onPressed: () => state.setAutoFollowGps(!state.autoFollowGps),
                icon: Icon(state.autoFollowGps ? Icons.gps_fixed : Icons.gps_not_fixed),
              ),
            ],
          ),
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(MapConfig.defaultLatitude, MapConfig.defaultLongitude),
                  initialZoom: MapConfig.defaultZoom,
                  onTap: (_, point) => _handleMapTap(point),
                  onLongPress: (_, point) => _addWaypointAt(context, point),
                ),
                children: [
                  if (_offlineProvider != null)
                    TileLayer(tileProvider: _offlineProvider!)
                  else
                    TileLayer(
                      urlTemplate: MapConfig.basemapTemplates[state.basemap]!,
                      subdomains: MapConfig.subdomains[state.basemap]!,
                      userAgentPackageName: 'com.vietflexmap.thucdia',
                    ),
                  if (trackPoints.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(points: trackPoints, strokeWidth: 4, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  if (_measurementPoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _measurementPoints,
                          strokeWidth: 3,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      ...state.waypoints.map(
                        (w) => Marker(
                          point: LatLng(w.latitude, w.longitude),
                          width: 44,
                          height: 44,
                          child: Tooltip(
                            message: w.name,
                            child: const Icon(Icons.place, size: 38, color: Colors.redAccent),
                          ),
                        ),
                      ),
                      if (current != null)
                        Marker(
                          point: current,
                          width: 36,
                          height: 36,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
                            ),
                            child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: const [TextSourceAttribution('OpenStreetMap contributors')],
                  ),
                ],
              ),
              Positioned(top: 12, left: 12, right: 12, child: _statusCard(context, state)),
              if (_measurementMode != MeasurementMode.none)
                Positioned(bottom: 18, left: 18, right: 18, child: _measurementCard(context)),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'measure',
                tooltip: 'Đo đạc',
                onPressed: _cycleMeasurementMode,
                child: const Icon(Icons.straighten),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.small(
                heroTag: 'waypoint',
                tooltip: 'Thêm waypoint GPS',
                onPressed: () async {
                  try {
                    await state.addWaypointFromCurrentLocation();
                  } catch (e) {
                    if (context.mounted) _showError(context, e.toString());
                  }
                },
                child: const Icon(Icons.add_location_alt_outlined),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: 'track',
                onPressed: state.activeTrack == null ? state.startTrack : state.stopTrack,
                icon: Icon(state.activeTrack == null ? Icons.route_outlined : Icons.stop_circle_outlined),
                label: Text(state.activeTrack == null ? 'Ghi track' : 'Dừng track'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scheduleOfflineProvider(AppState state) {
    final layer = state.offlineBasemap;
    final desiredPath = layer?.source;
    if (_loadingOffline || desiredPath == _offlinePath) return;
    _loadingOffline = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final old = _offlineProvider;
        if (old is MbTilesTileProvider) old.dispose();
        TileProvider? next;
        if (layer != null) {
          next = switch (layer.sourceType) {
            LayerSourceType.mbtiles => MbTilesTileProvider.fromPath(path: layer.source),
            LayerSourceType.pmtiles => await PmTilesTileProvider.fromSource(layer.source),
            _ => null,
          };
        }
        if (!mounted) return;
        setState(() {
          _offlineProvider = next;
          _offlinePath = desiredPath;
        });
      } catch (e) {
        if (mounted) _showError(context, 'Bản đồ offline lỗi: $e');
      } finally {
        _loadingOffline = false;
      }
    });
  }

  Widget _statusCard(BuildContext context, AppState state) {
    final p = state.currentPosition;
    final accuracy = p == null ? '—' : '±${p.accuracy.toStringAsFixed(1)} m';
    final track = state.activeTrack;
    final trackText = track == null
        ? 'Chưa ghi track'
        : '${track.points.length} điểm · ${_measurement.formatDistance(track.totalDistanceMeters)}';
    return Card(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(p == null ? Icons.gps_off : Icons.gps_fixed, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('GPS $accuracy · $trackText', maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _measurementCard(BuildContext context) {
    String value = 'Chạm bản đồ để thêm đỉnh';
    if (_measurementMode == MeasurementMode.distance && _measurementPoints.length >= 2) {
      value = _measurement.formatDistance(_measurement.distanceMeters(_measurementPoints));
    } else if (_measurementMode == MeasurementMode.area && _measurementPoints.length >= 3) {
      value = _measurement.formatArea(_measurement.areaSquareMeters(_measurementPoints));
    } else if (_measurementMode == MeasurementMode.bearing && _measurementPoints.length >= 2) {
      value = '${_measurement.bearingDegrees(_measurementPoints[0], _measurementPoints[1]).toStringAsFixed(1)}°';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: Text('${_measurementMode.name}: $value')),
            TextButton(onPressed: _clearMeasurement, child: const Text('Xóa')),
          ],
        ),
      ),
    );
  }

  void _handleMapTap(LatLng point) {
    if (_measurementMode == MeasurementMode.none) return;
    setState(() {
      if (_measurementMode == MeasurementMode.bearing && _measurementPoints.length >= 2) {
        _measurementPoints.clear();
      }
      _measurementPoints.add(point);
    });
  }

  void _cycleMeasurementMode() {
    setState(() {
      _measurementPoints.clear();
      _measurementMode = switch (_measurementMode) {
        MeasurementMode.none => MeasurementMode.distance,
        MeasurementMode.distance => MeasurementMode.area,
        MeasurementMode.area => MeasurementMode.bearing,
        MeasurementMode.bearing => MeasurementMode.none,
      };
    });
  }

  void _clearMeasurement() => setState(() => _measurementPoints.clear());

  Future<void> _addWaypointAt(BuildContext context, LatLng point) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm waypoint'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Tên điểm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Lưu')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    await context.read<AppState>().addWaypoint(
          latitude: point.latitude,
          longitude: point.longitude,
          source: WaypointSource.mapTap,
          name: name.isEmpty ? null : name,
        );
  }

  String _basemapLabel(BasemapType type) => switch (type) {
        BasemapType.openStreetMap => 'OpenStreetMap',
        BasemapType.googleStreets => 'Google Streets',
        BasemapType.googleSatellite => 'Google Satellite',
        BasemapType.googleHybrid => 'Google Hybrid',
      };

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
