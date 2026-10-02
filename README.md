# Vietflex Thực địa

Ứng dụng GIS thực địa mã nguồn mở theo kiến trúc clean-room, được thiết kế lại từ yêu cầu nghiệp vụ và hành vi quan sát được của DVTmap.apk.

## Mục tiêu

- Offline-first cho Android khi đi thực địa.
- Ghi waypoint, track GNSS, ảnh hiện trường và thuộc tính.
- Đo khoảng cách, diện tích, phương vị.
- Làm việc với WGS84 và VN-2000.
- Import/export GeoJSON, KML, GPX; chuẩn bị adapter MBTiles/PMTiles.
- Dữ liệu có ID ổn định, timestamp, accuracy và metadata để đồng bộ về WebGIS.

## Nguyên tắc clean-room

Repository này không chứa mã nguồn trích xuất từ APK đóng. Kiến trúc và mã được viết lại độc lập dựa trên chức năng, định dạng dữ liệu, tài nguyên mã nguồn mở và yêu cầu nghiệp vụ thực địa.

## Kiến trúc dự kiến

```
lib/
  core/       # CRS, VN-2000, cấu hình bản đồ
  data/       # model dữ liệu thực địa
  services/   # GNSS, lưu trữ, track, import/export
  features/   # map, waypoint, media, coordinate, settings
```

## Lộ trình

1. Core field GIS: Map + GNSS + waypoint + track + measurement.
2. Offline basemap: MBTiles/PMTiles.
3. Media: ảnh có GNSS/heading/time.
4. Import/export và đồng bộ WebGIS.
5. QA/QC thực địa, form schema, phân quyền và audit.

License: MIT.
