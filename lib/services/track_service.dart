import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../data/enums.dart';
import '../data/models.dart';
import 'location_service.dart';
import 'storage_service.dart';

class TrackService {
  TrackService(this.storage, this.location);

  final StorageService storage;
  final LocationService location;
  final Uuid _uuid = const Uuid();
  StreamSubscription<Position>? _subscription;

  GpsTrackModel? _active;
  GpsTrackModel? get active => _active;

  Future<GpsTrackModel> start({
    double maxAccuracyMeters = 25,
    void Function(GpsTrackModel track)? onChanged,
  }) async {
    await stop();
    final now = DateTime.now();
    _active = GpsTrackModel(
      id: _uuid.v4(),
      name: 'Track ${now.toLocal().toIso8601String().substring(0, 19)}',
      status: TrackStatus.recording,
      startedAt: now,
      totalDistanceMeters: 0,
    );
    await storage.saveTrack(_active!);

    _subscription = location.positionStream(distanceFilter: 2).listen((position) async {
      if (_active == null || position.accuracy > maxAccuracyMeters) return;
      final point = GpsTrackPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        recordedAt: position.timestamp ?? DateTime.now(),
      );
      final points = [..._active!.points];
      var distance = _active!.totalDistanceMeters;
      if (points.isNotEmpty) {
        final previous = points.last;
        distance += LocationService.distanceMeters(
          previous.latitude,
          previous.longitude,
          point.latitude,
          point.longitude,
        );
      }
      points.add(point);
      _active = _active!.copyWith(
        totalDistanceMeters: distance,
        points: points,
      );
      await storage.appendTrackPoint(_active!.id, point);
      await storage.saveTrack(_active!);
      onChanged?.call(_active!);
    });
    onChanged?.call(_active!);
    return _active!;
  }

  Future<GpsTrackModel?> stop({void Function(GpsTrackModel track)? onChanged}) async {
    await _subscription?.cancel();
    _subscription = null;
    if (_active == null) return null;
    _active = _active!.copyWith(
      status: TrackStatus.completed,
      endedAt: DateTime.now(),
    );
    await storage.saveTrack(_active!);
    final completed = _active;
    onChanged?.call(completed!);
    _active = null;
    return completed;
  }

  Future<void> dispose() async => _subscription?.cancel();
}
