# Vietflex Field WebGIS

## Chạy local

`webgis/` là static site. Runtime JavaScript được lưu theo các fragment byte-for-byte để cập nhật ổn định qua repository; ghép trước khi serve:

```bash
cat webgis/src/app.part-* > webgis/app.js
echo "742a816db91339cdac6cd5386eeeb32f41e9e139d475fd63913d1754b8a5eeaf  webgis/app.js" | sha256sum -c -
python -m http.server 8080 --directory webgis
```

Mở `http://localhost:8080`.

Không nên mở trực tiếp bằng `file://` vì Service Worker, module import, Geolocation và một số chính sách CORS yêu cầu HTTP/HTTPS.

## GitHub Pages

Workflow `.github/workflows/pages.yml` ghép runtime, xác minh SHA-256, kiểm cú pháp JavaScript và manifest, sau đó đóng gói thư mục `webgis/` để triển khai bằng GitHub Pages khi `main` thay đổi.

Trang dự kiến:

`https://vietflexmap.github.io/thucdia/`

## PMTiles

Chọn **Thêm PMTiles**, nhập URL HTTP(S) tới archive. Server/object storage cần:

- hỗ trợ `Range` request;
- trả `206 Partial Content` khi phù hợp;
- cho phép CORS từ origin WebGIS;
- expose các header Range cần thiết nếu cấu hình bucket/CDN yêu cầu.

Raster PMTiles có thể thêm trực tiếp. Vector PMTiles cần `source-layer`; WebGIS thử đọc `vector_layers` từ metadata trước khi yêu cầu nhập thủ công.

## Offline

Service Worker cache application shell. Feature/workspace được lưu trong IndexedDB. Bản đồ nền online không trở thành bản đồ offline chỉ vì application shell đã cache. Offline production nên dùng PMTiles/VFM/package dữ liệu được quản lý riêng.

## Đồng bộ

Nút **WebGIS API** lưu endpoint backend. v0.2 chưa có auth contract nên nút **Đồng bộ** không gửi dữ liệu và không xóa hàng đợi; đây là hành vi có chủ đích để tránh false-sync.
