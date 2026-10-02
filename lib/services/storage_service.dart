import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../data/enums.dart';
import '../data/models.dart';

class StorageService {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final base = await getDatabasesPath();
    _db = await openDatabase(
      p.join(base, 'vietflex_thucdia.db'),
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
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
        await db.execute('CREATE INDEX idx_track_points_track ON track_points(track_id, id)');
      },
    );
    return _db!;
  }

  Future<List<WaypointModel>> loadWaypoints() async {
    final db = await database;
    final rows = await db.query('waypoints', orderBy: 'created_at DESC');
    return rows.map(WaypointModel.fromMap).toList();
  }

  Future<void> saveWaypoint(WaypointModel value) async {
    final db = await database;
    await db.insert('waypoints', value.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteWaypoint(String id) async {
    final db = await database;
    await db.delete('waypoints', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveTrack(GpsTrackModel track) async {
    final db = await database;
    await db.insert('tracks', track.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> appendTrackPoint(String trackId, GpsTrackPoint point) async {
    final db = await database;
    await db.insert('track_points', point.toMap(trackId));
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
      result.add(GpsTrackModel(
        id: row['id']! as String,
        name: row['name']! as String,
        status: TrackStatus.values.byName(row['status']! as String),
        startedAt: DateTime.parse(row['started_at']! as String),
        endedAt: row['ended_at'] == null ? null : DateTime.parse(row['ended_at']! as String),
        totalDistanceMeters: (row['total_distance_m']! as num).toDouble(),
        points: points.map(GpsTrackPoint.fromMap).toList(),
      ));
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
    await db.insert('photos', photo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
