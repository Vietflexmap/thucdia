# DVTmap.apk – clean-room functional analysis

## Fingerprint

- File: `DVTmap.apk`
- SHA-256: `bdef9c61d3f6ad57a754e9db4599a295c74952fc9c796f504eddb6ba7bc4119b`
- Size: ~65 MB
- Android entry class observed in DEX: `com/dvtmap/app/MainActivity`
- Runtime: Flutter AOT (`libapp.so`, `libflutter.so`)

## Open-source/runtime dependencies observed

Symbols/assets indicate use of:

- `flutter_map`, `latlong2`
- `geolocator`, Google Play Services Location
- `camera`, CameraX, `camera_with_gps`
- `sqlite3`, `mbtiles`
- `file_picker`, `path_provider`, `shared_preferences`, `share_plus`
- `image_picker`, `flutter_compass`, `connectivity_plus`
- `xml`, `archive`, `http`, `uuid`

## Recovered module names

Flutter AOT retains source URI strings that expose the application's module layout. Observed modules include:

```text
core/app_theme.dart
core/map_config.dart
core/vn2000.dart
data/app_state.dart
data/enums.dart
data/field_photo_model.dart
data/gps_track_model.dart
data/map_layer_model.dart
data/waypoint_model.dart
features/coordinates/coordinates_screen.dart
features/home/home_screen.dart
features/map/map_screen.dart
features/map/feature_info_panel.dart
features/map/map_layers_panel.dart
features/map/measurement_panel.dart
features/map/navigation_panel.dart
features/map/track_info_panel.dart
features/map/track_list_screen.dart
features/media/media_screen.dart
features/photo/photo_detail_screen.dart
features/settings/settings_screen.dart
features/waypoint/waypoint_form.dart
features/waypoint/waypoint_list_screen.dart
services/compass_service.dart
services/geo_parser.dart
services/location_service.dart
services/map_file_service.dart
services/mbtiles_service.dart
services/measurement_service.dart
services/navigation_service.dart
services/network_service.dart
services/photo_service.dart
services/storage_service.dart
services/track_service.dart
services/waypoint_service.dart
```

## Behavior/functionality observed

AOT strings expose identifiers and UI/action names consistent with:

- `WaypointModel`, `GpsTrackModel`, `GpsTrackPoint`, `FieldPhoto`, `MapLayerModel`
- `startTrack`, `saveCurrentTrack`, `resumeTrack`, `addWaypoint`, `updateWaypoint`, `removeWaypoint`
- `parseGeoJson`, `parseKml`, GPX builder/export
- `setBasemap`, `toggleLayerVisibility`, `importMapFile`
- `MeasurementMode`, `DistanceUnit`, `AreaUnit`, `measure_distance_button`, `measure_area_button`, `measure_bearing_button`
- `NavigationMode`, `startNavigation`, `stopNavigation`
- `WGS84 - EPSG:4326`, `vn2000`, coordinate parsing/copy
- `.mbtiles`, `MBTilesMetadata`

Network tile templates observed:

```text
https://tile.openstreetmap.org/{z}/{x}/{y}.png
https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}
https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}
https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}
```

## Clean-room reconstruction policy

This repository uses the observations above only to define **behavioral compatibility and architecture**. It does not contain decompiled proprietary Dart source or copied implementation bodies from the APK.
