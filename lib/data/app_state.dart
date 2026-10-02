import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../services/exchange_service.dart';
import '../services/location_service.dart';
import '../services/offline_map_catalog_service.dart';
import '../services/photo_service.dart';
import '../services/storage_service.dart';
import '../services/track_service.dart';
import 'enums.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  AppState() {
    trackService = TrackService(storage, location);
    photoService = PhotoService(storage, location);
  }

  final storage = StorageService();
  final location = LocationService();
  final exchange = ExchangeService();
  final offlineMaps = OfflineMapCatalogService();
  late final TrackService trackService;
  late final PhotoService photoService;
  final Uuid _uuid = const Uuid();

  List<WaypointModel> waypoints = [];
  List<GpsTrackModel> tracks = [];
  List<FieldPhoto> photos = [];
  Position? currentPosition;
  GpsTrackModel? activeTrack;
  BasemapType basemap = BasemapType.openStreetMap;
  CoordinateMode coordinateMode = CoordinateMode.wgs84;
  bool autoFollowGps = true;
  double gpsAccuracyThreshold = 25;
  double centralMeridian = 105.75;
  MapLayerModel? offlineBasemap;
  bool initialized = false;

  StreamSubscription<Position>? _positionSubscription;

  Future<void> initialize() async {
    if (initialized) return;
    final prefs = await SharedPreferences.getInstance();
    gpsAccuracyThreshold = prefs.getDouble('gps_accuracy_threshold') ?? 25;
    centralMeridian = prefs.getDouble('central_meridian') ?? 105.75;
    final basemapName = prefs.getString('basemap');
    if (basemapName != null) {
      basemap = BasemapType.values.where((e) => e.name == basemapName).firstOrNull ?? basemap;
    }
    final offlinePath = prefs.getString('offline_basemap_path');
    final offlineType = prefs.getString('offline_basemap_type');
    final offlineName = prefs.getString('offline_basemap_name');
    if (offlinePath != null && offlineType != null) {
      final type = LayerSourceType.values.where((e) => e.name == offlineType).firstOrNull;
      if (type != null) {
        offlineBasemap = MapLayerModel(
          id: 'offline-basemap',
          name: offlineName ?? 'Offline map',
          sourceType: type,
          source: offlinePath,
        );
      }
    }
    waypoints = await storage.loadWaypoints();
    tracks = await storage.loadTracks();
    photos = await storage.loadPhotos();
    initialized = true;
    notifyListeners();
  }

  Future<void> startGpsWatch() async {
    if (!await location.ensureReady()) return;
    await _positionSubscription?.cancel();
    _positionSubscription = location.positionStream(distanceFilter: 1).listen((position) {
      currentPosition = position;
      notifyListeners();
    });
  }

  Future<WaypointModel> addWaypointFromCurrentLocation({String? name}) async {
    final position = currentPosition ?? await location.getCurrentPosition();
    return addWaypoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      source: WaypointSource.gps,
      name: name,
    );
  }

  Future<WaypointModel> addWaypoint({
    required double latitude,
    required double longitude,
    double? altitude,
    double? accuracy,
    required WaypointSource source,
    String? name,
  }) async {
    final waypoint = WaypointModel(
      id: _uuid.v4(),
      name: name ?? 'WP ${waypoints.length + 1}',
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      accuracy: accuracy,
      createdAt: DateTime.now(),
      source: source,
    );
    await storage.saveWaypoint(waypoint);
    waypoints = [waypoint, ...waypoints];
    notifyListeners();
    return waypoint;
  }

  Future<void> startTrack() async {
    if (activeTrack != null) return;
    activeTrack = await trackService.start(
      maxAccuracyMeters: gpsAccuracyThreshold,
      onChanged: (track) {
        activeTrack = track;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  Future<void> stopTrack() async {
    final completed = await trackService.stop(onChanged: (track) {
      activeTrack = track;
      notifyListeners();
    });
    if (completed != null) {
      tracks = [completed, ...tracks.where((e) => e.id != completed.id)];
    }
    activeTrack = null;
    notifyListeners();
  }

  Future<FieldPhoto?> capturePhoto() async {
    final photo = await photoService.capture();
    if (photo != null) {
      photos = [photo, ...photos];
      notifyListeners();
    }
    return photo;
  }


  Future<int> importWaypoints() async {
    final imported = await exchange.importWaypoints();
    for (final waypoint in imported) {
      await storage.saveWaypoint(waypoint);
    }
    if (imported.isNotEmpty) {
      final ids = imported.map((e) => e.id).toSet();
      waypoints = [...imported, ...waypoints.where((e) => !ids.contains(e.id))];
      notifyListeners();
    }
    return imported.length;
  }

  Future<String> exportWaypoints() => exchange.exportWaypointsGeoJson(waypoints);

  Future<String> exportTrack(GpsTrackModel track) => exchange.exportTrackGpx(track);


  Future<MapLayerModel?> importOfflineBasemap() async {
    final layer = await offlineMaps.importContainer();
    if (layer == null) return null;
    offlineBasemap = layer;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_basemap_path', layer.source);
    await prefs.setString('offline_basemap_type', layer.sourceType.name);
    await prefs.setString('offline_basemap_name', layer.name);
    notifyListeners();
    return layer;
  }

  Future<void> clearOfflineBasemap() async {
    offlineBasemap = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_basemap_path');
    await prefs.remove('offline_basemap_type');
    await prefs.remove('offline_basemap_name');
    notifyListeners();
  }

  Future<void> setBasemap(BasemapType value) async {
    basemap = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('basemap', value.name);
    notifyListeners();
  }

  Future<void> setGpsAccuracyThreshold(double value) async {
    gpsAccuracyThreshold = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('gps_accuracy_threshold', value);
    notifyListeners();
  }

  Future<void> setCentralMeridian(double value) async {
    centralMeridian = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('central_meridian', value);
    notifyListeners();
  }

  void setAutoFollowGps(bool value) {
    autoFollowGps = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    trackService.dispose();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
