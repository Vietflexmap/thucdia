import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/vn2000.dart';
import '../../data/app_state.dart';

class CoordinatesScreen extends StatelessWidget {
  const CoordinatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final p = state.currentPosition;
        final projected = p == null
            ? null
            : Vn2000.projectWgs84(
                latitude: p.latitude,
                longitude: p.longitude,
                centralMeridian: state.centralMeridian,
              );
        return Scaffold(
          appBar: AppBar(title: const Text('Tọa độ thực địa')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                context,
                title: 'WGS84 · EPSG:4326',
                rows: {
                  'Vĩ độ': p?.latitude.toStringAsFixed(8) ?? '—',
                  'Kinh độ': p?.longitude.toStringAsFixed(8) ?? '—',
                  'Cao độ': p == null ? '—' : '${p.altitude.toStringAsFixed(2)} m',
                  'Độ chính xác': p == null ? '—' : '±${p.accuracy.toStringAsFixed(1)} m',
                  'Tốc độ': p == null ? '—' : '${(p.speed * 3.6).toStringAsFixed(1)} km/h',
                  'Hướng': p == null ? '—' : '${p.heading.toStringAsFixed(1)}°',
                },
                onCopy: p == null ? null : () => _copy(context, '${p.latitude}, ${p.longitude}'),
              ),
              const SizedBox(height: 12),
              _card(
                context,
                title: 'VN-2000 / TM-3 (bước chiếu)',
                rows: {
                  'X (Northing)': projected == null ? '—' : projected.xNorthing.toStringAsFixed(3),
                  'Y (Easting)': projected == null ? '—' : projected.yEasting.toStringAsFixed(3),
                  'Kinh tuyến trục': '${state.centralMeridian.toStringAsFixed(5)}°',
                  'k₀': projected?.scaleFactor.toStringAsFixed(4) ?? '0.9999',
                },
                onCopy: projected == null
                    ? null
                    : () => _copy(context, '${projected.xNorthing.toStringAsFixed(3)}, ${projected.yEasting.toStringAsFixed(3)}'),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Lưu ý nghiệp vụ: tọa độ GNSS là WGS84. Màn hình VN-2000 hiện thực hiện bước chiếu Transverse Mercator theo kinh tuyến trục cấu hình. Công việc địa chính chính xác cao cần thêm bộ tham số chuyển datum WGS84 ↔ VN-2000 đã được đơn vị có thẩm quyền phê duyệt.',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required Map<String, String> rows,
    VoidCallback? onCopy,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                IconButton(onPressed: onCopy, tooltip: 'Sao chép', icon: const Icon(Icons.copy_outlined)),
              ],
            ),
            const Divider(),
            ...rows.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    SelectableText(entry.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép tọa độ')));
    }
  }
}
