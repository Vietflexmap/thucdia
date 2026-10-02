# Architecture – field GIS first

## 1. Domain layer

Stable records are kept independent of map UI:

- Waypoint: UUID + WGS84 + accuracy + source + time.
- Track: UUID + ordered GNSS points + accuracy/speed/heading + time.
- Photo: UUID + local file + GNSS + heading + time.
- Map layer: UUID + source type + source URI/path.

## 2. Offline-first storage

SQLite is the local source of truth. Network availability must not be required to create/edit field data. Map tiles are a separate concern.

## 3. Map adapters

- Online: OSM/Google XYZ raster.
- Offline raster: MBTiles via `flutter_map_mbtiles`.
- Offline/local or HTTP Range: PMTiles via `flutter_map_pmtiles`.
- Future: MVT/PMTiles vector, VFM, COG, GeoPackage.

## 4. GNSS pipeline

```text
Android Location -> Geolocator -> accuracy gate -> domain point -> SQLite
                                     |                  |
                                     +-> live UI         +-> export/sync
```

Track points worse than the configured horizontal accuracy threshold are rejected before persistence.

## 5. CRS

GNSS remains WGS84 as the canonical raw observation. VN-2000 is a derived representation. Datum transformation parameters are intentionally configurable/not hard-coded because legal/cadastral workflows may require approved parameters.

## 6. WebGIS/VFM integration target

The future sync envelope should carry:

```text
featureId
geometryWgs84
observedAt
receivedAt
accuracy
sourceDevice
operator/session
properties
mediaRefs
qualityFlag
version
```

This maps naturally to Vietflex WebGIS SDK and can later be packed into VFM without changing field capture semantics.
