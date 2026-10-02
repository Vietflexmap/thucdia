import 'dart:convert';

import 'enums.dart';

class WaypointModel {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final DateTime createdAt;
  final WaypointSource source;

  const WaypointModel({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    required this.createdAt,
    required this.source,
  });

  WaypointModel copyWith({String? name, String? description}) => WaypointModel(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        accuracy: accuracy,
        createdAt: createdAt,
        source: source,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'created_at': createdAt.toUtc().toIso8601String(),
        'source': source.name,
      };

  factory WaypointModel.fromMap(Map<String, Object?> map) => WaypointModel(
        id: map['id']! as String,
        name: map['name']! as String,
        description: map['description'] as String?,
        latitude: (map['latitude']! as num).toDouble(),
        longitude: (map['longitude']! as num).toDouble(),
        altitude: (map['altitude'] as num?)?.toDouble(),
        accuracy: (map['accuracy'] as num?)?.toDouble(),
        createdAt: DateTime.parse(map['created_at']! as String),
        source: WaypointSource.values.byName(map['source']! as String),
      );

  Map<String, Object?> toGeoJsonFeature() => {
        'type': 'Feature',
        'id': id,
        'geometry': {
          'type': 'Point',
          'coordinates': [longitude, latitude, if (altitude != null) altitude],
        },
        'properties': {
          'name': name,
          'description': description,
          'accuracy_m': accuracy,
          'created_at': createdAt.toUtc().toIso8601String(),
          'source': source.name,
        },
      };
}

class GpsTrackPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime recordedAt;

  const GpsTrackPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    this.heading,
    required this.recordedAt,
  });

  Map<String, Object?> toMap(String trackId) => {
        'track_id': trackId,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
      };

  factory GpsTrackPoint.fromMap(Map<String, Object?> map) => GpsTrackPoint(
        latitude: (map['latitude']! as num).toDouble(),
        longitude: (map['longitude']! as num).toDouble(),
        altitude: (map['altitude'] as num?)?.toDouble(),
        accuracy: (map['accuracy'] as num?)?.toDouble(),
        speed: (map['speed'] as num?)?.toDouble(),
        heading: (map['heading'] as num?)?.toDouble(),
        recordedAt: DateTime.parse(map['recorded_at']! as String),
      );
}

class GpsTrackModel {
  final String id;
  final String name;
  final TrackStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double totalDistanceMeters;
  final List<GpsTrackPoint> points;

  const GpsTrackModel({
    required this.id,
    required this.name,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.totalDistanceMeters,
    this.points = const [],
  });

  GpsTrackModel copyWith({
    TrackStatus? status,
    DateTime? endedAt,
    double? totalDistanceMeters,
    List<GpsTrackPoint>? points,
  }) =>
      GpsTrackModel(
        id: id,
        name: name,
        status: status ?? this.status,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
        points: points ?? this.points,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'status': status.name,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt?.toUtc().toIso8601String(),
        'total_distance_m': totalDistanceMeters,
      };
}

class FieldPhoto {
  final String id;
  final String filePath;
  final String? note;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? heading;
  final DateTime takenAt;

  const FieldPhoto({
    required this.id,
    required this.filePath,
    this.note,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.heading,
    required this.takenAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'file_path': filePath,
        'note': note,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'heading': heading,
        'taken_at': takenAt.toUtc().toIso8601String(),
      };

  factory FieldPhoto.fromMap(Map<String, Object?> map) => FieldPhoto(
        id: map['id']! as String,
        filePath: map['file_path']! as String,
        note: map['note'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        accuracy: (map['accuracy'] as num?)?.toDouble(),
        heading: (map['heading'] as num?)?.toDouble(),
        takenAt: DateTime.parse(map['taken_at']! as String),
      );
}

class MapLayerModel {
  final String id;
  final String name;
  final LayerSourceType sourceType;
  final String source;
  final bool visible;

  const MapLayerModel({
    required this.id,
    required this.name,
    required this.sourceType,
    required this.source,
    this.visible = true,
  });
}

String prettyJson(Object? value) => const JsonEncoder.withIndent('  ').convert(value);
