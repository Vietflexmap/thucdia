# Vietflex Field GIS

**Vietflex Field GIS** là nền tảng GIS thực địa offline-first, phát triển theo clean-room architecture từ yêu cầu nghiệp vụ và hành vi quan sát được của ứng dụng tham chiếu. Repository không chứa mã Dart trích xuất từ APK.

- **Mobile runtime:** Flutter + SQLite + GNSS + MBTiles/PMTiles raster.
- **WebGIS runtime:** MapLibre GL JS + PMTiles + IndexedDB + PWA.
- **Domain contract:** Project → Survey Session → Feature → Attachment → Sync Queue.
- **License:** MIT.

## WebGIS

Sau khi GitHub Pages được triển khai từ `main`:

**https://vietflexmap.github.io/thucdia/**

Source web nằm trong [`webgis/`](webgis/). WebGIS v0.2 có Project/Survey Session, số hóa Point/Line/Polygon, GNSS trình duyệt, IndexedDB offline workspace, import GeoJSON/KML/GPX, export GeoJSON, raster/vector PMTiles, layer visibility, QA metadata cơ bản và persistent sync queue.

> v0.2 không giả lập thành công đồng bộ server. Nếu chưa có authenticated API adapter, hàng đợi vẫn giữ trạng thái `pending`.

## Kiến trúc v0.2

```text
                         VIETFLEX FIELD GIS
                                │
                ┌───────────────┴───────────────┐
                │                               │
          Flutter Mobile                   Field WebGIS
                │                               │
         GNSS / Camera                    MapLibre / PMTiles
                │                               │
            GnssBroker                    IndexedDB / PWA
                │                               │
       SQLite schema v2                        │
                └───────────────┬───────────────┘
                                │
                         Domain Contract
                                │
             Project → Session → FeatureRecord
                                │
                revision / QA / syncState
                                │
                         Sync Queue v0.3
                                │
                        Vietflex WebGIS
                                │
                         VFM snapshot
```

Chi tiết: [`docs/FIELD_GIS_PLATFORM.md`](docs/FIELD_GIS_PLATFORM.md).

## Nâng cấp lõi từ v0.1

### Một GNSS stream dùng chung

`GnssBroker` thay cho việc AppState và TrackService tự mở hai native location streams độc lập.

```text
Geolocator → GnssBroker → Map / Track / future QA / media
```

### Track recorder append-oriented

Track points được xử lý tuần tự, chỉ tính khoảng cách từ điểm được chấp nhận gần nhất và ghi point + summary trong transaction. Điều này loại bỏ việc copy toàn bộ danh sách track ở mỗi GNSS sample của v0.1 và tránh callback SQLite chồng nhau.

### SQLite schema v2

Bổ sung migration và các bảng:

- `projects`
- `survey_sessions`
- `field_features`
- `attachments`
- `sync_queue`

Các bảng waypoint/track/photo v0.1 vẫn được giữ để tương thích dữ liệu cũ trong giai đoạn chuyển đổi.

## Domain dữ liệu ổn định

`FeatureRecord` không phụ thuộc map engine:

```text
id
projectId
sessionId
layerId
geometry / geometryType
properties
accuracy
source
qualityFlag
revision
syncState
createdAt / updatedAt / deletedAt
```

WGS84 là representation quan sát gốc. VN-2000 được xem là pipeline datum transformation + projection riêng; mã hiện tại chưa được tuyên bố là chuyển đổi địa chính pháp lý đầy đủ.

## Chạy Flutter

```bash
flutter create . --platforms=android --org com.vietflexmap --project-name vietflex_thucdia
flutter pub get
flutter test
flutter run
```

## Chạy WebGIS local

Source runtime lớn được lưu theo các fragment byte-for-byte trong `webgis/src/`. Ghép trước khi chạy:

```bash
cat webgis/src/app.part-* > webgis/app.js
python -m http.server 8080 --directory webgis
```

Mở `http://localhost:8080`.

## PMTiles

WebGIS dùng PMTiles protocol trực tiếp với MapLibre. Production endpoint cần HTTP Range + CORS. Vector PMTiles cần `source-layer`. Xem [`docs/WEBGIS.md`](docs/WEBGIS.md).

## CI / chất lượng

GitHub Actions chạy:

```text
dart format
→ flutter analyze
→ flutter test
→ flutter build apk --debug
→ upload APK artifact
```

GitHub Pages workflow ghép và xác minh checksum runtime WebGIS, kiểm tra cú pháp JS/manifest rồi triển khai `webgis/` độc lập với Flutter build.

## Roadmap

- **v0.3:** authenticated WebGIS sync, server revision/conflict resolution, dynamic form schema, attachment SHA-256, persistent PMTiles catalog.
- **v0.4:** snapping/topology/undo-redo, background tracking + crash recovery, QA/QC rule engine, audit event log.
- **v0.5:** Bluetooth/USB NMEA GNSS, NTRIP/RTCM, explicit RTK FIX/FLOAT, vertical datum/geoid model.
- **v1.0:** VFM project package, GeoAI QA/field assistant, workflow chuyên biệt cho đất đai, môi trường, nông nghiệp, hạ tầng và kiểm kê.

## Clean-room note

Thiết kế dựa trên yêu cầu chức năng, hành vi quan sát được và các thành phần mã nguồn mở. Không sao chép implementation đóng từ APK tham chiếu.

## License

MIT.
