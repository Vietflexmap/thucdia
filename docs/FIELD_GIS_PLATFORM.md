# Vietflex Field GIS Platform v0.2

## Mục tiêu

Vietflex Field GIS là nền tảng thu thập và kiểm tra dữ liệu không gian **offline-first**, gồm hai runtime dùng chung một hợp đồng dữ liệu:

- **Mobile Flutter**: GNSS, track, ảnh hiện trường, bản đồ offline, thu thập tại hiện trường.
- **WebGIS**: Project/Survey Session, số hóa Point/Line/Polygon, import/export, PMTiles, QA/QC sơ bộ và hàng đợi đồng bộ.

Mục tiêu kiến trúc là hỗ trợ các workflow chuyên biệt tương tự nhóm công cụ Field GIS hiện đại mà không khóa dữ liệu vào một map engine hay một backend cụ thể.

## Domain contract

```text
Project
  └── SurveySession
        ├── FeatureRecord<Point|LineString|Polygon>
        ├── Attachment
        └── Observation

FeatureRecord
  id                UUID
  projectId         UUID
  sessionId         UUID
  layerId           stable logical layer id
  geometry          GeoJSON geometry, canonical WGS84 by default
  properties        dynamic attributes
  accuracy          horizontal accuracy in metres when available
  source            web-map / browser-gnss / import:* / external GNSS
  qualityFlag       unverified / acceptable / good / high_precision / ...
  revision          monotonic local revision
  syncState         local / pending / syncing / synced / conflict / error
  createdAt
  updatedAt
  deletedAt         tombstone, not destructive sync deletion
```

SQLite is the mutable source of truth on Flutter. IndexedDB is the local workspace on WebGIS. VFM is planned as a transport/snapshot/project package rather than replacing the mutable database in v0.2.

## GNSS pipeline

v0.1 opened independent position streams for the application and track recorder. v0.2 introduces `GnssBroker`:

```text
Android Location / Geolocator
            │
            ▼
        GnssBroker
            │
     ┌──────┼────────┐
     ▼      ▼        ▼
    Map   Track    Future QA/Photo
```

This provides one native stream and a consistent latest observation for downstream consumers.

## Track recorder v0.2

The track recorder is now append-oriented:

1. Position events enter a serialized processing chain.
2. Accuracy gate is applied.
3. Distance is calculated from the last accepted point only.
4. The point and track summary are updated atomically in one SQLite transaction.
5. The UI is notified after persistence.

This removes the v0.1 list-copy operation on every sample and prevents overlapping asynchronous SQLite writes from the GNSS stream.

Remaining work for long tracks: render/query track points by viewport/window instead of retaining the complete active polyline in UI memory.

## SQLite schema v2

New tables:

- `projects`
- `survey_sessions`
- `field_features`
- `attachments`
- `sync_queue`

The database now includes `onUpgrade` migration from schema v1 to v2. Existing v0.1 waypoint/track/photo tables are retained for backward compatibility while features are migrated progressively to the generic domain.

## WebGIS runtime

`webgis/` is a static GitHub Pages application based on:

- MapLibre GL JS
- PMTiles browser protocol
- IndexedDB
- Service Worker / PWA shell
- GeoJSON as the browser exchange representation

Implemented in v0.2:

- project creation and project switching;
- active/completed survey sessions;
- draw Point, LineString and Polygon;
- browser GNSS capture with recorded accuracy;
- local FeatureRecord persistence in IndexedDB;
- selection and attribute editing;
- deletion tombstones and sync queue;
- import GeoJSON, KML and GPX for common Point/LineString/Polygon workflows;
- export project GeoJSON;
- raster and vector PMTiles URL adapter;
- layer visibility;
- online/offline status;
- local API endpoint configuration without pretending data was synced;
- installable PWA shell.

## PMTiles contract

Production PMTiles endpoints should support HTTP Range and CORS. Vector PMTiles requires a valid `source-layer`. The WebGIS tries `metadata.vector_layers[0].id` when the user does not supply one.

Do not treat public OSM raster tiles as an offline bulk-download service. The bundled OSM layer is an interactive online reference layer; Vietflex deployments should prefer organization-controlled PMTiles/R2/CDN basemaps for production and offline use.

## Sync contract v0.3

The client already persists queue records but v0.2 intentionally does **not** mark them as synced without an authenticated server adapter.

Recommended API envelope:

```json
{
  "featureId": "uuid",
  "projectId": "uuid",
  "sessionId": "uuid",
  "revision": 3,
  "geometryWgs84": {"type": "Point", "coordinates": [106.0, 10.0]},
  "properties": {},
  "observedAt": "2026-10-02T02:30:00Z",
  "receivedAt": "2026-10-02T02:30:02Z",
  "accuracy": 0.03,
  "qualityFlag": "high_precision",
  "sourceDevice": "device-id",
  "mediaRefs": [],
  "operation": "upsert"
}
```

Server response must return accepted revision/version and conflict information. Conflict resolution must never silently overwrite a higher server revision.

## CRS / VN-2000

Canonical observations remain WGS84. The existing VN-2000 code is the projection stage only. Survey-grade/legal cadastral output requires a validated datum transformation using the approved parameter set for the intended area/workflow, plus conformance tests against control points.

Recommended pipeline:

```text
WGS84 observation
  → datum transformation
  → VN-2000 geographic
  → TM-3 / approved projected CRS
  → validation against control points
```

## Roadmap to specialist production grade

### v0.3

- authenticated Vietflex WebGIS sync adapter;
- server revision/conflict resolver;
- generic form schema and domain validation;
- IndexedDB/SQLite spatial indexes or viewport query layer;
- attachments with SHA-256 and immutable metadata;
- vector PMTiles catalog persisted per project;
- WebGIS editing undo/redo and snapping.

### v0.4

- topology rules;
- background/foreground-service mobile tracking and crash recovery;
- robust QA/QC rule engine;
- batch import streaming for large files;
- project package export/import;
- audit event log.

### v0.5+

- Bluetooth/USB NMEA GNSS;
- NTRIP/RTCM and explicit RTK FIX/FLOAT quality fields;
- geoid/vertical datum model;
- VFM adapter;
- GeoAI-assisted QA, media classification and field assistant.

## Quality gates

Every platform change should pass:

```text
format
→ flutter analyze
→ flutter test
→ Android debug build
→ WebGIS static validation
→ integration/conformance suites as they are added
```

A successful build is not equivalent to survey-grade correctness. CRS, GNSS quality, topology and sync conflict behavior require domain-specific conformance tests.
