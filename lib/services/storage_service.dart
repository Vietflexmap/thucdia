import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../data/enums.dart';
import '../data/field_models.dart';
import '../data/models.dart';

class StorageService {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final base = await getDatabasesPath();
    _db = await openDatabase(
      p.join(base, 'vietflex_thucdia.db'),
      version: 2,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _createLegacyTables(db);
        await _createFieldPlatformTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createFieldPlatformTables(db);
        }
      },
    );
    return _db!;
  }

  Future<void> _createLegacyTables(Database db) async {
    await db.execute('''
      CREATE TABLE waypoints(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL,
        accuracy REAL,
        created_at TEXT NOT NULL,
        source TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE tracks(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        status TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        total_distance_m REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE track_points(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        track_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL,
        accuracy REAL,
        speed REAL,
        heading REAL,
        recorded_at TEXT NOT NULL,
        FOREIGN KEY(track_id) REFERENCES tracks(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE photos(
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        note TEXT,
        latitude REAL,
        longitude REAL,
        accuracy REAL,
        heading REAL,
        taken_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_track_points_track ON track_points(track_id, id)',
    );
  }

  Future<void> _createFieldPlatformTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        crs TEXT NOT NULL DEFAULT 'EPSG:4326',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS survey_sessions(
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        name TEXT NOT NULL,
        status TEXT NOT NULL,
        operator_name TEXT,
        device_id TEXT,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS field_features(
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        layer_id TEXT NOT NULL,
        geometry_type TEXT NOT NULL,
        geometry_json TEXT NOT NULL,
        properties_json TEXT NOT NULL DEFAULT '{}',
        accuracy REAL,
        source TEXT NOT NULL DEFAULT 'field',
        quality_flag TEXT NOT NULL DEFAULT 'unverified',
        revision INTEGER NOT NULL DEFAULT 1,
        sync_state TEXT NOT NULL DEFAULT 'local',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
        FOREIGN KEY(session_id) REFERENCES survey_sessions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attachments(
        id TEXT PRIMARY KEY,
        feature_id TEXT,
        session_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        mime_type TEXT,
        sha256 TEXT,
        captured_at TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        accuracy REAL,
        heading REAL,
        FOREIGN KEY(feature_id) REFERENCES field_features(id) ON DELETE SET NULL,
        FOREIGN KEY(session_id) REFERENCES survey_sessions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        state TEXT NOT NULL DEFAULT 'pending',
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sessions_project '
      'ON survey_sessions(project_id, started_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_features_project_layer '
      'ON field_features(project_id, layer_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_features_session '
      'ON field_features(session_id, updated_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_features_sync '
      'ON field_features(sync_state, updated_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_state '
      'ON sync_queue(state, id)',
    );
  }

  Future<List<WaypointModel>> loadWaypoints() async {
    final db = await database;
    final rows = await db.query('waypoints', orderBy: 'created_at DESC');
    return rows.map(WaypointModel.fromMap).toList();
  }

  Future<void> saveWaypoint(WaypointModel value) async {
    final db = await database;
    await db.insert(
      'waypoints',
      value.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteWaypoint(String id) async {
    final db = await database;
    await db.delete('waypoints', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveTrack(GpsTrackModel track) async {
    final db = await database;
    await db.insert(
      'tracks',
      track.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> appendTrackPoint(String trackId, GpsTrackPoint point) async {
    final db = await database;
    await db.insert('track_points', point.toMap(trackId));
  }

  Future<void> appendTrackPointAndUpdateSummary(
    String trackId,
    GpsTrackPoint point,
    double totalDistanceMeters,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('track_points', point.toMap(trackId));
      await txn.update(
        'tracks',
        {'total_distance_m': totalDistanceMeters},
        where: 'id = ?',
        whereArgs: [trackId],
      );
    });
  }

  Future<List<GpsTrackModel>> loadTracks() async {
    final db = await database;
    final rows = await db.query('tracks', orderBy: 'started_at DESC');
    final result = <GpsTrackModel>[];
    for (final row in rows) {
      final points = await db.query(
        'track_points',
        where: 'track_id = ?',
        whereArgs: [row['id']],
        orderBy: 'id ASC',
      );
      result.add(
        GpsTrackModel(
          id: row['id']! as String,
          name: row['name']! as String,
          status: TrackStatus.values.byName(row['status']! as String),
          startedAt: DateTime.parse(row['started_at']! as String),
          endedAt: row['ended_at'] == null
              ? null
              : DateTime.parse(row['ended_at']! as String),
          totalDistanceMeters: (row['total_distance_m']! as num).toDouble(),
          points: points.map(GpsTrackPoint.fromMap).toList(),
        ),
      );
    }
    return result;
  }

  Future<List<FieldPhoto>> loadPhotos() async {
    final db = await database;
    final rows = await db.query('photos', orderBy: 'taken_at DESC');
    return rows.map(FieldPhoto.fromMap).toList();
  }

  Future<void> savePhoto(FieldPhoto photo) async {
    final db = await database;
    await db.insert(
      'photos',
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FieldProject>> loadProjects() async {
    final db = await database;
    final rows = await db.query('projects', orderBy: 'updated_at DESC');
    return rows.map(FieldProject.fromMap).toList();
  }

  Future<void> saveProject(FieldProject project) async {
    final db = await database;
    await db.insert(
      'projects',
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SurveySession>> loadSurveySessions(String projectId) async {
    final db = await database;
    final rows = await db.query(
      'survey_sessions',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'started_at DESC',
    );
    return rows.map(SurveySession.fromMap).toList();
  }

  Future<void> saveSurveySession(SurveySession session) async {
    final db = await database;
    await db.insert(
      'survey_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FeatureRecord>> loadFeatures({
    required String projectId,
    String? sessionId,
    String? layerId,
  }) async {
    final db = await database;
    final where = <String>['project_id = ?', 'deleted_at IS NULL'];
    final args = <Object?>[projectId];
    if (sessionId != null) {
      where.add('session_id = ?');
      args.add(sessionId);
    }
    if (layerId != null) {
      where.add('layer_id = ?');
      args.add(layerId);
    }
    final rows = await db.query(
      'field_features',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'updated_at DESC',
    );
    return rows.map(FeatureRecord.fromMap).toList();
  }

  Future<void> saveFeature(
    FeatureRecord feature, {
    bool enqueue = true,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'field_features',
        feature.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (enqueue) {
        final now = DateTime.now().toUtc().toIso8601String();
        await txn.insert('sync_queue', {
          'entity_type': 'feature',
          'entity_id': feature.id,
          'operation': feature.deletedAt == null ? 'upsert' : 'delete',
          'payload_json': jsonEncode(feature.toGeoJsonFeature()),
          'state': FieldSyncState.pending.name,
          'attempts': 0,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  Future<int> pendingSyncCount() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM sync_queue WHERE state IN (?, ?)',
      [FieldSyncState.pending.name, FieldSyncState.error.name],
    );
    return (rows.first['count'] as num?)?.toInt() ?? 0;
  }
}
