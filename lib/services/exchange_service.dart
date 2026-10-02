import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/models.dart';
import 'geo_parser.dart';

class ExchangeService {
  Future<List<WaypointModel>> importWaypoints() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['geojson', 'json', 'kml', 'gpx'],
    );
    final path = result?.files.single.path;
    if (path == null) return const [];
    final text = await File(path).readAsString();
    final ext = p.extension(path).toLowerCase();
    return switch (ext) {
      '.geojson' || '.json' => GeoParser.parseGeoJsonWaypoints(text),
      '.gpx' => GeoParser.parseGpxWaypoints(text),
      '.kml' => GeoParser.parseKmlWaypoints(text),
      _ => throw FormatException('Unsupported file extension: $ext'),
    };
  }

  Future<String> exportWaypointsGeoJson(List<WaypointModel> waypoints) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    await exportDir.create(recursive: true);
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(exportDir.path, 'waypoints_$stamp.geojson'));
    await file.writeAsString(GeoParser.buildGeoJson(waypoints), flush: true);
    return file.path;
  }

  Future<String> exportTrackGpx(GpsTrackModel track) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    await exportDir.create(recursive: true);
    final file = File(p.join(exportDir.path, '${track.id}.gpx'));
    await file.writeAsString(GeoParser.buildGpxTrack(track), flush: true);
    return file.path;
  }
}
