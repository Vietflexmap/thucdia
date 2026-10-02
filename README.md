# Vietflex Thực địa

Ứng dụng GIS thực địa Flutter, viết lại theo mô hình **clean-room** từ yêu cầu nghiệp vụ và hành vi quan sát được của `DVTmap.apk`. Mã trong repository này không phải mã Dart trích xuất từ APK.

## Mục tiêu v0.1

- GNSS thời gian thực, hiển thị accuracy/speed/heading.
- Waypoint từ vị trí GPS hoặc long-press trên bản đồ.
- Ghi GPS track có lọc theo ngưỡng độ chính xác.
- Ảnh hiện trường được lưu cùng GNSS/time/heading.
- Đo khoảng cách, diện tích và phương vị.
- WGS84 + bước chiếu VN-2000/TM-3 theo kinh tuyến trục cấu hình.
- SQLite local, chạy được khi mất mạng đối với dữ liệu nghiệp vụ.
- Nền bản đồ online OSM/Google và **offline MBTiles/PMTiles raster**.
- Import waypoint GeoJSON/KML/GPX; export Waypoint GeoJSON và Track GPX.

## Kiến trúc

```text
lib/
├─ core/        # theme, basemap config, projection VN-2000
├─ data/        # domain models, enum, application state
├─ services/    # GNSS, SQLite, track, photo, import/export, offline maps
└─ features/    # map, coordinates, media, waypoint, track, settings
```

Nguyên tắc chính: **field data độc lập map engine**. Waypoint/track/photo được lưu theo model riêng; MBTiles/PMTiles chỉ là adapter nền bản đồ. Cách này giúp sau này thay `flutter_map` bằng MapLibre, thêm VFM, hoặc đồng bộ WebGIS mà không thay schema dữ liệu thực địa.

## Khởi tạo platform Android

Repository tập trung vào source nghiệp vụ. Trên máy có Flutter stable:

```bash
flutter create . --platforms=android --org com.vietflexmap --project-name vietflex_thucdia
flutter pub get
flutter run
```

Sau khi `flutter create`, bảo đảm Android manifest có quyền `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `CAMERA`, `INTERNET` như file mẫu trong repo.

## Quy trình thực địa đề xuất

1. Chuẩn bị MBTiles/PMTiles cho khu vực khảo sát.
2. Chọn ngưỡng accuracy phù hợp thiết bị/môi trường.
3. Ghi waypoint/track/photo trong một phiên khảo sát.
4. Kiểm tra QA/QC tại chỗ: accuracy, số điểm, chiều dài/diện tích.
5. Export GeoJSON/GPX hoặc đồng bộ về WebGIS.

## VN-2000

`core/vn2000.dart` hiện triển khai **bước chiếu Transverse Mercator** trên ellipsoid WGS84 với `k0=0.9999` và kinh tuyến trục cấu hình. Để dùng cho công việc địa chính yêu cầu độ chính xác pháp lý, cần thêm phép chuyển datum WGS84 ↔ VN-2000 bằng bộ tham số được phê duyệt cho quy trình nghiệp vụ tương ứng.

## DVTmap compatibility map

APK tham chiếu cho thấy các nhóm chức năng: `Map`, `Waypoint`, `GPS Track`, `FieldPhoto`, `Measurement`, `Navigation`, `Coordinates`, `Settings`, `VN2000`, `MBTiles`, import `GeoJSON/KML/GPX/MBTiles`. Xem `docs/APK_ANALYSIS.md`.

## Roadmap

- v0.2: session/project khảo sát, form schema, thuộc tính động, QA/QC.
- v0.3: PMTiles vector/MVT, VFM layer adapter, cache vùng chọn.
- v0.4: đồng bộ WebGIS, conflict resolution, audit trail.
- v0.5: RTK/NMEA/Bluetooth GNSS, geofence, survey workflow.

## License

MIT.
