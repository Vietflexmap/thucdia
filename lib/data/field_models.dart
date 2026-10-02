import 'dart:convert';

enum SurveySessionStatus { draft, active, completed, archived }

enum FeatureGeometryType { point, lineString, polygon }

enum FieldSyncState { local, pending, syncing, synced, conflict, error }

class FieldProject {
  final String id;
  final String name;
  final String? description;
  final String crs;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FieldProject({
    required this.id,
    required this.name,
    this.description,
    this.crs = 'EPSG:4326',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'crs': crs,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory FieldProject.fromMap(Map<String, Object?> map) => FieldProject(
        id: map['id']! as String,
        name: map['name']! as String,
        description: map['description'] as String?,
        crs: map['crs']! as String,
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
      );
}

class SurveySession {
  final String id;
  final String projectId;
  final String name;
  final SurveySessionStatus status;
  final String? operatorName;
  final String? deviceId;
  final DateTime startedAt;
  final DateTime? endedAt;

  const SurveySession({
    required this.id,
    required this.projectId,
    required this.name,
    required this.status,
    this.operatorName,
    this.deviceId,
    required this.startedAt,
    this.endedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'project_id': projectId,
        'name': name,
        'status': status.name,
        'operator_name': operatorName,
        'device_id': deviceId,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt?.toUtc().toIso8601String(),
      };

  factory SurveySession.fromMap(Map<String, Object?> map) => SurveySession(
        id: map['id']! as String,
        projectId: map['project_id']! as String,
        name: map['name']! as String,
        status: SurveySessionStatus.values.byName(map['status']! as String),
        operatorName: map['operator_name'] as String?,
        deviceId: map['device_id'] as String?,
        startedAt: DateTime.parse(map['started_at']! as String),
        endedAt: map['ended_at'] == null ? null : DateTime.parse(map['ended_at']! as String),
      );
}

class FeatureRecord {
  final String id;
  final String projectId;
  final String sessionId;
  final String layerId;
  final FeatureGeometryType geometryType;
  final Map<String, Object?> geometry;
  final Map<String, Object?> properties;
  final double? accuracy;
  final String source;
  final String qualityFlag;
  final int revision;
  final FieldSyncState syncState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const FeatureRecord({
    required this.id,
    required this.projectId,
    required this.sessionId,
    required this.layerId,
    required this.geometryType,
    required this.geometry,
    this.properties = const {},
    this.accuracy,
    this.source = 'field',
    this.qualityFlag = 'unverified',
    this.revision = 1,
    this.syncState = FieldSyncState.local,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'project_id': projectId,
        'session_id': sessionId,
        'layer_id': layerId,
        'geometry_type': geometryType.name,
        'geometry_json': jsonEncode(geometry),
        'properties_json': jsonEncode(properties),
        'accuracy': accuracy,
        'source': source,
        'quality_flag': qualityFlag,
        'revision': revision,
        'sync_state': syncState.name,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'deleted_at': deletedAt?.toUtc().toIso8601String(),
      };

  factory FeatureRecord.fromMap(Map<String, Object?> map) => FeatureRecord(
        id: map['id']! as String,
        projectId: map['project_id']! as String,
        sessionId: map['session_id']! as String,
        layerId: map['layer_id']! as String,
        geometryType: FeatureGeometryType.values.byName(map['geometry_type']! as String),
        geometry: Map<String, Object?>.from(jsonDecode(map['geometry_json']! as String) as Map),
        properties: Map<String, Object?>.from(jsonDecode(map['properties_json']! as String) as Map),
        accuracy: (map['accuracy'] as num?)?.toDouble(),
        source: map['source']! as String,
        qualityFlag: map['quality_flag']! as String,
        revision: map['revision']! as int,
        syncState: FieldSyncState.values.byName(map['sync_state']! as String),
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
        deletedAt: map['deleted_at'] == null ? null : DateTime.parse(map['deleted_at']! as String),
      );

  Map<String, Object?> toGeoJsonFeature() => {
        'type': 'Feature',
        'id': id,
        'geometry': geometry,
        'properties': {
          ...properties,
          '_projectId': projectId,
          '_sessionId': sessionId,
          '_layerId': layerId,
          '_accuracy': accuracy,
          '_qualityFlag': qualityFlag,
          '_revision': revision,
          '_syncState': syncState.name,
          '_updatedAt': updatedAt.toUtc().toIso8601String(),
        },
      };
}

class SyncQueueItem {
  final int? id;
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, Object?> payload;
  final FieldSyncState state;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SyncQueueItem({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    this.state = FieldSyncState.pending,
    this.attempts = 0,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'payload_json': jsonEncode(payload),
        'state': state.name,
        'attempts': attempts,
        'last_error': lastError,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}
