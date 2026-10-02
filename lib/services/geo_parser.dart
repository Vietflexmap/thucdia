import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../data/enums.dart';
import '../data/models.dart';

class GeoParser {
  static const Uuid _uuid = Uuid();

  static List<WaypointModel> parseGeoJsonWaypoints(String text) {
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    final features = (decoded['features'] as List? ?? const []);
    final result = <WaypointModel>[];
    for (final raw in features) {
      final feature = raw as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry == null || geometry['type'] != 'Point') continue;
      final coords = (geometry['coordinates'] as List).cast<num>();
      final props = (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
      result.add(WaypointModel(
        id: (feature['id'] ?? _uuid.v4()).toString(),
        name: (props['name'] ?? 'Imported point').toString(),
        description: props['description']?.toString(),
        longitude: coords[0].toDouble(),
        latitude: coords[1].toDouble(),
        altitude: coords.length > 2 ? coords[2].toDouble() : null,
        accuracy: (props['accuracy_m'] as num?)?.toDouble(),
        createdAt: DateTime.tryParse(props['created_at']?.toString() ?? '') ?? DateTime.now(),
        source: WaypointSource.importFile,
      ));
    }
    return result;
  }

  static List<WaypointModel> parseGpxWaypoints(String text) {
    final document = XmlDocument.parse(text);
    return document.findAllElements('wpt').map((element) {
      final lat = double.parse(element.getAttribute('lat')!);
      final lon = double.parse(element.getAttribute('lon')!);
      return WaypointModel(
        id: _uuid.v4(),
        name: element.getElement('name')?.innerText ?? 'GPX waypoint',
        description: element.getElement('desc')?.innerText,
        latitude: lat,
        longitude: lon,
        altitude: double.tryParse(element.getElement('ele')?.innerText ?? ''),
        createdAt: DateTime.tryParse(element.getElement('time')?.innerText ?? '') ?? DateTime.now(),
        source: WaypointSource.importFile,
      );
    }).toList();
  }

  static List<WaypointModel> parseKmlWaypoints(String text) {
    final document = XmlDocument.parse(text);
    final result = <WaypointModel>[];
    for (final placemark in document.findAllElements('Placemark')) {
      final point = placemark.findElements('Point').firstOrNull;
      final coordinates = point?.getElement('coordinates')?.innerText.trim();
      if (coordinates == null || coordinates.isEmpty) continue;
      final values = coordinates.split(',');
      if (values.length < 2) continue;
      result.add(WaypointModel(
        id: _uuid.v4(),
        name: placemark.getElement('name')?.innerText ?? 'KML point',
        description: placemark.getElement('description')?.innerText,
        longitude: double.parse(values[0]),
        latitude: double.parse(values[1]),
        altitude: values.length > 2 ? double.tryParse(values[2]) : null,
        createdAt: DateTime.now(),
        source: WaypointSource.importFile,
      ));
    }
    return result;
  }

  static String buildGeoJson(List<WaypointModel> waypoints) => prettyJson({
        'type': 'FeatureCollection',
        'features': waypoints.map((e) => e.toGeoJsonFeature()).toList(),
      });

  static String buildGpxTrack(GpsTrackModel track) {
    final points = track.points.map((p) {
      final ele = p.altitude == null ? '' : '<ele>${p.altitude}</ele>';
      return '<trkpt lat="${p.latitude}" lon="${p.longitude}">$ele<time>${p.recordedAt.toUtc().toIso8601String()}</time></trkpt>';
    }).join();
    return '<?xml version="1.0" encoding="UTF-8"?><gpx version="1.1" creator="Vietflex ThucDia"><trk><name>${_xml(track.name)}</name><trkseg>$points</trkseg></trk></gpx>';
  }

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
