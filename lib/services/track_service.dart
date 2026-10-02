import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../data/enums.dart';
import '../data/models.dart';
import 'gnss_broker.dart';
import 'location_service.dart';
import 'storage_service.dart';

/// Append-only track recorder.
///
/// GNSS positions are serialized through [_processing] so SQLite writes and
/// distance calculations cannot overlap when the native stream emits bursts.
class TrackService {
  TrackService(this.storage, this.gnss);

  final StorageService storage;
  final GnssBroker gnss;
  final Uuid _uuid = const Uuid();
  StreamSubscription<Position>? _subscription;
  Future<void> _processing = Future<void>.value();
  final List<GpsTrackPoint> _activePoints = <GpsTrackPoint>[];
  GpsTrackPoint? _lastPoint;

  GpsTrackModel? _active;
  GpsTrackModel? get active => _active;

  Future<GpsTrackModel> start({
    double maxAccuracyMeters = 25,
    void Function(GpsTrackModel track)? onChanged,
  }) async {
    await stop();
    final ready = await gnss.start(distanceFilter: 1);
    if (!ready) {
      throw StateError('GNSS is not available or location permission was denied.');
    }

    final now = DateTime.now();
    _activePoints.clear();
    _lastPoint = null;
    _active = GpsTrackModel(
      id: _uuid.v4(),
      name: 'Track ${now.toLocal().toIso8601String().substring(0, 19)}',
      status: TrackStatus.recording,
      startedAt: now,
      totalDistanceMeters: 0,
      points: _activePoints,
    );
    await storage.saveTrack(_active!);

    _subscription = gnss.stream.listen((position) {
      _processing = _processing
          .catchError((Object _, StackTrace __) {})
          .then((_) => _acceptPosition(position, maxAccuracyMeters, onChanged));
    });
    onChanged?.call(_active!);
    return _active!;
  }

  Future<void> _acceptPosition(
    Position position,
    double maxAccuracyMeters,
    void Function(GpsTrackModel track)? onChanged,
  ) async {
    final active = _active;
    if (active == null || position.accuracy > maxAccuracyMeters) return;

    final point = GpsTrackPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading,
      recordedAt: position.timestamp,
    );

    var distance = active.totalDistanceMeters;
    final previous = _lastPoint;
    if (previous != null) {
      distance += LocationService.distanceMeters(
        previous.latitude,
        previous.longitude,
        point.latitude,
        point.longitude,
      );
    }

    _activePoints.add(point);
    _lastPoint = point;
    _active = active.copyWith(
      totalDistanceMeters: distance,
      points: _activePoints,
    );

    await storage.appendTrackPointAndUpdateSummary(active.id, point, distance);
    if (_active != null) onChanged?.call(_active!);
  }

  Future<GpsTrackModel?> stop({void Function(GpsTrackModel track)? onChanged}) async {
    await _subscription?.cancel();
    _subscription = null;
    await _processing.catchError((Object _, StackTrace __) {});
    if (_active == null) return null;

    _active = _active!.copyWith(
      status: TrackStatus.completed,
      endedAt: DateTime.now(),
      points: List<GpsTrackPoint>.unmodifiable(_activePoints),
    );
    await storage.saveTrack(_active!);
    final completed = _active;
    onChanged?.call(completed!);
    _active = null;
    _lastPoint = null;
    return completed;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _processing.catchError((Object _, StackTrace __) {});
  }
}
