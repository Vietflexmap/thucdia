import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../data/enums.dart';
import '../data/models.dart';

/// Imports offline map containers into app-owned storage.
///
/// Rendering adapters are intentionally separate so the app can support both
/// MBTiles and PMTiles without coupling field-data logic to one map engine.
class OfflineMapCatalogService {
  final Uuid _uuid = const Uuid();

  Future<MapLayerModel?> importContainer() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['mbtiles', 'pmtiles'],
    );
    final source = result?.files.single.path;
    if (source == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final mapsDir = Directory(p.join(dir.path, 'offline_maps'));
    await mapsDir.create(recursive: true);
    final target = p.join(mapsDir.path, p.basename(source));
    if (p.normalize(source) != p.normalize(target)) {
      await File(source).copy(target);
    }

    final ext = p.extension(target).toLowerCase();
    var name = p.basenameWithoutExtension(target);
    if (ext == '.mbtiles') {
      final metadata = await readMbtilesMetadata(target);
      name = metadata['name'] ?? name;
    }

    return MapLayerModel(
      id: _uuid.v4(),
      name: name,
      sourceType: ext == '.pmtiles' ? LayerSourceType.pmtiles : LayerSourceType.mbtiles,
      source: target,
    );
  }

  Future<Map<String, String>> readMbtilesMetadata(String path) async {
    final db = await openDatabase(path, readOnly: true, singleInstance: false);
    try {
      final rows = await db.query('metadata');
      return {
        for (final row in rows)
          if (row['name'] != null && row['value'] != null)
            row['name'].toString(): row['value'].toString(),
      };
    } finally {
      await db.close();
    }
  }
}
