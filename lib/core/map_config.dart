import '../data/enums.dart';

class MapConfig {
  static const double defaultLatitude = 10.7769;
  static const double defaultLongitude = 106.7009;
  static const double defaultZoom = 16;

  static const Map<BasemapType, String> basemapTemplates = {
    BasemapType.openStreetMap: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    BasemapType.googleStreets: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
    BasemapType.googleSatellite: 'https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
    BasemapType.googleHybrid: 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
  };

  static const Map<BasemapType, List<String>> subdomains = {
    BasemapType.openStreetMap: <String>[],
    BasemapType.googleStreets: <String>['0', '1', '2', '3'],
    BasemapType.googleSatellite: <String>['0', '1', '2', '3'],
    BasemapType.googleHybrid: <String>['0', '1', '2', '3'],
  };
}
